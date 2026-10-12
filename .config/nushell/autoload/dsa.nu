# dsa - Stop all running docker containers
export def dsa [] {
    print "Running command to: Stop all running containers"
    let containers = (^docker container ls --all --quiet | lines)
    if not ($containers | is-empty) {
        ^docker container stop ...$containers
    } else {
        print "No containers found to stop"
    }
}
