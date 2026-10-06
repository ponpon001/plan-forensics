"""Username/password authentication against the shared planner service."""
import from "@jac/runtime" { jacSetToken, __getApiBaseUrl }

def:pub AuthForm(onAuth: Callable[[], None]) -> JsxElement {
    has isSignup: bool = False,
        username: str = "",
        password: str = "",
        error: str = "",
        loading: bool = False;

    async def handleSubmit(e: FormEvent) {
        e.preventDefault();
        if loading {
            return;
        }
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
        try {
            identity = {"type": "username", "value": username.strip()};
            payload: dict[str, any] = {
                "credential": {"type": "password", "password": password}
            };
            if isSignup {
                payload["identities"] = [identity];
            } else {
                payload["identity"] = identity;
            }
            operation = "register" if isSignup else "login";
            requestOptions = {
                "method": "POST",
                "headers": {"Content-Type": "application/json"},
                "body": JSON.stringify(payload)
            };
            response = await fetch(
                __getApiBaseUrl() + "/api/planner/user/" + operation, requestOptions
            );
            if response.status == 404 or response.status == 405 {
                response = await fetch(
                    __getApiBaseUrl() + "/user/" + operation, requestOptions
                );
            }
            result: any = await response.json();
            if not response.ok {
                error = result.error.message or "Could not sign in.";
                return;
            }
            jacSetToken(result.data.token);
            password = "";
            onAuth();
        } except Exception {
            error = "Could not reach the planner service. Check that jac run is active.";
        } finally {
            loading = False;
        }
    }

    <main className="auth-page">
        <section className="auth-story" aria-label="About Plan Forensics">
            <div className="brand-lockup brand-lockup-light">
                <span className="brand-mark">PF</span>
                <strong>Plan Forensics</strong>
            </div>
            <div className="auth-copy">
                <span className="eyebrow">A PLANNER FOR IMPERFECT DAYS</span>
                <h1>
                    Plans fail.
                    <br/>
                    Find the clue.
                </h1>
                <p>
                    Turn abandoned tasks into evidence, uncover the blocker, and leave with one move you can actually make.
                </p>
            </div>
            <div className="evidence-strip">
                <span>01 · Plan</span>
                <span>02 · Observe</span>
                <span>03 · Recover</span>
            </div>
        </section>
        <section className="auth-panel">
            <div className="auth-card">
                <span className="auth-kicker">PRIVATE CASE FILE</span>
                <h2>{("Create your workspace" if isSignup else "Welcome back")}</h2>
                <p>
                    {(
                        "Start collecting better evidence about your plans."
                            if isSignup
                            else "Continue with today’s investigation."
                    )}
                </p>
                {(<div className="error-message" role="alert">{error}</div>)
                    if error
                    else None}
                <form onSubmit={handleSubmit} className="auth-form">
                    <label htmlFor="auth-username">Username</label>
                    <input
                        id="auth-username"
                        type="text"
                        autoComplete="username"
                        required={True}
                        value={username}
                        placeholder="Your username"
                        onChange={lambda (e: ChangeEvent) { username = e.target.value; }}
                    />
                    <label htmlFor="auth-password">Password</label>
                    <input
                        id="auth-password"
                        type="password"
                        autoComplete={"new-password"
                            if isSignup
                            else "current-password"}
                        required={True}
                        value={password}
                        placeholder="At least 8 characters"
                        onChange={lambda (e: ChangeEvent) { password = e.target.value; }}
                    />
                    <button
                        className="primary-button auth-submit"
                        type="submit"
                        disabled={loading}
                    >
                        {(
                            "Opening…"
                                if loading
                                else (
                                    "Create workspace" if isSignup else "Open case file"
                                )
                        )}
                    </button>
                </form>
                <button
                    type="button"
                    className="text-button"
                    disabled={loading}
                    onClick={lambda {
                        isSignup = not isSignup;
                        error = "";
                    }}
                >
                    {(
                        "Already have a workspace? Sign in"
                            if isSignup
                            else "New here? Create a workspace"
                    )}
                </button>
            </div>
        </section>
    </main>
}
