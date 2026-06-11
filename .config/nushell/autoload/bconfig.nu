# Dependencies:
#   functions: none
#   builtins:  none
#   externals: bundle

# Configure Bundler with local settings (clean, shared gems, path, bin, jobs)
export def bconfig [] {
    ^bundle config --local clean true
    ^bundle config --local disable_shared_gems true
    ^bundle config --local path .rubygems
    ^bundle config --local bin bin
    ^bundle config --local jobs 8
}
