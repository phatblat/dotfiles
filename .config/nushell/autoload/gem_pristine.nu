# gem_pristine - Runs the pristine command for all gems
# Fix gem write permissions:
#   ERROR:  While executing gem ... (Errno::EACCES)
#   Permission denied @ rb_sysopen - /opt/homebrew/Cellar/ruby/.../specifications/matrix-0.4.2.gemspec
export def gem_pristine [] {
    let specs = (glob /opt/homebrew/Cellar/ruby/3.2.2_1/lib/ruby/gems/3.2.0/specifications/*)
    if ($specs | is-not-empty) {
        ^chmod u+w ...$specs
    }
    ^gem pristine --all
}
