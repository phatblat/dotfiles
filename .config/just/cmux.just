# cmux — keep Settings-window preferences tracked in ~/.config/cmux/cmux.json

# Validates cmux.json and reports Settings preferences missing from or differing in it (auth, machine, and runtime state excluded)
[group('cmux')]
[script]
check-cmux-settings *ARGS:
    set -euo pipefail
    # Run both checks so one failure does not hide the other.
    status=0
    cmux config check || status=1
    python3 {{ justfile_directory() }}/scripts/cmux-settings.py check {{ ARGS }} || status=1
    exit "$status"

# Writes cmux Settings preferences that drift from cmux.json into cmux.json
[group('cmux')]
fix-cmux-settings:
    python3 {{ justfile_directory() }}/scripts/cmux-settings.py fix
