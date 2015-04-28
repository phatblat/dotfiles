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
# OSX_PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin:/usr/X11R6/bin

if [ -d /Users/ben/Library/Python/2.7/bin ] ; then
	PYTHON_PATH=/Users/ben/Library/Python/2.7/bin
	export PATH=${PYTHON_PATH}:${PATH}
fi

# Prepend user bin dir to PATH
# TODO: Get rbenv to load path in correct order
export PATH=~/bin:/usr/local/bin:${PATH}:/usr/bin:/bin:/usr/sbin:/sbin
