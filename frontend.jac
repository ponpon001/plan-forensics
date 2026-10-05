"""Authenticated Day Planner client."""
import "./assets/frontend.css";
import "./assets/task-item.css";
import from "@jac/runtime" { jacLogout, jacIsLoggedIn }
import from .components.AuthForm { AuthForm }
import from .components.Header { Header }
import from .components.TasksPanel { TasksPanel }
import from .components.ShoppingPanel { ShoppingPanel }

def:pub app -> JsxElement {
    has isLoggedIn: bool = False,
        checkingAuth: bool = True;

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
        return <p className="auth-loading" role="status">Checking session...</p>;
    }

    if not isLoggedIn {
        return <AuthForm onAuth={handleAuth}/>;
    }

    <div className="container">
        <Header onLogout={handleLogout}/>
        <div className="planner-columns">
            <TasksPanel/>
            <ShoppingPanel/>
        </div>
    </div>
}
