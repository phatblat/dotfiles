# Squash function - squashes HEAD into parent non-interactively
# Usage: squash

# Check if working copy is dirty
if ((git status --porcelain | length) > 0) {
    echo "Error: Git working copy is dirty. Commit or stash changes before squashing." >& stderr
    return 1
}

# Check if there is a parent commit
let parent = (git rev-parse HEAD^1)
if $parent == "" {
    echo "Error: No parent commit to squash into. This is the first commit." >& stderr
    return 1
}

# Get the original commit message
let msg = (git log -1 --format=%B $parent)

# Soft reset to parent
git reset --soft $parent

# Commit with original message
git commit -m "$msg"

echo "Successfully squashed HEAD commit into parent."
