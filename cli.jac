"""Command-line companion for the shared Plan Forensics service."""
import argparse;
import asyncio;
import getpass;
import json;
import os;
import sys;
import time;
import urllib.error;
import urllib.request;
import from pathlib { Path }
import from types { SimpleNamespace }
import from jaclang.server { sv_client }
import from endpoints {
    TaskView, BlockerReportView, add_task, get_dashboard, toggle_task, update_task, delete_task,
    control_task_timer, record_task_blocker, request_recovery,
    begin_recovery, finish_recovery
}

def auth_request(base: str, username: str, password: str, register: bool = False) -> str {
    identity = {"type": "username", "value": username};
    payload: dict[str, any] = {"credential": {"type": "password", "password": password}};
    if register { payload["identities"] = [identity]; }
    else { payload["identity"] = identity; }
    operation = "register" if register else "login";
    for prefix in ["/api/planner/user/", "/user/"] {
        request = urllib.request.Request(
            base + prefix + operation, data=json.dumps(payload).encode(),
            headers={"Content-Type": "application/json"}
        );
        try {
            with urllib.request.urlopen(request, timeout=15) as response {
                return str(json.loads(response.read())["data"]["token"]);
            }
        } except urllib.error.HTTPError as error {
            if error.code in [404, 405] and prefix == "/api/planner/user/" { continue; }
            raise ValueError(
                ("Registration" if register else "Sign-in") + " failed (HTTP "
                + str(error.code) + "). " + error.read().decode(errors="replace")[:240]
            );
        }
    }
    raise ValueError("Authentication endpoint was not found on this server.");
}

def session_error(saved_url: str, current_url: str) -> str {
    return (
        "Saved login belongs to " + saved_url + ", but this command targets "
        + current_url + ". Use --url " + saved_url
        + " or sign in again with: jac run cli -- --url " + current_url + " login USERNAME"
    );
}

