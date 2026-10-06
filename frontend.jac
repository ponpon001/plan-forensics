"""Authenticated Plan Forensics web client."""
import "./assets/frontend.css";
import "./assets/task-item.css";
import from "@jac/runtime" { jacLogout, jacIsLoggedIn }
import from .components.AuthForm { AuthForm }
import from .components.Header { Header }
import from .components.TasksPanel { TasksPanel }

def:pub app -> JsxElement {
    has isLoggedIn: bool = False,
        checkingAuth: bool = True,
        activeView: str = "today";

    can with entry {
        isLoggedIn = jacIsLoggedIn();
        checkingAuth = False;
    }

    def handleAuth {
        isLoggedIn = True;
    }

    def handleLogout {
        jacLogout();
        isLoggedIn = False;
    }

    if checkingAuth {
        return
            <main className="auth-loading" role="status">
                <span className="loading-mark">PF</span>
                <p>Opening your case file…</p>
            </main>;
    }

    if not isLoggedIn {
        return <AuthForm onAuth={handleAuth}/>;
    }

    <div className="app-shell">
        <aside className="app-sidebar" aria-label="Planner navigation">
            <div className="brand-lockup">
                <span className="brand-mark">PF</span>
                <div>
                    <strong>Plan Forensics</strong>
                    <span>Personal case desk</span>
                </div>
            </div>
            <nav className="sidebar-nav" aria-label="Case views">
                <button
                    type="button"
                    className={"nav-item nav-item-active"
                        if activeView == "today"
                        else "nav-item"}
                    aria-current={"page" if activeView == "today" else None}
                    onClick={lambda { activeView = "today"; }}
                >
                    <span aria-hidden="true">◫</span>{" "}
                    Today
                </button>
                <div className="nav-label">Evidence</div>
                <button
                    type="button"
                    className={"nav-item nav-item-active"
                        if activeView == "blockers"
                        else "nav-item"}
                    aria-current={"page" if activeView == "blockers" else None}
                    onClick={lambda { activeView = "blockers"; }}
                >
                    <span className="dot dot-amber"></span>
                    Blocker reports
                </button>
                <button
                    type="button"
                    className={"nav-item nav-item-active"
                        if activeView == "recovered"
                        else "nav-item"}
                    aria-current={"page" if activeView == "recovered" else None}
                    onClick={lambda { activeView = "recovered"; }}
                >
                    <span className="dot dot-green"></span>
                    Recovered plans
                </button>
            </nav>
            <div className="sidebar-tip">
                <span className="tip-label">Method</span>
                <p>
                    Record what stopped you. The detective returns one small move—not another giant plan.
                </p>
            </div>
        </aside>
        <main className="app-main">
            <Header onLogout={handleLogout} activeView={activeView}/>
            <TasksPanel view={activeView}/>
        </main>
    </div>
}
