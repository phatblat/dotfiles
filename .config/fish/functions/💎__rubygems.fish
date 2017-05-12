# Installs and updates Ruby gems.
#
# Bundler is used to install most gems locally for the projects that need them.
# Only a few gems are installed at the system level.
function 💎__rubygems
    echo "💎  Ruby Gems"
    echo

    # Only admins can manage gems installed at the system level.
    if user_is_admin
        # Workaround to no access to /usr/bin on Sierra
        #   Updating rubygems-update
        #   ERROR:  While executing gem ... (Errno::EPERM)
        #       Operation not permitted - /usr/bin/update_rubygems
        # http://stackoverflow.com/questions/33015875/operation-not-permitted-usr-bin-update-rubygems/34098613#answer-39928447
        sudo gem update --bindir /usr/local/bin --system
        sudo gem update --bindir /usr/local/bin

        # Bundler
        sudo gem install bundler --bindir /usr/local/bin

        # Fix for "Your bundle is locked to rake (12.0.0), but that version could not be found in any of the sources listed in your Gemfile."
        # http://stackoverflow.com/questions/41757144/your-bundle-is-locked-to-rake-12-0-0-but-that-version-could-not-be-found-in-a
        sudo gem install rubygems-bundler --bindir /usr/local/bin
        sudo gem regenerate_binstubs
    end

    pushd ~

    # Install gems configured at user level
    bundle install

    # Update user gems
    bundle outdated
    bundle update

    popd
end
