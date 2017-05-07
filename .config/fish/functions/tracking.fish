# Display tracking branch information.
function tracking
    git rev-parse --abbrev-ref --symbolic-full-name @{u} $argv
end
