# Dependencies:
#   functions: is_mac is_linux
#   builtins:  path join path exists is-empty mkdir str trim str starts-with str join fill open save append first
#   externals: date fish hostname

# Private: check if a flag is present in a list of args
def flag_in [flag: string, args: list<string>]: nothing -> bool {
    $flag in $args
}

# Private: run an upstall module if its include_flag is in modules_to_run and skip_flag is not
def upmodule [
    module_fn: string,      # Fish function name (emoji OK for fish)
    display_name: string,   # Human-readable label
    include_flag: string,   # Token that triggers this module
    skip_flag: string,      # Token that suppresses this module
    modules_to_run: list<string>
] {
    if (flag_in $skip_flag $modules_to_run) {
        print $"($display_name) (skipped)"
    } else if (flag_in $include_flag $modules_to_run) {
        print ("" | fill --width 80 --character "-")
        # Delegate to the fish implementation for now — nu ports are in separate batches
        ^fish -c $module_fn
    }
    # else: not selected, run silently
}

# Updates and installs system and shell dependencies such as utilities, libraries, plugins and apps
export def upstall [...args: string] {
    let upstall_dir = ($env.HOME | path join ".config" "upstall")
    if not ($upstall_dir | path exists) {
        mkdir $upstall_dir
    }

    let machine = (^hostname | str trim)
    let last_ran_file = ($upstall_dir | path join $"last_run.($machine)")
    if ($last_ran_file | path exists) {
        let last_ran = (open $last_ran_file | str trim)
        print $"upstall \(Last ran: ($last_ran)\)"
    }
    ^date +%Y-%m-%dT%H:%M:%S%z | save --force $last_ran_file

    # Base module list (order matters)
    mut all_modules = ["ruby", "brew", "omf", "mint", "rustup", "pip", "npm", "powerline", "vscode"]

    if (is_mac) {
        $all_modules = ($all_modules | append ["cask", "macos"])
    } else if (is_linux) {
        $all_modules = ($all_modules | append ["apt"])
    }

    let modules_to_run: list<string> = if (flag_in "--nothing" $args) {
        # Smoke test — all skip flags, nothing runs
        ["--noas", "--noapt", "--nobr", "--noca", "--nofm", "--nog", "--nojs",
         "--nomt", "--nonx", "--noomf", "--noos", "--nopl", "--nopy", "--norb",
         "--nors", "--notm", "--novi", "--novs", "--noxc"]
    } else if ($args | is-empty) {
        # No args: run all default modules
        $all_modules
    } else if (($args | first) | str starts-with "--") {
        # Skip flags passed: merge with all_modules
        ($args | append $all_modules)
    } else {
        # Explicit module list
        $args
    }

    print $"modules_to_run: ($modules_to_run | str join ' ')"

    upmodule "🗄_gitconfig"  "🗄 Git config"   "git"       "--nog"   $modules_to_run
    upmodule "🦀_rustup"     "🦀 Rustup"       "rust"      "--nors"  $modules_to_run
    upmodule "💎_rubygems"   "💎 Ruby Gems"    "ruby"      "--norb"  $modules_to_run
    upmodule "🔨_xcode"      "🔨 Xcode"        "xcode"     "--noxc"  $modules_to_run
    upmodule "📦_apt"        "📦 APT"          "apt"       "--noapt" $modules_to_run
    upmodule "🍺_brew"       "🍺 Homebrew"     "brew"      "--nobr"  $modules_to_run
    upmodule "🍻_cask"       "🍻 Cask"         "cask"      "--noca"  $modules_to_run
    upmodule "🌱_mint"       "🌱 Mint"         "mint"      "--nomt"  $modules_to_run
    upmodule "🐠_omf"        "🐠 oh-my-fish"   "omf"       "--noomf" $modules_to_run
    upmodule "🐍_pip"        "🐍 PIP"          "pip"       "--nopy"  $modules_to_run
    upmodule "🕸_npm"        "🕸 NPM"          "npm"       "--nojs"  $modules_to_run
    upmodule "▶️_powerline"  "▶️ Powerline"     "powerline" "--nopl"  $modules_to_run
    upmodule "🗒_vundle"     "🗒 Vundle"       "vundle"    "--novi"  $modules_to_run
    upmodule "📝_textmate"   "📝 TextMate"     "textmate"  "--notm"  $modules_to_run
    upmodule "⚛️_apm"        "⚛️ APM"           "apm"       "--noap"  $modules_to_run
    upmodule "🆚_vscode"     "🆚 VS Code"      "vscode"    "--novs"  $modules_to_run
    upmodule "📺_mas"        "📺 mas"          "mas"       "--noas"  $modules_to_run
    upmodule "🖥_macos"      "🖥 macOS"        "macos"     "--noos"  $modules_to_run
    upmodule "❄️_nix"        "❄️ nix"           "nix"       "--nonx"  $modules_to_run
}
