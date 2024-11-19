function changelog \
    --description='Create changelog'

    set --local fileName CHANGELOG.md
    set --local currentDir (string split '/' (pwd))[-1]

    if test -f $fileName
        error "This directory already contains a $fileName"
        return 1
    end

    echo "\
# $currentDir Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

" >$fileName

end
