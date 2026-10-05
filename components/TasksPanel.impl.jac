"""Task panel request handlers."""

impl TasksPanel.loadTasks -> None {
    loading = True;
    error = "";
    try {
        tasks = await get_tasks();
    } except Exception {
        error = "Could not load tasks. Check your connection or sign in again.";
    } finally {
        loading = False;
    }
}

impl TasksPanel.addTask(e: FormEvent) -> None {
    e.preventDefault();
    if not taskText.strip() or adding { return; }
    adding = True;
    error = "";
    try {
        await add_task(taskText.strip());
        taskText = "";
        tasks = await get_tasks();
    } except Exception {
        error = "Could not add the task. Check that Ollama is running, then retry.";
    } finally {
        adding = False;
    }
}

impl TasksPanel.toggleTask(id: str) -> None {
    error = "";
    try {
        await toggle_task(id);
        tasks = await get_tasks();
    } except Exception {
        error = "Could not update the task. Please retry.";
    }
}

impl TasksPanel.deleteTask(id: str) -> None {
    error = "";
    try {
        await delete_task(id);
        tasks = await get_tasks();
    } except Exception {
        error = "Could not delete the task. Please retry.";
    }
}
