"""Task panel request handlers."""

impl TasksPanel.loadTasks -> None {
    loading = True;
    error = "";
    try {
        snapshot = await get_dashboard();
    } except Exception {
        error = "Could not load your case file. Check the server or sign in again.";
    } finally {
        loading = False;
    }
}

impl TasksPanel.addTask(e: FormEvent) -> None {
    e.preventDefault();
    if not taskText.strip() or adding {
        return;
    }
    adding = True;
    error = "";
    planned = 25;
    if minutesText == "15" {
        planned = 15;
    } elif minutesText == "45" {
        planned = 45;
    } elif minutesText == "60" {
        planned = 60;
    } elif minutesText == "90" {
        planned = 90;
    }
    try {
        await add_task(taskText.strip(), priority, planned, dueDate);
        taskText = "";
        dueDate = "";
        snapshot = await get_dashboard();
    } except Exception {
        error = "Could not add the task. Your AI key may be unavailable; retry in a moment.";
    } finally {
        adding = False;
    }
}


impl TasksPanel.editTask(
    id: str, title: str, due: str, nextPriority: str, planned: int
) -> None {
    if busyId { return; }
    busyId = id;
    error = "";
    try {
        saved = await update_task(id, title, due, nextPriority, planned);
        if saved is None {
            error = "That task is no longer available. Reload the case file.";
        }
        snapshot = await get_dashboard();
    } except Exception {
        error = "Could not save those changes. Check the title, date, and estimate.";
    } finally {
        busyId = "";
    }
}


impl TasksPanel.controlTimer(id: str, action: str) -> None {
    if busyId { return; }
    busyId = id;
    error = "";
    try {
        saved = await control_task_timer(id, action);
        if saved is None {
            error = "That task is no longer available. Reload the case file.";
        }
        snapshot = await get_dashboard();
    } except Exception {
        error = "Could not update the focus timer. Refresh before trying again.";
    } finally {
        busyId = "";
    }
}

impl TasksPanel.toggleTask(id: str) -> None {
    if busyId {
        return;
    }
    busyId = id;
    error = "";
    try {
        await toggle_task(id);
        snapshot = await get_dashboard();
    } except Exception {
        error = "Could not update the task. Refresh before trying again.";
    } finally {
        busyId = "";
    }
}

impl TasksPanel.deleteTask(id: str) -> None {
    if busyId {
        return;
    }
    busyId = id;
    error = "";
    try {
        await delete_task(id);
        snapshot = await get_dashboard();
    } except Exception {
        error = "Could not delete the task. Refresh before trying again.";
    } finally {
        busyId = "";
    }
}

impl TasksPanel.recordBlocker(id: str, reason: str, note: str) -> None {
    if busyId {
        return;
    }
    busyId = id;
    error = "";
    try {
        saved = await record_task_blocker(id, reason, note);
        if saved is None {
            error = "That task is no longer available. Reload the case file.";
        } else {
            await request_recovery(id);
        }
        snapshot = await get_dashboard();
    } except Exception {
        error = "The evidence could not be saved. Refresh before trying again.";
    } finally {
        busyId = "";
    }
}


impl TasksPanel.regenerateRecovery(id: str) -> None {
    if busyId {
        return;
    }
    busyId = id;
    error = "";
    try {
        refreshed = await request_recovery(id);
        if refreshed is None {
            error = "That task is no longer available. Reload the case file.";
        }
        snapshot = await get_dashboard();
    } except Exception {
        error = "Could not regenerate the next move. Check the AI connection and retry.";
    } finally {
        busyId = "";
    }
}
