# Configure ls to show colors and trailing slashes on directories.
function ls --wraps ls
    command ls -Gp $argv
end
