# Ditto Projects

## Issue Tracking

This project uses **Linear** for all issue tracking.

- In `forge` the team is **FORGE**.
- In `cloud-services` the team is **PORT**.

Use the **`lncli`** CLI for all Linear operations (reading issues, updating status, creating issues, adding comments, etc.). Do NOT use Linear MCP tools — use `lncli` instead.

Run `lncli` or `lncli usage` to see all available commands and usage details.

Common commands:

```bash
# Read an issue
lncli issues read FORGE-xxx

# Create an issue
lncli issues create --team FORGE -d "Description in **markdown**" -p 3 "My issue title"

# Update an issue status
lncli issues update FORGE-123 -s "In Progress"
```
