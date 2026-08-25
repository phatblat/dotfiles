# gdotenv - Grep variable names from .env files found recursively
export def gdotenv [search_term?: string] {
    let skip = [".env.example" ".env.sample" ".env.template"]
    let pruned = [
        "**/.git/**"
        "**/node_modules/**"
        "**/target/**"
        "**/vendor/**"
        "**/.venv/**"
        "**/dist/**"
        "**/build/**"
    ]

    let rows = (
        glob "**/.env*" --no-dir --exclude $pruned
        | where { |p|
            let base = ($p | path basename)
            (($base == ".env") or ($base | str starts-with ".env.")) and ($base not-in $skip)
        }
        | each { |f|
            let rel = ($f | path relative-to $env.PWD)
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
