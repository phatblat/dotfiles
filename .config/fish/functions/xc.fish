function xc \
    --description='Xcode wrapper function'

    if test -f Package.swift
        open Package.swift $argv
        return
    end

    if test -d *.xcworkspace
        open *.xcworkspace $argv
        return
    end

    if test -d *.xcodeproj
        open *.xcodeproj $argv
        return
    end
end
