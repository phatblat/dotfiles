# lgg - Pretty history graph
export def --wrapped lgg [...args] {
    ^git log --graph --abbrev-commit --date=relative --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' ...$args
}
