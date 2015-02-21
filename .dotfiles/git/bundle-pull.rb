#-------------------------------------------------------------------------------
#
# bundle.rb
# Functions for complex git-bundle actions
#
#-------------------------------------------------------------------------------

puts 'loading bundle.rb'

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
def bundle_pull()
    puts 'bundle-pull'
    # local remote_hostname

    # determine remote_hostname
    username = ENV['USER']
    puts "username: #{username}"

    hostname = `hostname`
    case
        when 'octoair.local'
            puts 'This is octoair'
            remote_hostname = 'imac.local'
        when 'imac.local'
            puts 'This is imac'
            remote_hostname = 'imac.local'
    end
    puts "remote_hostname: #{remote_hostname}"

end

bundle_pull()
