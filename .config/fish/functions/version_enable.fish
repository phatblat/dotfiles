function version_enable \
    --description 'Runs the enable-versioning.rb ruby script.'

    bundle exec ruby ~/.dotfiles/xcode/enable-versioning.rb $argv
end
