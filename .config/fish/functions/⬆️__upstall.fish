# Updates and installs system and shell dependencies (utilities, libraries, plugins, apps).
# Sometimes these are custom forks or configuration to tweak any of these.
function ⬆️__upstall
    createdirs ~/.config/upstall

    set -l last_ran_file ~/.config/upstall/last_run.(machine_id)
    set -l last_ran (cat $last_ran_file)
    echo "⬆️  Upstall (Last ran: "$last_ran")"
    date_iso8601 >$last_ran_file

    repeatchar -

    🗄__gitconfig

    repeatchar -

    if contains -- "--no-brew" $argv; or contains -- "--nobr" $argv
        echo "🍺  Homebrew (skipped)"
    else
        🍺__brew
    end

    repeatchar -

    if contains -- "--no-fisherman" $argv; or contains -- "--nofm" $argv
        echo "🐟  Fisherman (skipped)"
    else
        🐟__fisherman
    end

    repeatchar -

    if contains -- "--no-textmate" $argv; or contains -- "--notm" $argv
        echo "📝  TextMate (skipped)"
    else
        📝__textmate
    end

    repeatchar -
end
