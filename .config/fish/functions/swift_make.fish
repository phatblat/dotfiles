function swift_make \
    --description='Adds template Makefile for Swift projects.'

    set -l repo ~/dev/swift/Makefile-swift
    set -l src_file $repo/Makefile

    clone_or_pull $repo git@github.com:phatblat/Makefile-swift.git

    if test $PWD != (root)
        pushd (root)
        cp -v $src_file .
        popd
        return
    end

    cp -v $src_file .
end
