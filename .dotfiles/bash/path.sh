#-------------------------------------------------------------------------------
#
# PATH building
#
#-------------------------------------------------------------------------------
#
# Python
#
export PYTHONPATH=/Library/Python/2.6/site-packages/

#
# ImageMagick
#
#export IMAGEMAGICK_HOME=/usr/local/imagemagick

# TextMate SVN
# http://wiki.macromates.com/Main/SubversionCheckout
export LC_CTYPE=en_US.UTF-8
# If you get an error "svn: Can't recode string", then you may need to unset the LC_ALL environment variable:
# export LC_ALL=

export ANDROID_SDK_ROOT=/Applications/adt-bundle-mac/sdk
ANDROID_PATH=${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/tools

#
# Node path
#
export NODE_PATH=/usr/local/lib/node_modules

#
# System path
#
# echo $PATH

# Manually setting the original OS X path so that reloadprofile won't keep growing the PATH
# OSX_PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/X11/bin:/usr/X11R6/bin

BOXEN_PATH=/opt/boxen/rbenv/shims:/opt/boxen/rbenv/bin:/opt/boxen/rbenv/plugins/ruby-build/bin:/opt/boxen/bin:/opt/boxen/homebrew/bin:/opt/boxen/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin

# Prepend user bin dir to PATH
export PATH=~/bin:/usr/local/bin:${ANDROID_PATH}:${FORTIFY_PATH}/bin:${BOXEN_PATH}

# echo $PATH
