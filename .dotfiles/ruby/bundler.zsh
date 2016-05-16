#-------------------------------------------------------------------------------
#
# ruby/bundler.zsh
# Command-line aliases for Bundler
#
#-------------------------------------------------------------------------------

# Bundler
config='--clean --path .rubygems --binstubs bin'
alias bi="bundle install $config"
alias bu='bundle update'
alias be='bundle exec'

# El Capitan workaround to not being able to install Bundler to /usr/bin
# sudo gem install bundler --bindir /usr/local/bin

# Fastlane
alias bef='bundle exec fastlane'
