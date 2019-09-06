function ow \
        --description='Opens Xcode workspace in the current or subdir'
    # Open all but project.xcworkspace
    open (string match --entire --invert project.xcworkspace **.xcworkspace)
end
