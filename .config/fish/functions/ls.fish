function ls \
    --description 'List files with colors and trailing slashes on directories' \
    --wraps ls
    # -p      Write a slash (`/') after each filename if that file is a directory.

    # -G      Enable colorized output.  This option is equivalent to defining
    # CLICOLOR in the environment.  (See lscolors.)

    set --local cmd 'command ls -p'
    if command --query exa
        set cmd exa
    end

    set -lx LC_ALL C
    eval $cmd $argv
end
