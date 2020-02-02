# Updates and installs system and shell dependencies (utilities, libraries, plugins, apps).
# Sometimes these are custom forks or configuration to tweak any of these.
function ⏫__upstall
    createdirs ~/.config/upstall

    set -l last_ran_file ~/.config/upstall/last_run.(machine_id)
    if test -f $last_ran_file
        set -l last_ran (cat $last_ran_file)
        echo "⏫  Upstall (Last ran: "$last_ran")"
    end
    date_iso8601 >$last_ran_file

    # Disabled by default: apm fisherman textmate vundle xcode
    set -l all_modules \
        ruby \
        brew \
        omf \
        sdkman \
        pip \
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

    echo "all_modules: $all_modules"

    if contains -- --nothing $argv
        # Smoke test
        set argv --norb --noxc --nobr --noca --noomf --nofm --nosdk --nopy --nojs ---nopl -novi --notm --novs --noos
    else if test -z "$argv"
        # No args means run all
        set argv $all_modules
    else if test '--' = (string sub --length 2 -- $argv[1])
        # Skip flag passed
        set argv $argv $all_modules
    end

    ⬆️__upmodule 🗄__gitconfig
    ⬆️__upmodule 💎__rubygems    "💎  Ruby Gems"  ruby       --norb $argv
    ⬆️__upmodule 🔨__xcode       "🔨  Xcode"      xcode      --noxc $argv
    ⬆️__upmodule 📦__apt         "📦  APT"        apt        --noapt $argv
    ⬆️__upmodule 🍺__brew        "🍺  Homebrew"   brew       --nobr $argv
    ⬆️__upmodule 🍻__cask        "🍻  Cask"       cask       --noca $argv
    ⬆️__upmodule 🐠__omf         "🐠  oh-my-fish" omf        --noomf $argv
    ⬆️__upmodule 🐟__fisherman   "🐟  Fisherman"  fisherman  --nofm $argv
    ⬆️__upmodule 🧰__sdkman      "🧰  SDKman"     sdk        --nosdk $argv
    ⬆️__upmodule 🐍__pip         "🐍  PIP"        pip        --nopy $argv
    ⬆️__upmodule 🕸__npm         "🕸  NPM"        npm        --nojs $argv
    ⬆️__upmodule ▶️__powerline    "▶️  Powerline"   powerline  --nopl $argv
    ⬆️__upmodule 🗒__vundle      "🗒  Vundle"     vundle     --novi $argv
    ⬆️__upmodule 📝__textmate    "📝  TextMate"   textmate   --notm $argv
    ⬆️__upmodule ⚛️__apm          "⚛️  APM"         apm        --noap $argv
    ⬆️__upmodule 🆚__vscode      "🆚  VS Code"    vscode     --novs $argv
    ⬆️__upmodule 🖥__macos       "🖥  macOS"      macos      --noos $argv
end
