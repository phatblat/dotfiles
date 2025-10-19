#!/usr/bin/env fish
# Performs release steps on an Xcode project.
#
# 1. Increments the project/build version.
# 2. Commits the change.
# 3. Tags the commit with the new version in the format: release/123001
# 4. Pushes the changes to the remote repo.
function release
    # Ensure current dir is in a clean git repo
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "This command must be run in a git repo."
        return 1
    end

    if test -n (git status --porcelain)
        echo "Can't release with a dirty work tree."
        return 2
    end

    # Verify that there is a valid Xcode project in the current dir
    version_build
    if test $status -ne 0
        # agvtool what-version
        return 1
    end

    # Release notes
    get --prompt "Have you checked in your release notes?" \
        --default="y" | read -l checked_in

    switch $checked_in
    case "y" "yes"
        echo "YES"
    case "n" "no"
        echo "NO"
        return 1
    end

    # Version
    version bump
    set -l build_version (version_build)

    # Track and share
    git add --update
    git commit --message "Version $build_version"
    git tag "release/$build_version"
    # TODO: Determine default remote to used so that push commands can be combined
    # set -l branch (git symbolic-ref --short HEAD)
    git push
    git push --tags

    # Final status
    version
end
