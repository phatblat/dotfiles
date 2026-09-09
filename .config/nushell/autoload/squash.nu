# Squash function - squashes HEAD into parent non-interactively
# Usage: squash

# Check if working copy is dirty
if ((git status --porcelain | length) > 0) {
    echo "Error: Git working copy is dirty. Commit or stash changes before squashing." >& stderr
    return 1
}

# Check if there is a parent commit
let commit_count = (git rev-list --count HEAD | into int)
if $commit_count < 2 {
    echo "Error: No parent commit to squash into. This is the first commit." >& stderr
    return 1
}

let parent = (git rev-parse HEAD^1)

# Get the original commit message
let msg = (git log -1 --format=%B $parent)

# Soft reset to parent
git reset --soft $parent

# Commit with original message
print $msg | git commit --file=-

echo "Successfully squashed HEAD commit into parent."
