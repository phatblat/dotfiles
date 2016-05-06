#-------------------------------------------------------------------------------
#
# ruby/bundler.zsh
# Command-line aliases for Bundler
#
#-------------------------------------------------------------------------------

# Bundler
config='--clean --path .rubygems --binstubs bin'
alias bi="bundle install $config"
alias bu="bundle update $config"
alias be='bundle exec'

# Fastlane
alias bef='bundle exec fastlane'
