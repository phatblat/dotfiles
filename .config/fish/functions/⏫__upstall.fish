# Updates and installs system and shell dependencies (utilities, libraries, plugins, apps).
# Sometimes these are custom forks or configuration to tweak any of these.
function ⏫__upstall
    createdirs ~/.config/upstall

    set -l last_ran_file ~/.config/upstall/last_run.(machine_id)
    set -l last_ran (cat $last_ran_file)
    echo "⏫  Upstall (Last ran: "$last_ran")"
    date_iso8601 >$last_ran_file

    if contains -- --nothing $argv
        set argv $argv --no-ruby --no-xcode --no-brew --no-cask --no-fisherman --no-textmate
    end

    ⬆️__upmodule 🗄__gitconfig
    ⬆️__upmodule 💎__rubygems    "💎  Ruby Gems" --no-ruby       --norb $argv
    ⬆️__upmodule 📱__xcode       "📱  Xcode"     --no-xcode      --noxc $argv
    ⬆️__upmodule 🍺__brew        "🍺  Homebrew"  --no-brew       --nobr $argv
    ⬆️__upmodule 🍻__cask        "🍻  Cask"      --no-cask       --noca $argv
    ⬆️__upmodule 🐟__fisherman   "🐟  Fisherman" --no-fisherman  --nofm $argv
    ⬆️__upmodule 📝__textmate    "📝  TextMate"  --no-textmate   --notm $argv
end
