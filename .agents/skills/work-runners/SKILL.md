---
name: "work-runners"
description: "Check macOS GHA runner status for the getditto org"
---

# work-runners

Use this skill when the user asks to run the migrated command `work-runners` or invokes `$work-runners`.

## Command Template

# Check macOS GHA Runners

Query the getditto org's macOS runner group and report status.

## Step 1: Fetch Runner Data

Runner group ID 8 is the "macOS" group in the getditto org.

```bash
gh api orgs/getditto/actions/runner-groups/8/runners --jq '{
  total: .total_count,
  online: [.runners[] | select(.status == "online")] | length,
  offline: [.runners[] | select(.status == "offline")] | length,
  offline_names: [.runners[] | select(.status == "offline") | .name],
  busy: [.runners[] | select(.busy == true)] | length,
  busy_names: [.runners[] | select(.busy == true) | .name]
}'
```

## Step 2: Report

Format as a concise summary:

```
## macOS GHA Runners (getditto)

Online: 34/34
Offline: 0
Busy: 5 — mac-ami01, mac-ami02, mac-ami03, mac-ami04, mac-ami05
```

If any runners are offline, list them with a warning:

```
⚠ Offline: 2 — mac-ami14, mac-ami22
```

If all runners are online and none are offline, report clean:

```
✓ All 34 runners online
```

## Step 3: Check for Busy Runners (Optional Detail)

If called with `--detail` or `--verbose` argument, also show per-runner status:

```bash
gh api orgs/getditto/actions/runner-groups/8/runners --jq '.runners | sort_by(.name) | .[] | "\(.status)\t\(.busy)\t\(.name)\t\(.labels | map(.name) | join(", "))"'
```

Format as a table.
