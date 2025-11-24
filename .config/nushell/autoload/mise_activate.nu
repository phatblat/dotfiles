def mise_activate [] {
    let mise_path = $nu.default-config-dir | path join mise.nu
    mise activate nu | lines | where { not (($in | str starts-with "hide") or ($in | str starts-with "set")) } | str join "\n" | save $mise_path --append
}
