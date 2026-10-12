# gitconfig_setup - Sets git user.name and user.email in XDG_CONFIG_HOME
export def gitconfig_setup [email?: string, name?: string] {
    print "🗄 Git configuration"
    print ""

    let config_dir = ($nu.home-dir | path join ".config" "git")
    mkdir $config_dir
    let global_config = ($config_dir | path join "config")
    if not ($global_config | path exists) {
        touch $global_config
    }

    let have_both = (
        (try { ^git config --file $global_config user.name o> /dev/null; true } catch { false })
        and
        (try { ^git config --file $global_config user.email o> /dev/null; true } catch { false })
    )

    if $have_both {
        open --raw $global_config | print --no-newline
        return
    }

    let final_name = (if ($name | is-empty) { input "Git user.name: " } else { $name })
    let final_email = (if ($email | is-empty) { input "Git user.email: " } else { $email })

    ^git config --file $global_config user.name $final_name
    ^git config --file $global_config user.email $final_email

    print $global_config
    open --raw $global_config | print --no-newline
}
