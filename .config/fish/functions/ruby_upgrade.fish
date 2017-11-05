function ruby_upgrade --description='Upgrades ruby across major versions' 
    brew update
    brew info ruby
    brew unlink ruby
    brew cleanup ruby
    brew install ruby
    brew link ruby

    gem --version
    gem update --system
end