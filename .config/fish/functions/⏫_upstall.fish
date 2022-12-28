function ⏫_upstall \
    --description='Updates and installs system and shell dependencies such as utilities, libraries, plugins and apps. Sometimes these are custom forks or configuration to tweak any of these.'

    createdirs ~/.config/upstall

    set -l last_ran_file ~/.config/upstall/last_run.(machine_id)
    if test -f $last_ran_file
        set -l last_ran (cat $last_ran_file)
        echo "⏫ Upstall (Last ran: "$last_ran")"
    end
    date_iso8601 >$last_ran_file

    # Disabled by default: apm textmate vundle xcode
    set -l all_modules \
        ruby \
        brew \
        fisher \
        omf \
        mint \
        rustup \
        sdkman \
        pip \
        nvm \
        npm \
        powerline \
        vscode

    if is_mac
        set all_modules $all_modules \
            cask \
            macos
    else if is_linux
        set all_modules $all_modules \
            apt
    end

    # Log the default modules for the os
    # echo "all_modules: $all_modules"

    set --local modules_to_run

    # FIXME: --nothing doesn't work
    if contains -- --nothing $argv
        # Smoke test
        set modules_to_run \
            --noas \
            --noapt \
            --nobr \
            --noca \
            --nofm \
            --nog \
            --nojs \
            --nomt \
            --nonx \
            --noomf \
            --noos \
            --nopl \
            --nopy \
            --norb \
            --nors \
            --nosdk \
            --notm \
            --novi \
            --novs \
            --noxc
    else if test -z "$argv"
        # No args means run all
        set modules_to_run $all_modules
    else if test '--' = "(string sub --length 2 -- $argv[1])"
        # Skip flag passed (upstall --nofoo)
        set modules_to_run $argv $all_modules
    else
        # Run only the requested modules
        set modules_to_run $argv
    end

    echo "modules_to_run: $modules_to_run"

    ⬆️_upmodule 🗄_gitconfig "🗄 Git config" git        --nog    $modules_to_run
    ⬆️_upmodule 🦀_rustup    "🦀 Rustup"     rust       --nors   $modules_to_run
    ⬆️_upmodule 💎_rubygems  "💎 Ruby Gems"  ruby       --norb   $modules_to_run
    ⬆️_upmodule 🔨_xcode     "🔨 Xcode"      xcode      --noxc   $modules_to_run
    ⬆️_upmodule 📦_apt       "📦 APT"        apt        --noapt  $modules_to_run
    ⬆️_upmodule 🍺_brew      "🍺 Homebrew"   brew       --nobr   $modules_to_run
    ⬆️_upmodule 🍻_cask      "🍻 Cask"       cask       --noca   $modules_to_run
    ⬆️_upmodule 🐟_fisher    "🐟 Fisher"     fisher     --nofm   $modules_to_run
    ⬆️_upmodule 🌱_mint      "🌱 Mint"       mint       --nomt   $modules_to_run
    ⬆️_upmodule 🐠_omf       "🐠 oh-my-fish" omf        --noomf  $modules_to_run
    ⬆️_upmodule 🧰_sdkman    "🧰 SDKman"     sdk        --nosdk  $modules_to_run
    ⬆️_upmodule 🐍_pip       "🐍 PIP"        pip        --nopy   $modules_to_run
    ⬆️_upmodule 🕸_nvm       "🕸 NVM"        nvm        --nojs   $modules_to_run
    ⬆️_upmodule 🕸_npm       "🕸 NPM"        npm        --nojs   $modules_to_run
    ⬆️_upmodule ▶️_powerline  "▶️ Powerline"   powerline  --nopl   $modules_to_run
    ⬆️_upmodule 🗒_vundle    "🗒 Vundle"     vundle     --novi   $modules_to_run
    ⬆️_upmodule 📝_textmate  "📝 TextMate"   textmate   --notm   $modules_to_run
    ⬆️_upmodule ⚛️_apm        "⚛️ APM"         apm        --noap   $modules_to_run
    ⬆️_upmodule 🆚_vscode    "🆚 VS Code"    vscode     --novs   $modules_to_run
    ⬆️_upmodule 📺_mas       "📺 mas"        mas        --noas   $modules_to_run
    ⬆️_upmodule 🖥_macos     "🖥 macOS"      macos      --noos   $modules_to_run
    ⬆️_upmodule ❄️_nix        "❄️ nix"         nix        --nonx   $modules_to_run
end
