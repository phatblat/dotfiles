function root \
    --description='Display the path to the root of the current git repo.'

    git rev-parse --show-toplevel $argv
end
