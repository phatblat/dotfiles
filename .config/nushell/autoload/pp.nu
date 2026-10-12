# Dependencies:
#   functions: publish
#   builtins:  none
#   externals: none

# Publish the current branch to the phatblat remote
const publish_nu = path self publish.nu
source $publish_nu
export def pp [] {
    publish phatblat
}
