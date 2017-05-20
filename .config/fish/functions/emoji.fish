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

    for i in (seq (count $names))
        if test $char_name = $names[$i]
            echo -n $emoji[$i]"  " | pbcopy
            echo $emoji[$i]
            return
        end
    end

    echo "Unknown emoji: $char_name"
    return 2

    switch $char_name
        case format
            echo 🎨
        case performance
            echo 🚀 # alt: 🐎
        case docs
            echo ✏️
        case idea
            echo 💡
        case progress
            echo 🚧
        case feature
            echo ➕
        case feature_remove
            echo ➖
        case logging
            echo 🔈
        case logging_reduce
            echo 🔇
        case bug
            echo 🐛
        case tests
            echo ✅
        case security
            echo 🔒
        case dependencies
            echo ⬆️
        case dependencies_downgrade
            echo ⬇️
        case leaks #plugging memory leaks
            echo 🚱
        case linux
            echo 🐧
        case macos
            echo 🍎
        case windows
            echo 🏁
        case  emove # removing code or files
            echo 🔥
        case ci # fixing the CI build
            echo 💚
        case lint # resolving linter warnings
            echo 👕
        case '*'
            echo "Unknown emoji"
    end
end
