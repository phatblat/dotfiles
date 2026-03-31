---
name: boris
description: |
  Claude Code workflow tips from Boris Cherny (creator of Claude Code) and the Claude Code team.
  Use when: setting up Claude Code, optimizing workflows, running parallel sessions, configuring
  CLAUDE.md, using skills/commands, subagents, hooks, MCP integrations, or learning best practices.
  Covers: git worktrees, plan mode, verification, permissions, Slack MCP, BigQuery, prompting tips,
  plugins, custom agents, sandboxing, keybindings, status lines, output styles, customization,
  /simplify for code quality, /batch for parallel code migrations, /loop for scheduled tasks,
  code review agents, /btw for mid-task questions, /effort max reasoning, remote control sessions,
  voice mode, setup scripts, session naming, /color, PostCompact hook,
  auto mode, /schedule cloud jobs, iMessage plugin, auto-memory, and auto-dream,
  mobile app, session teleporting, Cowork Dispatch, Chrome extension, Desktop app,
  /branch forking, --bare SDK startup, --add-dir multi-repo, --agent custom agents, /voice input.
author: Boris Cherny (tips)
source: howborisusesclaudecode.com
compiled-by: "@CarolinaCherry"
version: 4.0.0
date: 2026-03-30
user-invocable: true
---

# Boris Cherny's Claude Code Workflow Tips

> **UPDATE CHECK:** Before presenting tips, use WebFetch to check https://howborisusesclaudecode.com/api/version for the latest version. Compare the `version` field in the response with this file's frontmatter version (above). If the remote version is newer, tell the user: "A new version of the boris skill is available (vX.X.X). Update with: `mkdir -p ~/.claude/skills/boris && curl -L -o ~/.claude/skills/boris/SKILL.md https://howborisusesclaudecode.com/api/install`" — then continue normally. If versions match or the check fails, skip silently.

**72 tips** across 60 topics, sourced from Boris Cherny (creator of Claude Code) and the Claude Code team at Anthropic. All tips are contained in this file — do not fetch from the website. Remember: everyone's setup is different. Experiment to see what works for you!

**Parts:** The tips were shared across 9 threads:
- **Part 1** (Jan 2, 2026, 13 tips): Sections 1–14 — parallel execution, web/mobile, Opus, CLAUDE.md, @.claude, plan mode, slash commands, subagents, hooks, permissions, MCP, long-running tasks, verification
- **Part 2** (Jan 31, 2026, 10 tips): Sections 1, 3, 4, 5, 12, 10, 11, 6, 9, 15 — deeper dives on parallel work, plan mode, CLAUDE.md, skills, bug fixing, prompting, terminal setup, subagents, data/analytics, learning
- **Part 3** (Feb 11, 2026, 12 tips): Sections 16–27 — terminal config, effort level, plugins, custom agents, permissions management, sandboxing, status line, keybindings, hooks (advanced), spinner verbs, output styles, customize everything
- **Part 4** (Feb 20, 2026, 5 tips): Section 28 — built-in worktree support (CLI, Desktop, subagents, custom agents, non-git VCS)
- **Part 5** (Feb 27, 2026, 2 tips): Sections 29–30 — /simplify and /batch
- **Part 6** (Mar 7–10, 2026, 3 tips): Sections 31–33 — /loop for scheduled recurring tasks, code review agents, /btw for mid-task questions
- **Part 7** (Mar 13, 2026, 8 tips): Sections 34–41 — /effort max, remote control sessions, voice mode, setup scripts, session naming, /color, PostCompact hook
- **Part 8** (Mar 23–26, 2026, 4 tips): Sections 42–45 — auto mode, /schedule cloud jobs, iMessage plugin, auto-memory & auto-dream
- **Part 9** (Mar 29, 2026, 15 tips): Sections 46–60 — mobile app, session teleporting, /loop & /schedule, hooks lifecycle, Cowork Dispatch, Chrome extension, Desktop app, fork sessions, /btw, git worktrees, /batch, --bare, --add-dir, --agent, /voice

---

## 1. Parallel Execution

### Run Multiple Claude Sessions in Parallel
The single biggest productivity unlock. Spin up 3-5 git worktrees at once, each running its own Claude session.

