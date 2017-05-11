# Edit (and wait) using the configured VISUAL editor (TextMate),
# blocking the shell from progressing until the editor is closed.
function editw
    eval $VISUAL -w $argv
end
