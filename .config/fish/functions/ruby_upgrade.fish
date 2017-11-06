function ruby_upgrade --description='Upgrades ruby across major versions' 
    brew update
    brew info ruby
    brew unlink ruby
    brew cleanup ruby
    brew install ruby
    brew link --overwrite ruby

    bak /usr/local/lib/ruby/gems/2.4.0/gems
    bak /usr/local/lib/ruby/gems/2.4.0/extensions

    gem --version
    gem update --system
end