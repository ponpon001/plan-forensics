"""Username/password login and signup form."""
import from "@jac/runtime" { SignupResult, jacLogin, jacSignup }

def:pub AuthForm(onAuth: Callable[[], None]) -> JsxElement {
    has isSignup: bool = False,
        username: str = "",
        password: str = "",
        error: str = "",
        loading: bool = False;

    async def handleSubmit(e: FormEvent) {
        e.preventDefault();
        if loading { return; }
        error = "";
        if not username.strip() or not password {
            error = "Enter a username and password.";
            return;
        }
        if isSignup and len(password) < 8 {
            error = "Use a password with at least 8 characters.";
            return;
        }

        loading = True;
        signupResult: SignupResult | None = None;
        loginOk: bool = False;
        try {
            if isSignup {
                signupResult = await jacSignup(username.strip(), password);
                if not signupResult.success {
                    error = signupResult.error if signupResult.error else "Could not create the account.";
                    return;
                }
            }
            loginOk = await jacLogin(username.strip(), password);
            if loginOk {
                onAuth();
            } else {
                error = "Account created, but sign-in failed. Try signing in." if isSignup else "Invalid username or password.";
            }
        } except Exception {
            error = "Could not connect to the server. Please try again.";
        } finally {
            loading = False;
        }
    }

    <main className="auth-page">
        <div className="auth-card">
            <h1>Day Planner</h1>
            <p>{("Create your account" if isSignup else "Sign in to your planner")}</p>
            {(<p className="error-message" role="alert">{error}</p>) if error else None}
            <form onSubmit={handleSubmit} className="auth-form">
                <label htmlFor="auth-username">Username</label>
                <input id="auth-username" className="task-input" type="text"
                    autoComplete="username" required={True} value={username}
                    onChange={lambda (e: ChangeEvent) { username = e.target.value; }}/>
                <label htmlFor="auth-password">Password</label>
                <input id="auth-password" className="task-input" type="password"
                    autoComplete={"new-password" if isSignup else "current-password"}
                    required={True} value={password}
                    onChange={lambda (e: ChangeEvent) { password = e.target.value; }}/>
                <button className="add-button" type="submit" disabled={loading}>
                    {("Please wait..." if loading else ("Create account" if isSignup else "Sign in"))}
                </button>
            </form>
            <button type="button" className="auth-switch" disabled={loading}
                onClick={lambda {
                    isSignup = not isSignup;
                    error = "";
                }}>
                {("Already have an account? Sign in" if isSignup else "New here? Create an account")}
            </button>
        </div>
    </main>
}
