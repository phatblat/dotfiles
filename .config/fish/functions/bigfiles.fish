# 
function bigfiles
    echo "File sizes in KB"
    du -ka . | sort -n -r | head -n 10
end

