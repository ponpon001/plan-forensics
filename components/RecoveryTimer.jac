"""Five-minute recovery timer with persisted outcome feedback."""
import from endpoints { BlockerReportView, begin_recovery, finish_recovery }


def formatClock(seconds: int) -> str {
    minutes = int(seconds / 60);
    remainder = seconds % 60;
    return str(minutes) + ":" + ("0" if remainder < 10 else "") + str(remainder);
}


def outcomeText(outcome: str) -> str {
    if outcome == "worked" {
        return "Worked";
    }
    if outcome == "still_blocked" {
        return "Still blocked";
    }
    if outcome == "stopped_early" {
        return "Stopped early";
    }
    if outcome == "running" {
        return "Recovery started";
    }
    return "Not tried yet";
}


def:pub RecoveryTimer(
    incident: BlockerReportView, onSaved: Callable[[], None]
) -> JsxElement {
    has secondsLeft: int = 300,
        sessionActive: bool = False,
        running: bool = False,
        reflecting: bool = False,
        saving: bool = False,
        error: str = "";

    can with [running, secondsLeft] entry {
        if running and secondsLeft > 0 {
            timeoutId = setTimeout(lambda { secondsLeft -= 1; }, 1000);
            return lambda { clearTimeout(timeoutId); };
        }
        if running and secondsLeft <= 0 {
            running = False;
            reflecting = True;
        }
    }

    async def startRecovery {
        if saving {
            return;
        }
        saving = True;
        error = "";
        try {
            started = await begin_recovery(incident.id);
            if started is None {
                error = "This recovery record is no longer available.";
            } else {
                secondsLeft = 300;
                sessionActive = True;
                reflecting = False;
                running = True;
            }
        } except Exception {
            error = "Could not start the recovery timer.";
        } finally {
            saving = False;
        }
    }

    def pauseRecovery {
        running = False;
    }

    def resumeRecovery {
        if secondsLeft > 0 {
            reflecting = False;
            running = True;
        }
    }

    def reflectNow {
        running = False;
        reflecting = True;
    }

    async def saveOutcome(outcome: str) {
        if saving {
            return;
        }
        saving = True;
        error = "";
        try {
            saved = await finish_recovery(incident.id, outcome, 300 - secondsLeft);
            if saved is None {
                error = "This recovery record is no longer available.";
            } else {
                sessionActive = False;
                reflecting = False;
                running = False;
                await onSaved();
            }
        } except Exception {
            error = "Could not save the recovery result.";
        } finally {
            saving = False;
        }
    }

    <div className="recovery-timer">
        {(
            <div className="timer-session" aria-live="polite">
                <div className="timer-clock">
                    <span>{formatClock(secondsLeft)}</span>
                    <small>{("focus running" if running else "focus paused")}</small>
                </div>
                <div className="timer-controls">
                    {(
                        <button
                            type="button"
                            className="secondary-button"
                            onClick={pauseRecovery}
                        >
                            Pause
                        </button>
                    )
                        if running
                        else (
                            <button
                                type="button"
                                className="secondary-button"
                                onClick={resumeRecovery}
                                disabled={secondsLeft == 0}
                            >
                                Resume
                            </button>
                        )}
                    <button type="button" className="text-button" onClick={reflectNow}>
                        Finish & reflect
                    </button>
                </div>
            </div>
        )
            if sessionActive and not reflecting
            else None}{(
            <div className="outcome-panel">
                <span>What happened?</span>
                <div>
                    <button
                        type="button"
                        className="outcome-button outcome-worked"
                        disabled={saving}
                        onClick={lambda { saveOutcome("worked"); }}
                    >
                        Worked
                    </button>
                    <button
                        type="button"
                        className="outcome-button"
                        disabled={saving}
                        onClick={lambda { saveOutcome("still_blocked"); }}
                    >
                        Still blocked
                    </button>
                    <button
                        type="button"
                        className="outcome-button"
                        disabled={saving}
                        onClick={lambda { saveOutcome("stopped_early"); }}
                    >
                        Stopped early
                    </button>
                </div>
            </div>
        )
            if sessionActive and reflecting
            else None}{(
            <div className="recorded-outcome">
                <span>Last attempt</span>
                <strong>{outcomeText(incident.outcome)}</strong>
                {(<small>{incident.elapsed_seconds} sec focused</small>)
                    if incident.elapsed_seconds > 0
                    else None}
            </div>
        )
            if not sessionActive and incident.outcome not in ["pending", "running"]
            else None}{(<div className="timer-error" role="alert">{error}</div>)
            if error
            else None}{(
            <button
                type="button"
                className="primary-button timer-start"
                disabled={saving}
                onClick={startRecovery}
            >
                {(
                    "Starting…"
                        if saving
                        else (
                            "Try recovery again"
                                if incident.outcome not in ["pending", "running"]
                                else "Start 5-min recovery"
                        )
                )}
            </button>
        )
            if not sessionActive
            else None}
    </div>
}
