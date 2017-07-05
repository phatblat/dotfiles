# Standard ignored files.
function ignores
    # Xcode
    list -s \
        .DS_Store \
        '*.xccheckout' \
        '*.xcscmblueprint' \
        xcuserdata \
        Carthage/ \
        Pods/ \
        .rubygems/ \
        bin/ \
        build/ \
        .gradle/
end
