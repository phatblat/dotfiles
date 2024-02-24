function upstreamify \
    --description 'Renames origin to upstream'

    remote rename origin upstream
    rv
end
