# https://github.com/fish-shell/fish-shell/issues/117#issuecomment-212318212
function ltime --description='Time last command took to complete'
    echo (echo 'scale=3; ' $CMD_DURATION ' / 1000' | bc)"s"
end
