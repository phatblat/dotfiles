# deflate - Unzip git blobs
export def deflate [file: string] {
    if ($file | is-empty) {
        error make { msg: "Usage: deflate .git/objects/55/7db03de997c86a4a028e1ebd3a1ceb225be238" }
    }
    if ($file | path type) != 'file' {
        error make { msg: $"($file) does not exist or is not a file" }
    }
    ^perl -MCompress::Zlib -e 'undef $/; print uncompress(<>)' $file
}
