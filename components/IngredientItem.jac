"""One persisted ingredient with its amount, price and carbohydrate flag."""
import from endpoints { ShoppingItem }

def:pub IngredientItem(ingredient: ShoppingItem) -> JsxElement {
    <div className="ingredient-item">
        <div className="ingredient-info">
            <strong>{ingredient.name}</strong>
            <span className="ingredient-quantity">{ingredient.quantity}{" "}{ingredient.unit}</span>
        </div>
        <div className="ingredient-meta">
            {(<span className="carb-badge">High carbs</span>) if ingredient.carby else None}
            <span>${f"{ingredient.cost:.2f}"}</span>
        </div>
    </div>
}
