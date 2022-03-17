function fzf_key_bindings \
    --description="Wrapper for fzf key binding script that accounts for mac differences in homebrew root."
    eval (brew_home fzf)/shell/key-bindings.fish
end
