"""Task management panel. Mounted only for an authenticated user."""
import from endpoints { Task, add_task, get_tasks, toggle_task, delete_task, record_task_blocker }
import from .TaskItem { TaskItem }

def:pub TasksPanel -> JsxElement {
    has tasks: list[Task] = [],
        taskText: str = "",
        loading: bool = True,
        adding: bool = False,
        reporting: bool = False,
        error: str = "";

    can with entry {
        loadTasks();
    }

    async def loadTasks -> None;
    async def addTask(e: FormEvent) -> None;
    async def toggleTask(id: str) -> None;
    async def deleteTask(id: str) -> None;
    async def recordBlocker(id: str, reason: str, note: str) -> None;

    remaining = len([
        task for task in tasks
        if not task.done
    ]);

    <section className="planner-panel" aria-labelledby="tasks-heading">
        <h2 id="tasks-heading">Today's Tasks</h2>
        <form onSubmit={addTask} className="task-form">
            <input
                className="task-input"
                type="text"
                aria-label="Task title"
                value={taskText}
                onChange={lambda (e: ChangeEvent) {
                    taskText = e.target.value;
                }}
                placeholder="What needs to be done today?"
                disabled={adding}
            />

            <button
                className="add-button"
                type="submit"
                disabled={adding or not taskText.strip()}
            >
                {("Adding..." if adding else "Add")}
            </button>
        </form>
        {(
            <p className="status-message">Loading tasks...</p>
        ) if loading else None}
        {(<div className="error-message" role="alert">
            <p>{error}</p>
            <button type="button" className="secondary-button"
                onClick={loadTasks} disabled={loading or adding}>Reload tasks</button>
        </div>) if error else None}

        {(
            <p className="status-message">
                No tasks yet. Add your first task above.
            </p>
        ) if not loading and len(tasks) == 0 else None}

        {[
            <TaskItem
                key={jid(task)}
                taskId={jid(task)}
                title={task.title}
                done={task.done}
                category={task.category}
                blockerReason={task.blocker_reason}
                blockerNote={task.blocker_note}
                blockerCount={task.blocker_count}
                busy={reporting}
                onBlock={recordBlocker}
                onToggle={toggleTask}
                onDelete={deleteTask}
            />
            for task in tasks
        ] if not loading else None}

        <p className="task-count">
            {remaining}
            {(" task remaining" if remaining == 1 else " tasks remaining")}
        </p>
    </section>
}
