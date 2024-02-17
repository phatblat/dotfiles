function nv \
    --description='Node version'

    if not type --query node
        error "Node.js is not installed."
        return 2
    end

    node --version
end
