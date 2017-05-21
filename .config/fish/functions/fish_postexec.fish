# Custom function for fish_postexec event
function fish_postexec --on-event fish_postexec
    # Switch back to vi command (default) mode after each terminal command.
    fish_vi_key_bindings default
end