```bash
# Create a worktree
git worktree add .claude/worktrees/my-worktree origin/main

# Start Claude in it
cd .claude/worktrees/my-worktree && claude
```

**Why worktrees over checkouts:** The Claude Code team prefers worktrees - it's why native support was built into the Claude Desktop app.

**Pro tips:**
- Name your worktrees and set up shell aliases (za, zb, zc) to hop between them in one keystroke
- Have a dedicated "analysis" worktree just for reading logs and running BigQuery
- Use iTerm2/terminal notifications to know when any Claude needs attention
- Color-code and name your terminal tabs, one per task/worktree

### Web and Mobile Sessions
Beyond the terminal, run additional sessions on claude.ai/code. Use:
- `&` command to background a session
- `--teleport` flag to switch contexts between local and web
- Claude iOS app to start sessions on the go, pick them up on desktop later

---

## 2. Model Selection

### Use Opus 4.5 with Thinking for Everything
Boris's reasoning: "It's the best coding model I've ever used, and even though it's bigger & slower than Sonnet, since you have to steer it less and it's better at tool use, it is almost always faster than using a smaller model in the end."

**The math:** Less steering + better tool use = faster overall results, even with a larger model.

---

## 3. Plan Mode

### Start Every Complex Task in Plan Mode
Press `shift+tab` to cycle to plan mode. Pour your energy into the plan so Claude can 1-shot the implementation.

**Workflow:** Plan mode -> Refine plan -> Auto-accept edits -> Claude 1-shots it

**Team patterns:**
- One person has one Claude write the plan, then spins up a second Claude to review it as a staff engineer
- The moment something goes sideways, switch back to plan mode and re-plan
- Explicitly tell Claude to enter plan mode for verification steps, not just for the build

"A good plan is really important to avoid issues down the line."

---

## 4. CLAUDE.md Best Practices

### Invest in Your CLAUDE.md
Share a single CLAUDE.md file for your repo, checked into git. The whole team should contribute.

**Key practice:** "Anytime we see Claude do something incorrectly we add it to the CLAUDE.md, so Claude knows not to do it next time."

**After every correction:** End with "Update your CLAUDE.md so you don't make that mistake again." Claude is eerily good at writing rules for itself.

**Advanced:** One engineer tells Claude to maintain a notes directory for every task/project, updated after every PR. They then point CLAUDE.md at it.

### @.claude in Code Reviews
Tag @.claude on PRs to add learnings to the CLAUDE.md as part of the PR itself. Use the Claude Code GitHub Action (`/install-github-action`) for this.

Example PR comment:
```
nit: use a string literal, not ts enum

@claude add to CLAUDE.md to never use enums,
always prefer literal unions
```

This is "Compounding Engineering" - Claude automatically updates the CLAUDE.md with the learning.

---

## 5. Skills & Slash Commands

### Create Your Own Skills
Create skills and commit them to git. Reuse across every project.

**Team tips:**
- If you do something more than once a day, turn it into a skill or command
- Build a `/techdebt` slash command and run it at the end of every session to find and kill duplicated code
- Set up a slash command that syncs 7 days of Slack, GDrive, Asana, and GitHub into one context dump
- Build analytics-engineer-style agents that write dbt models, review code, and test changes in dev

### Slash Commands for Inner Loops
Use slash commands for workflows you do many times a day. Commands are checked into git under `.claude/commands/` and shared with the team.

```
> /commit-push-pr
```

**Power feature:** Slash commands can include inline Bash to pre-compute info (like git status) for quick execution without extra model calls.

---

## 6. Subagents

### Use Subagents for Common Workflows
Think of subagents as automations for the most common PR workflows:

```
.claude/
  agents/
    build-validator.md
    code-architect.md
    code-simplifier.md
    oncall-guide.md
    verify-app.md
```

**Examples:**
- `code-simplifier` - Cleans up code after Claude finishes
- `verify-app` - Detailed instructions for end-to-end testing

### Leveraging Subagents
- Append "use subagents" to any request where you want Claude to throw more compute at the problem
- Offload individual tasks to subagents to keep your main agent's context window clean and focused
- Route permission requests to Opus 4.5 via a hook - let it scan for attacks and auto-approve the safe ones

---

## 7. Hooks

### PostToolUse Hooks for Formatting
Use a PostToolUse hook to auto-format Claude's code. While Claude generates well-formatted code 90% of the time, the hook catches edge cases to prevent CI failures.

