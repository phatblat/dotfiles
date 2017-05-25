# Updates and installs system and shell dependencies (utilities, libraries, plugins, apps).
# Sometimes these are custom forks or configuration to tweak any of these.
function ⏫__upstall
    createdirs ~/.config/upstall

    set -l last_ran_file ~/.config/upstall/last_run.(machine_id)
    set -l last_ran (cat $last_ran_file)
    echo "⏫  Upstall (Last ran: "$last_ran")"
    date_iso8601 >$last_ran_file

    if test -z "$argv"
        # No args means run all
        set argv ruby xcode brew cask fisherman pip npm powerline vundle textmate macos
    else if contains -- --nothing $argv
        # Smoke test
        set argv --norb --noxc --nobr --noca --nofm --nopy --nojs ---nopl -novi --notm --noos
    end


    ⬆️__upmodule 🗄__gitconfig
    ⬆️__upmodule 💎__rubygems    "💎  Ruby Gems" ruby       --norb $argv
    ⬆️__upmodule 🔨__xcode       "🔨  Xcode"     xcode      --noxc $argv
    ⬆️__upmodule 🍺__brew        "🍺  Homebrew"  brew       --nobr $argv
    ⬆️__upmodule 🍻__cask        "🍻  Cask"      cask       --noca $argv
    ⬆️__upmodule 🐟__fisherman   "🐟  Fisherman" fisherman  --nofm $argv
    ⬆️__upmodule 🐍__pip         "🐍  PIP"       pip        --nopy $argv
    ⬆️__upmodule 🕸__npm         "🕸  NPM"       npm        --nojs $argv
    ⬆️__upmodule ▶️__powerline   "▶️  Powerline" powerline  --nopl $argv
    ⬆️__upmodule 🗒__vundle      "🗒  Vundle"    vundle     --novi $argv
    ⬆️__upmodule 📝__textmate    "📝  TextMate"  textmate   --notm $argv
    ⬆️__upmodule 🖥__macos       "🖥  macOS"     macos      --noos $argv
end
