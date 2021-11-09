function binstall \
    --description='Install Bundler with the proper bindir.'

    sudo gem install bundler --bindir (brew_home)/bin $argv
end
