"""Meal shopping list with persisted ingredients and AI generation."""
import from endpoints {
    ShoppingItem, generate_list, get_shopping_list, clear_shopping_list
}
import from .IngredientItem { IngredientItem }

def:pub ShoppingPanel -> JsxElement {
    has ingredients: list[ShoppingItem] = [],
        mealText: str = "",
        loading: bool = True,
        operation: str = "",
        error: str = "";

    async def loadList {
        loading = True;
        error = "";
        try {
            ingredients = await get_shopping_list();
        } except Exception {
            error = "Could not load your shopping list. Please retry.";
        } finally {
            loading = False;
        }
    }

    can with entry { loadList(); }

    async def generate(e: FormEvent) {
        e.preventDefault();
        if not mealText.strip() or loading or operation { return; }
        operation = "generate";
        error = "";
        try {
            ingredients = await generate_list(mealText.strip());
        } except Exception {
            error = "Could not generate the list. Check that Ollama is running, then try again.";
        } finally {
            operation = "";
        }
    }

    async def clearList {
        if loading or operation { return; }
        operation = "clear";
        error = "";
        try {
            await clear_shopping_list();
            ingredients = [];
            mealText = "";
        } except Exception {
            error = "Could not clear the shopping list. Please try again.";
        } finally {
            operation = "";
        }
    }

    totalCost = 0.0;
    for ing in ingredients { totalCost = totalCost + ing.cost; }

    <section className="planner-panel" aria-labelledby="shopping-heading">
        <h2 id="shopping-heading">Meal Shopping List</h2>
        <p className="panel-description">Describe a meal and how many people it serves.</p>
        <form onSubmit={generate} className="meal-form">
            <label htmlFor="meal-description">What are you cooking?</label>
            <textarea
                id="meal-description"
                className="task-input meal-input"
                value={mealText}
                onChange={lambda (e: ChangeEvent) { mealText = e.target.value; }}
                placeholder="Chicken stir fry for 4 with rice and vegetables"
                disabled={loading or operation != ""}
                rows={3}
            />
            <button
                type="submit"
                className="add-button"
                disabled={loading or operation != "" or not mealText.strip()}
            >
                {("Generating..." if operation == "generate" else "Generate shopping list")}
            </button>
        </form>
        {(<div className="error-message" role="alert">
            <p>{error}</p>
            <button type="button" className="secondary-button" onClick={loadList}
                disabled={loading or operation != ""}>Reload saved list</button>
        </div>) if error else None}
        <div aria-live="polite">
            {(<p className="status-message">Loading shopping list...</p>) if loading else None}
            {(<p className="status-message">Generating ingredients with AI...</p>)
                if operation == "generate" else None}
            {(<p className="status-message">Your ingredients will appear here. Start with a meal above.</p>)
                if not loading and not operation and not error and len(ingredients) == 0 else None}
        </div>
        {[<IngredientItem key={jid(ing)} ingredient={ing}/> for ing in ingredients]}
        {(<div className="shopping-footer">
            <strong>Estimated total: ${f"{totalCost:.2f}"}</strong>
            <button type="button" className="secondary-button" onClick={clearList}
                disabled={loading or operation != ""}>
                {("Clearing..." if operation == "clear" else "Clear list")}
            </button>
        </div>) if len(ingredients) > 0 else None}
    </section>
}
