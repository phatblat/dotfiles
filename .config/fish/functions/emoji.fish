# Prints an emoji cheat sheet for commit comments.
#
# Taken from:
# - https://gist.github.com/pocotan001/68f96bf86891db316f20
# - https://github.com/atom/atom/blob/master/CONTRIBUTING.md#git-commit-messages
function emoji --argument-names char_name

    set -l names format performance docs idea progress feature feature_remove logging logging_reduce bug tests security dependencies dependencies_downgrade leaks linux macos windows remove ci lint
    set -l emoji 🎨 🚀 ✏️ 💡 🚧 ➕ ➖ 🔈 🔇 🐛 ✅ 🔒 ⬆️ ⬇️ 🚱 🐧 🍎 🏁 🔥 💚 👕

    if test -z "$char_name"
        for i in (seq (count $names))
            echo "  "$emoji[$i]"  "$names[$i]
        end
        return
    end

    # aliases
    switch $char_name
        case fmt
            set char_name format
        case perf
            set char_name performance
        case doc
            set char_name docs
        case idea
            set char_name idea
        case prog wip
            set char_name progress
        case feat
            set char_name feature
        case remove rem
            set char_name feature_remove
        case log logs
            set char_name logging
        case logdown logsdown
            set char_name logging_reduce
        case defect
            set char_name bug
        case test
            set char_name tests
        case sec
            set char_name security
        case deps up
            set char_name dependencies
        case depsdown down
            set char_name dependencies_downgrade
        case leak #plugging memory leaks
            set char_name leaks
        case linux
            set char_name linux
        case mac apple
            set char_name macos
        case win
            set char_name windows
        case rem delete del # removing code or files
            set char_name remove
        case build # fixing the CI build
            set char_name ci
        case linter # resolving linter warnings
            set char_name lint
    end

    for i in (seq (count $names))
        if test $char_name = $names[$i]
            echo -n $emoji[$i]"  " | pbcopy
            echo $emoji[$i]
            return
        end
    end

    error "Unknown emoji: $char_name"
    return 2
end
