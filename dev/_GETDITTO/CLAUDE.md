# Ditto Projects

## Issue Tracking

The projects stored in this directory use **Linear** for all issue tracking.

Use the **`linear`** CLI (`schpet/linear-cli`) for all Linear operations (reading issues, updating status, creating issues, adding comments, etc.). Also available as the `/linear-cli` skill.

Run `linear --help` or `linear issue --help` to see all available commands and usage details.

Common commands:

```bash
# View an issue
linear issue view DEVX-xxx

# List my issues
linear issue mine --state started

# Create an issue
linear issue create --team DEVX -d "Description in **markdown**" -p 3 "My issue title"

# Update an issue status
linear issue update DEVX-123 -s started
```
