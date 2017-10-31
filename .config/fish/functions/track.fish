function track --argument-names branch --wraps=git --description='Creates a local tracking branch.'
    if test -z $branch
        echo "Usage: track branch"
        return 1
    end
    c -t $branch
end
