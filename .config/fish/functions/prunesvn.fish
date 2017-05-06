# 
function prunesvn
    find . -type d -name .svn -exec rm -rf {} \; $argv
end

