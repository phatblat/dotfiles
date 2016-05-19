#-------------------------------------------------------------------------------
#
# ruby/bundler.zsh
# Command-line aliases for Bundler
#
#-------------------------------------------------------------------------------

# Bundler
function bconfig {
  bundle config --local clean true
  bundle config --local path .rubygems
  bundle config --local bin bin
  bundle config --local jobs 8
}
alias bi='bundle install'
alias bu='bundle update'
alias be='bundle exec'
alias bv='bundle --version'

# El Capitan workaround to not being able to install Bundler to /usr/bin
# sudo gem install bundler --bindir /usr/local/bin

# Fastlane
alias bef='bundle exec fastlane'
