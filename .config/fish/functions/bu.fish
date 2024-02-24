function bu \
    --description 'Update gems in the bundle.' \
    --wraps=bundle
    bundle update $argv
end