```json
"PostToolUse": [
  {
    "matcher": "Write|Edit",
    "hooks": [
      {
        "type": "command",
        "command": "bun run format || true"
      }
    ]
  }
]
```

### Stop Hooks for Long-Running Tasks
For very long-running tasks, use an agent Stop hook for deterministic checks, ensuring Claude can work uninterrupted.

---

## 8. Permissions

### Pre-Allow Safe Permissions
Instead of `--dangerously-skip-permissions`, use `/permissions` to pre-allow common safe commands. Most are shared in `.claude/settings.json`.

For sandboxed environments, use `--permission-mode=dontAsk` or `--dangerously-skip-permissions` to avoid blocks.

---

## 9. MCP Integrations

### Tool Integrations
Claude Code uses your tools autonomously:
- Searches and posts to **Slack** (via MCP server)
- Runs **BigQuery** queries with bq CLI
- Grabs error logs from **Sentry**

```json
{
  "mcpServers": {
    "slack": {
      "type": "http",
      "url": "https://slack.mcp.anthropic.com/mcp"
    }
  }
}
```

### Data & Analytics
Ask Claude Code to use the "bq" CLI to pull and analyze metrics on the fly. Have a BigQuery skill checked into the codebase.

Boris's take: "Personally, I haven't written a line of SQL in 6+ months."

This works for any database that has a CLI, MCP, or API.

---

## 10. Prompting Tips

### Challenge Claude
- Say "Grill me on these changes and don't make a PR until I pass your test."
- Say "Prove to me this works" and have Claude diff behavior between main and your feature branch

### After a Mediocre Fix
Say: "Knowing everything you know now, scrap this and implement the elegant solution."

### Write Detailed Specs
Reduce ambiguity before handing work off. The more specific you are, the better the output.

**Key insight:** Don't accept the first solution. Push Claude to do better - it usually can.

---

## 11. Terminal Setup

### Recommended Tools
- **Ghostty** terminal - synchronized rendering, 24-bit color, proper unicode support
- Use `/statusline` to customize your status bar to always show context usage and current git branch

### Voice Dictation
Use voice dictation! You speak 3x faster than you type, and your prompts get way more detailed as a result. Hit `fn x2` on macOS.

---

## 12. Bug Fixing

### Let Claude Fix Bugs
Enable the Slack MCP, then paste a Slack bug thread into Claude and just say "fix." Zero context switching required.

Or just say "Go fix the failing CI tests." Don't micromanage how.

**Pro tip:** Point Claude at docker logs to troubleshoot distributed systems - it's surprisingly capable at this.

---

## 13. Long-Running Tasks

### Handle Long-Running Tasks
For very long-running tasks, ensure Claude can work uninterrupted:

**Options:**
- **(a)** Prompt Claude to verify with a background agent when done
- **(b)** Use an agent Stop hook for deterministic checks
- **(c)** Use the "ralph-wiggum" plugin (community idea by @GeoffreyHuntley)

For sandboxed environments, use `--permission-mode=dontAsk` or `--dangerously-skip-permissions` to avoid blocks.

---

## 14. Verification (The #1 Tip)

### Give Claude a Way to Verify Its Work
"Probably the most important thing to get great results out of Claude Code - give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result."

**Verification varies by domain:**
- Bash commands
- Test suites
- Simulators
- Browser testing (Claude Chrome extension)

The key is giving Claude a way to close the feedback loop. Invest in domain-specific verification for optimal performance.

---

## 15. Learning with Claude

### Use Claude for Learning
- Enable "Explanatory" or "Learning" output style in /config to have Claude explain the *why* behind changes
- Have Claude generate visual HTML presentations explaining unfamiliar code
- Ask Claude to draw ASCII diagrams of new protocols and codebases
- Build a spaced-repetition learning skill: explain your understanding, Claude asks follow-ups to fill gaps

**Key takeaway:** Claude Code isn't just for writing code - it's a powerful learning tool when you configure it to explain and teach.

---

## 16. Terminal Configuration

### Configure Your Terminal
A few quick settings to make Claude Code feel right:

