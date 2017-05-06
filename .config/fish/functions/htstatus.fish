# 
function htstatus
    ps awx | grep httpd $argv
end

