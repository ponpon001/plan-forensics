"""Plan Forensics service: persistent tasks, evidence, and AI recovery clues."""

import datetime;


enum Category { WORK, STUDY, PERSONAL, SHOPPING, HEALTH, FITNESS, OTHER }

sem Category.WORK = "Jobs, meetings, and professional tasks";
sem Category.STUDY = "School, courses, exams, homework, and learning";
sem Category.PERSONAL = "Personal errands and private-life tasks";
sem Category.HEALTH = "Medical appointments, medication, rest, and health maintenance";
sem Category.SHOPPING = "Buying groceries, clothing, household goods, or other items";
sem Category.FITNESS = "Exercise, workouts, sports, and physical training";
sem Category.OTHER = "Tasks that do not fit any other category";


def:priv categorize(title: str) -> Category by llm();
sem categorize = """
Classify the task title into the single most suitable category.
School subjects, studying, homework, and exams must be categorized as STUDY.
Use HEALTH only for medical care, medication, rest, or health maintenance.
""";


def:priv propose_smallest_recovery_step(
    task_title: str, blocker_reason: str, blocker_note: str
) -> str by llm();

sem propose_smallest_recovery_step = """
Return exactly one immediately executable action for the specific task.
The action must take five minutes or less, start with a verb, and produce a
visible output. Name a concrete noun, document, topic, person, or deliverable
from task_title or blocker_note. Do not schedule work for later and do not use
vague phrases such as "open the materials", "make progress", "work on it",
"do the easiest action", or "reserve time". Use at most 24 words and never
give multiple options or motivational advice.
""";


node Task {
    has title: str,
        done: bool = False,
        category: str = "other",
        priority: str = "medium",
        planned_minutes: int = 25,
        due_date: str = "",
        created_at: str = "",
        focus_seconds: int = 0,
        focus_started_at: str = "",
        focus_running: bool = False,
        blocker_reason: str = "",
        blocker_note: str = "",
        blocker_count: int = 0,
        next_step: str = "",
        recovery_source: str = "";
}


node BlockerReport {
    has reason: str,
        note: str = "",
        created_at: str = "",
        recovery_step: str = "",
        outcome: str = "pending",
        started_at: str = "",
        completed_at: str = "",
        elapsed_seconds: int = 0,
        recovery_source: str = "";
}


obj TaskView {
    has id: str,
        title: str,
        done: bool = False,
        category: str = "other",
        priority: str = "medium",
        planned_minutes: int = 25,
        due_date: str = "",
        created_at: str = "",
        focus_seconds: int = 0,
        focus_started_at: str = "",
        focus_running: bool = False,
        blocker_reason: str = "",
        blocker_note: str = "",
        blocker_count: int = 0,
        next_step: str = "",
        recovery_source: str = "";
}


obj BlockerReportView {
    has id: str,
        task_id: str,
        task_title: str,
        reason: str,
        note: str = "",
        created_at: str = "",
        recovery_step: str = "",
        outcome: str = "pending",
        started_at: str = "",
        completed_at: str = "",
        elapsed_seconds: int = 0,
        recovery_source: str = "";
}


obj PlannerSnapshot {
    has tasks: list[TaskView] = [],
        reports: list[BlockerReportView] = [],
        remaining: int = 0,
        completed: int = 0,
        planned_minutes: int = 0,
        blocker_reports: int = 0,
        recovery_attempts: int = 0,
        recovery_successes: int = 0,
        top_blocker: str = "";
}


def:priv to_view(task: Task) -> TaskView {
    live_seconds = task.focus_seconds;
    if task.focus_running and task.focus_started_at {
        started = datetime.datetime.fromisoformat(task.focus_started_at);
        live_seconds += max(0, int((datetime.datetime.now(datetime.UTC) - started).total_seconds()));
    }
    return TaskView(
        id=jid(task),
        title=task.title,
        done=task.done,
        category=task.category,
        priority=task.priority,
        planned_minutes=task.planned_minutes,
        due_date=task.due_date,
        created_at=task.created_at,
        focus_seconds=live_seconds,
        focus_started_at=task.focus_started_at,
        focus_running=task.focus_running,
        blocker_reason=task.blocker_reason,
        blocker_note=task.blocker_note,
        blocker_count=task.blocker_count,
        next_step=task.next_step,
        recovery_source=task.recovery_source
    );
}


