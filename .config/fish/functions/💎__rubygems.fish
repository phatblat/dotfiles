# Installs and updates Ruby gems.
#
# Bundler is used to install most gems locally for the projects that need them.
# Only a few gems are installed at the system level.
#
# Sequencing
# - Before: xcode
function 💎__rubygems
    echo "💎  Updating Ruby Gems"
    echo

    # TODO: Install ruby using homebrew
    # TODO: Check ownership of gemdir, require admin user only if using system ruby
    # FIXME: Fix write permission on /usr/local/Cellar/ruby/2.4.1_1/bin/
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
        gem_install bundler

        # Fix for "Your bundle is locked to rake (12.0.0), but that version could not be found in any of the sources listed in your Gemfile."
        # http://stackoverflow.com/questions/41757144/your-bundle-is-locked-to-rake-12-0-0-but-that-version-could-not-be-found-in-a
        gem_install rubygems-bundler
        gem regenerate_binstubs
    end

    pushd ~

    # Ensure bundler is installed
    if not which -s bundle
        error "Bundler is not installed"
        return 1
    end

    # Update user gems
    bundle outdated
    bundle update

    popd
end
