# Dependencies:
#   functions: bo
#   builtins:  none
#   externals: bundle

const bo_nu = path self bo.nu
source $bo_nu

# bog - List outdated gems using the local Gemfile
# `bundle outdated` has no --gemfile option, so point BUNDLE_GEMFILE at it.
export def bog [] {
    with-env {BUNDLE_GEMFILE: ($env.PWD | path join Gemfile)} { bo }
}
