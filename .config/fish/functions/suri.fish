# Init and update git submodules recursively.
function suri
    git submodule update --recursive --init $argv
end
