"""Native mobile companion for Plan Forensics."""
import from "@jac/mobui" { View, Text, TextInput, Pressable, ScrollView }
import from "@jac/runtime" {
    jacSetToken,
    __getApiBaseUrl,
    jacLogout,
    jacIsLoggedIn,
    __getLocalStorage,
    __setLocalStorage
}
import from endpoints {
    TaskView,
    BlockerReportView,
    PlannerSnapshot,
    add_task,
    get_dashboard,
    toggle_task,
    update_task,
    delete_task,
    control_task_timer,
    record_task_blocker,
    request_recovery,
    begin_recovery,
    finish_recovery
}
import from mobile_theme { MC, MS }

def MobileButton(
    label: str, action: Callable, quiet: bool = False, disabled: bool = False
) -> JsxElement {
    return
        <Pressable
            accessibilityRole="button"
            accessibilityLabel={label}
            disabled={disabled}
            onPress={action}
            style={[
                MS.button,
                MS.quietButton if quiet else {},
                {"opacity": 0.45 if disabled else 1}
            ]}
        >
            <Text style={[MS.buttonText, MS.quietButtonText if quiet else {}]}>
                {label}
            </Text>
        </Pressable>;
}

def MobileTask(
    task: TaskView, busy: bool,
    onToggle: Callable[[str], None],
    onEdit: Callable[[str, str, str, str, int], None],
    onDelete: Callable[[str], None],
    onTimer: Callable[[str, str], None],
    onBlock: Callable[[str, str, str], None]
) -> JsxElement {
    has editing: bool = False, reporting: bool = False,
        editTitle: str = task.title, editDate: str = task.due_date,
        editPriority: str = task.priority,
        editMinutes: str = str(task.planned_minutes),
        reason: str = "unclear", note: str = "",
        shownSeconds: int = task.focus_seconds;

    can with [task.focus_seconds, task.focus_running] entry {
        shownSeconds = task.focus_seconds;
    }
    can with [task.focus_running, shownSeconds] entry {
        if task.focus_running {
            tick = setTimeout(lambda { shownSeconds += 1; }, 1000);
            return lambda { clearTimeout(tick); };
        }
    }

    def openEdit {
        editTitle = task.title;
        editDate = task.due_date;
        editPriority = task.priority;
        editMinutes = str(task.planned_minutes);
        editing = True;
    }

    def toggleEdit {
        if editing {
            editing = False;
        } else {
            openEdit();
        }
    }

    <View style={[MS.taskCard, {"opacity": 0.62 if task.done else 1}]}>
        <View style={MS.between}>
            <View style={[MS.stack, {"flex": 1, "gap": 7}]}>
                <Text style={MS.taskTitle}>{task.title}</Text>
                <View style={MS.row}>
                    <View style={MS.pill}>
                        <Text style={MS.pillText}>{task.category}</Text>
                    </View>
                    <Text style={MS.meta}>
                        {str(task.planned_minutes)} min · {task.priority}
                    </Text>
                </View>
                {<Text style={MS.meta}>Due {task.due_date}</Text>
                    if task.due_date else None}
            </View>
            <Pressable
                accessibilityRole="button"
                accessibilityLabel={("Reopen " if task.done else "Complete ")
                    + task.title}
                disabled={busy}
                onPress={lambda { onToggle(task.id); }}
                style={[MS.check, MS.checkDone if task.done else {}]}
            >
                <Text style={MS.checkText}>{"✓" if task.done else ""}</Text>
            </Pressable>
        </View>
        {<View style={MS.divider}/> if task.next_step and not task.done else None}
        {<Text style={MS.small}>Next move · {task.next_step}</Text>
            if task.next_step and not task.done
            else None}
        <View style={MS.divider}/>
        <View style={MS.focusRow}>
            <Text style={MS.focusClock}>{str(int(shownSeconds / 60))}:{("0" if shownSeconds % 60 < 10 else "") + str(shownSeconds % 60)}</Text>
            <Text style={MS.meta}>{"Focusing" if task.focus_running else "Focused"}</Text>
        </View>
        <View style={MS.chipRow}>
            <MobileButton
                label={"Pause" if task.focus_running else ("Resume" if shownSeconds > 0 else "Start focus")}
                action={lambda { onTimer(task.id, "pause" if task.focus_running else "start"); }}
                quiet={True} disabled={busy or task.done}/>
            {<MobileButton label="Finish task" action={lambda { onTimer(task.id, "finish"); }}
                disabled={busy}/> if not task.done else None}
            {<MobileButton label="Reset" action={lambda { onTimer(task.id, "reset"); }}
                quiet={True} disabled={busy}/> if shownSeconds > 0 and not task.done else None}
        </View>
        <View style={MS.chipRow}>
            <MobileButton label={"Cancel edit" if editing else "Edit task"}
                action={toggleEdit}
                quiet={True} disabled={busy}/>
            {<MobileButton label={"Cancel report" if reporting else "Report blocker"}
                action={lambda { reporting = not reporting; }} quiet={True} disabled={busy}/>
                if not task.done else None}
            <MobileButton label="Delete" action={lambda { onDelete(task.id); }}
                quiet={True} disabled={busy}/>
        </View>
        {<View style={MS.stack}>
            <Text style={MS.label}>EDIT TASK</Text>
            <TextInput accessibilityLabel="Edit title" style={MS.input}
                value={editTitle} onChangeText={lambda (value: str) { editTitle = value; }}/>
            <TextInput accessibilityLabel="Due date YYYY-MM-DD" style={MS.input}
                value={editDate} placeholder="YYYY-MM-DD (optional)"
                placeholderTextColor={MC.muted}
                onChangeText={lambda (value: str) { editDate = value; }}/>
            <TextInput accessibilityLabel="Estimated minutes" style={MS.input}
                value={editMinutes} keyboardType="number-pad"
                onChangeText={lambda (value: str) { editMinutes = value; }}/>
            <View style={MS.chipRow}>
                {[<MobileButton key={item} label={item} quiet={editPriority != item}
                    action={lambda { editPriority = item; }}/>
                    for item in ["low", "medium", "high"]]}
            </View>
            <MobileButton label="Save changes" disabled={busy or not editTitle.strip() or not editMinutes.strip()}
                action={lambda {
                    onEdit(task.id, editTitle, editDate, editPriority, int(editMinutes));
                    editing = False;
                }}/>
        </View> if editing else None}
        {<View style={MS.stack}>
            <Text style={MS.label}>WHAT GOT IN THE WAY?</Text>
            <View style={MS.chipRow}>
                {[<MobileButton key={item} label={item.replace("_", " ")}
                    quiet={reason != item} action={lambda { reason = item; }}/>
                    for item in ["unclear", "too_large", "no_time", "low_energy", "missing_resource", "other"]]}
            </View>
            <TextInput accessibilityLabel="Blocker note" style={MS.input}
                value={note} multiline={True} maxLength={500}
                placeholder="What happened right before you stopped?"
                placeholderTextColor={MC.muted}
                onChangeText={lambda (value: str) { note = value; }}/>
            <MobileButton label="Save & find next move" disabled={busy}
                action={lambda { onBlock(task.id, reason, note); reporting = False; note = ""; }}/>
        </View> if reporting else None}
    </View>
}


