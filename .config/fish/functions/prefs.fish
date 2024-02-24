function prefs \
    --description 'Opens System Preferences, optionally to a specific pane. Specify "list" to see the available panes.' \
    --argument-names pref_pane

    set -l cmd open -b com.apple.systempreferences
    set -l path /System/Library/PreferencePanes/

    if test -z pref_pane
        eval $cmd
        return
    end

    switch $pref_pane
        case list
            # Lists available pref panes
            ls $path
            return
        case k kb keyboard
            set pref_pane Keyboard
        case s sec security
            set pref_pane Security
    end

    eval $cmd $path$pref_pane.prefPane
end
