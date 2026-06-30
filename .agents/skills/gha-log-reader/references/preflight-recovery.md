# Pre-flight Recovery Paths

Full recovery dialogs for failed dependency checks. Follow the path matching the
failed check; do not proceed past a hard failure until resolved or the user has
accepted a fallback.

## 1. `gh` CLI missing (hard failure — no `gh`, no live data)

Do not attempt any API calls. Switch to paste mode:

> "I need the `gh` CLI to fetch live run data and it's not installed. You can still
> get a diagnosis by pasting the log directly.
>
> **How to get the log:**
> 1. Open the failing run in your browser
> 2. Click the failing job in the left sidebar
> 3. Click the failing step to expand it
> 4. Click the gear icon (⚙) → **View raw logs**, or use the **Download log archive**
>    button at the top right of the job view
> 5. Paste the output here — focus on the failing step and any lines above it
>    (last ~100–200 lines of that step is usually enough)
>
> If you paste the full log, I'll find the failure signal automatically."

Once the user pastes log content, proceed directly to Phase 1 using the pasted text
instead of fetching. Skip all `gh` commands for the rest of the session.

## 2. `gh` not authenticated (hard failure)

> "The `gh` CLI is installed but not authenticated. Run:
> ```
> gh auth login
> ```
> Choose GitHub.com → HTTPS → authenticate via browser. Then retry."

Do not proceed until authenticated.

### Authenticated but no repo access (403 or 404 on first API call)

Do not run a proactive access check — that would consume an API request. Instead,
if any Phase 0 API call returns 403 or 404, surface it immediately:

> "Got a 403/404 fetching job data. This usually means:
> - Your token doesn't have `repo` scope for this private repo
> - Run `gh auth status` to confirm scopes, or re-auth with: `gh auth login --scopes repo`"

## 3. `jq` missing

Ask the user before falling back:

> "`jq` is not installed — I need it to parse the GitHub API responses. I can fall
> back to using Python 3 instead, but I want you to know:
>
> ⚠️ The Python fallback executes code locally on your machine (short inline
> scripts passed to `python3 -c`). This is generally safe for JSON parsing, but
> it does involve code execution. If that's not acceptable in your environment,
> install `jq` (`brew install jq` / `apt install jq`) and restart.
>
> Should I proceed with the Python 3 fallback?"

Only use `python3` if the user explicitly agrees. If they decline both, switch to
paste mode (same as the missing `gh` path above).