def MobileReport(
    incident: BlockerReportView, busy: bool,
    onRegenerate: Callable[[str], None],
    onStart: Callable[[str], None],
    onFinish: Callable[[str, str, int], None]
) -> JsxElement {
    has secondsLeft: int = 300,
        active: bool = False,
        running: bool = False,
        reflecting: bool = False;

    can with [running, secondsLeft] entry {
        if running and secondsLeft > 0 {
            tick = setTimeout(lambda { secondsLeft -= 1; }, 1000);
            return lambda { clearTimeout(tick); };
        }
        if running and secondsLeft <= 0 {
            running = False;
            reflecting = True;
        }
    }

    <View style={MS.taskCard}>
        <Text style={MS.eyebrow}>{incident.created_at.split("T")[0]} · {incident.reason.replace("_", " ")}</Text>
        <Text style={MS.taskTitle}>{incident.task_title}</Text>
        {<Text style={MS.small}>{incident.note}</Text> if incident.note else None}
        <Text style={MS.meta}>Status · {incident.outcome.replace("_", " ")}</Text>
        {<View style={MS.recovery}>
            <Text style={MS.label}>FIVE-MINUTE EXPERIMENT</Text>
            <Text style={MS.recoveryText}>{incident.recovery_step}</Text>
            <Text style={MS.meta}>{"Safe fallback" if incident.recovery_source == "fallback" else "AI generated"}</Text>
        </View> if incident.recovery_step else None}
        {<MobileButton label="Regenerate next move" quiet={True} disabled={busy}
            action={lambda { onRegenerate(incident.task_id); }}/>
            if incident.recovery_step else None}
        {<MobileButton label={"Try recovery again" if incident.outcome not in ["pending", "running"] else "Start 5-min recovery"}
            disabled={busy} action={lambda {
                onStart(incident.id);
                secondsLeft = 300;
                active = True;
                running = True;
                reflecting = False;
            }}/>
            if incident.recovery_step and not active else None}
        {<View style={MS.stack}>
            <Text style={MS.focusClock}>{str(int(secondsLeft / 60))}:{("0" if secondsLeft % 60 < 10 else "") + str(secondsLeft % 60)}</Text>
            <View style={MS.chipRow}>
                <MobileButton label={"Pause" if running else "Resume"} quiet={True}
                    action={lambda { running = not running; }}/>
                <MobileButton label="Finish & reflect" action={lambda {
                    running = False; reflecting = True;
                }}/>
            </View>
        </View> if active and not reflecting else None}
        {<View style={MS.stack}>
            <Text style={MS.label}>WHAT HAPPENED?</Text>
            <View style={MS.chipRow}>
                {[<MobileButton key={outcome} label={outcome.replace("_", " ")}
                    disabled={busy} action={lambda {
                        onFinish(incident.id, outcome, 300 - secondsLeft);
                        active = False;
                        reflecting = False;
                    }}/>
                    for outcome in ["worked", "still_blocked", "stopped_early"]]}
            </View>
        </View> if active and reflecting else None}
        {<Text style={MS.meta}>{str(incident.elapsed_seconds)} sec focused</Text>
            if incident.outcome in ["worked", "still_blocked", "stopped_early"] else None}
    </View>
}

