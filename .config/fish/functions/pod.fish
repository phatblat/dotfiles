function pod \
    --description='Display the local version of CocoaPods.' \
    --wraps='pod'

    set -l cmd_prefix

    set -l bundler (findup Gemfile)
    if test -n "$bundler"
        set cmd_prefix "bundle exec"
    end

    eval command $cmd_prefix pod $argv
end
