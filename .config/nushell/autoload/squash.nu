# squash - squash HEAD into its parent non-interactively: combines the two
# commits into one, sitting where the parent used to be, keeping the parent's
# commit message.
#
# Autoload files are sourced by every interactive nushell session, so every
# statement must stay inside the command body: top-level code runs at shell
# startup against whatever repo the shell opened in. Top-level code here once
# popped the tip commit off every clean repo a new shell landed in.
#
# Usage: squash

export def squash [] {
    if (^git status --porcelain | is-not-empty) {
        print --stderr "Error: Git working copy is dirty. Commit or stash changes before squashing."
        return
    }

    if (^git rev-parse --abbrev-ref HEAD) == "HEAD" {
        print --stderr "Error: Cannot squash in a detached HEAD state; check out a branch first."
        return
    }

    let commit_count = (^git rev-list --count HEAD | into int)
    if $commit_count < 2 {
        print --stderr "Error: No parent commit to squash into. This is the first commit."
        return
    }

    let parent = (^git rev-parse HEAD^1)
    let msg = (^git log -1 --format=%B $parent)

    if $commit_count == 2 {
        # Parent is the repository's root commit: there is no grandparent to
        # reset onto, so replace both commits with a single new root commit.
        ^git update-ref -d HEAD
    } else {
        # Reset onto the grandparent, not the parent: resetting onto the
        # parent only recreates a sibling of it with a new message, leaving
        # the commit count unchanged instead of squashing two into one.
        ^git reset --soft $"($parent)~1"
    }

    # `print` writes straight to stdout and puts nothing in the pipeline, so
    # `print $msg | git commit` handed git an empty message: the commit aborted
    # and left HEAD popped. Pipe the value itself.
    $msg | ^git commit --file=-

    print "Successfully squashed HEAD commit into parent."
}
