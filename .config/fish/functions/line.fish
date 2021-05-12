# https://github.com/fish-shell/fish-shell/issues/206#issuecomment-255232968
function line \
    --argument-names line_number \
    --description='Extracts a single line of stdin. With no arguments, the first line is used.'

    if test -z "$line_number"
        set line_number 1
    end

    cat | tail -n +$line_number | head -n 1
end
