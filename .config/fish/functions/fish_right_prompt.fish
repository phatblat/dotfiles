function fish_right_prompt
    env $POWERLINE_COMMAND  shell right --last-exit-code=$status --last-pipe-status=$status --jobnum=(jobs -p | wc -l) --renderer-arg=client_id=1125 --width=$_POWERLINE_COLUMNS --renderer-arg=mode=$fish_bind_mode --renderer-arg=default_mode=$_POWERLINE_DEFAULT_MODE
end
