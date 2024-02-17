function ccuss \
    --wraps carthage \
    --description='Update depencencies in git submodules without building using Carthage over SSH'
    carthage update --no-use-binaries --no-build --use-ssh --use-submodules $argv
end
