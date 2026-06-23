# Dependencies:
#   functions: none
#   builtins:  str length str join each print
#   externals: none

# Repeats a character a fixed number of times (default 80)
export def repeatchar [char: string, length: int = 80]: nothing -> nothing {
    if ($char | str length) == 0 {
        error make { msg: "Usage: repeatchar - 80" }
    }
    print (1..$length | each { |_| $char } | str join)
}
