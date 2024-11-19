function bpru \
    --description='Update CocoaPod repos.'

    bundle exec "pod repo update $argv"
end
