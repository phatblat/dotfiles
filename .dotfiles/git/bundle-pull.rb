#-------------------------------------------------------------------------------
#
# bundle.rb
# Functions for complex git-bundle actions
#
#-------------------------------------------------------------------------------

puts "loading bundle.rb"

# bundle-pull
#
# Ensure clean work tree before start, abort if dirty.
#
# - SSH in
# - stash changes
# - get HEAD SHA
# - get stash
# - get stash SHA
# - bundle create (& verify)
# - end SSH
# - git fetch OTHER_HOST $USER/REPO_PATH/BUNDLE_FILE bundle_branch
#   - User dir is used as root (so can't get to system files, less typing)
def bundlepull()
    puts "bundle-pull"
    # local remote_hostname

    # determine remote_hostname
    # if $HOST = "octoair.local"
    #     remote_hostname = "imac.local"

end

bundlepull()
