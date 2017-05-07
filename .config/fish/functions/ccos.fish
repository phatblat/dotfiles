# Checkout source of dependencies using Carthage over SSH.
function ccos
    carthage checkout --no-use-binaries --use-ssh $argv
end
