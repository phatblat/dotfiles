# Display the path to the root of the current git repo.
function root
    git rev-parse --show-toplevel $argv
end
