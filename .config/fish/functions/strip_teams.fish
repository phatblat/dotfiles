function strip_teams \
    --description 'Strip codesign from the Teams app' \
    --argument-names path

    set -l teams_path "/Applications/Microsoft Teams.app"

    # 1st arg overrides default path
    if test -n "$path"
        set teams_path $path
    end

    # https://support.ecamm.com/en/articles/4343963-virtual-camera-missing-after-microsoft-teams-update
    sudo codesign \
        --verbos \
        --remove-signature "$teams_path/Contents/Frameworks/Microsoft Teams Helper (Renderer).app"
end
