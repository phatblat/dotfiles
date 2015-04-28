#-------------------------------------------------------------------------------
#
# RBENV
#
#-------------------------------------------------------------------------------
if [ -d /opt/boxen ] ; then
    export RBENV_ROOT=/opt/boxen/homebrew/var/rbenv
else
    export RBENV_ROOT=/usr/local/var/rbenv
fi

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# export PATH=${PATH}:${RBENV_ROOT}/versions/$(cat ${RBENV_ROOT}/version)/bin
# echo $PATH
