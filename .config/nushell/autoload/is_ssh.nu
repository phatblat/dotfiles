# is_ssh - Tests whether the current terminal session is an SSH session
export def is_ssh [] {
    (not (($env.SSH_CLIENT? | default "") | is-empty))
    or (not (($env.SSH_TTY? | default "") | is-empty))
}
