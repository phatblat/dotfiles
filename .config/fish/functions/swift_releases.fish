function swift_releases --description='Check for Swift releases'
    for date in (jot - 10 20)
        echo $date
        curl -IL https://swift.org/builds/development/xcode/swift-DEVELOPMENT-SNAPSHOT-2018-10-$date-a/swift-DEVELOPMENT-SNAPSHOT-2018-10-$date-a-osx.pkg
    end
end