def:pub app -> JsxElement {
    has snapshot: PlannerSnapshot = PlannerSnapshot(),
        server: str = "http://10.0.2.2:8000",
        username: str = "",
        password: str = "",
        taskText: str = "",
        taskDate: str = "",
        taskPriority: str = "medium",
        taskMinutes: str = "25",
        activeView: str = "today",
        searchText: str = "",
        categoryFilter: str = "all",
        priorityFilter: str = "all",
        statusFilter: str = "open",
        signup: bool = False,
        connected: bool = False,
        logged: bool = False,
        loading: bool = True,
        busy: bool = False,
        error: str = "";

    async def refresh {
        loading = True;
        error = "";
        try {
            snapshot = await get_dashboard();
        } except Exception {
            error = "Could not load tasks. Check the server address and your session.";
        } finally {
            loading = False;
        }
    }

    async def connect {
        if not server.startswith("http://") and not server.startswith("https://") {
            error = "Use a server address beginning with http:// or https://.";
            return;
        }
        server = server.rstrip("/");
        globalThis.__JAC_API_BASE_URL__ = server;
        __setLocalStorage("plan_forensics_server", server);
        jacLogout();
        logged = False;
        connected = True;
        loading = False;
        error = "";
    }

    can with entry {
        savedServer = __getLocalStorage("plan_forensics_server");
        loggedNow = jacIsLoggedIn();
        hasServer = bool(savedServer);
        if hasServer {
            server = savedServer;
            globalThis.__JAC_API_BASE_URL__ = savedServer;
            connected = True;
        }
        logged = loggedNow;
        if hasServer and loggedNow {
            refresh();
        } else {
            loading = False;
        }
    }

    async def authenticate {
        if busy {
            return;
        }
        if not username.strip() or not password {
            error = "Enter a username and password.";
            return;
        }
        if signup and len(password) < 8 {
            error = "Use at least 8 characters for the password.";
            return;
        }
        busy = True;
        error = "";
        try {
            identity = {"type": "username", "value": username.strip()};
            payload: dict[str, any] = {
                "credential": {"type": "password", "password": password}
            };
            if signup {
                payload["identities"] = [identity];
            } else {
                payload["identity"] = identity;
            }
            operation = "register" if signup else "login";
            requestOptions = {
                "method": "POST",
                "headers": {"Content-Type": "application/json"},
                "body": JSON.stringify(payload)
            };
            response = await fetch(
                __getApiBaseUrl() + "/api/planner/user/" + operation, requestOptions
            );
            if response.status == 404 or response.status == 405 {
                response = await fetch(
                    __getApiBaseUrl() + "/user/" + operation, requestOptions
                );
            }
            result: any = await response.json();
            if not response.ok {
                error = result.error.message or "Could not sign in.";
                return;
            }
            jacSetToken(result.data.token);
            logged = True;
            password = "";
            await refresh();
        } except Exception {
            error = "Could not sign in. Check the server and try again.";
        } finally {
            busy = False;
        }
    }

    async def addTask {
        if busy or not taskText.strip() {
            return;
        }
        busy = True;
        error = "";
        try {
            await add_task(taskText.strip(), taskPriority, int(taskMinutes), taskDate);
            taskText = "";
            taskDate = "";
            await refresh();
        } except Exception {
            error = "Could not add that task. Try again.";
        } finally {
            busy = False;
        }
    }

    async def toggleTask(id: str) {
        if busy {
            return;
        }
        busy = True;
        error = "";
        try {
            await toggle_task(id);
            await refresh();
        } except Exception {
            error = "Could not update that task. Refresh and try again.";
        } finally {
            busy = False;
        }
    }

    async def editTask(id: str, title: str, due: str, priority: str, minutes: int) {
        if busy { return; }
        busy = True;
        error = "";
        try {
            await update_task(id, title, due, priority, minutes);
            await refresh();
        } except Exception {
            error = "Could not save task changes. Check the date and estimate.";
        } finally { busy = False; }
    }

    async def deleteTask(id: str) {
        if busy { return; }
        busy = True;
        error = "";
        try {
            await delete_task(id);
            await refresh();
        } except Exception { error = "Could not delete the task."; }
        finally { busy = False; }
    }

    async def taskTimer(id: str, action: str) {
        if busy { return; }
        busy = True;
        error = "";
        try {
            await control_task_timer(id, action);
            await refresh();
        } except Exception { error = "Could not update the focus timer."; }
        finally { busy = False; }
    }

    async def reportBlocker(id: str, reason: str, note: str) {
        if busy { return; }
        busy = True;
        error = "";
        try {
            await record_task_blocker(id, reason, note);
            await request_recovery(id);
            await refresh();
            activeView = "recovered";
        } except Exception { error = "Could not save the blocker report."; }
        finally { busy = False; }
    }

    async def regenerate(id: str) {
        if busy { return; }
        busy = True;
        error = "";
        try {
            await request_recovery(id);
            await refresh();
        } except Exception { error = "Could not regenerate the next move."; }
        finally { busy = False; }
    }

    async def startRecovery(id: str) {
        if busy { return; }
        busy = True;
        error = "";
        try {
            await begin_recovery(id);
            await refresh();
        } except Exception { error = "Could not start the recovery timer."; }
        finally { busy = False; }
    }

    async def finishRecovery(id: str, outcome: str, elapsed: int) {
        if busy { return; }
        busy = True;
        error = "";
        try {
            await finish_recovery(id, outcome, elapsed);
            await refresh();
        } except Exception { error = "Could not save recovery feedback."; }
        finally { busy = False; }
    }

    async def logout {
        jacLogout();
        logged = False;
        password = "";
        snapshot = PlannerSnapshot();
    }

    visibleTasks = [
        task for task in snapshot.tasks
        if (not searchText.strip() or searchText.lower() in task.title.lower())
        and (categoryFilter == "all" or task.category == categoryFilter)
        and (priorityFilter == "all" or task.priority == priorityFilter)
        and (statusFilter == "all"
            or (statusFilter == "open" and not task.done)
            or (statusFilter == "completed" and task.done))
    ];
    recoveredReports = [incident for incident in snapshot.reports if incident.recovery_step];
    successRate = int((snapshot.recovery_successes * 100) / snapshot.recovery_attempts)
        if snapshot.recovery_attempts > 0 else 0;

    <ScrollView
        style={MS.screen}
        contentContainerStyle={MS.page}
        keyboardShouldPersistTaps="handled"
    >
        <View style={MS.header}>
            <View style={MS.brandRow}>
                <View style={MS.brandMark}>
                    <Text style={MS.brandMarkText}>PF</Text>
                </View>
                <View>
                    <Text style={MS.brand}>Plan Forensics</Text>
                    <Text style={MS.meta}>Mobile field desk</Text>
                </View>
            </View>
            {<MobileButton label="Sign out" action={logout} quiet={True}/>
                if logged
                else None}
        </View>
        {<Text accessibilityRole="alert" style={MS.error}>{error}</Text>
            if error
            else None}
        {<View style={MS.card}>
            <Text style={MS.eyebrow}>CONNECT TO YOUR SERVER</Text>
            <Text style={MS.title}>Open the same case file.</Text>
            <Text style={MS.subtitle}>
                Use your computer’s LAN address, or 10.0.2.2 from the Android emulator.
            </Text>
            <TextInput
                accessibilityLabel="Server address"
                style={MS.input}
                value={server}
                autoCapitalize="none"
                onChangeText={lambda (text: str) { server = text; }}
            />
            <MobileButton label="Connect" action={connect}/>
        </View>
            if not connected
            else None}
        {<View style={MS.card}>
            <Text style={MS.eyebrow}>PRIVATE CASE FILE</Text>
            <Text style={MS.title}>
                {"Create workspace" if signup else "Welcome back"}
            </Text>
            <TextInput
                accessibilityLabel="Username"
                style={MS.input}
                value={username}
                autoCapitalize="none"
                placeholder="Username"
                placeholderTextColor={MC.muted}
                onChangeText={lambda (text: str) { username = text; }}
            />
            <TextInput
                accessibilityLabel="Password"
                style={MS.input}
                value={password}
                secureTextEntry={True}
                placeholder="Password"
                placeholderTextColor={MC.muted}
                onChangeText={lambda (text: str) { password = text; }}
            />
            <MobileButton
                label={"Create workspace" if signup else "Sign in"}
                action={authenticate}
                disabled={busy}
            />
            <MobileButton
                label={"Sign in instead" if signup else "Create an account"}
                action={lambda {
                    signup = not signup;
                    error = "";
                }}
                quiet={True}
                disabled={busy}
            />
        </View>
            if connected and not logged
            else None}
        {<View style={MS.stack}>
            <View style={MS.tabs}>
                {[<Pressable key={item} accessibilityRole="button"
                    accessibilityLabel={item} onPress={lambda { activeView = item; }}
                    style={[MS.tab, MS.tabActive if activeView == item else {}]}>
                    <Text style={[MS.tabText, MS.tabTextActive if activeView == item else {}]}>
                        {"Today" if item == "today" else ("Blocker reports" if item == "blockers" else "Recovered plans")}
                    </Text>
                </Pressable> for item in ["today", "blockers", "recovered"]]}
            </View>
            {<View style={MS.stack}>
                <Text style={MS.eyebrow}>TODAY’S CASE LOAD</Text>
                <Text style={MS.title}>Make the next move visible.</Text>
                <View style={MS.summary}>
                    <View><Text style={MS.summaryNumber}>{str(snapshot.remaining)}</Text><Text style={MS.meta}>open</Text></View>
                    <View><Text style={MS.summaryNumber}>{str(snapshot.completed)}</Text><Text style={MS.meta}>resolved</Text></View>
                    <View><Text style={MS.summaryNumber}>{str(snapshot.planned_minutes)}</Text><Text style={MS.meta}>planned min</Text></View>
                </View>
                <View style={MS.card}>
                    <Text style={MS.label}>NEW TASK</Text>
                    <TextInput accessibilityLabel="New task" style={MS.input} value={taskText}
                        placeholder="Add a task…" placeholderTextColor={MC.muted}
                        onChangeText={lambda (text: str) { taskText = text; }}/>
                    <TextInput accessibilityLabel="New task due date" style={MS.input}
                        value={taskDate} placeholder="Due date YYYY-MM-DD (optional)"
                        placeholderTextColor={MC.muted}
                        onChangeText={lambda (text: str) { taskDate = text; }}/>
                    <TextInput accessibilityLabel="New task minutes" style={MS.input}
                        value={taskMinutes} keyboardType="number-pad"
                        onChangeText={lambda (text: str) { taskMinutes = text; }}/>
                    <View style={MS.chipRow}>
                        {[<MobileButton key={item} label={item} quiet={taskPriority != item}
                            action={lambda { taskPriority = item; }}/>
                            for item in ["low", "medium", "high"]]}
                    </View>
                    <MobileButton label={"Adding…" if busy else "Add task"} action={addTask}
                        disabled={busy or not taskText.strip() or not taskMinutes.strip()}/>
                </View>
                <View style={MS.card}>
                    <Text style={MS.label}>FIND A TASK</Text>
                    <TextInput accessibilityLabel="Search tasks" style={MS.input}
                        value={searchText} placeholder="Search task titles…"
                        placeholderTextColor={MC.muted}
                        onChangeText={lambda (text: str) { searchText = text; }}/>
                    <Text style={MS.label}>CATEGORY</Text>
                    <View style={MS.chipRow}>
                        {[<MobileButton key={item} label={item} quiet={categoryFilter != item}
                            action={lambda { categoryFilter = item; }}/>
                            for item in ["all", "work", "study", "personal", "health", "shopping", "fitness", "other"]]}
                    </View>
                    <Text style={MS.label}>PRIORITY</Text>
                    <View style={MS.chipRow}>
                        {[<MobileButton key={item} label={item} quiet={priorityFilter != item}
                            action={lambda { priorityFilter = item; }}/>
                            for item in ["all", "high", "medium", "low"]]}
                    </View>
                    <Text style={MS.label}>STATUS</Text>
                    <View style={MS.chipRow}>
                        {[<MobileButton key={item} label={item} quiet={statusFilter != item}
                            action={lambda { statusFilter = item; }}/>
                            for item in ["open", "completed", "all"]]}
                    </View>
                </View>
                {<Text style={MS.meta}>Loading tasks…</Text> if loading else None}
                {[<MobileTask key={task.id} task={task} busy={busy}
                    onToggle={toggleTask} onEdit={editTask} onDelete={deleteTask}
                    onTimer={taskTimer} onBlock={reportBlocker}/>
                    for task in visibleTasks] if not loading else None}
                {<View style={MS.empty}><Text style={MS.taskTitle}>No matching tasks.</Text>
                    <Text style={MS.subtitle}>Change a filter or add a task.</Text></View>
                    if not loading and len(visibleTasks) == 0 else None}
            </View> if activeView == "today" else None}
            {<View style={MS.stack}>
                <Text style={MS.eyebrow}>EVIDENCE LOG</Text>
                <Text style={MS.title}>Blocker reports</Text>
                <Text style={MS.subtitle}>{str(len(snapshot.reports))} events preserved</Text>
                {[<MobileReport key={incident.id} incident={incident} busy={busy}
                    onRegenerate={regenerate} onStart={startRecovery}
                    onFinish={finishRecovery}/> for incident in snapshot.reports]}
                {<Text style={MS.subtitle}>Report a blocker on an open task to start your evidence log.</Text>
                    if len(snapshot.reports) == 0 else None}
            </View> if activeView == "blockers" else None}
            {<View style={MS.stack}>
                <Text style={MS.eyebrow}>RECOVERY LAB</Text>
                <Text style={MS.title}>Recovered plans</Text>
                <View style={MS.summary}>
                    <View><Text style={MS.summaryNumber}>{str(len(recoveredReports))}</Text><Text style={MS.meta}>next moves</Text></View>
                    <View><Text style={MS.summaryNumber}>{str(snapshot.recovery_attempts)}</Text><Text style={MS.meta}>attempts</Text></View>
                    <View><Text style={MS.summaryNumber}>{str(successRate)}%</Text><Text style={MS.meta}>success</Text></View>
                </View>
                {[<MobileReport key={incident.id} incident={incident} busy={busy}
                    onRegenerate={regenerate} onStart={startRecovery}
                    onFinish={finishRecovery}/> for incident in recoveredReports]}
                {<Text style={MS.subtitle}>No recovery experiments yet. Report a blocker from Today.</Text>
                    if len(recoveredReports) == 0 else None}
            </View> if activeView == "recovered" else None}
        </View> if connected and logged else None}
    </ScrollView>
}
