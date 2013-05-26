#-------------------------------------------------------------------------------
#
# RBENV
#
#-------------------------------------------------------------------------------
export RBENV_ROOT=/usr/local/var/rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

export PATH=${PATH}:/usr/local/var/rbenv/versions/$(cat /usr/local/var/rbenv/version)/bin
# echo $PATH
