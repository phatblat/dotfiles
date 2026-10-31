set quiet

# Module recipes start in this file's directory; run from the repo root, where
# scripts/backlog.py reads docs/backlog/ (justfile_directory() is not allowed here)
set working-directory := '../..'

# Lists open backlog items grouped by priority (Urgent first); a priority argument prints only that group
[default]
list priority="":
    python3 {{ justfile_directory() }}/scripts/backlog.py list {{ quote(priority) }}

# Creates docs/backlog/<kebab-slug>.md from a title, with empty Problem and Outcome sections
new title priority="Unprioritized":
    python3 {{ justfile_directory() }}/scripts/backlog.py new -- {{ quote(title) }} {{ quote(priority) }}
