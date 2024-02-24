function pue \
    --description 'Update example app pods without updating repos.'

    pod update \
        --project-directory=Example \
        --no-repo-update \
        $argv
end
