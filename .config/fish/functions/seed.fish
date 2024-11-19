# https://derflounder.wordpress.com/2018/01/06/setting-your-mac-to-receive-macos-beta-updates-using-seedutil/
function seed \
    --description='Wrapper for macOS seedutil' \
    --argument-names action

    set -l seed_cmd /System/Library/PrivateFrameworks/Seeding.framework/Versions/A/Resources/seedutil

    switch $action
        case enroll
            sudo $seed_cmd enroll DeveloperSeed
            softwareupdate --list
        case unenroll
            sudo $seed_cmd unenroll
        case fixup
            sudo $seed_cmd fixup
        case migrate
            sudo $seed_cmd migrate $argv
        case '*'
            sudo $seed_cmd current
    end
end
