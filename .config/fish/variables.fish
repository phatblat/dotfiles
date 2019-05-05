#
# ~/.config/fish/variables.fish
# Dotfiles
#
# Exported variables in fish shell.
#

# Upper case
set --export ANDROID_HOME (brew_home)/share/android-sdk
set --export ANDROID_SDK_ROOT (brew_home)/share/android-sdk
set --export ANDROID_NDK_HOME (brew_home)/share/android-ndk
set --export ARCHFLAGS "-arch x86_64"
set --export GPG_TTY (tty)
set --export GRADLE_HOME (brew_home gradle)/libexec
set --export GROOVY_HOME (brew_home groovy)/libexec
set --export ICLOUD_HOME "~/Library/Mobile Documents"
set --export ICLOUD_DRIVE $ICLOUD_HOME"/com~apple~CloudDocs"
set --export JABBA_HOME ~/.jabba
set --export KERNEL (uname)
set --export LANG en_US.UTF-8
set --export LANGUAGE en_US.UTF-8
set --export LC_ALL en_US.UTF-8
set --export LC_CTYPE en_US.UTF-8
set --export OPENSSL_PATH (brew_home openssl)/bin/openssl
set --export REALM_OBJECT_SERVER_VERSION 1.8.3
set --export REALM_OBJECT_SERVER_PATH ~/dev/realm/_releases/realm-mobile-platform-$REALM_OBJECT_SERVER_VERSION

# ls command colors - http://osxdaily.com/2013/02/05/improve-terminal-appearance-mac-os-x/
set --export CLICOLOR 1
set --export LSCOLORS ExFxBxDxCxegedabagacad

# Lower case
set --export github_user phatblat
set --global --export sdkman_prefix ~/.sdkman

# Editor
# After variables which depend on functions that define variables
set --export EDITOR_CLI "vim" # vi vim
set --export EDITOR_GUI "code" # atom (vs)code mate mvim subl
set --export CLI_WAIT_FLAG "-f"
set --export GUI_WAIT_FLAG "-w"

# EDITOR or VISUAL, only one defined
# Use EDITOR for non-console users (su someoneelse) and SSH connections
if not console_user; or is_ssh
    set --export EDITOR $EDITOR_CLI
    set --export WAIT_FLAG $CLI_WAIT_FLAG
    set --erase VISUAL
else
    set --export VISUAL $EDITOR_GUI
    set --export WAIT_FLAG $GUI_WAIT_FLAG
    set --erase EDITOR
end

# fish_user_paths
set --global fish_user_paths \
    /usr/local/opt/ruby/bin \
    /usr/local/sbin \
    /usr/local/opt/sqlite/bin \
    $fish_user_paths

# PATH
set --export --global PATH \
    ./bin \
    ~/bin \
    (brew_home)/bin \
    (brew_home curl)/bin \
    /snap/bin \
    $ANDROID_HOME/tools/bin \
    /usr/local/opt/python/libexec/bin \
    $PATH

# Custom HOME handling for octodec. Since /Users/phatblat is a symlink,
# it causes PWD to not match HOME, preventing powerline from shortening paths.
if begin string match --quiet phatblat $USER; and string match --quiet --entire octodec (hostname); end
    set --export --global HOME /Volumes/ThunderBay/Users/phatblat
end

# ls color formatting - LS_COLWIDTHS
#
# If this variable is set, it is considered to be a colon-delimited list of
# minimum column widths.  Unreasonable and insufficient widths are ignored
# (thus zero signifies a dynamically sized column).  Not all columns have
# changeable widths.  The fields are, in order: inode, block count,
# number of links, user name, group name, flags, file size, file name.
set --export LS_COLWIDTHS 0:10:0:10:0:0:10:0

# Java
# FIXME: jabba doesn't update fish environment
# jabba use default
# jabba deactivate
# setjdk 1.8
