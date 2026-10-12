# is_ssh - Tests whether the current terminal session is an SSH session
export def is_ssh [] {
    (($env.SSH_CLIENT? | default "") != "") or (($env.SSH_TTY? | default "") != "")
}