def format_task(task: any) -> str {
    mark = "✓" if task.done else "○";
    due = " · due " + task.due_date if task.due_date else "";
    focus = " · focus " + str(task.focus_seconds // 60) + "m" if task.focus_seconds else "";
    return (
        f"{mark} {task.id}  [{task.priority} / {task.category}] {task.title}"
        f" · {task.planned_minutes}m{due}{focus}"
    );
}

def print_report(incident: BlockerReportView) {
    print(f"{incident.id} · {incident.created_at[:10]} · {incident.task_title}");
    print("  Blocker: " + incident.reason.replace("_", " "));
    if incident.note { print("  Note: " + incident.note); }
    print("  Outcome: " + incident.outcome.replace("_", " "));
    if incident.recovery_step {
        print("  Five-minute experiment: " + incident.recovery_step);
        print("  Source: " + incident.recovery_source);
    }
    if incident.started_at { print("  Started: " + incident.started_at); }
    if incident.completed_at {
        print("  Finished: " + incident.completed_at);
        print("  Focused: " + str(incident.elapsed_seconds) + " seconds");
    }
}

def countdown(seconds: int) -> int {
    started = time.monotonic();
    try {
        while True {
            elapsed = int(time.monotonic() - started);
            left = max(0, seconds - elapsed);
            print(f"\rRecovery time remaining: {left // 60:02d}:{left % 60:02d} ", end="", flush=True);
            if left == 0 { break; }
            time.sleep(1);
        }
    } except KeyboardInterrupt {
        print("\nTimer stopped early. You can still record your result.");
    }
    print();
    return min(3600, int(time.monotonic() - started));
}

async def main -> int {
    parser = argparse.ArgumentParser(description="Plan Forensics: tasks and recovery from the terminal.");
    parser.add_argument("--url", `default=os.environ.get("PLAN_FORENSICS_URL", "http://127.0.0.1:8000"));
    parser.add_argument("--priority", choices=["low", "medium", "high"]);
    parser.add_argument("--minutes", type=int);
    parser.add_argument("--due", `default=None, help="YYYY-MM-DD; use an empty value to clear");
    parser.add_argument("--title", `default=None, help="New title for edit");
    parser.add_argument("command", choices=[
        "register", "login", "logout", "today", "add", "edit", "toggle",
        "block", "blockers", "recovered", "report", "recover", "finish", "timer", "delete"
    ]);
    parser.add_argument("value", nargs="?", `default="");
    parser.add_argument("extra", nargs="*");
    args = parser.parse_args();
    base = str(args.url).rstrip("/");
    credentials = Path(os.environ.get(
        "PLAN_FORENSICS_SESSION", str(Path.home() / ".plan-forensics.json")
    ));
    os.environ["JAC_APP_PLANNER_URL"] = base + "/api/planner";
    try {
        if args.command == "logout" {
            credentials.unlink(missing_ok=True);
            print("Signed out.");
            return 0;
        }
        if args.command in ["register", "login"] {
            if not args.value { parser.error(args.command + " needs a username"); }
            password = os.environ.get("PLAN_FORENSICS_PASSWORD") or getpass.getpass("Password: ");
            if args.command == "register" and len(password) < 8 {
                raise ValueError("Use at least 8 characters for the password.");
            }
            token = auth_request(base, str(args.value), password, args.command == "register");
            fd = os.open(str(credentials), os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600);
            with os.fdopen(fd, "w") as handle { json.dump({"url": base, "token": token}, handle); }
            credentials.chmod(0o600);
            print("Account created and signed in." if args.command == "register" else "Signed in.");
            return 0;
        }
        if not credentials.exists() {
            raise ValueError("Sign in first: jac run cli -- login USERNAME");
        }
        saved = json.loads(credentials.read_text());
        if saved.get("url") != base {
            raise ValueError(session_error(str(saved.get("url", "unknown")), base));
        }
        sv_client.set_bearer_token(str(saved["token"]));
        if args.command in ["add", "edit", "toggle", "block", "report", "recover", "finish", "timer", "delete"] and not args.value {
            parser.error(args.command + " needs a task title or ID");
        }

        if args.command == "add" {
            added_task = await add_task(str(args.value), str(args.priority or "medium"),
                int(args.minutes or 25), str(args.due or ""));
            print("Added: " + format_task(added_task));
        } elif args.command == "edit" {
            snapshot = await get_dashboard();
            current = next((task for task in snapshot.tasks if task.id == args.value), None);
            if current is None { raise ValueError("Task not found."); }
            edited = await update_task(
                current.id, str(args.title if args.title is not None else current.title),
                str(args.due if args.due is not None else current.due_date),
                str(args.priority or current.priority),
                int(args.minutes if args.minutes is not None else current.planned_minutes)
            );
            if edited is None { raise ValueError("Task not found."); }
            print("Updated: " + format_task(edited));
        } elif args.command == "toggle" {
            toggled_task = await toggle_task(str(args.value));
            if toggled_task is None { raise ValueError("Task not found."); }
            print(("Resolved: " if toggled_task.done else "Reopened: ") + toggled_task.title);
        } elif args.command == "timer" {
            if not args.extra { parser.error("timer needs start, pause, finish, or reset"); }
            timed_task = await control_task_timer(str(args.value), str(args.extra[0]));
            if timed_task is None { raise ValueError("Task not found."); }
            print("Timer " + str(args.extra[0]) + ": " + format_task(timed_task));
        } elif args.command == "delete" {
            result = await delete_task(str(args.value));
            print("Deleted." if result else "Task not found.");
        } elif args.command == "block" {
            if not args.extra {
                parser.error("block needs a reason: unclear, too_large, no_time, low_energy, missing_resource, or other");
            }
            saved_report = await record_task_blocker(str(args.value), str(args.extra[0]),
                " ".join(str(part) for part in args.extra[1:]));
            if saved_report is None { raise ValueError("Task not found."); }
            recovered = await request_recovery(str(args.value));
            if recovered is not None { print("Next move: " + recovered.next_step); }
        } elif args.command in ["blockers", "recovered", "report"] {
            snapshot = await get_dashboard();
            reports = snapshot.reports;
            if args.command == "recovered" {
                reports = [incident for incident in reports if incident.recovery_step];
            }
            if args.command == "report" {
                reports = [incident for incident in reports if incident.id == args.value];
            }
            if not reports { print("No matching reports yet."); }
            for incident in reports { print_report(incident); print(); }
        } elif args.command == "recover" {
            incident = await begin_recovery(str(args.value));
            if incident is None { raise ValueError("Report not found."); }
            print("Five-minute experiment: " + incident.recovery_step);
            elapsed = countdown(300);
            print("Outcome: 1 = Worked, 2 = Still blocked, 3 = Stopped early");
            choice = input("Choose 1, 2, or 3: ").strip();
            outcomes = {"1": "worked", "2": "still_blocked", "3": "stopped_early"};
            if choice not in outcomes {
                print("No outcome saved. Use `finish REPORT_ID worked|still_blocked|stopped_early SECONDS` later.");
                return 1;
            }
            outcome_report = await finish_recovery(incident.id, outcomes[choice], elapsed);
            if outcome_report is not None { print_report(outcome_report); }
        } elif args.command == "finish" {
            if len(args.extra) < 2 { parser.error("finish needs OUTCOME and elapsed SECONDS"); }
            finished_report = await finish_recovery(str(args.value), str(args.extra[0]), int(args.extra[1]));
            if finished_report is None { raise ValueError("Report not found."); }
            print_report(finished_report);
        } else {
            snapshot = await get_dashboard();
            print(f"PLAN FORENSICS · {snapshot.remaining} open · {snapshot.completed} resolved · {snapshot.planned_minutes} min planned");
            print("─" * 72);
            for task in snapshot.tasks {
                print(format_task(task));
                if task.next_step and not task.done { print("   ↳ " + task.next_step); }
            }
            if not snapshot.tasks { print("No tasks yet. Add one with the add command."); }
        }
        return 0;
    } except Exception as error {
        print("Plan Forensics: " + str(error), file=sys.stderr);
        return 1;
    }
}

test "CLI URL mismatch gives both addresses" {
    message = session_error("http://localhost:8000", "https://example.test");
    assert "http://localhost:8000" in message;
    assert "https://example.test" in message;
    assert "--url" in message;
}

test "CLI task line shows deadline and focus" {
    task = SimpleNamespace(
        id="abc", title="Write report", done=False, category="work",
        priority="high", planned_minutes=25, due_date="2026-10-10", focus_seconds=125
    );
    line = format_task(task);
    assert "Write report" in line;
    assert "2026-10-10" in line;
    assert "focus 2m" in line;
}

with entry:__main__ { sys.`exit(asyncio.run(main())); }
