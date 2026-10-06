"""Daily agenda and plan-failure evidence dashboard."""
import from endpoints {
    TaskView,
    PlannerSnapshot,
    add_task,
    update_task,
    control_task_timer,
    get_dashboard,
    toggle_task,
    delete_task,
    record_task_blocker,
    request_recovery
}
import from .TaskItem { TaskItem }
import from .RecoveryTimer { RecoveryTimer }

def reasonLabel(reason: str) -> str {
    if not reason {
        return "No pattern yet";
    }
    if reason == "too_large" {
        return "Task felt too large";
    }
    if reason == "no_time" {
        return "Not enough time";
    }
    if reason == "low_energy" {
        return "Low energy";
    }
    if reason == "missing_resource" {
        return "Missing a resource";
    }
    if reason == "unclear" {
        return "Unclear starting point";
    }
    return "Other interruption";
}


def outcomeLabel(outcome: str) -> str {
    if outcome == "worked" {
        return "Worked";
    }
    if outcome == "still_blocked" {
        return "Still blocked";
    }
    if outcome == "stopped_early" {
        return "Stopped early";
    }
    if outcome == "running" {
        return "In progress";
    }
    return "Ready";
}


def evidenceDate(value: str) -> str {
    return value.split("T")[0] if value else "Today";
}

