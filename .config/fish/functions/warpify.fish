# https://docs.warp.dev/features/subshells#automatically-warpify-subshells
function warpify \
    --description 'Warpifies subshell'

    printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "fish" }}\x9c'
end
