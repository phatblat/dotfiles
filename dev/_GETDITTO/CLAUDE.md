# Ditto Projects

## Issue Tracking

The projects stored in this directory use **Linear** for all issue tracking.

Use the **`lncli`** CLI for all Linear operations (reading issues, updating status, creating issues, adding comments, etc.). Do NOT use Linear MCP tools — use `lncli` instead.

Run `lncli` or `lncli usage` to see all available commands and usage details.

Common commands:

```bash
# Read an issue
lncli issues read DEVX-xxx

# Create an issue
lncli issues create --team DEVX -d "Description in **markdown**" -p 3 "My issue title"

# Update an issue status
lncli issues update DEVX-123 -s "In Progress"
```
