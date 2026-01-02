# Pretty git log graph with ten commits
export def l [...args] {
    ^git log -10 --graph --abbrev-commit --date=relative --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' ...$args
}
