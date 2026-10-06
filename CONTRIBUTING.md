# Development and submission checks

Use a branch for each coherent change and describe the behavior plus actual validation in the pull request. Keep credentials, local user data, and generated bundles out of commits.

## Checks before opening a PR

From the repository root:

```sh
jac check
jac build
git diff --check
git status --short
```

Use `jac check` without a file argument to check the whole application. Run targeted `jac test` commands for changed behavior and report warnings and untested paths honestly. Follow `AGENTS.md` before editing Jac files.

## Manual web smoke check

Start with `jac run --dev`. Use a dedicated test account and disposable tasks.

- Register and sign in.
- Add a task; verify its title and category.
- Refresh and verify the saved task remains.
- Mark the task complete, then reopen it.
- Sign out and verify that task data is hidden.
- Sign in with a second test account and verify the first account's tasks are absent.
- Return to the first account and delete only the disposable task.

Existing AI task creation requires the configured Ollama model. Document model setup in the submission instructions. A successful build alone does not prove these interactions work.

## Blocker workflow check

After the blocker-reporting feature is merged:

- Add an unfinished disposable task and expand "I'm stuck".
- Select a reason, enter a note, and save.
- Verify the latest reason, trimmed note, and report count appear.
- Refresh and verify the record remains.
- Submit a different reason; verify the latest record changes and the count increases.
- Complete the task; verify blocker reporting is hidden.
- Run `jac test endpoints.jac` for validation and task-scope tests.

## Before Canvas submission

- Test the documented installation from a fresh checkout.
- Verify root-level `jac run` starts the web application and server.
- Add author name and UMID to the root README.
- Include mobile and CLI launch instructions once implemented.
- Demonstrate the same task through web, mobile, and CLI using one backend/account.
- Ensure course staff can access the repository and the PR links.
- Include relevant classroom PR links; PR count by itself does not establish eligibility or a particular grade.

Mobile and CLI are not implemented in the initial Day Planner foundation. This checklist is a verification guide, not a claim that all checks have passed.
