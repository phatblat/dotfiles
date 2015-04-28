#-------------------------------------------------------------------------------
#
# RBENV
#
#-------------------------------------------------------------------------------
export RBENV_ROOT=/usr/local/var/rbenv

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

export PATH=${PATH}:${RBENV_ROOT}/versions/$(cat ${RBENV_ROOT}/version)/bin
# echo $PATH
