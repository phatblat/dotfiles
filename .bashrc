# OS X loads .bash_profile even for non-login shells, so source it for tools that don't follow the pattern (like git-sh)
if [ -f ~/.bash_profile ]; then
   source ~/.bash_profile
fi

export PATH=/Users/ben/bin/Sencha/Cmd/3.1.2.342:$PATH

export SENCHA_CMD_3_0_0="/Users/ben/bin/Sencha/Cmd/3.1.2.342"
