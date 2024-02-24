function has_space \
    --description 'Tests whether string continas a space' \
    --argument-names string

    if string match --entire --invert ' ' "$string"
        return 1
    end
end
