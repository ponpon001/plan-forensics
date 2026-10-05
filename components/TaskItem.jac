# Display one task with toggle and delete actions.


def:pub TaskItem(
    taskId: str,
    title: str,
    done: bool,
    category: str,
    onToggle: Callable[[str], None],
    onDelete: Callable[[str], None]
) -> JsxElement {
    
    def handleToggle(_e: ChangeEvent) {
        onToggle(taskId);
    }

    def handleDelete(_e: MouseEvent) {
        onDelete(taskId);
    }

    <div className="task-item">
        <input
            className="task-checkbox"
            type="checkbox"
            checked={done}
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
        >
            Delete
        </button>
    </div>
}