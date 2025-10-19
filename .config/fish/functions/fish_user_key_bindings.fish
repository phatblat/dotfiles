#!/usr/bin/env fish
# Enables VI-style key bindings. Updates $fish_key_bindings.
# https://github.com/fish-shell/fish-shell/issues/1435
function fish_user_key_bindings
    fish_vi_key_bindings insert
end
