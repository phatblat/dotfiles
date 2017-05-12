# Updates and installs system and shell dependencies (utilities, libraries, plugins, apps).
# Sometimes these are custom forks or configuration to tweak any of these.
function 🔻_upstall
    createdirs ~/.config/upstall

    set -l last_ran_file ~/.config/upstall/last_run.(machine_id)
    set -l last_ran (cat $last_ran_file)
    echo "🔻  Upstall (Last ran: "$last_ran")"
    date_iso8601 >$last_ran_file

    repeatchar -

    # Only prompt for user info when not already set
    if test -z (git config user.email)
        _gitconfig
    else
        echo "Git configuration"
        cat ~/.config/git/config
    end

    if not contains -- "--no-fisherman" $argv; and not contains -- "--nofm" $argv
        repeatchar -
        echo ♻️_fisherman
        # ♻️_fisherman
    end

    if not contains -- "--no-textmate" $argv; and not contains -- "--notm" $argv
        repeatchar -
        echo ♻️_tmbundles
        # ♻️_tmbundles
    end

    repeatchar -
end
