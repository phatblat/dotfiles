---
name: ramp-get-started
area: Getting Started
supported_surfaces: [cli, mcp]
description: |-
  Hand your agent this playbook. It gets you set up on Ramp — or applying, if
  you're new — plus the menu of everything else you can do. Use as the one-fetch
  entry point for Ramp across Claude Desktop, ChatGPT, Claude Code, Codex, and
  Perplexity.
title: "Get started with Ramp"
url: https://agents.ramp.com/playbooks/get-started
runtimes: [Claude Desktop, ChatGPT, Claude Code, Codex, Perplexity]
---

# Get started with Ramp

Hand your agent this playbook and it'll figure out whether you're a new or existing Ramp customer, walk you through the right onboarding path, and then hand you the menu of every other playbook you can run. This is the one-fetch entry point — the rest of the playbook directory becomes discoverable once setup is done.

## Keep Ramp skills current

If you installed Ramp skills through the Ramp CLI, refresh the catalog and installed copies with:

```bash
ramp skills update
ramp skills install --all
```

## How to run

Identify which runtime you're operating in (Claude Desktop, ChatGPT, Claude Code, Codex, Perplexity). Use the matching section below; ignore the others.

## Claude Desktop

Copy and run this prompt:

```
## Before you run
- None — this playbook gets you set up.

I want to use Ramp with you. First, ask me:

> Do you already have a Ramp account?

If **yes** (existing customer):
1. Walk me through enabling the Ramp connector: the Claude Desktop connector lives at https://claude.ai/directory/61bac03c-3f98-4b3c-affb-1b99533fa82c — open it and follow the prompts to add Ramp.
2. Confirm I can see Ramp tools in this conversation.
3. Ask whether I want Ramp Agent Cards enabled for my business — if yes, point me to https://docs.ramp.com/developer-api/v1/agent-cards for setup instructions.

If **no** (new customer):
1. Tell me Ramp is a finance platform — corporate cards, bill pay, and expense management — and that I'll need to apply for an account.
2. Point me to https://ramp.com/ to apply. Mention the application takes a few minutes and approval is usually same-day.
3. Once I'm approved and logged in, come back here and we'll wire up the connector.

## What you can do next

Once I'm set up, fetch the playbook directory at https://agents.ramp.com/.well-known/agent-skills/index.json for the full menu of things you can do for me.
```

## ChatGPT

Copy and run this prompt:

```
## Before you run
- None — this playbook gets you set up.

I want to use Ramp with you. First, ask me:

> Do you already have a Ramp account?

If **yes** (existing customer):
1. Walk me through enabling the Ramp connector: the Ramp app for ChatGPT lives at https://chatgpt.com/apps/ramp/asdk_app_69250fb6281c819195b52a1556b0060c — open it and follow the prompts to authorize Ramp.
2. Confirm I can see Ramp tools in this conversation.
3. Ask whether I want Ramp Agent Cards enabled for my business — if yes, point me to https://docs.ramp.com/developer-api/v1/agent-cards for setup instructions.

If **no** (new customer):
1. Tell me Ramp is a finance platform — corporate cards, bill pay, and expense management — and that I'll need to apply for an account.
2. Point me to https://ramp.com/ to apply. Mention the application takes a few minutes and approval is usually same-day.
3. Once I'm approved and logged in, come back here and we'll wire up the connector.

## What you can do next

Once I'm set up, fetch the playbook directory at https://agents.ramp.com/.well-known/agent-skills/index.json for the full menu of things you can do for me.
```

## Claude Code

Copy and run this prompt:

```
## Before you run
- None — this playbook gets you set up.

I want to use Ramp with you from the terminal. First, ask me:

> Do you already have a Ramp account?

If **yes** (existing customer):
1. Install the Ramp CLI if it's not already installed — run `ramp --version` first, and only if that fails, install it safely: download the installer to a private temp file (`install_sh=$(mktemp)` then `curl -fsSL -o "$install_sh" https://agents.ramp.com/install.sh`), review the script, then run it pinned to a specific release tag from https://github.com/ramp-public/ramp-cli/releases (`RAMP_VERSION=<tag> bash "$install_sh"`) — the installer downloads that versioned tarball and verifies its published SHA-256 checksum before installing anything. Never pipe the installer URL straight into `bash`, and never download it to a fixed, predictable path.
2. Log me in: `ramp auth login` (this opens a browser; I complete sign-in there).
3. Confirm `ramp --version` returns a version and `ramp auth status` shows me authenticated.
4. Ask whether I want Ramp Agent Cards enabled for my business — if yes, point me to https://docs.ramp.com/developer-api/v1/agent-cards for setup instructions.

If **no** (new customer):
1. Tell me Ramp is a finance platform — corporate cards, bill pay, and expense management — and that I'll need to apply for an account.
2. Install the Ramp CLI if it's not already installed — run `ramp --version` first, and only if that fails, install it safely: download the installer to a private temp file (`install_sh=$(mktemp)` then `curl -fsSL -o "$install_sh" https://agents.ramp.com/install.sh`), review the script, then run it pinned to a specific release tag from https://github.com/ramp-public/ramp-cli/releases (`RAMP_VERSION=<tag> bash "$install_sh"`) — the installer downloads that versioned tarball and verifies its published SHA-256 checksum before installing anything. Never pipe the installer URL straight into `bash`, and never download it to a fixed, predictable path.
3. Apply to Ramp: fetch https://agents.ramp.com/.well-known/agent-skills/ramp-apply-for-account/SKILL.md and follow it. It runs my whole application:
   - It first asks whether my business already has a formed legal entity with an EIN, so it can take the right path — I don't need to decide that up front.
   - If I already have a company, it pre-fills what it can, lets me drop in a document (like an EIN letter) to fill the rest, and paces the application to completion — handing me Ramp links for the steps only I can do (phone verification, SSN, legal agreements, final submit). It never submits for me.
   - If I don't have a legal entity yet, it starts the application with incorporation enabled and, after I submit the application, files my US LLC through Ramp in the same application — there is no second application. (It handles the formation step for me via the ramp-incorporate skill; I don't fetch anything myself.) Incorporating through Ramp has a cost — pricing and details are the source of truth at https://agents.ramp.com/docs/account/incorporate; tell me it isn't free and offer to fetch that page for me if I want the specifics before deciding.
