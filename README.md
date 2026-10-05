# Plan Forensics

A personal planner that helps users understand what blocked a task and choose a smaller, practical next step.

## Current implementation

This repository starts from an existing Jac Day Planner. It contains a web interface, authentication UI, private task endpoints, persistent task nodes, AI task categorization, and an AI meal shopping list. Runtime behavior has not yet been verified for this repository setup.

Blocker tracking, recovery suggestions, mobile, and CLI are planned features, not completed features.

## Setup

- Install Jac 0.37.21, matching `jac.toml`.
- Install the project's dependencies with `jac install`.
- For the existing AI features, install and start Ollama and download the configured model with `ollama pull gemma3:4b`.
- From the repository root, run `jac run` to start the web application and server. For development, use `jac run --dev`.

Follow the URL printed by the server and register or log in. Fresh-checkout setup and runtime validation remain to be completed.

## Planned core workflow

1. Add a personal task.
2. Complete it, or select "I'm stuck".
3. Record a blocker such as insufficient time, low energy, unclear first step, or missing resources.
4. Request a small next-step suggestion.
5. Review and confirm suggestions before saving new tasks.
6. Inspect summaries of recorded blockers without treating a few records as proof of a behavioral pattern.

## Four-component delivery plan

| Component | Responsibility | Status |
| --- | --- | --- |
| Server | Persist user tasks, blocker records, and recovery suggestions | Existing task backend; extensions planned |
| Web | Manage tasks, report blockers, review suggestions | Existing Day Planner UI; extensions planned |
| Mobile | View tasks, complete tasks, report blockers using the same backend | Not implemented |
| CLI | Add/list/complete tasks and record blockers using the same backend | Not implemented |

Mobile and CLI launch instructions will be added when those components work. The current project does not yet satisfy the full four-component assignment requirement.

## Submission checklist

- [ ] Add author name and UMID before submitting.
- [ ] Implement and test blocker persistence.
- [ ] Implement recovery suggestions with a usable fallback if AI is unavailable.
- [ ] Implement mobile and CLI against the same authenticated backend.
- [ ] Verify user data isolation across interfaces.
- [ ] Verify root-level `jac run` from a fresh checkout.
- [ ] Document mobile and CLI setup and usage.
- [ ] Include relevant PR links with the Canvas submission.

## Attribution

Built on the [Jac AI Day Planner tutorial](https://www.jac-lang.org/tutorials/first-app/build-ai-day-planner/). Plan Forensics extends that foundation with a planned blocker-and-recovery workflow.
