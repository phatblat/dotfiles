# Dependencies:
#   functions: rv
#   builtins:  lines str trim print
#   externals: git

# Rename the git 'origin' remote to 'phatblat' if not already present
const rv_nu = path self rv.nu
source $rv_nu
export def pborigin [] {
    let all_remotes = (^git remote | lines | each { |r| $r | str trim })
    if ('phatblat' in $all_remotes) {
        print "The phatblat remote is already set up."
        rv
        return
    }
    ^git remote rename origin phatblat
    rv
}
