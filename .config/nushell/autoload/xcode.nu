# xcode - Installs and updates Xcode
export def --env xcode [] {
    print "Xcode"
    print ""

    let existing_user = ($env.XCODE_INSTALL_USER? | default "")
    if ($existing_user | is-empty) {
        let email = (try { ^git config user.email | str trim } catch { "" })
        if ($email | is-not-empty) {
            $env.XCODE_INSTALL_USER = $email
        }
    }

    # Currently selected version
    ^xcode-select --print-path

    # Update the list of available versions to install
    ^xcversion update

    # Install the CLI tools, if necessary
    if not ("/Library/Developer/CommandLineTools/usr/lib/libxcrun.dylib" | path exists) {
        ^xcversion install-cli-tools
    }

    print "Available:"
    ^xcversion list
    let installed = (^xcversion list | lines)
    let newest_version = ($installed | last)
    if not ($newest_version | str contains "(installed)") {
        mut options = ["--no-show-release-notes"]

        # Don't activate beta versions automatically
        if ($newest_version | str contains "beta") {
            $options = ($options | append "--no-switch")
        }

        ^xcversion install $newest_version ...$options

        # Clean out old simulators
        ^xcrun simctl delete unavailable
    }

    print ""
    print "Installed:"
    ^xclist

    print ""
    print "Themes"
    let xcode_themes_dir = $"($env.HOME)/Library/Developer/Xcode/UserData/FontAndColorThemes"
    let xcode_dev_dir = $"($env.HOME)/dev/xcode"
    let repo_dir = $"($xcode_dev_dir)/xcode-themes"
    ^mkdir -p $xcode_themes_dir $xcode_dev_dir
    clone_or_pull $repo_dir "git@github.com:hdoria/xcode-themes.git"
    cd $repo_dir
    for theme in (ls | where name =~ '\.dvtcolortheme$' | get name) {
        if not ($"($xcode_themes_dir)/($theme)" | path exists) {
            # Only copy new themes
            ^cp -v $theme $xcode_themes_dir
        }
    }
}