def:priv to_report_view(task: Task, incident: BlockerReport) -> BlockerReportView {
    return BlockerReportView(
        id=jid(incident),
        task_id=jid(task),
        task_title=task.title,
        reason=incident.reason,
        note=incident.note,
        created_at=incident.created_at,
        recovery_step=incident.recovery_step,
        outcome=incident.outcome,
        started_at=incident.started_at,
        completed_at=incident.completed_at,
        elapsed_seconds=incident.elapsed_seconds,
        recovery_source=incident.recovery_source
    );
}


def:priv clean_due_date(value: str) -> str {
    clean = value.strip();
    if clean {
        try {
            datetime.date.fromisoformat(clean);
        } except Exception {
            raise ValueError("Date must use YYYY-MM-DD.");
        }
    }
    return clean;
}


def:priv settle_focus(task: Task) {
    if task.focus_running and task.focus_started_at {
        try {
            started = datetime.datetime.fromisoformat(task.focus_started_at);
            now = datetime.datetime.now(datetime.UTC);
            elapsed = int((now - started).total_seconds());
            if elapsed > 0 {
                task.focus_seconds += elapsed;
            }
        } except Exception {}
    }
    task.focus_running = False;
    task.focus_started_at = "";
}

def:priv fallback_recovery_step(
    task_title: str, reason: str, blocker_note: str
) -> str {
    task = '"' + task_title.strip() + '"';
    evidence = blocker_note.strip();
    if reason == "too_large" {
        return "Rewrite "
            + task
            + " as three checkboxes, then begin only the first checkbox for five minutes.";
    }
    if reason == "no_time" {
        return "Set a five-minute timer for "
            + task
            + ", list its next three actions, and begin the first one now.";
    }
    if reason == "low_energy" {
        return "Set a five-minute timer, open "
            + task
            + ", and produce one visible line, answer, or change.";
    }
    if reason == "missing_resource" {
        return "For "
            + task
            + ", name the exact missing item or person and send one request for it now.";
    }
    if reason == "unclear" {
        return "For "
            + task
            + ", write one sentence defining done and the first action that would make it true.";
    }
    if evidence {
        return "Turn this blocker into one physical action for "
            + task
            + ": "
            + evidence;
    }
    return "For "
        + task
        + ", write the next physical action and do it for five minutes.";
}


def:protect add_task(
    title: str,
    priority: str = "medium",
    planned_minutes: int = 25,
    due_date: str = ""
) -> TaskView {
    clean_title = title.strip();
    if not clean_title or len(clean_title) > 160 {
        raise ValueError("Use a task title between 1 and 160 characters.");
    }
    if priority not in ["low", "medium", "high"] {
        raise ValueError("Priority must be low, medium, or high.");
    }
    if planned_minutes < 5 or planned_minutes > 240 {
        raise ValueError("Planned time must be between 5 and 240 minutes.");
    }
    category = "other";
    try {
        category = str(categorize(clean_title)).split(".")[-1].lower();
    } except Exception {}
    task = root ++> Task(
        title=clean_title,
        category=category,
        priority=priority,
        planned_minutes=planned_minutes,
        due_date=clean_due_date(due_date),
        created_at=datetime.datetime.now(datetime.UTC).isoformat()
    );
    return to_view(task);
}


