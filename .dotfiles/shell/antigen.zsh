#-------------------------------------------------------------------------------
#
# shell/antigen.zsh
# Antigen zsh plugin setup
# http://antigen.sharats.me
#
#-------------------------------------------------------------------------------

source "$(brew --prefix)/share/antigen.zsh"
antigen use oh-my-zsh
# Override the oh-my-zsh 'd' alias
unalias d && alias d='git diff'

# Antigen Bundles
antigen bundle common-aliases
antigen bundle phatblat/powerline-shell --branch=custom
antigen bundle robbyrussell/oh-my-zsh plugins/ruby
antigen bundle zsh-users/zsh-syntax-highlighting

# Antigen Themes
antigen theme gnzh

#antigen apply