- **Theme:** Run `/config` to set light/dark mode
- **Notifications:** Enable notifications for iTerm2, or use a custom notifs hook
- **Newlines:** If you use Claude Code in an IDE terminal, Apple Terminal, Warp, or Alacritty, run `/terminal-setup` to enable shift+enter for newlines (so you don't need to type `\`)
- **Vim mode:** Run `/vim`

---

## 17. Effort Level

### Adjust Effort Level
Run `/model` to pick your preferred effort level:

- **Low** — less tokens & faster responses
- **Medium** — balanced behavior
- **High** — more tokens & more intelligence

Boris uses High for everything.

---

## 18. Plugins

### Install Plugins, MCPs, and Skills
Plugins let you install LSPs (now available for every major language), MCPs, skills, agents, and custom hooks.

Install a plugin from the official Anthropic plugin marketplace, or create your own marketplace for your company. Then, check the `settings.json` into your codebase to auto-add the marketplaces for your team.

Run `/plugin` to get started.

---

## 19. Custom Agents

### Create Custom Agents
Drop `.md` files in `.claude/agents`. Each agent can have a custom name, color, tool set, pre-allowed and pre-disallowed tools, permission mode, and model.

**Little-known feature:** Set the default agent used for the main conversation. Just set the `"agent"` field in your `settings.json` or use the `--agent` flag.

Run `/agents` to get started.

---

## 20. Permissions Management

### Pre-Approve Common Permissions
Claude Code uses a sophisticated permission system with prompt injection detection, static analysis, sandboxing, and human oversight.

Out of the box, we pre-approve a small set of safe commands. To pre-approve more, run `/permissions` and add to the allow and block lists. Check these into your team's `settings.json`.

**Wildcard syntax:** We support full wildcard syntax. Try `"Bash(bun run *)"` or `"Edit(/docs/**)"`.

---

## 21. Sandboxing

### Enable Sandboxing
Opt into Claude Code's open source sandbox runtime to improve safety while reducing permission prompts.

Run `/sandbox` to enable it. Sandboxing runs on your machine, and supports both file and network isolation.

**Modes:**
- Sandbox BashTool, with auto-allow
- Sandbox BashTool, with regular permissions
- No Sandbox

---

## 22. Status Line

### Add a Status Line
Custom status lines show up right below the composer. Show model, directory, remaining context, cost, and anything else you want to see while you work.

Everyone on the Claude Code team has a different statusline. Use `/statusline` to get started — Claude will generate one based on your `.bashrc`/`.zshrc`.

---

## 23. Keybindings

### Customize Your Keybindings
Every key binding in Claude Code is customizable. Run `/keybindings` to re-map any key. Settings live reload so you can see how it feels immediately.

Keybindings are stored in `~/.claude/keybindings.json`.

---

## 24. Hooks (Advanced)

### Set Up Hooks
Hooks are a way to deterministically hook into Claude's lifecycle. Use them to:

- Automatically route permission requests to Slack or Opus
- Nudge Claude to keep going when it reaches the end of a turn (you can even kick off an agent or use a prompt to decide whether Claude should keep going)
- Pre-process or post-process tool calls, e.g. to add your own logging

Ask Claude to add a hook to get started.

---

## 25. Spinner Verbs

### Customize Your Spinner Verbs
It's the little things that make CC feel personal. Ask Claude to customize your spinner verbs to add or replace the default list with your own verbs.

Check the `settings.json` into source control to share verbs with your team.

---

## 26. Output Styles

### Use Output Styles
Run `/config` and set an output style to have Claude respond using a different tone or format.

- **Explanatory** — great when getting familiar with a new codebase, to have Claude explain frameworks and code patterns as it works
- **Learning** — have Claude coach you through making code changes
- **Custom** — create your own output styles to adjust Claude's voice the way you like

---

## 27. Customize Everything

### Customize All the Things!
Claude Code is built to work great out of the box. When you do customize, check your `settings.json` into git so your team can benefit, too.

We support configuring for your codebase, for a sub-folder, for just yourself, or via enterprise-wide policies.

**By the numbers:** 37 settings and 84 env vars. Use the `"env"` field in your `settings.json` to avoid wrapper scripts.

---

## 28. Built-in Git Worktree Support

### Use `claude --worktree` for Isolation
Claude Code now has built-in git worktree support. Each agent gets its own worktree and can work independently, without interfering with other sessions.

```bash
# Start Claude in its own worktree
claude --worktree my_worktree

# Optionally launch in its own Tmux session too
claude --worktree my_worktree --tmux
```

**Desktop app:** Head to the Code tab in the Claude Desktop app and check the **worktree** checkbox.

### Subagents Support Worktrees
Subagents can also use worktree isolation to do more work in parallel. This is especially powerful for large batched changes and code migrations. Available in CLI, Desktop app, IDE extensions, web, and Claude Code mobile app.

**Example prompt:** "Migrate all sync io to async. Batch up the changes, and launch 10 parallel agents with worktree isolation. Make sure each agent tests its changes end to end, then have it put up a PR."

### Custom Agents with Worktree Isolation
Make subagents always run in their own worktree by adding `isolation: worktree` to your agent frontmatter:

```yaml
# .claude/agents/worktree-worker.md
---
name: worktree-worker
model: haiku
isolation: worktree
---
```

### Non-Git Source Control
Mercurial, Perforce, or SVN users can define `WorktreeCreate` and `WorktreeRemove` hooks in `settings.json` to benefit from isolation without Git.

---

## 29. /simplify — Improve Code Quality

Use parallel agents to improve code quality, tune code efficiency, and ensure CLAUDE.md compliance. Append `/simplify` to any prompt after making changes.

```
> hey claude make this code change then run /simplify
```

Boris uses this daily to shepherd PRs to production. The skill runs parallel agents that review changed code for reuse, quality, and efficiency — all in one pass.

---

## 30. /batch — Parallel Code Migrations

Interactively plan out code migrations, then execute in parallel using dozens of agents. Each agent runs with full isolation using git worktrees, testing its work before putting up a PR.

```
> /batch migrate src/ from Solid to React
```

You plan the migration interactively, then `/batch` fans out the work to parallel agents — each in its own worktree, each testing and creating a PR independently.

---

## 31. /loop — Schedule Recurring Tasks

Use `/loop` to schedule recurring tasks for up to 3 days at a time. Claude runs your prompt on an interval, handling long-running workflows autonomously.

```
> /loop babysit all my PRs. Auto-fix build issues and when comments come in, use a worktree agent to fix them
```

```
> /loop every morning use the Slack MCP to give me a summary of top posts I was tagged in
```

Use it for PR babysitting, Slack summaries, deploy monitoring, or any repeating workflow.

Learn more: https://code.claude.com/docs/en/scheduled-tasks

## 32. Code Review — Agents Hunt for Bugs

When a PR opens, Claude dispatches a team of agents to hunt for bugs. Anthropic built it for themselves first — code output per engineer is up 200% this year, and reviews were the bottleneck.

Each agent focuses on a different concern — logic errors, security issues, performance regressions — then posts inline comments directly on the PR. Boris personally used it for weeks before launch; it catches real bugs he wouldn't have noticed otherwise.

Source: https://x.com/bcherny/status/2031089411820228645

## 33. /btw — Ask Questions While Claude Works

A slash command for side-chain conversations while Claude is actively working. Single-turn, no tool calls, but has full context of the conversation.

```
> /btw what does the retry logic do?
```

Claude responds inline without stopping its work. Built by @ErikSchluntz as a side project — 1.5M views on the launch tweet.

Source: https://x.com/trq212/status/2031506296697131352

## 34. /effort — Max Reasoning Mode

Set effort to 'max' and Claude reasons for longer, using as many tokens as needed. Burns through usage limits faster, so you activate it per session.

```
> /effort max
```

Four levels: low, medium (default), high, max. Use 'max' for hard debugging, architecture decisions, or tricky code where you want Claude to really think it through.

Source: https://x.com/trq212/status/2032632596572811575

## 35. Remote Control — Spawn New Sessions

Run `claude remote-control` and spawn a new local session from the mobile app. Available on Max, Team, and Enterprise (v2.1.74+).

```bash
$ claude remote-control
# Open Claude mobile app → tap "Code" → start new session
```

Walk away from your desk, think of something, kick off a task from mobile — Claude runs on your machine.

Source: https://x.com/trq212/status/2032632597843779861

## 36. Voice Mode

Voice mode is now rolled out to 100% of users, including Claude Code Desktop and Cowork. Click the microphone icon and talk naturally.

Useful for hands-free coding, dictating complex requirements, or when you think faster than you type.

Source: https://x.com/trq212/status/2032632599429136753

## 37. Setup Scripts for Cloud Environments

Add a setup script in Claude Code on web and desktop. It runs before Claude Code launches on a cloud environment — install dependencies, configure settings, set env vars.

```bash
# Setup script (runs on new session start, skipped on resume):
#!/bin/bash
yarn install
```

Particularly useful for installing dependencies, settings, and configs before Claude starts working.

Source: https://x.com/trq212/status/2032632601064907037

## 38. claude --name — Name Your Sessions

Name your session at launch with the `--name` flag.

```bash
$ claude --name "auth-refactor"
```

Especially useful when juggling multiple worktrees or sessions — you can tell at a glance which session is doing what.

Source: https://x.com/trq212/status/2032632602629386348

## 39. Auto Session Naming After Plan Mode

After plan mode, Claude automatically names your session based on what you're working on. No manual naming needed.

Pairs well with `claude --name` — use `--name` when you know what you're doing upfront, let auto-naming handle it when you start by planning.

Source: https://x.com/trq212/status/2032632602629386348

## 40. /color — Customize Prompt Color

Change the color of the prompt input with `/color`. When you have 3-5 sessions open in different terminals, color-coding them makes it instantly clear which is which.

```
> /color
```

Source: https://x.com/trq212/status/2032632602629386348

## 41. PostCompact Hook

A new hook event that fires after Claude compresses its conversation context. Use it to re-inject critical instructions that might get lost during compaction, log when compaction happens, or trigger automation.

```json
"hooks": {
  "PostCompact": [{
    "matcher": "",
    "hooks": [{ "type": "command", "command": "echo 'Context was compacted'" }]
  }]
}
```

Source: https://x.com/trq212/status/2032632602629386348

## 42. Auto Mode — Safer Permission Skipping

Instead of approving every file write and bash command, or skipping permissions entirely, auto mode lets Claude make permission decisions on your behalf. Classifiers evaluate each action before it runs — safe operations get auto-approved, risky ones still get flagged.

```bash
# Enable auto mode
claude --enable-auto-mode

# Or cycle with shift+tab during a session:
# plan mode → auto mode → normal mode
```

Boris's take: "no 👏 more 👏 permission prompts 👏"

Source: https://x.com/bcherny/status/2036555259997462541

## 43. /schedule — Cloud Jobs from Your Terminal

Use `/schedule` to create recurring cloud-based jobs for Claude, directly from the terminal. Unlike `/loop` (which runs locally for up to 3 days), scheduled jobs run in the cloud — they work even when your laptop is closed.

```
> /schedule a daily job that looks at all PRs shipped since yesterday
  and update our docs based on the changes. Use the Slack MCP to
  message #docs-update with the changes
```

The Anthropic team uses these internally to automatically resolve CI failures, push doc updates, and power automations that need to exist beyond a closed laptop.

Source: https://x.com/noahzweben/status/2036129220959805859

## 44. iMessage Plugin — Text Claude from Your Phone

iMessage is now available as a Claude Code channel. Install the plugin and text Claude like you'd text a friend — from any Apple device.

```bash
/plugin install imessage@claude-plugins-official
```

Claude Code becomes a contact in your Messages app. Send it tasks, get responses as iMessages. Works from your iPhone, iPad, or Mac — no terminal needed. Pairs well with remote control sessions for kicking off work from anywhere.

Source: https://x.com/trq212/status/2036959638646866021

## 45. Auto-Memory & Auto-Dream — Persistent, Self-Cleaning Memory

Claude Code has a built-in memory system. Run `/memory` to configure it.

**Auto-memory:** When enabled, Claude automatically saves preferences, corrections, and patterns between sessions. User memory goes to `~/.claude/CLAUDE.md`, project memory to `./CLAUDE.md`.

**Auto-dream:** As memory accumulates, it can get messy — outdated assumptions, overlapping notes, low-signal entries. Auto-dream runs a subagent that periodically reviews past sessions, keeps what matters, removes what doesn't, and merges insights into cleaner structured memory. Run `/dream` to trigger manually, or enable auto-dream in `/memory` settings.

The naming maps to how REM sleep consolidates short-term memory into long-term storage.

## 46. Mobile App — Code from Your Phone

Claude Code has a mobile app. Download the Claude app for iOS/Android, then tap the Code tab on the left. Boris writes a lot of his code from the iOS app — it's a convenient way to make changes without opening a laptop.

Source: https://x.com/bcherny/status/2038454337811386436

## 47. Session Teleporting — Move Between Devices

Move sessions back and forth between mobile/web/desktop and terminal.

```bash
# Continue a cloud session on your machine
claude --teleport
# or /teleport from inside a session

# Control a local session from phone/web
/remote-control
```

Boris has "Enable Remote Control for all sessions" set in his /config.

Source: https://x.com/bcherny/status/2038454339933548804

## 48. /loop and /schedule — Automated Workflows

Two of the most powerful features in Claude Code. Use these to schedule Claude to run automatically at a set interval, for up to a week at a time.

Boris's running loops:
- `/loop 5m /babysit` — auto-address code review, auto-rebase, and shepherd PRs to production
- `/loop 30m /slack-feedback` — automatically put up PRs for Slack feedback every 30 mins
- `/loop /post-merge-sweeper` — put up PRs to address code review comments I missed
- `/loop 1h /pr-pruner` — close out stale and no longer necessary PRs

**Pro tip:** Experiment with turning workflows into skills + loops. It's powerful.

Source: https://x.com/bcherny/status/2038454341884154269

## 49. Hooks — Deterministic Agent Lifecycle Logic

Use hooks to deterministically run logic as part of the agent lifecycle:
- Dynamically load in context each time you start Claude (SessionStart)
- Log every bash command the model runs (PreToolUse)
- Route permission prompts to WhatsApp for you to approve/deny (PermissionRequest)
- Poke Claude to keep going whenever it stops (Stop)

See https://code.claude.com/docs/en/hooks

Source: https://x.com/bcherny/status/2038454343519932844

## 50. Cowork Dispatch — Remote Control for Claude Desktop

Boris uses Dispatch every day to catch up on Slack and emails, manage files, and do things on his laptop when he's not at a computer. "When I'm not coding, I'm dispatching."

Dispatch is a secure remote control for the Claude Desktop app. It can use your MCPs, browser, and computer, with your permission.

Source: https://x.com/bcherny/status/2038454345419936040

## 51. Chrome Extension — Verify Frontend Work

The most important tip for using Claude Code: give Claude a way to verify its output. Once you do that, Claude will iterate until the result is great.

Think of it like any other engineer: if you ask someone to build a website but they aren't allowed to use a browser, will the result look good? Probably not. But if you give them a browser, they will write code and iterate until it looks good.

Boris uses the Chrome extension every time he works on web code. It tends to work more reliably than other similar MCPs. Download for Chrome/Edge at code.claude.com/docs/en/browser.

Source: https://x.com/bcherny/status/2038454347156398333

## 52. Desktop App — Auto Start and Test Web Servers

Use the Claude Desktop app to have Claude automatically start and test web servers. The Desktop app bundles in the ability for Claude to automatically run your web server and even test it in a built-in browser.

You can set up something similar in CLI or VSCode using the Chrome extension, or just use the Desktop app.

Source: https://x.com/bcherny/status/2038454348804714642

## 53. Fork Your Session

People often ask how to fork an existing session. Two ways:

```bash
# Option 1: From inside your session
/branch

# Option 2: From the CLI
claude --resume <session-id> --fork-session
```

Source: https://x.com/bcherny/status/2038454350214041740

## 54. /btw — Side Queries While Claude Works

Use /btw all the time to answer quick questions while the agent works. Single-turn, no tool calls, but has full context of the conversation. Claude responds inline without stopping its work.

```
> /btw how do i spell daushund?
  dachshund — German for "badger dog" (dachs = badger, hund = dog).
```

Source: https://x.com/bcherny/status/2038454351849787485

## 55. Git Worktrees — Deep Parallel Work

Claude Code ships with deep support for git worktrees. Worktrees are essential for doing lots of parallel work in the same repository. Boris has dozens of Claudes running at all times.

```bash
# Start a new session in a worktree
claude -w

# Or check the "worktree" checkbox in the Claude Desktop app
```

For non-git VCS users, use the WorktreeCreate hook to add your own logic for worktree creation.

Source: https://x.com/bcherny/status/2038454353787519164

## 56. /batch — Fan Out Massive Changesets

/batch interviews you, then has Claude fan out the work to as many worktree agents as it takes (dozens, hundreds, even thousands) to get it done. Use it for large code migrations and other kinds of parallelizable work.

Source: https://x.com/bcherny/status/2038454355469484142

## 57. --bare — 10x Faster SDK Startup

By default, when you run `claude -p` (or the TypeScript or Python SDKs) it searches for local CLAUDE.md's, settings, and MCPs. But for non-interactive usage, most of the time you want to explicitly specify what to load via --system-prompt, --mcp-config, --settings, etc.

```bash
claude -p "summarize this codebase" \
    --output-format=stream-json \
    --verbose \
    --bare
```

This was a design oversight when the SDK was first built. In a future version, the default will flip to --bare. For now, opt in with the flag.

Source: https://x.com/bcherny/status/2038454357088457168

## 58. --add-dir — Give Claude Access to More Folders

When working across multiple repositories, start Claude in one repo and use `--add-dir` (or `/add-dir`) to let Claude see the other repo. This not only tells Claude about the repo, but also gives it permissions to work in it.

```bash
# At launch
claude --add-dir /path/to/other-repo

# During a session
> /add-dir /path/to/other-repo
```

Or, add "additionalDirectories" to your team's settings.json to always load in additional folders when starting Claude Code.

Source: https://x.com/bcherny/status/2038454359047156203

## 59. --agent — Custom System Prompt & Tools

Custom agents are a powerful primitive that often gets overlooked. Define a new agent in .claude/agents, then run `claude --agent=<your agent's name>`.

```yaml
# .claude/agents/ReadOnly.md
---
name: ReadOnly
description: Read-only agent restricted to the Read tool only
color: blue
tools: Read
---

You are a read-only agent that cannot edit files or run bash.
```

See https://code.claude.com/docs/en/sub-agents

Source: https://x.com/bcherny/status/2038454360418787764

## 60. /voice — Voice Input

Boris does most of his coding by speaking to Claude, rather than typing. To do the same:
- CLI: run /voice then hold the space bar
- Desktop: press the voice button
- iOS: enable dictation in your iOS settings

Source: https://x.com/bcherny/status/2038454362226467112

---

## Quick Reference

| Tip | Key Action |
|-----|------------|
| Parallel work | Use git worktrees, 3-5 sessions |
| Model | Opus with thinking |
| Planning | Start in plan mode for complex tasks |
| CLAUDE.md | Update after every correction |
| Skills | /simplify, /batch, /btw, custom workflows |
| Subagents | Offload to keep context clean |
| Hooks | PostToolUse, SessionStart, PermissionRequest, Stop |
| Permissions | Pre-allow safe commands, wildcards |
| MCP | Integrate Slack, BigQuery, Sentry |
| Long-running | Use Stop hooks, background agents |
| Verification | Chrome extension, browser testing |
| Learning | Use Claude to explain and teach |
| Terminal | /config, /voice, /color, keybindings |
| Effort | /effort max for deeper thinking |
| Plugins & Agents | LSPs, MCPs, --agent, custom agents |
| Sandboxing | /sandbox for file & network isolation |
| Status line | /statusline for custom info display |
| Customize | Spinners, output styles, 37 settings, 84 env vars |
| Worktrees | claude -w, Desktop, subagent isolation, non-git VCS |
| Scheduled Tasks | /loop, /schedule, automated workflows |
| Code Review | Agent-powered PR reviews that catch real bugs |
| Remote Control | Teleport, mobile app, /remote-control |
| Session Management | --name, /branch, --fork-session, auto-naming |
| Setup Scripts | Automate cloud environment setup |
| PostCompact | Hook for context compression events |
| Auto Mode | Safer permission skipping with classifiers |
| iMessage | Text Claude from any Apple device |
| Auto-Memory & Dream | Persistent, self-cleaning memory system |
| Mobile App | Code from iOS/Android Claude app |
| Cowork Dispatch | Remote control for Claude Desktop |
| Desktop App | Auto start and test web servers |
| --bare | 10x faster SDK startup |
| --add-dir | Give Claude access to more folders |

---

*Source: [howborisusesclaudecode.com](https://howborisusesclaudecode.com) - Tips from Boris Cherny's January–March 2026 threads*
