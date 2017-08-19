#
# ~/.config/fish/variables.fish
# Dotfiles
#
# Exported variables in fish shell.
#

# Editor
set --export EDITOR_CLI "vim" # vi vim
set --export EDITOR_GUI "atom" # atom mate mvim subl
set --export CLI_WAIT_FLAG "-f"
set --export GUI_WAIT_FLAG "-w"

# EDITOR or VISUAL, only one defined
# Use EDITOR for non-login shells (su someoneelse) and SSH connections
if not status is-login; or is_ssh
    set --export EDITOR $EDITOR_CLI
    set --export WAIT_FLAG $CLI_WAIT_FLAG
    set --erase VISUAL
else
    set --export VISUAL $EDITOR_GUI
    set --export WAIT_FLAG $GUI_WAIT_FLAG
    set --erase EDITOR
end

set --export ANDROID_HOME (brew_home)/share/android-sdk
set --export ANDROID_SDK_ROOT (brew_home)/share/android-sdk
set --export ANDROID_NDK_HOME (brew_home)/share/android-ndk
set --export ARCHFLAGS "-arch x86_64"
set --export GPG_TTY (tty)
set --export GRADLE_HOME (brew_home gradle)/libexec
set --export GRADLE_OPTS -Xmx1g
set --export GRADLE_HEAP_SPACE -Xmx1g
set --export GROOVY_HOME (brew_home groovy)/libexec
set --export JAVA_HOME (/usr/libexec/java_home)
set --export JAVA_OPTS "-Xms256m -Xmx512m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
set --export ICLOUD_HOME "~/Library/Mobile Documents"
set --export ICLOUD_DRIVE $ICLOUD_HOME"/com~apple~CloudDocs"
set --export LANG en_US.UTF-8
set --export LANGUAGE en_US.UTF-8
set --export LC_ALL en_US.UTF-8
set --export LC_CTYPE en_US.UTF-8
set --export OPENSSL_PATH (brew_home openssl)/bin/openssl

# fish_user_paths
set --global fish_user_paths \
    ~/Library/Python/2.7/bin \
    /usr/local/sbin \
    /usr/local/opt/sqlite/bin \
    $fish_user_paths

# PATH
set --export --global PATH ./bin ~/bin (brew_home curl)/bin $PATH

# ls color formatting - LS_COLWIDTHS
#
# If this variable is set, it is considered to be a colon-delimited list of
# minimum column widths.  Unreasonable and insufficient widths are ignored
# (thus zero signifies a dynamically sized column).  Not all columns have
# changeable widths.  The fields are, in order: inode, block count,
# number of links, user name, group name, flags, file size, file name.
set --export LS_COLWIDTHS 0:10:0:10:0:0:10:0

# Obsolete rsync variables
set --export phatblat_imac /Users/phatblat.bak/
set --export phatblat_external /Volumes/ThunderBay/Users/phatblat/
