# function_template - Print a shell function skeleton to stdout
export def function_template [function_name?: string, argname?: string] {
    if ($function_name | is-empty) {
        error make { msg: "Usage: function_template function_name [argname]" }
    }
    let arg = (if ($argname | is-empty) { "argname" } else { $argname })
    print $"function ($function_name)\(\) {"
    print $"    # ($function_name) does something"
    print $"    if [[ -z \"$($arg)\" ]]; then"
    print $"        echo 'Usage: ($function_name) [($arg)]'"
    print "        return 1"
    print "    fi"
    print ""
    print "}"
}
