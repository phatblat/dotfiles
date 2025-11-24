# Regenerate and load starship prompt
export def starship_on [...args: string] {
    mkdir ($nu.vendor-autoload-dirs | last)
    let starship_config_file =  $nu.vendor-autoload-dirs | last | path join "starship.nu"
    const starship_config_file = $nu.data-dir | path join "vendor/autoload/starship.nu"
    let starship_config = starship init nu

    # starship init nu | save --force ~/.cache/starship/init.nu
    $starship_config | save --force starship_config_file

    if ($starship_config_file | path exists) {
        eval $starship_config
    }
}
