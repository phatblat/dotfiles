# 
function developer_mode
    DevToolsSecurity -status && sudo DevToolsSecurity -enable $argv
end

