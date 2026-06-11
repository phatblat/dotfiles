# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Pretty history graph showing all branches (git log --all --graph)
export def --wrapped lga [...rest] {
    ^git log --all --graph --abbrev-commit --date=relative --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' ...$rest
}
