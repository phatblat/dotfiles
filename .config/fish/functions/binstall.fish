# Install Bundler with the proper bindir.
function binstall
    sudo gem install bundler --bindir (brew_home)/bin $argv
end
