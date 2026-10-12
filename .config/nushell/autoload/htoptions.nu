# htoptions - Send an HTTP request using the OPTIONS method using burl
export def htoptions [...args] {
    ^burl OPTIONS ...$args
}
