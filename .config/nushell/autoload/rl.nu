# Dependencies:
#   functions: none
#   builtins:  cd path expand
#   externals: none

# Navigate to ~/dev/www/reflog/www
export def --env rl [] {
    cd ("~/dev/www/reflog/www" | path expand)
}
