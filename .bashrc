# OS X loads .bash_profile even for non-login shells, so source it for tools that don't follow the pattern (like git-sh)
if [ -f ~/.bash_profile ]; then
   source ~/.bash_profile
fi
