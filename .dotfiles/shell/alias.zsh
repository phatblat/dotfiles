#-------------------------------------------------------------------------------
#
# shell/alias.zsh
# Miscellaneous command-line aliases
#
#-------------------------------------------------------------------------------

# ls
alias l='ls -lFh'         # size,show type,human readable
alias ll='ls -l'          # long list
alias la='ls -lAFh'       # long list,show almost all,show type,human readable
alias lr='ls -tRFh'       # sorted by date,recursive,show type,human readable
alias lt='ls -ltFh'       # long list,sorted by date,show type,human readable
alias ldot="la -d .*"     # List hidden files
alias ldir="ls -ld */"    # List dirs
alias ldotdir="la -d .*/" # List hidden dirs

# File sizes
alias bigfiles='echo "File sizes in KB" && du -ka . | sort -n -r | head -n 10'

#
# Shell Helpers
#
alias h='history | tail -n 23'

# Search history
alias hgrep='fc -El 0 | grep'

# Copy last command
alias hcopy="fc -ln -1 | pbcopy"

# Copy current path
alias pcopy="pwd | xargs echo -n | pbcopy"


# External Tools
# eval $(thefuck --alias)
eval "$(direnv hook zsh)"
