# Prints an emoji cheat sheet for commit comments.
#
# Taken from:
# - https://gist.github.com/pocotan001/68f96bf86891db316f20
# - https://github.com/atom/atom/blob/master/CONTRIBUTING.md#git-commit-messages
function emoji
    # --argument-names arg1
    # if test -z $arg1
    #     echo "Usage: emoji arg1"
    #     return 1
    # end
    # switch $arg1
    #     case on ON On
    #     case off OFF Off
    #     case '*'
    # end

    echo "Consider starting the commit message with an applicable emoji:
• 🎨 when improving the format/structure of the code
• 🚀 when improving performance
• ✏️ when writing docs
• 💡 new idea
• 🚧 work in progress
• ➕ when adding feature
• ➖ when removing feature
• 🔈 when adding logging
• 🔇 when reducing logging
• 🐛 when fixing a bug
• ✅ when adding tests
• 🔒 when dealing with security
• ⬆️ when upgrading dependencies
• ⬇️ when downgrading dependencies
◦ 🎨 :art: when improving the format/structure of the code
◦ 🐎 :racehorse: when improving performance
◦ 🚱 :non-potable_water: when plugging memory leaks
◦ 📝 :memo: when writing docs
◦ 🐧 :penguin: when fixing something on Linux
◦ 🍎 :apple: when fixing something on macOS
◦ 🏁 :checkered_flag: when fixing something on Windows
◦ 🐛 :bug: when fixing a bug
◦ 🔥 :fire: when removing code or files
◦ 💚 :green_heart: when fixing the CI build
◦ ✅ :white_check_mark: when adding tests
◦ 🔒 :lock: when dealing with security
◦ ⬆️ :arrow_up: when upgrading dependencies
◦ ⬇️ :arrow_down: when downgrading dependencies
◦ 👕 :shirt: when removing linter warnings"
end