def:protect update_task(
    id: str,
    title: str,
    due_date: str,
    priority: str,
    planned_minutes: int
) -> TaskView | None {
    clean_title = title.strip();
    if not clean_title or len(clean_title) > 160 {
        raise ValueError("Use a task title between 1 and 160 characters.");
    }
    if priority not in ["low", "medium", "high"] {
        raise ValueError("Priority must be low, medium, or high.");
    }
    if planned_minutes < 5 or planned_minutes > 240 {
        raise ValueError("Planned time must be between 5 and 240 minutes.");
    }
    clean_date = clean_due_date(due_date);
    for task in [root-->][?:Task] {
        if jid(task) == id {
            task.title = clean_title;
            task.due_date = clean_date;
            task.priority = priority;
            task.planned_minutes = planned_minutes;
            return to_view(task);
        }
    }
    return None;
}


def:protect control_task_timer(id: str, action: str) -> TaskView | None {
    if action not in ["start", "pause", "finish", "reset"] {
        raise ValueError("Timer action must be start, pause, finish, or reset.");
    }
    for task in [root-->][?:Task] {
        if jid(task) == id {
            if action == "start" {
                if task.done {
                    raise ValueError("Reopen the task before starting focus time.");
                }
                if not task.focus_running {
                    task.focus_started_at = datetime.datetime.now(
                        datetime.UTC
                    ).isoformat();
                    task.focus_running = True;
                }
            } elif action == "pause" {
                settle_focus(task);
            } elif action == "finish" {
                settle_focus(task);
                task.done = True;
            } else {
                task.focus_seconds = 0;
                task.focus_started_at = "";
                task.focus_running = False;
            }
            return to_view(task);
        }
    }
    return None;
}


def:protect get_tasks -> list[TaskView] {
    return [to_view(task) for task in [root-->][?:Task]];
}


def:protect get_dashboard -> PlannerSnapshot {
    tasks = [root-->][?:Task];
    views = [to_view(task) for task in tasks];
    report_views: list[BlockerReportView] = [];
    for task in tasks {
        for incident in [task-->][?:BlockerReport] {
            report_views.append(to_report_view(task, incident));
        }
    }
    remaining = sum(
        1
        for task in tasks
        if not task.done
    );
    completed = sum(
        1
        for task in tasks
        if task.done
    );
    planned = sum(
        task.planned_minutes
        for task in tasks
        if not task.done
    );
    reports = len(report_views);
    recovery_attempts = sum(
        1
        for incident in report_views
        if incident.outcome in ["worked", "still_blocked", "stopped_early"]
    );
    recovery_successes = sum(
        1
        for incident in report_views
        if incident.outcome == "worked"
    );
    top_reason = "";
    top_count = 0;
    for reason in [
        "unclear",
        "too_large",
        "no_time",
        "low_energy",
        "missing_resource",
        "other"
    ] {
        count = sum(
            1
            for incident in report_views
            if incident.reason == reason
        );
        if count > top_count {
            top_reason = reason;
            top_count = count;
        }
    }
    return PlannerSnapshot(
        tasks=views,
        reports=report_views,
        remaining=remaining,
        completed=completed,
        planned_minutes=planned,
        blocker_reports=reports,
        recovery_attempts=recovery_attempts,
        recovery_successes=recovery_successes,
        top_blocker=top_reason
    );
}


def:protect toggle_task(id: str) -> TaskView | None {
    for task in [root-->][?:Task] {
        if jid(task) == id {
            if not task.done {
                settle_focus(task);
            }
            task.done = not task.done;
            return to_view(task);
        }
    }
    return None;
}


def:protect delete_task(id: str) -> dict[str, str] {
    for task in [root-->][?:Task] {
        if jid(task) == id {
            del task;
            return {"deleted": id};
        }
    }
    return {};
}


"""Record blocker evidence without depending on the AI provider."""
def:protect record_task_blocker(
    id: str, reason: str, note: str = ""
) -> TaskView | None {
    if reason
        not in [
            "no_time",
            "low_energy",
            "too_large",
            "unclear",
            "missing_resource",
            "other"
        ] {
        raise ValueError("Choose a supported blocker reason.");
    }
    if len(note.strip()) > 500 {
        raise ValueError("Keep the note within 500 characters.");
    }
    for task in [root-->][?:Task] {
        if jid(task) == id {
            if task.done {
                raise ValueError("Reopen the task before reporting a blocker.");
            }
            task.blocker_reason = reason;
            task.blocker_note = note.strip();
            task.blocker_count += 1;
            task.next_step = "";
            task ++> BlockerReport(
                reason=reason,
                note=note.strip(),
                created_at=datetime.datetime.now(datetime.UTC).isoformat()
            );
            return to_view(task);
        }
    }
    return None;
}


