# 
function entitlements
    codesign -d --entitlements :- $argv
end

