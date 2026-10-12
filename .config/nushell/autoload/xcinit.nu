# xcinit - Runs Xcode new_project.rb ruby script
export def --wrapped xcinit [...args] {
    let script = $"($env.HOME)/.dotfiles/xcode/new_project.rb"
    ^$script ...$args
}
