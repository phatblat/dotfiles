#-------------------------------------------------------------------------------
#
# shell/config.zsh
# Shell configuration
#
#-------------------------------------------------------------------------------

# Enable vi style command editing.
# This setting doesn't work when applied in shell/options.zsh
# bindkey -v

# Carthage Zsh Completion
# https://github.com/Carthage/Carthage/blob/master/Documentation/BashZshFishCompletion.md#zsh
autoload -U compinit
compinit -u

# Allow [ or ] whereever you want
# https://robots.thoughtbot.com/how-to-use-arguments-in-a-rake-task
unsetopt nomatch