4. Applying is what signs me in: accepting the invite email during signup authorizes the Ramp CLI, so there's no separate login step. If that browser handoff gets interrupted, ramp-apply-for-account tells me how to finish it.

## What you can do next

Once I'm set up, fetch the playbook directory at https://agents.ramp.com/.well-known/agent-skills/index.json for the full menu of things you can do for me.
```

## Codex

Copy and run this prompt:

```
## Before you run
- None — this playbook gets you set up.

I want to use Ramp with you from the terminal. First, ask me:

> Do you already have a Ramp account?

If **yes** (existing customer):
1. Install the Ramp CLI if it's not already installed — run `ramp --version` first, and only if that fails, install it safely: download the installer to a private temp file (`install_sh=$(mktemp)` then `curl -fsSL -o "$install_sh" https://agents.ramp.com/install.sh`), review the script, then run it pinned to a specific release tag from https://github.com/ramp-public/ramp-cli/releases (`RAMP_VERSION=<tag> bash "$install_sh"`) — the installer downloads that versioned tarball and verifies its published SHA-256 checksum before installing anything. Never pipe the installer URL straight into `bash`, and never download it to a fixed, predictable path.
2. Log me in: `ramp auth login` (this opens a browser; I complete sign-in there).
3. Confirm `ramp --version` returns a version and `ramp auth status` shows me authenticated.
4. Ask whether I want Ramp Agent Cards enabled for my business — if yes, point me to https://docs.ramp.com/developer-api/v1/agent-cards for setup instructions.

If **no** (new customer):
1. Tell me Ramp is a finance platform — corporate cards, bill pay, and expense management — and that I'll need to apply for an account.
2. Install the Ramp CLI if it's not already installed — run `ramp --version` first, and only if that fails, install it safely: download the installer to a private temp file (`install_sh=$(mktemp)` then `curl -fsSL -o "$install_sh" https://agents.ramp.com/install.sh`), review the script, then run it pinned to a specific release tag from https://github.com/ramp-public/ramp-cli/releases (`RAMP_VERSION=<tag> bash "$install_sh"`) — the installer downloads that versioned tarball and verifies its published SHA-256 checksum before installing anything. Never pipe the installer URL straight into `bash`, and never download it to a fixed, predictable path.
3. Apply to Ramp: fetch https://agents.ramp.com/.well-known/agent-skills/ramp-apply-for-account/SKILL.md and follow it. It runs my whole application:
   - It first asks whether my business already has a formed legal entity with an EIN, so it can take the right path — I don't need to decide that up front.
   - If I already have a company, it pre-fills what it can, lets me drop in a document (like an EIN letter) to fill the rest, and paces the application to completion — handing me Ramp links for the steps only I can do (phone verification, SSN, legal agreements, final submit). It never submits for me.
   - If I don't have a legal entity yet, it starts the application with incorporation enabled and, after I submit the application, files my US LLC through Ramp in the same application — there is no second application. (It handles the formation step for me via the ramp-incorporate skill; I don't fetch anything myself.) Incorporating through Ramp has a cost — pricing and details are the source of truth at https://agents.ramp.com/docs/account/incorporate; tell me it isn't free and offer to fetch that page for me if I want the specifics before deciding.
4. Applying is what signs me in: accepting the invite email during signup authorizes the Ramp CLI, so there's no separate login step. If that browser handoff gets interrupted, ramp-apply-for-account tells me how to finish it.

## What you can do next

Once I'm set up, fetch the playbook directory at https://agents.ramp.com/.well-known/agent-skills/index.json for the full menu of things you can do for me.
```

## Perplexity

Copy and run this prompt:

```
## Before you run
- None — this playbook gets you set up.

I want to use Ramp with you. First, ask me:

> Do you already have a Ramp account?

If **yes** (existing customer):
1. Walk me through enabling the Ramp connector: the Perplexity connector lives at https://www.perplexity.ai/computer/connectors?connector=ramp — open it and follow the prompts to authorize Ramp.
2. Confirm I can see Ramp tools in this conversation.
3. Ask whether I want Ramp Agent Cards enabled for my business — if yes, point me to https://docs.ramp.com/developer-api/v1/agent-cards for setup instructions.

If **no** (new customer):
1. Tell me Ramp is a finance platform — corporate cards, bill pay, and expense management — and that I'll need to apply for an account.
2. Point me to https://ramp.com/ to apply. Mention the application takes a few minutes and approval is usually same-day.
3. Once I'm approved and logged in, come back here and we'll wire up the connector.

## What you can do next

Once I'm set up, fetch the playbook directory at https://agents.ramp.com/.well-known/agent-skills/index.json for the full menu of things you can do for me.
```
