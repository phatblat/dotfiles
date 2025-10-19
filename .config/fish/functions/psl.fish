#!/usr/bin/env fish
# Displays process information with custom format.
#
# Keywords for columns (-o):
# - %cpu        percentage CPU usage (alias pcpu)
# - %mem        percentage memory usage (alias pmem)
# - args        command and arguments
# - command     command and arguments
# - cpu         short-term CPU usage factor (for scheduling)
# - etime       elapsed running time
# - lstart      time started
# - paddr=ADDR  swap address
# - pid         process ID
# - ppid        parent process ID
# - pri         scheduling priority
# - rss         resident set size
# - start       time started
# - time        accumulated CPU time, user + system (alias cputime)
# - tt          control terminal name (two letter abbreviation)
# - tty         full name of control terminal
# - uid         effective user ID
# - user        user name (from UID)
# - vsz         virtual size in Kbytes (alias vsize)
# - wchan
function psl --wraps ps
    ps \
        # Columns
        -o user \
        -o pid \
        -o '%cpu' \
        -o '%mem' \
        -o time \
        -o command=COMMAND \
        # Display information about other users' processes as well as your own.  This will skip any processes which do not have a control ling terminal, unless the -x option is also specified.
        -a \
        # Display the processes belonging to the specified usernames.
        # -uroot -uphatblat \
        # Repeat the information header as often as necessary to guarantee one header per page of information.
        -h \
        # Sort by current CPU usage, instead of the combination of controlling terminal and process ID.
        -r \
        # Sort by memory usage, instead of the combination of controlling terminal and process ID.
        -m \
        $argv
end
