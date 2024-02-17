function cbootios \
    --description='Bootstrap Carthage-managed dependencies for the iOS platform.'

    carthage bootstrap \
        --no-use-binaries \
            --platform iOS \
        $argv
end
