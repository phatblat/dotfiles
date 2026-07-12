# Launch Codex without alternate screen mode (main profile)
export def --wrapped cx [...args] {
    ^codex --no-alt-screen --profile main ...$args
    let status = $env.LAST_EXIT_CODE

    # Reset enhanced keyboard reporting after inline Codex sessions.
    if (is-terminal --stdout) {
        print --no-newline $"(ansi --escape '<u')(ansi --escape '=0u')(ansi --escape '>4;0m')"
    }

    $env.LAST_EXIT_CODE = $status
}
