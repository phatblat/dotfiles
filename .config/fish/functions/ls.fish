# Configure ls to show colors and trailing slashes on directories.
function ls --wraps ls
    # -p      Write a slash (`/') after each filename if that file is a directory.

    # -G      Enable colorized output.  This option is equivalent to defining
    # CLICOLOR in the environment.  (See lscolors.)

    command ls -Gp $argv
end
