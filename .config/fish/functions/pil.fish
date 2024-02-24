function pil \
    --description 'Special "local" pod install for KP Mobile. See pul'

    LOCAL=1 \
        pod install $argv
end
