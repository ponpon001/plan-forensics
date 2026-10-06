# Plan Forensics

> **Author:** Linyi Lin
> **UMID:** ssylinyi

Plan Forensics is a personal planner for the moment a plan stops working. It keeps a private daily task list, records why unfinished tasks became blocked, and uses the configured AI model to return one concrete recovery action that takes five minutes or less. The visual language is inspired by Notion Calendar’s calm information density, while the evidence timeline and case-file workflow give the project its own identity.

## What makes it different

- **Failure-aware planning:** every blocker report is preserved as a timestamped event instead of being silently overwritten.
- **AI recovery experiments:** the configured model turns a blocker into one five-minute next move; a built-in timer records whether it worked.
- **Reliable fallback:** task creation and blocker recovery still work when the AI provider is unavailable.
- **One private graph:** web, native mobile, and CLI clients use the same authenticated Jac service and persisted data.
- **Measured recovery:** the dashboard tracks completed attempts, recovery success rate, and recurring blocker patterns.

## Architecture

| Component | Jac app | Responsibility |
| --- | --- | --- |
| Server | `planner` → `endpoints.jac` | Authentication boundary, persistent task graph, validation, statistics, and AI calls |
| Web | `web` → `main.jac` | Full planning and blocker-investigation workspace |
| Mobile | `mobile` → `mobile.jac` | Native React Native companion with task editing, filters, timers, and recovery reports |
| CLI | `cli` → `cli.jac` | Terminal account setup, task management, blocker history, and recovery experiments |

`Task` nodes are attached to each authenticated user’s `root`, so planning data persists and remains isolated per account. The service returns `TaskView` and `PlannerSnapshot` objects across app boundaries; clients never manipulate persistent nodes directly.

## Prerequisites

- Jac `0.37.23`
- Node dependencies installed by `jac install`
- An API key for any byLLM-supported provider, if AI-powered classification and recovery clues are desired
- For native Android: Android/Expo prerequisites provisioned by Jac on first run

## Install and run the web app

From the repository root:

```bash
jac install
jac run
```

Open <http://localhost:8000>, create an account, and add a task. A bare `jac run` starts the default `web` app and colocates the shared `planner` service, satisfying the submission requirement.

### Choose an AI model

The instructor can choose any byLLM-supported provider. Edit the model section in `jac.toml`; for example, OpenAI uses:

```toml
[byllm.model]
default_model = "gpt-4o-mini"
api_key = "${OPENAI_API_KEY}"
```

Then provide the matching key as an environment variable in the same terminal that starts Jac:

```bash
read -s -p "OpenAI API key: " OPENAI_API_KEY
printf '\n'
export OPENAI_API_KEY
jac run
```

For another provider, replace both values with that provider's model name and environment variable, such as `gemini/gemini-2.0-flash` with `${GOOGLE_API_KEY}`. Never paste a real key into `jac.toml` or commit one to GitHub. Close the terminal or run `unset OPENAI_API_KEY` to remove the temporary credential. Without a working provider, the core planner remains usable and recovery clues use the local `Safe fallback`; successful provider responses are labeled `AI generated`.

## Mobile app

Keep the web/server process running. For the fast browser preview of the React Native interface:

```bash
jac run --dev --platform web mobile
```

For an Android device or emulator:

```bash
jac run --dev mobile
```

Enter the backend address on the connection screen:

- Android emulator: `http://10.0.2.2:8000`
- Physical phone: `http://YOUR_COMPUTER_LAN_IP:8000`
- Browser preview: `http://127.0.0.1:8000`

Then sign in with the same account used on the web. Mobile now supports task editing, due dates, priority and estimate changes, search and filters, focus timers, blocker reports, and five-minute recovery experiments.

## CLI

Keep the web/server process running. Create an account from the CLI, or sign in using an account created on web or mobile:

```bash
jac run cli -- register YOUR_USERNAME
jac run cli -- login YOUR_USERNAME
```

Useful commands:

```bash
jac run cli -- today
jac run cli -- --priority high --minutes 45 --due 2026-10-12 add "Finish project reflection"
jac run cli -- --title "Finish final reflection" --minutes 30 edit TASK_ID
jac run cli -- timer TASK_ID start
jac run cli -- timer TASK_ID pause
jac run cli -- timer TASK_ID finish
jac run cli -- toggle TASK_ID
jac run cli -- block TASK_ID too_large "The scope is still unclear"
jac run cli -- blockers
jac run cli -- recovered
jac run cli -- report REPORT_ID
jac run cli -- recover REPORT_ID
jac run cli -- delete TASK_ID
jac run cli -- logout
```

`recover REPORT_ID` starts the five-minute countdown and then prompts for Worked, Still blocked, or Stopped early. If the timer is interrupted, use `finish REPORT_ID worked|still_blocked|stopped_early SECONDS` to save the outcome. The CLI stores its session token in `~/.plan-forensics.json` with owner-only permissions. Set `PLAN_FORENSICS_URL` when the backend is not at `http://127.0.0.1:8000`; a saved login for a different address will now produce an explicit error.

## Suggested demo

1. Create an account in the web app.
2. Add a high-priority 45-minute task and show the AI category.
3. Open **Report a blocker**, choose “The task feels too large,” and save a short note.
4. Show the generated five-minute **Next move** and the updated evidence summary.
5. Open the mobile preview or CLI and complete the same task to demonstrate shared state.

## Verification

```bash
jac check
jac test planner
jac test cli
jac build web
jac build --platform web mobile
```

Before submitting, verify the author details at the top of this README and try the commands from a fresh checkout.

## Attribution

Built on the [Jac AI Day Planner tutorial](https://www.jac-lang.org/tutorials/first-app/build-ai-day-planner/). Plan Forensics extends that foundation with an implemented blocker-and-recovery workflow across web, mobile, and CLI clients.
