"""Day Planner server-side data layer."""

enum Category {
    WORK,
    STUDY,
    PERSONAL,
    SHOPPING,
    HEALTH,
    FITNESS,
    OTHER
}

sem Category.WORK = "Jobs, meetings, and professional tasks";
sem Category.STUDY = "School, courses, exams, homework, and learning";
sem Category.PERSONAL = "Personal errands and private-life tasks";
sem Category.HEALTH = "Medical appointments, illness, medication, rest, and health maintenance";
sem Category.SHOPPING = "Buying groceries, clothing, household goods, or other items";
sem Category.FITNESS = "Exercise, workouts, sports, and physical training";
sem Category.OTHER = "Tasks that do not fit any other category";

def categorize(title: str) -> Category by llm();
sem categorize = """
Classify the task title into the single most suitable category.
School subjects, studying, homework, and exams must be categorized as STUDY.
Use HEALTH only for medical care, illness, medication, rest, or health maintenance.
""";


enum Unit: str {
    PIECE = "piece",
    LB = "lb",
    OZ = "oz",
    CUP = "cup",
    TBSP = "tbsp",
    TSP = "tsp",
    BUNCH = "bunch"
}

sem Unit.PIECE = "Count of whole items, such as eggs, onions or bell peppers";
sem Unit.LB = "Pounds by weight, such as meat or fish";
sem Unit.OZ = "Ounces by weight, such as cheese";
sem Unit.CUP = "Cups by volume, such as rice, flour, milk or water";
sem Unit.TBSP = "Tablespoons, such as oil or sauces";
sem Unit.TSP = "Teaspoons, such as salt or spices";
sem Unit.BUNCH = "Bunches, such as scallions or fresh herbs";

obj Ingredient {
    has name: str,
        quantity: float,
        unit: Unit,
        cost: float,
        carby: bool;
}

sem Ingredient.unit = "Choose the appropriate measurement unit for each ingredient; preserve explicitly requested units. PIECE is only for whole countable items, not a default for all ingredients.";
sem Ingredient.quantity = "Total amount needed for the described meal";
sem Ingredient.cost = "Estimated total cost in USD";
sem Ingredient.carby = "True if this ingredient is high in carbohydrates";

def generate_shopping_list(
    meal_description: str
) -> list[Ingredient] by llm();

sem generate_shopping_list = """
Generate a practical shopping list for the described meal.
Return every required ingredient with its total quantity,
measurement unit, estimated USD cost, and carbohydrate status.
Preserve quantities and units explicitly specified in the meal description.
Otherwise choose realistic cooking measures: meat in lb or oz, rice in cup,
oil and sauces in tbsp, salt and spices in tsp, herbs in bunch,
and whole eggs or vegetables in piece. The quantity must match its unit.
""";

node ShoppingItem {
    has name: str,
        quantity: float,
        unit: str,
        cost: float,
        carby: bool;
}

def:protect generate_list(meal: str) -> list[ShoppingItem] {
    # Generate first so a failed AI request does not erase the saved list.
    ingredients = generate_shopping_list(meal);

    # delete previous shopping list
    for item in [root-->][?:ShoppingItem] {
        del item;
    }

    for ing in ingredients {
        root ++> ShoppingItem(
            name=ing.name,
            quantity=ing.quantity,
            unit=str(ing.unit),
            cost=ing.cost,
            carby=ing.carby
        );
    }

    return [root-->][?:ShoppingItem];
}

def:protect get_shopping_list -> list[ShoppingItem] {
    return [root-->][?:ShoppingItem];
}

def:protect clear_shopping_list -> dict[str, bool] {
    for item in [root-->][?:ShoppingItem] {
        del item;
    }

    return {"cleared": True};
}


node Task{
    has title: str,
        done: bool = False,
        category: str = "other";
}

def:protect add_task(title: str) -> Task{
    category = str(categorize(title)).split(".")[-1].lower();
    return root ++> Task(title=title, category=category);    
}

def:protect get_tasks -> list[Task] {
    return [root -->][?:Task];
}

# switch tasks's completion status
def:protect toggle_task(id: str) -> Task | None{
    for task in [root-->][?:Task]{
        if jid(task) == id {
            task.done = not task.done;
            return task;
        }
    }
    return None;
}

def:protect delete_task(id: str) -> dict[str, str]{
    for task in [root-->][?:Task]{
        if jid(task) == id {
            del task;
            return {"deleted": id};

        }
    }
    return {};
}

