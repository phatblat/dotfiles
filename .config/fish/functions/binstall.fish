# Install Bundler with the proper bindir.
function binstall
    sudo gem install bundler --bindir /usr/local/bin $argv
end
