function editw \
    --description 'Edit (and wait) using the configured VISUAL editor, blocking the shell from progressing until the editor is closed.'
    toggle_wait on
    edit $argv
    toggle_wait off
end
