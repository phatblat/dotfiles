# filesize - Print the size of a file
export def filesize [file?: string] {
    if ($file | is-empty) {
        error make { msg: "Usage: filesize filename" }
    }
    ls $file | get 0.size
}
