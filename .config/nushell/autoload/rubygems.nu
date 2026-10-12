# rubygems - Installs and updates Ruby gems (converted from 💎_rubygems)
const user_is_admin_nu = path self user_is_admin.nu
source $user_is_admin_nu
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
