# ruby_upgrade - Upgrades ruby across major versions
export def ruby_upgrade [] {
    ^brew update
    ^brew info ruby
    ^brew unlink ruby
    ^brew cleanup ruby
    ^brew install ruby
    ^brew link --overwrite ruby

    ^rm -rf /usr/local/lib/ruby/gems/2.4.0/gems
    ^rm -rf /usr/local/lib/ruby/gems/2.4.0/extensions

    let tmpfile = (^mktemp /tmp/ruby_upgrade.XXXXXX | str trim)
    let gem_err = (do { ^gem --version } | complete | get stderr)
    $gem_err | save -f $tmpfile

    print "Looping over gem errors"
    for line in (open $tmpfile | lines | where {|l| $l | str contains 'Try: '}) {
        let pristine_cmd = ($line | split row 'Try: ' | last | str trim)
        try { ^sh -c $pristine_cmd }
    }
    ^rm $tmpfile

    ^gem update --system
    ^gem install bundler
}