"""Generate a recovery clue, falling back locally when Gemini is unavailable."""
def:protect request_recovery(id: str) -> TaskView | None {
    for task in [root-->][?:Task] {
        if jid(task) == id {
            if task.done {
                raise ValueError("Reopen the task before requesting a recovery step.");
            }
            if not task.blocker_reason {
                raise ValueError("Record a blocker before requesting a recovery step.");
            }
            suggestion = "";
            try {
                suggestion = propose_smallest_recovery_step(
                    task.title, task.blocker_reason, task.blocker_note
                ).strip();
            } except Exception {}
            task.recovery_source = "gemini" if suggestion else "fallback";
            task.next_step = suggestion
                if suggestion
                else fallback_recovery_step(
                    task.title, task.blocker_reason, task.blocker_note
                );
            reports = [task-->][?:BlockerReport];
            if len(reports) > 0 {
                latest = reports[len(reports) - 1];
                latest.recovery_step = task.next_step;
                latest.recovery_source = task.recovery_source;
            }
            return to_view(task);
        }
    }
    return None;
}


def:protect begin_recovery(report_id: str) -> BlockerReportView | None {
    for task in [root-->][?:Task] {
        for incident in [task-->][?:BlockerReport] {
            if jid(incident) == report_id {
                if not incident.recovery_step {
                    raise ValueError(
                        "Generate a recovery step before starting the timer."
                    );
                }
                incident.outcome = "running";
                incident.started_at = datetime.datetime.now(datetime.UTC).isoformat();
                incident.completed_at = "";
                incident.elapsed_seconds = 0;
                return to_report_view(task, incident);
            }
        }
    }
    return None;
}


def:protect finish_recovery(
    report_id: str, outcome: str, elapsed_seconds: int
) -> BlockerReportView | None {
    if outcome not in ["worked", "still_blocked", "stopped_early"] {
        raise ValueError("Choose a supported recovery outcome.");
    }
    if elapsed_seconds < 0 or elapsed_seconds > 3600 {
        raise ValueError("Recovery time must be between 0 and 3600 seconds.");
    }
    for task in [root-->][?:Task] {
        for incident in [task-->][?:BlockerReport] {
            if jid(incident) == report_id {
                if not incident.started_at {
                    raise ValueError(
                        "Start the recovery timer before recording an outcome."
                    );
                }
                incident.outcome = outcome;
                incident.completed_at = datetime.datetime.now(datetime.UTC).isoformat();
                incident.elapsed_seconds = elapsed_seconds;
                return to_report_view(task, incident);
            }
        }
    }
    return None;
}

test "blocker updates preserve task and record repeated attempts" {
    task = root ++> Task(title="Blocker test");
    try {
        saved = record_task_blocker(jid(task), "unclear", "  Need requirements  ");
        assert saved is not None;
        assert saved.blocker_note == "Need requirements";
        assert not saved.done;
        assert saved.title == "Blocker test";
        saved = record_task_blocker(jid(task), "too_large");
        assert saved is not None;
        assert saved.blocker_count == 2;
        assert saved.blocker_reason == "too_large";
        assert saved.blocker_note == "";
    } finally {
        del task;
    }
}


test "invalid blocker inputs leave the task unchanged" {
    task = root ++> Task(title="Validation test");
    try {
        with testraises(ValueError) {
            record_task_blocker(jid(task), "unknown");
        }
        with testraises(ValueError) {
            record_task_blocker(jid(task), "other", "x" * 501);
        }
        assert task.blocker_count == 0;
        task.done = True;
        with testraises(ValueError) {
            record_task_blocker(jid(task), "no_time");
        }
        assert task.blocker_count == 0;
    } finally {
        del task;
    }
}


