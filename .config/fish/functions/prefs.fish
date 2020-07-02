function prefs \
    --description='prefs' \
    --argument-names pref_pane

    set -l cmd open -b com.apple.systempreferences

    if test -z pref_pane
        eval $cmd
        return
    end

    switch $pref_pane
        case s sec security
            set pref_pane Security
    end

    eval $cmd /System/Library/PreferencePanes/$pref_pane.prefPane
end
