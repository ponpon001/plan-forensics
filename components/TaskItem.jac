"""One task card with editing, focus timing, evidence, and recovery actions."""

def formatFocusClock(seconds: int) -> str {
    hours = int(seconds / 3600);
    minutes = int((seconds % 3600) / 60);
    remainder = seconds % 60;
    minuteText = ("0" if hours > 0 and minutes < 10 else "") + str(minutes);
    secondText = ("0" if remainder < 10 else "") + str(remainder);
    return (str(hours) + ":" if hours > 0 else "") + minuteText + ":" + secondText;
}

def:pub TaskItem(
    taskId: str, title: str, done: bool, category: str, priority: str,
    plannedMinutes: int, dueDate: str, focusSeconds: int,
    focusStartedAt: str, focusRunning: bool, blockerReason: str,
    blockerNote: str, blockerCount: int, nextStep: str, recoverySource: str,
    busy: bool, onBlock: Callable[[str, str, str], None],
    onToggle: Callable[[str], None], onDelete: Callable[[str], None],
    onEdit: Callable[[str, str, str, str, int], None],
    onTimer: Callable[[str, str], None]
) -> JsxElement {
    has reason: str = "unclear", note: str = "", editing: bool = False,
        editTitle: str = title, editDate: str = dueDate,
        editPriority: str = priority, editMinutes: str = str(plannedMinutes),
        displayedSeconds: int = focusSeconds;

    can with [focusSeconds, focusRunning] entry {
        displayedSeconds = focusSeconds;
    }
    can with [focusRunning, displayedSeconds] entry {
        if focusRunning {
            timeoutId = setTimeout(lambda { displayedSeconds += 1; }, 1000);
            return lambda { clearTimeout(timeoutId); };
        }
    }

    def submitBlocker(e: FormEvent) {
        e.preventDefault();
        if not busy { onBlock(taskId, reason, note); note = ""; }
    }
    def openEditor {
        editTitle = title; editDate = dueDate; editPriority = priority;
        editMinutes = str(plannedMinutes); editing = True;
    }
    def submitEdit(e: FormEvent) {
        e.preventDefault();
        if not busy and editTitle.strip() and editMinutes.strip() {
            onEdit(taskId, editTitle.strip(), editDate, editPriority, int(editMinutes));
            editing = False;
        }
    }

    <article className={"task-card priority-" + priority + (" task-card-done" if done else "")}>
        <div className="task-main-row">
            <label className="check-control">
                <input type="checkbox" checked={done} disabled={busy}
                    aria-label={("Reopen " if done else "Complete ") + title}
                    onChange={lambda (_e: ChangeEvent) { onToggle(taskId); }}/>
                <span aria-hidden="true"></span>
            </label>
            <div className="task-body">
                <div className="task-title-row">
                    <h3>{title}</h3>
                    <span className={"priority-label priority-label-" + priority}>{priority}</span>
                </div>
                <div className="task-meta">
                    <span className={"category-badge category-" + category}>{category}</span>
                    <span>{plannedMinutes} min plan</span>
                    {(<span>Due {dueDate}</span>) if dueDate else None}
                    {(<span>{blockerCount} blocker {("report" if blockerCount == 1 else "reports")}</span>) if blockerCount > 0 else None}
                </div>
            </div>
            <div className="task-actions">
                <button type="button" className="icon-button edit-button"
                    aria-label={"Edit " + title} title="Edit task" disabled={busy}
                    onClick={openEditor}>✎</button>
                <button type="button" className="icon-button delete-button"
                    aria-label={"Delete " + title} title="Delete task" disabled={busy}
                    onClick={lambda (_e: MouseEvent) { onDelete(taskId); }}>×</button>
            </div>
        </div>
        {(
            <form className="task-edit-form" onSubmit={submitEdit}>
                <div className="edit-grid">
                    <label className="edit-title-field">Task title
                        <input type="text" value={editTitle} maxLength={160} disabled={busy}
                            onChange={lambda (e: ChangeEvent) { editTitle = e.target.value; }}/>
                    </label>
                    <label>Due date
                        <input type="date" value={editDate} disabled={busy}
                            onChange={lambda (e: ChangeEvent) { editDate = e.target.value; }}/>
                    </label>
                    <label>Priority
                        <select value={editPriority} disabled={busy}
                            onChange={lambda (e: ChangeEvent) { editPriority = e.target.value; }}>
                            <option value="low">Low</option><option value="medium">Medium</option><option value="high">High</option>
                        </select>
                    </label>
                    <label>Estimate
                        <input type="number" min="5" max="240" value={editMinutes}
                            disabled={busy}
                            onChange={lambda (e: ChangeEvent) { editMinutes = e.target.value; }}/>
                    </label>
                </div>
                <div className="edit-footer">
                    <button type="button" className="text-button" onClick={lambda { editing = False; }}>Cancel</button>
                    <button type="submit" className="secondary-button" disabled={busy or not editTitle.strip() or not editMinutes.strip()}>Save changes</button>
                </div>
            </form>
        ) if editing else None}
        <div className="task-focus-strip" aria-live="polite">
            <div>
                <span className={"focus-pulse" if focusRunning else "focus-dot"}></span>
                <strong>{formatFocusClock(displayedSeconds)}</strong>
                <small>{"focusing now" if focusRunning else "focused"}</small>
            </div>
            <div className="task-focus-actions">
                {(<button type="button" className="secondary-button" disabled={busy}
                    onClick={lambda { onTimer(taskId, "pause"); }}>Pause</button>)
                    if focusRunning else
                    (<button type="button" className="secondary-button" disabled={busy or done}
                    onClick={lambda { onTimer(taskId, "start"); }}>
                        {"Resume" if displayedSeconds > 0 else "Start focus"}
                    </button>)}
                {(<button type="button" className="text-button" disabled={busy}
                    onClick={lambda { onTimer(taskId, "reset"); }}>Reset</button>)
                    if displayedSeconds > 0 and not done else None}
                {(<button type="button" className="focus-finish" disabled={busy}
                    onClick={lambda { onTimer(taskId, "finish"); }}>Finish task</button>)
                    if not done else None}
            </div>
        </div>
        {(
            <div className="recovery-clue" role="status">
                <div className="clue-icon" aria-hidden="true">↳</div>
                <div><div className="clue-heading"><span>Next move</span>
                    <small className={"source-badge source-fallback" if recoverySource == "fallback" else "source-badge"}>
                        {"Safe fallback" if recoverySource == "fallback" else "AI generated"}
                    </small></div><p>{nextStep}</p></div>
            </div>
        ) if nextStep and not done else None}
        {(<div className="evidence-note"><span>Last evidence · {blockerReason.replace("_", " ")}</span>
            {(<p>{blockerNote}</p>) if blockerNote else None}</div>) if blockerReason and not done else None}
        {(
            <details className="blocker-details"><summary>Report a blocker</summary>
                <form onSubmit={submitBlocker} className="blocker-form">
                    <label htmlFor={"reason-" + taskId}>What got in the way?</label>
                    <select id={"reason-" + taskId} value={reason} disabled={busy}
                        onChange={lambda (e: ChangeEvent) { reason = e.target.value; }}>
                        <option value="unclear">I don’t know where to start</option>
                        <option value="too_large">The task feels too large</option>
                        <option value="no_time">I ran out of time</option>
                        <option value="low_energy">I don’t have the energy</option>
                        <option value="missing_resource">I’m missing something</option>
                        <option value="other">Something else happened</option>
                    </select>
                    <label htmlFor={"note-" + taskId}>Optional case note</label>
                    <textarea id={"note-" + taskId} value={note} maxLength={500} disabled={busy}
                        placeholder="What happened right before you stopped?"
                        onChange={lambda (e: ChangeEvent) { note = e.target.value; }}/>
                    <div className="form-footer"><span>{len(note)} / 500</span>
                        <button type="submit" className="secondary-button" disabled={busy}>
                            {"Analyzing…" if busy else "Save & find next move"}
                        </button></div>
                </form>
            </details>
        ) if not done else None}
    </article>
}
