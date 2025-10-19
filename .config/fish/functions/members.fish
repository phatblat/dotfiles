#!/usr/bin/env fish
# List members of the given group.
function members --argument-names group
    if test -z $group
        echo "Usage: members group"
        return 1
    end

    for user in (dscl . -list /Users)
        if test (dsmemberutil checkmembership -U $user -G $group | grep "is a member")
            echo $user
        end
    end
end
