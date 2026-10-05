"""day-planner - Entry Point.

Combines server-side endpoints with the client-side UI.
"""

import from endpoints {
    Task,
    ShoppingItem,
    add_task,
    get_tasks,
    toggle_task,
    delete_task,
    record_task_blocker,
    generate_list,
    get_shopping_list,
    clear_shopping_list
}

# Client-side UI

import from .frontend { app as ClientApp }

def:pub app -> JsxElement {
    <ClientApp/>
}
