function pu \
    --description 'Update Pods without updating repos.'

    pod update --no-repo-update $argv
end
