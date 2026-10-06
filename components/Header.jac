"""Top bar for the daily case desk."""
def:pub Header(onLogout: Callable[[], None], activeView: str = "today") -> JsxElement {
    pageTitle = "Blocker reports"
        if activeView == "blockers"
        else ("Recovered plans" if activeView == "recovered" else "Today");
    <header className="topbar">
        <div className="breadcrumb">
            <span>My planner</span>
            <span aria-hidden="true">/</span>
            <strong>{pageTitle}</strong>
        </div>
        <div className="topbar-actions">
            <span className="sync-status">
                <span></span>
                Saved to your private graph
            </span>
            <button type="button" className="quiet-button" onClick={onLogout}>
                Sign out
            </button>
        </div>
    </header>
}
