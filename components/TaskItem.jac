# Display one task with toggle and delete actions.


def:pub TaskItem(
    taskId: str,
    title: str,
    done: bool,
    category: str,
    blockerReason: str,
    blockerNote: str,
    blockerCount: int,
    busy: bool,
    onBlock: Callable[[str, str, str], None],
    onToggle: Callable[[str], None],
    onDelete: Callable[[str], None]
) -> JsxElement {
    has reason: str = "unclear",
        note: str = "";

    def submitBlocker(e: FormEvent) {
        e.preventDefault();
        if not busy { onBlock(taskId, reason, note); }
    }
    
    def handleToggle(_e: ChangeEvent) {
        onToggle(taskId);
    }

    def handleDelete(_e: MouseEvent) {
        onDelete(taskId);
    }

    <div>
    <div className="task-item">
        <input
            className="task-checkbox"
            type="checkbox"
            checked={done}
            disabled={busy}
            onChange={handleToggle}
        />

        <span
            className={
                "task-title "
                + ("task-title-done" if done else "")
            }
        >
            {title}
        </span>
        <span className={"category-badge category-" + category}>{category}</span>

        <button
            className="delete-button"
            onClick={handleDelete}
            disabled={busy}
        >
            Delete
        </button>
    </div>
    {(<p role="status">Latest blocker: {blockerReason.replace("_", " ")}
        {" · "}{blockerCount}{" reports"}
        {(" — " + blockerNote) if blockerNote else ""}
    </p>) if blockerReason else None}
    {(<details>
        <summary>I'm stuck</summary>
        <form onSubmit={submitBlocker}>
            <label>
                What got in the way?
                <select value={reason} disabled={busy}
                    onChange={lambda (e: ChangeEvent) { reason = e.target.value; }}>
                    <option value="unclear">I don't know where to start</option>
                    <option value="too_large">Task feels too large</option>
                    <option value="no_time">Not enough time</option>
                    <option value="low_energy">Low energy</option>
                    <option value="missing_resource">Missing something I need</option>
                    <option value="other">Other</option>
                </select>
            </label>
            <label>
                Optional note (500 characters maximum)
                <textarea value={note} maxLength={500} disabled={busy}
                    onChange={lambda (e: ChangeEvent) { note = e.target.value; }}/>
            </label>
            <button type="submit" className="secondary-button" disabled={busy}>
                {("Saving..." if busy else "Save blocker")}
            </button>
        </form>
    </details>) if not done else None}
    </div>
}
