# gdotenv - Grep variable names from .env files found recursively
export def gdotenv [search_term?: string] {
    # Directories that never contain user dotenv files, pruned everywhere.
    let prune_names = [
        ".git" "node_modules" "target" "vendor" ".venv" "dist" "build"
        ".gradle" ".cargo" ".rustup" ".konan" ".local" ".cache" ".puro"
        ".dartServer" ".google-cloud-sdk" ".npm" ".bun"
    ]
    # Heavyweight top-level dirs in $HOME with zero .env yield. Applied
    # only when scanning from the home directory itself.
    let home_prune_names = [
        "Library" "go" "Pictures" "Music" "Movies" "Downloads" "Documents"
        "OrbStack" "OneDrive" "Fastlane" "2ndBrain" "2ndBrain.obsidian"
        "obsidian.test" "Applications" "Public"
    ]
    let skips = [".env.example" ".env.sample" ".env.template"]

    if (which fd | is-empty) {
        error make {msg: "gdotenv: fd not found on PATH (install via 'mise use -g fd')"}
    }

    mut names = ($prune_names ++ $skips)
    if (($env.PWD | path expand) == ($env.HOME | path expand)) {
        $names = ($names ++ $home_prune_names)
    }
    let excludes = ($names | reduce --fold [] {|p, acc| $acc ++ ["-E" $p] })

    let rows = (
        ^fd --hidden --no-ignore --type f ...$excludes '^\.env(\..+)?$' . err> /dev/null
        | lines
        | each { |f|
            let rel = ($f | str replace --regex '^\./' '')
            open --raw $f
            | lines
            | parse --regex '^\s*(?:export\s+)?(?<key>[A-Za-z_][A-Za-z0-9_]*)\s*='
            | get key
            | each { |k| {file: $rel, key: $k} }
        }
        | flatten
    )

    if ($search_term | is-empty) {
        $rows
    } else {
        let needle = ($search_term | str lowercase)
        $rows | where { |r| ($r.key | str lowercase | str contains $needle) }
    }
}
