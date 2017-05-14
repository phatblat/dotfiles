# Tests whether the current terminal session is an SSH session.
 function is_ssh
     test -n "$SSH_CLIENT" -o -n "$SSH_TTY"
 end
