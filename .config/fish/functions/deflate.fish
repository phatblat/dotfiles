#!/usr/bin/env fish
function deflate --argument-names path --description='Unzip git blobs'
    if test -z "$path"
        echo "Usage: deflate .git/objects/55/7db03de997c86a4a028e1ebd3a1ceb225be238"
        return 1
    else if not test -f "$path"
        echo "$path does not exist"
        return 2
    end

    perl -MCompress::Zlib -e 'undef $/; print uncompress(<>)' $path
end
