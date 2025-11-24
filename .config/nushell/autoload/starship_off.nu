# Remove starship prompt
export def starship_off [...args: string] {
    let starship_config_file = $nu.vendor-autoload-dirs | last | path join "starship.nu"
    rm --force starship_config_file
}
