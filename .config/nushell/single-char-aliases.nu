# Single-character aliases converted from fish shell functions

# a - Add files to git staging area
def a [...files] {
    git add ...$files
}

# b - Manage git branch
def b [...args] {
    git branch ...$args
}

# c - Performs a git checkout
def c [...args] {
    git checkout ...$args
}

# d - Git diff with custom options
def d [...args] {
    git diff --unified=1 --no-prefix ...$args
}

# e - Short alias for editing a file using VISUAL or EDITOR
def e [path?: string = "."] {
    let editor = if ($env.VISUAL? != null) { $env.VISUAL } else { $env.EDITOR }
    ^$editor $path
}

# g - Gradle alias
def g [...args] {
    gradle ...$args
}


# m - Git merge
def m [...args] {
    git merge ...$args
}

# o - Short alias for open
def o [path?: string] {
    if ($path == null) {
        ^open .
    } else {
        # -t causes the given path to be opened with the default app
        ^open -t $path
    }
}

# r - Interactive rebase for the last few commits
def r [count?: int = 10] {
    # Note: toggle_wait is a fish-specific function
    # In nushell, we can just run the command directly
    git rebase --interactive $"HEAD~($count)"
}

# s - Display abbreviated git status
def s [...args] {
    git status -sb ...$args
}