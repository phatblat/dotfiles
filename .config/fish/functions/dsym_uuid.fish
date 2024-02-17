# 
function dsym_uuid
    mdls -name com_apple_xcode_dsym_uuids -raw *.dSYM | grep -e \\\" | sed 's/[ |\\\"]//g' $argv
end
