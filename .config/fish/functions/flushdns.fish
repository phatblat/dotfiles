# 
function flushdns
    sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder; echo "DNS cache flushed" $argv
end

