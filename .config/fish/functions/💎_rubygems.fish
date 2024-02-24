# Bundler is used to install most gems locally for the projects that need them.
# Only a few gems are installed at the system level.
#
# Sequencing
# - Before: xcode
function 💎_rubygems \
    --description 'Installs and updates Ruby gems.'

    echo "💎 Updating Ruby Gems"
    echo

    # TODO: Check ownership of gemdir, require admin user only if using system ruby
    # Only admins can manage gems installed at the system level.
    if user_is_admin
        # Workaround to no access to /usr/bin on Sierra
        #   Updating rubygems-update
        #   ERROR:  While executing gem ... (Errno::EPERM)
        #       Operation not permitted - /usr/bin/update_rubygems
        # http://stackoverflow.com/questions/33015875/operation-not-permitted-usr-bin-update-rubygems/34098613#answer-39928447
        gem_update --system
        gem_update

        # Bundler
        binstall
    end
end
