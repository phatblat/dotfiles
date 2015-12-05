#-------------------------------------------------------------------------------
#
# PATH building
#
#-------------------------------------------------------------------------------

#
# System path
#
# echo $PATH

# Manually setting the original OS X path so that reloadprofile won't keep growing the PATH
OSX_PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

# Prepend user bin dir to PATH
export PATH=~/bin${PYTHON_PATH}:${PATH}
