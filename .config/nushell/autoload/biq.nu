# biq - Quiet bundle install
export def --wrapped biq [...args] {
    bi --quiet ...$args
}
