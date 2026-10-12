# rubygems - Installs and updates Ruby gems (converted from 💎_rubygems)
export def rubygems [] {
    print "💎 Updating Ruby Gems"
    print ""

    if (user_is_admin) {
        # Workaround to no access to /usr/bin on Sierra
        # Updating rubygems-update
        ^gem update --system
        ^gem update

        # Bundler
        ^gem install bundler
    }
}
