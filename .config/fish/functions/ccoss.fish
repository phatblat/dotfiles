# Checkout source of dependencies into git submodules using Carthage over SSH.
function ccoss
    carthage checkout --no-use-binaries --use-ssh --use-submodules $argv
end
