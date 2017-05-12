# Updates and installs system and shell dependencies (utilities, libraries, plugins, apps).
# Sometimes these are custom forks or configuration to tweak any of these.
function 🔻_upstall
    createdirs ~/.config/upstall

    set -l last_ran_file ~/.config/upstall/last_run.(machine_id)
    set -l last_ran (cat $last_ran_file)
    echo "🔻  Upstall (Last ran: "$last_ran")"
    date >$last_ran_file

    repeatchar -

    # Only prompt for user info when not already set
    if test -z (git config user.email)
        _gitconfig
    else
        echo "Git configuration"
        cat ~/.config/git/config
    end

    repeatchar -
    ♻️_fisherman
    repeatchar -
    ♻️_tmbundles
    repeatchar -
end
