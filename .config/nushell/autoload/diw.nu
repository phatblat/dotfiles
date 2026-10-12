# diw - Remove all Ping Identity docker images
export def diw [] {
    print "Running command to: Remove all Ping Identity Docker images"

    # Prune unused images
    dip

    let images = (^docker image ls --format '{{.Repository}} {{.ID}}' 'pingidentity/*' | lines)
    if not ($images | is-empty) {
        let image_ids = (^docker image ls --format '{{.ID}}' 'pingidentity/*' | lines)
        ^docker image rm --force ...$image_ids
    } else {
        print "***No Ping Identity images present to remove***"
    }
}
