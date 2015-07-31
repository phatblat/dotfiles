#-------------------------------------------------------------------------------
#
# PATH building
#
#-------------------------------------------------------------------------------

export LC_CTYPE=en_US.UTF-8

#
# System path
#
# echo $PATH

# Manually setting the original OS X path so that reloadprofile won't keep growing the PATH
OSX_PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

if [ -d ${HOME}/Library/Python/2.7/bin ] ; then
	PYTHON_PATH=:${HOME}/Library/Python/2.7/bin
fi

# Prepend user bin dir to PATH
# TODO: Get rbenv to load path in correct order
export PATH=~/bin:${OSX_PATH}${PYTHON_PATH}