def:pub TasksPanel(view: str = "today") -> JsxElement {
    has snapshot: PlannerSnapshot = PlannerSnapshot(),
        taskText: str = "",
        priority: str = "medium",
        minutesText: str = "25",
        dueDate: str = "",
        searchText: str = "",
        categoryFilter: str = "all",
        priorityFilter: str = "all",
        statusFilter: str = "open",
        loading: bool = True,
        adding: bool = False,
        busyId: str = "",
        showCompleted: bool = False,
        error: str = "";

    can with entry {
        loadTasks();
    }

    async def loadTasks -> None;
    async def addTask(e: FormEvent) -> None;
    async def toggleTask(id: str) -> None;
    async def deleteTask(id: str) -> None;
    async def editTask(
        id: str, title: str, due: str, nextPriority: str, planned: int
    ) -> None;
    async def controlTimer(id: str, action: str) -> None;
    async def recordBlocker(id: str, reason: str, note: str) -> None;
    async def regenerateRecovery(id: str) -> None;

    total = snapshot.remaining + snapshot.completed;
    completionPercent = int((snapshot.completed * 100) / total) if total > 0 else 0;
    blockerReports = snapshot.reports;
    recoveredReports = [
        incident
        for incident in snapshot.reports
        if incident.recovery_step
    ];
    successRate = int((snapshot.recovery_successes * 100) / snapshot.recovery_attempts)
        if snapshot.recovery_attempts > 0
        else 0;
    filteredTasks = [
        task for task in snapshot.tasks
        if (not searchText.strip() or searchText.lower() in task.title.lower())
        and (categoryFilter == "all" or task.category == categoryFilter)
        and (priorityFilter == "all" or task.priority == priorityFilter)
        and (
            statusFilter == "all"
            or (statusFilter == "open" and not task.done)
            or (statusFilter == "completed" and task.done)
        )
    ];
    openFiltered = [task for task in filteredTasks if not task.done];
    completedFiltered = [task for task in filteredTasks if task.done];

    if view == "blockers" {
        return
            <section className="evidence-page" aria-labelledby="blocker-heading">
                <header className="evidence-header">
                    <div>
                        <span className="eyebrow">EVIDENCE LOG</span>
                        <h1 id="blocker-heading">Blocker reports</h1>
                        <p>
                            Every report is preserved, so repeated failure becomes a pattern instead of a forgotten task.
                        </p>
                    </div>
                    <div className="evidence-total">
                        <strong>{len(blockerReports)}</strong>
                        <span>events preserved</span>
                    </div>
                </header>
                {(
                    <div className="error-message" role="alert">
                        <span>{error}</span>
                        <button
                            type="button"
                            className="text-button"
                            onClick={loadTasks}
                        >
                            Reload
                        </button>
                    </div>
                )
                    if error
                    else None}
                {(
                    <div className="loading-state" role="status">
                        Reading blocker evidence…
                    </div>
                )
                    if loading
                    else None}
                {(
                    <div className="empty-state evidence-empty">
                        <span aria-hidden="true">?</span>
                        <h2>No blockers recorded yet.</h2>
                        <p>
                            Return to Today and report what stopped an unfinished task.
                        </p>
                    </div>
                )
                    if not loading and len(blockerReports) == 0
                    else None}
                {(
                    <div className="evidence-list">
                        {[
                            <article
                                className="evidence-entry blocker-entry"
                                key={incident.id}
                            >
                                <div className="evidence-index">BR</div>
                                <div className="evidence-body">
                                    <div className="evidence-entry-head">
                                        <div>
                                            <span className="evidence-meta">
                                                {evidenceDate(incident.created_at)} · {reasonLabel(
                                                    incident.reason
                                                )}
                                            </span>
                                            <h2>{incident.task_title}</h2>
                                        </div>
                                        <span
                                            className={"status-pill status-resolved"
                                                if incident.outcome == "worked"
                                                else "status-pill status-open"}
                                        >
                                            {outcomeLabel(incident.outcome)}
                                        </span>
                                    </div>
                                    {(<blockquote>{incident.note}</blockquote>)
                                        if incident.note
                                        else None}
                                    {(
                                        <div className="linked-recovery">
                                            <span>Recovered next move</span>
                                            <p>{incident.recovery_step}</p>
                                        </div>
                                    )
                                        if incident.recovery_step
                                        else None}
                                    {(
                                        <div className="attempt-footnote">
                                            <span>
                                                {outcomeLabel(incident.outcome)}
                                            </span>
                                            <span>
                                                {incident.elapsed_seconds} sec focused
                                            </span>
                                        </div>
                                    )
                                        if incident.outcome
                                            in [
                                                "worked",
                                                "still_blocked",
                                                "stopped_early"
                                            ]
                                        else None}
                                </div>
                            </article> for incident in blockerReports
                        ]}
                    </div>
                )
                    if not loading and len(blockerReports) > 0
                    else None}
            </section>;
    }

    if view == "recovered" {
        return
            <section className="evidence-page" aria-labelledby="recovered-heading">
                <header className="evidence-header">
                    <div>
                        <span className="eyebrow">RECOVERY LAB</span>
                        <h1 id="recovered-heading">Recovered plans</h1>
                        <p>
                            Test each five-minute next move, then record whether it actually got the plan moving.
                        </p>
                    </div>
                    <div className="evidence-total evidence-total-green">
                        <strong>{successRate}%</strong>
                        <span>recovery success</span>
                    </div>
                </header>
                <div className="recovery-stats" aria-label="Recovery statistics">
                    <div>
                        <strong>{len(recoveredReports)}</strong>
                        <span>next moves</span>
                    </div>
                    <div>
                        <strong>{snapshot.recovery_attempts}</strong>
                        <span>attempts finished</span>
                    </div>
                    <div>
                        <strong>{snapshot.recovery_successes}</strong>
                        <span>worked</span>
                    </div>
                    <div>
                        <strong>{reasonLabel(snapshot.top_blocker)}</strong>
                        <span>top blocker</span>
                    </div>
                </div>
                {(
                    <div className="error-message" role="alert">
                        <span>{error}</span>
                        <button
                            type="button"
                            className="text-button"
                            onClick={loadTasks}
                        >
                            Reload
                        </button>
                    </div>
                )
                    if error
                    else None}
                {(
                    <div className="loading-state" role="status">
                        Recovering case notes…
                    </div>
                )
                    if loading
                    else None}
                {(
                    <div className="empty-state evidence-empty">
                        <span aria-hidden="true">→</span>
                        <h2>No recovered plans yet.</h2>
                        <p>
                            Report a blocker from Today to generate the first five-minute experiment.
                        </p>
                    </div>
                )
                    if not loading and len(recoveredReports) == 0
                    else None}
                {(
                    <div className="recovery-grid">
                        {[
                            <article
                                className={"recovery-card recovery-card-done"
                                    if incident.outcome == "worked"
                                    else "recovery-card"}
                                key={incident.id}
                            >
                                <div className="recovery-card-top">
                                    <span className="recovery-arrow" aria-hidden="true">
                                        →
                                    </span>
                                    <span
                                        className={"status-pill status-resolved"
                                            if incident.outcome == "worked"
                                            else "status-pill status-open"}
                                    >
                                        {outcomeLabel(incident.outcome)}
                                    </span>
                                </div>
                                <span className="evidence-meta">
                                    {evidenceDate(incident.created_at)} · {reasonLabel(
                                        incident.reason
                                    )}
                                </span>
                                <h2>{incident.task_title}</h2>
                                <div className="next-move">
                                    <div className="source-row">
                                        <span>Five-minute experiment</span>
                                        <small
                                            className={"source-badge source-fallback"
                                                if incident.recovery_source
                                                    == "fallback"
                                                else "source-badge"}
                                        >
                                            {(
                                                "Safe fallback"
                                                    if incident.recovery_source
                                                        == "fallback"
                                                    else "AI generated"
                                            )}
                                        </small>
                                    </div>
                                    <p>{incident.recovery_step}</p>
                                </div>
                                <button
                                    type="button"
                                    className="text-button regenerate-button"
                                    disabled={busyId == incident.task_id}
                                    onClick={lambda { regenerateRecovery(
                                        incident.task_id
                                    ); }}
                                >
                                    {(
                                        "Regenerating…"
                                            if busyId == incident.task_id
                                            else "Regenerate next move"
                                    )}
                                </button>
                                <RecoveryTimer incident={incident} onSaved={loadTasks}/>
                            </article> for incident in recoveredReports
                        ]}
                    </div>
                )
                    if not loading and len(recoveredReports) > 0
                    else None}
            </section>;
    }
    <div className="workspace-grid">
        <section className="agenda" aria-labelledby="agenda-heading">
            <header className="agenda-header">
                <div>
                    <span className="eyebrow">TODAY’S CASE LOAD</span>
                    <h1 id="agenda-heading">Make the next move visible.</h1>
                    <p>Plan lightly. When something breaks, capture the evidence.</p>
                </div>
                <div className="date-tile" aria-label="Today">
                    <span>Today</span>
                    <strong>{snapshot.remaining}</strong>
                    <small>open</small>
                </div>
            </header>
            <form onSubmit={addTask} className="capture-card">
                <div className="capture-main">
                    <span className="capture-plus" aria-hidden="true">+</span>
                    <input
                        type="text"
                        aria-label="Task title"
                        value={taskText}
                        maxLength={160}
                        placeholder="Add a task to today…"
                        disabled={adding}
                        onChange={lambda (e: ChangeEvent) { taskText = e.target.value; }}
                    />
                </div>
                <div className="capture-options">
                    <label>
                        Priority
                        <select
                            value={priority}
                            disabled={adding}
                            onChange={lambda (e: ChangeEvent) { priority = e.target.value; }}
                        >
                            <option value="low">Low</option>
                            <option value="medium">Medium</option>
                            <option value="high">High</option>
                        </select>
                    </label>
                    <label>
                        Focus block
                        <select
                            value={minutesText}
                            disabled={adding}
                            onChange={lambda (e: ChangeEvent) { minutesText = e.target.value; }}
                        >
                            <option value="15">15 min</option>
                            <option value="25">25 min</option>
                            <option value="45">45 min</option>
                            <option value="60">60 min</option>
                            <option value="90">90 min</option>
                        </select>
                    </label>
                    <label>
                        Due date
                        <input
                            type="date"
                            value={dueDate}
                            disabled={adding}
                            onChange={lambda (e: ChangeEvent) {
                                dueDate = e.target.value;
                            }}
                        />
                    </label>
                    <button
                        className="primary-button"
                        type="submit"
                        disabled={adding or not taskText.strip()}
                    >
                        {("Classifying…" if adding else "Add to timeline")}
                    </button>
                </div>
            </form>
            <section className="filter-bar" aria-label="Filter tasks">
                <label className="search-field">
                    <span>Search</span>
                    <input
                        type="search"
                        value={searchText}
                        placeholder="Find a task…"
                        onChange={lambda (e: ChangeEvent) {
                            searchText = e.target.value;
                        }}
                    />
                </label>
                <label>
                    <span>Category</span>
                    <select value={categoryFilter} onChange={lambda (e: ChangeEvent) {
                        categoryFilter = e.target.value;
                    }}>
                        <option value="all">All categories</option>
                        <option value="work">Work</option>
                        <option value="study">Study</option>
                        <option value="personal">Personal</option>
                        <option value="health">Health</option>
                        <option value="shopping">Shopping</option>
                        <option value="fitness">Fitness</option>
                        <option value="other">Other</option>
                    </select>
                </label>
                <label>
                    <span>Priority</span>
                    <select value={priorityFilter} onChange={lambda (e: ChangeEvent) {
                        priorityFilter = e.target.value;
                    }}>
                        <option value="all">All priorities</option>
                        <option value="high">High</option>
                        <option value="medium">Medium</option>
                        <option value="low">Low</option>
                    </select>
                </label>
                <label>
                    <span>Status</span>
                    <select value={statusFilter} onChange={lambda (e: ChangeEvent) {
                        statusFilter = e.target.value;
                    }}>
                        <option value="open">Open</option>
                        <option value="completed">Completed</option>
                        <option value="all">All statuses</option>
                    </select>
                </label>
                {(
                    <button type="button" className="filter-clear" onClick={lambda {
                        searchText = "";
                        categoryFilter = "all";
                        priorityFilter = "all";
                        statusFilter = "open";
                    }}>
                        Clear
                    </button>
                )
                    if searchText or categoryFilter != "all"
                        or priorityFilter != "all" or statusFilter != "open"
                    else None}
            </section>
            {(
                <div className="error-message" role="alert">
                    <span>{error}</span>
                    <button type="button" className="text-button" onClick={loadTasks}>
                        Reload
                    </button>
                </div>
            )
                if error
                else None}
            {(
                <div className="loading-state" role="status">
                    Reading today’s evidence…
                </div>
            )
                if loading
                else None}
            {(
                <div className="empty-state">
                    <span aria-hidden="true">✓</span>
                    <h2>Your timeline is clear.</h2>
                    <p>Add one task above. Keep it concrete enough to finish.</p>
                </div>
            )
                if not loading and len(snapshot.tasks) == 0
                else None}
            {(
                <div className="empty-state filter-empty">
                    <span aria-hidden="true">⌕</span>
                    <h2>No matching evidence.</h2>
                    <p>Clear a filter or try a different task title.</p>
                </div>
            )
                if not loading and len(snapshot.tasks) > 0 and len(filteredTasks) == 0
                else None}
            {(
                <div className="timeline" aria-label="Open tasks">
                    <div className="timeline-label">
                        <span>Now</span>
                        <hr/>
                    </div>
                    {[
                        <TaskItem
                            key={task.id}
                            taskId={task.id}
                            title={task.title}
                            done={task.done}
                            category={task.category}
                            priority={task.priority}
                            plannedMinutes={task.planned_minutes}
                            dueDate={task.due_date}
                            focusSeconds={task.focus_seconds}
                            focusStartedAt={task.focus_started_at}
                            focusRunning={task.focus_running}
                            blockerReason={task.blocker_reason}
                            blockerNote={task.blocker_note}
                            blockerCount={task.blocker_count}
                            nextStep={task.next_step}
                            recoverySource={task.recovery_source}
                            busy={busyId == task.id}
                            onBlock={recordBlocker}
                            onToggle={toggleTask}
                            onDelete={deleteTask}
                            onEdit={editTask}
                            onTimer={controlTimer}
                        />
                        for task in openFiltered
                    ]}
                </div>
            )
                if not loading and len(openFiltered) > 0
                else None}
            {(
                <section className="completed-section">
                    <button
                        type="button"
                        className="completed-toggle"
                        onClick={lambda { showCompleted = not showCompleted; }}
                    >
                        <span>{"▾" if showCompleted else "▸"}</span>
                        Completed ·{" "}
                        {len(completedFiltered)}
                    </button>
                    {(
                        [
                            <TaskItem
                                key={task.id}
                                taskId={task.id}
                                title={task.title}
                                done={task.done}
                                category={task.category}
                                priority={task.priority}
                                plannedMinutes={task.planned_minutes}
                                dueDate={task.due_date}
                                focusSeconds={task.focus_seconds}
                                focusStartedAt={task.focus_started_at}
                                focusRunning={task.focus_running}
                                blockerReason={task.blocker_reason}
                                blockerNote={task.blocker_note}
                                blockerCount={task.blocker_count}
                                nextStep={task.next_step}
                                recoverySource={task.recovery_source}
                                busy={busyId == task.id}
                                onBlock={recordBlocker}
                                onToggle={toggleTask}
                                onDelete={deleteTask}
                                onEdit={editTask}
                                onTimer={controlTimer}
                            />
                            for task in completedFiltered
                        ]
                    )
                        if showCompleted or statusFilter == "completed"
                        else None}
                </section>
            )
                if not loading and len(completedFiltered) > 0
                else None}
        </section>
        <aside className="case-rail" aria-label="Planning evidence summary">
            <section className="rail-card progress-card">
                <div className="rail-heading">
                    <span>Case progress</span>
                    <strong>{completionPercent}%</strong>
                </div>
                <progress max={100} value={completionPercent}>
                    {completionPercent}%
                </progress>
                <p>{snapshot.completed} resolved · {snapshot.remaining} still open</p>
            </section>
            <section className="rail-card metrics-card">
                <span className="rail-kicker">TODAY AT A GLANCE</span>
                <div className="metric-row">
                    <span>Focus reserved</span>
                    <strong>{snapshot.planned_minutes} min</strong>
                </div>
                <div className="metric-row">
                    <span>Blocker reports</span>
                    <strong>{snapshot.blocker_reports}</strong>
                </div>
                <div className="metric-row">
                    <span>Recurring clue</span>
                    <strong>{reasonLabel(snapshot.top_blocker)}</strong>
                </div>
            </section>
            <section className="rail-card detective-card">
                <div className="detective-mark">AI</div>
                <div>
                    <span className="rail-kicker">RECOVERY DETECTIVE</span>
                    <h2>Stuck is data.</h2>
                    <p>
                        Open “Report a blocker” on any unfinished task. Gemini turns the evidence into one five-minute next move.
                    </p>
                </div>
            </section>
            <section className="rail-card protocol-card">
                <span className="rail-kicker">FIELD PROTOCOL</span>
                <ol>
                    <li>Name what stopped you.</li>
                    <li>Save the evidence.</li>
                    <li>Do only the returned next move.</li>
                </ol>
            </section>
        </aside>
    </div>
}
