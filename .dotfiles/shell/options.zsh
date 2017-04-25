#-------------------------------------------------------------------------------
#
# options.zsh
# Shell options
#
#-------------------------------------------------------------------------------

export TERM="xterm-256color"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"

# Allow [ or ] whereever you want
unsetopt nomatch

# Current zsh options
setopt alwaystoend
setopt autocd
setopt autopushd
setopt completeinword
setopt extendedhistory
setopt noflowcontrol
setopt histexpiredupsfirst
setopt histignoredups
setopt histignorespace
setopt histverify
setopt incappendhistory
setopt interactive
setopt interactivecomments
setopt login
setopt longlistjobs
setopt monitor
setopt nonomatch
setopt promptsubst
setopt pushdignoredups
setopt pushdminus
setopt sharehistory
setopt zle
