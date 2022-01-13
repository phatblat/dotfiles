function pu  \
    --description='Update Pods without updating repos.'

    bundle exec pod update --no-repo-update $argv
end
