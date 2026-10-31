# Deploys the dotfiles repo (primary checkout ~/dev/dotfiles) into $HOME with `mise dot`.
# Spec: .config/mise/conf.d/dotfiles.toml. Copyright: Ben Chatelain. MIT.

# Links and copies tracked dotfiles from the primary checkout into $HOME
[group('home')]
home-apply:
    python3 {{ justfile_directory() }}/scripts/home_spec.py links
    mise --cd "$HOME" dot apply --yes

# Regenerates the deploy spec from the tracked files (run by `just generate`)
[group('home')]
home-spec:
    python3 {{ justfile_directory() }}/scripts/home_spec.py generate

# Fails when the committed deploy spec is stale relative to the tracked files (run by `just check`)
[group('home')]
home-spec-check:
    python3 {{ justfile_directory() }}/scripts/home_spec.py check

# Shows which $HOME targets differ from the primary checkout
[group('home')]
home-status:
    mise --cd "$HOME" dot status

# Pins $HOME to <ref> by detaching the primary checkout there; the post-checkout hook re-applies
[group('home')]
[script]
home-deploy ref:
    primary="$(dirname "$(git -C {{ justfile_directory() }} rev-parse --path-format=absolute --git-common-dir)")"
    if ! git -C "$primary" cat-file -e "{{ ref }}:.config/mise/conf.d/dotfiles.toml"; then
        echo "home-deploy: {{ ref }} has no .config/mise/conf.d/dotfiles.toml; deploying it would orphan every link" >&2
        exit 1
    fi
    if ! git -C "$primary" cat-file -e "{{ ref }}:scripts/home-apply-hook"; then
        echo "home-deploy: {{ ref }} has no scripts/home-apply-hook; the post-checkout apply would stop running" >&2
        exit 1
    fi
    if ! git -C "$primary" diff --quiet || ! git -C "$primary" diff --cached --quiet; then
        echo "home-deploy: commit or stash the changes in $primary first" >&2
        exit 1
    fi
    live_file="$(git -C "$primary" rev-parse --path-format=absolute --git-path dotfiles-live-branch)"
    branch="$(git -C "$primary" branch --show-current)"
    if [ -n "$branch" ]; then
        printf '%s\n' "$branch" > "$live_file"
    fi
    git -C "$primary" switch --detach "{{ ref }}"

# Returns $HOME to live by switching the primary checkout back to the branch home-deploy left
[group('home')]
[script]
home-live:
    primary="$(dirname "$(git -C {{ justfile_directory() }} rev-parse --path-format=absolute --git-common-dir)")"
    live_file="$(git -C "$primary" rev-parse --path-format=absolute --git-path dotfiles-live-branch)"
    if [ ! -f "$live_file" ]; then
        echo "home-live: no home-deploy in effect ($live_file is missing)" >&2
        exit 1
    fi
    git -C "$primary" switch "$(cat "$live_file")"
    rm "$live_file"

# Copies app-rewritten files from $HOME into the primary checkout and restores replaced links
[group('home')]
home-capture *ARGS:
    python3 {{ justfile_directory() }}/scripts/home-capture.py {{ ARGS }}

# Links the $HOME-only paths in .config/wt/overlay/dev-dotfiles into the primary checkout
[group('home')]
[script]
home-overlay-links:
    primary="$(dirname "$(git -C {{ justfile_directory() }} rev-parse --path-format=absolute --git-common-dir)")"
    while IFS= read -r line || [ -n "$line" ]; do
        entry="${line%%#*}"
        entry="$(printf '%s' "$entry" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        [ -n "$entry" ] || continue
        if [ ! -e "$HOME/$entry" ]; then
            echo "skip: $HOME/$entry missing"
            continue
        fi
        mkdir -p "$(dirname "$primary/$entry")"
        ln -sfn "$HOME/$entry" "$primary/$entry"
    done < "$primary/.config/wt/overlay/dev-dotfiles"
