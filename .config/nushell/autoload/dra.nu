# dra - Remove all stopped docker containers
export def dra [] {
    print "Running command to: Remove all stopped containers"
    let containers = (^docker container ls --all --quiet | lines)
    if not ($containers | is-empty) {
        ^docker container rm ...$containers
    } else {
        print "No containers found to remove"
    }
}
