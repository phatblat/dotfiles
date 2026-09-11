# omp — oh-my-pi status, plugins, and model catalogs

# Lists running sessions for the requested agent
[group('omp')]
[script]
status agent:
    #!/usr/bin/env bash
    set -euo pipefail
    invocation_dir="{{ invocation_directory() }}"

    if [[ "{{ agent }}" != "omp" ]]; then
        echo "error: status currently supports only 'omp'" >&2
        exit 1
    fi

    found=0
    while read -r pid state etime command; do
        found=1
        version=$(sed -nE 's#.*oh-my-pi/([^/]+)/omp.*#\1#p' <<< "$command")
        args=$(sed -E 's#^.*oh-my-pi/[^ ]+/omp ?##' <<< "$command")
        cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
        marker=
        [[ "$cwd" == "$invocation_dir" ]] && marker=", current"
        if [[ -n "$args" ]]; then
            printf '%s — OMP %s, %s, %s%s\n' \
                "$pid" "$version" "$args" "$cwd" "$marker"
        else
            printf '%s — OMP %s, %s%s\n' \
                "$pid" "$version" "$cwd" "$marker"
        fi
    done < <(
        ps -axo pid=,state=,etime=,command= |
            awk '$0 ~ /oh-my-pi\/[^ ]+\/omp( |$)/ && $0 !~ /__omp_worker_/'
    )

    if (( ! found )); then
        echo "No running OMP sessions."
    fi

# Lists omp plugins whose installed version is behind the npm registry
[group('omp')]
omp-plugins-outdated:
    #!/usr/bin/env bash
    set -euo pipefail
    found=0
    while IFS=$'\t' read -r pkg installed; do
        latest=$(npm view "$pkg" version 2>/dev/null) || continue
        if [ "$installed" != "$latest" ]; then
            echo "$pkg $installed → $latest"
            found=1
        fi
    done < <(omp plugin list --json | jq -r '.npm[] | [.name, .version] | @tsv')
    if [ "$found" -eq 0 ]; then
        echo "All omp plugins are up to date"
    fi

# Installs bun dependency trees for tracked package.json manifests
[group('omp')]
[script]
install-bun-deps:
    set -euo pipefail
    for dir in {{ bun_manifest_dirs }}; do
        target="{{ justfile_directory() }}/$dir"
        if [[ ! -f "$target/package.json" ]]; then continue; fi
        echo "Installing bun dependencies in $dir..."
        (cd "$target" && bun install)
    done
    if command -v omp >/dev/null 2>&1; then omp plugin doctor --fix; fi

# Sync Casper model metadata and pricing from live APIs
[group('omp')]
[script]
update-casper-models:
    set -euo pipefail
    {{ justfile_directory() }}/scripts/sync-casper-models.sh
    if [ -z "$(git status --porcelain -- .omp/profiles/casper/agent/models.yml)" ]; then
        echo "Casper model catalog unchanged"
        exit 0
    fi
    git add .omp/profiles/casper/agent/models.yml
    git commit -m "chore(casper): sync models.yml with live catalog and pricing"

# Upgrades the installed omp version from the upstream GitHub repository
[group('omp')]
upgrade-omp:
    mise upgrade --bump oh-my-pi
    hk fix .config/mise/config.toml
    bash -ic 'cmt .config/mise/config.toml'

# Opens the omp plugin manifest in the configured editor
[group('omp')]
omp-plugins-edit:
    ${VISUAL:-${EDITOR:-vi}} {{ justfile_directory() }}/.omp/plugins/package.json

# Reinstalls omp plugins from the manifest, discarding node_modules
[group('omp')]
omp-plugins-reinstall:
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{ justfile_directory() }}/.omp/plugins
    rm -rf node_modules
    bun install
    omp plugin doctor --fix

# Updates omp plugins in bun.lock to their latest allowed version and syncs the plugin manifest
[group('omp')]
omp-plugins-update:
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{ justfile_directory() }}/.omp/plugins
    bun update
    omp plugin doctor --fix
