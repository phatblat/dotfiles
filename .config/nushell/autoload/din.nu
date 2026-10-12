# din - Remove all docker images
const dip_nu = path self dip.nu
source $dip_nu
export def din [] {
    print "Running command to: Remove all Docker images"

    # Prune unused images
    dip

    let images = (^docker image ls --format '{{.ID}}' | lines)
    if not ($images | is-empty) {
        ^docker image rm ...$images
    } else {
        print "***No images present to remove***"
    }
}
