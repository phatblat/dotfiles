# Custom function for fish_postexec event
function fish_postexec --on-event fish_postexec
    # Export CMD_DURATION so that powerline can access it
    set --export CMD_DURATION $CMD_DURATION

    # DISABLED:
    # Switch back to vi command (default) mode after each terminal command.
    # fish_vi_key_bindings insert
end
