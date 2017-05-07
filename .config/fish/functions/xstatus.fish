# Displays nginx process information.
function xstatus
    ps aux | grep nginx $argv
end
