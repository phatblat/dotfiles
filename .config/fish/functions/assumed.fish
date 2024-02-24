function assumed \
    --description 'List files in the current repo for which changes are ignored.'

    git ls-files -v | grep ^h | cut -c 3- $argv
end
