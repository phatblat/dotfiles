# Dependencies:
#   functions: none
#   builtins:  each flatten
#   externals: env open

# Launch Fork.app on macOS from the terminal
#
# `open -a` hands the calling shell's entire environment to the app, and a GUI
# app keeps that environment for its whole lifetime -- days, in practice. PATH
# is why this function exists, but the git debug variables that ride along with
# it are actively harmful:
#
#   With GIT_TRACE/GIT_TRACE_PERFORMANCE/GIT_SSH_COMMAND='ssh -vvv' set, every
#   git child Fork spawns floods its 16K stdout and 64K stderr pipes. Once Fork
#   stops draining them, the child finishes its work and then blocks forever in
#   write() from print_command_performance_atexit. Observed: four git processes
#   wedged for 12h at 0% CPU, and Fork's background fetch silently broken
#   because it parsed trace output as an error.
#
# The repo-scoping variables are stripped for the same reason: inherited from a
# hook or a scripted git invocation, they would pin a long-lived GUI to one
# worktree's index just as durably.
#
# Uses `^env -u` rather than `hide-env` so this stays identical in intent to the
# zsh function of the same name. `env -u` ignores names that are not set.
export def --wrapped fork [...rest] {
    let scrub = [
        "GIT_TRACE"
        "GIT_TRACE_SETUP"
        "GIT_TRACE_PERFORMANCE"
        "GIT_TRACE_PACKET"
        "GIT_TRACE_PACK_ACCESS"
        "GIT_TRACE_SHALLOW"
        "GIT_TRACE_CURL"
        "GIT_TRACE2"
        "GIT_TRACE2_EVENT"
        "GIT_TRACE2_PERF"
        "GIT_CURL_VERBOSE"
        "GIT_SSH_COMMAND"
        "GIT_DIR"
        "GIT_WORK_TREE"
        "GIT_INDEX_FILE"
        "GIT_OBJECT_DIRECTORY"
        "GIT_COMMON_DIR"
    ]
    let flags = ($scrub | each { |v| ["-u" $v] } | flatten)
    ^env ...$flags open -a Fork ...$rest
}
