#!/usr/bin/env fish
function fish_vendor_functions_dir \
    --description='Prints path to fish vendor_functions.d'

    pkg-config --variable functionsdir fish
end