test "blocker cannot target a task outside the current root" {
    unattached = Task(title="Not owned by current root");
    try {
        assert record_task_blocker(jid(unattached), "no_time") is None;
        assert unattached.blocker_count == 0;
    } finally {
        del unattached;
    }
}


test "dashboard summarizes persistent task evidence" {
    first = root ++> Task(
        title="One", planned_minutes=30, blocker_reason="unclear", blocker_count=2
    );
    second = root ++> Task(title="Two", done=True, planned_minutes=45);
    first_report = first ++> BlockerReport(
        reason="unclear", recovery_step="Ask one question."
    );
    second_report = first ++> BlockerReport(
        reason="unclear",
        recovery_step="Open the instructions.",
        outcome="worked",
        started_at="2026-01-01T00:00:00+00:00",
        completed_at="2026-01-01T00:03:00+00:00",
        elapsed_seconds=180
    );
    try {
        snapshot = get_dashboard();
        assert snapshot.remaining >= 1;
        assert snapshot.completed >= 1;
        assert snapshot.planned_minutes >= 30;
        assert snapshot.blocker_reports >= 2;
        assert snapshot.recovery_attempts >= 1;
        assert snapshot.recovery_successes >= 1;
        assert snapshot.top_blocker == "unclear";
    } finally {
        del first_report;
        del second_report;
        del first;
        del second;
    }
}


test "fallback recovery is task-specific and respects five minutes" {
    suggestion = fallback_recovery_step(
        "review and prepare for my midterm exam", "no_time", ""
    );
    assert "review and prepare for my midterm exam" in suggestion;
    assert "five-minute" in suggestion;
    assert "ten-minute" not in suggestion;
    assert "next three actions" in suggestion;
}

test "recovery timer records a validated outcome" {
    task = root ++> Task(title="Recovery test");
    incident = task ++> BlockerReport(
        reason="too_large", recovery_step="Write the first subtask."
    );
    try {
        started = begin_recovery(jid(incident));
        assert started is not None;
        assert started.outcome == "running";
        finished = finish_recovery(jid(incident), "worked", 75);
        assert finished is not None;
        assert finished.outcome == "worked";
        assert finished.elapsed_seconds == 75;
        with testraises(ValueError) {
            finish_recovery(jid(incident), "invalid", 10);
        }
    } finally {
        del incident;
        del task;
    }
}


test "task edits validate and preserve shared fields" {
    task = root ++> Task(title="Draft", category="study");
    try {
        saved = update_task(
            jid(task), "Revised draft", "2026-10-12", "high", 45
        );
        assert saved is not None;
        assert saved.title == "Revised draft";
        assert saved.due_date == "2026-10-12";
        assert saved.priority == "high";
        assert saved.planned_minutes == 45;
        assert saved.category == "study";
        with testraises(ValueError) {
            update_task(jid(task), "Still valid", "10/12/2026", "high", 45);
        }
    } finally {
        del task;
    }
}


test "task focus timer starts pauses resets and finishes" {
    task = root ++> Task(title="Timed task");
    try {
        started = control_task_timer(jid(task), "start");
        assert started is not None;
        assert started.focus_running;
        task.focus_started_at = (
            datetime.datetime.now(datetime.UTC) - datetime.timedelta(seconds=70)
        ).isoformat();
        assert to_view(task).focus_seconds >= 70;
        paused = control_task_timer(jid(task), "pause");
        assert paused is not None;
        assert not paused.focus_running;
        assert paused.focus_seconds >= 70;
        reset = control_task_timer(jid(task), "reset");
        assert reset is not None;
        assert reset.focus_seconds == 0;
        control_task_timer(jid(task), "start");
        finished = control_task_timer(jid(task), "finish");
        assert finished is not None;
        assert finished.done;
        assert not finished.focus_running;
        with testraises(ValueError) {
            control_task_timer(jid(task), "invalid");
        }
    } finally {
        del task;
    }
}
