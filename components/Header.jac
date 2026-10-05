"""Planner heading and sign-out action."""
def:pub Header(onLogout: Callable[[], None]) -> JsxElement {
    <header className="header planner-header">
        <div>
            <h1>Day Planner</h1>
            <p>Plan your day, one task at a time.</p>
        </div>
        <button type="button" className="secondary-button" onClick={onLogout}>
            Sign out
        </button>
    </header>
}
