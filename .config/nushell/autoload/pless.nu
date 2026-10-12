# pless - Use less to view the XML of a property list file
export def pless [file: path] {
    if ($file | is-empty) {
        error make { msg: "Usage: pless file" }
    }
    plcat $file | ^less
}
