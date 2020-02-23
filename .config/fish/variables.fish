
# ~/.config/fish/variables.fish
# Dotfiles
#
# Exported variables in fish shell.
#

set --export KERNEL (uname)

# Upper case
if is_mac
    set --export ANDROID_HOME ~/Library/Android/sdk
    set --export ANDROID_SDK_ROOT $ANDROID_HOME
    set --export ANDROID_NDK_HOME (brew_home)/share/android-ndk
else if is_linux
    set --export ANDROID_HOME ~/Android/Sdk
    set --export ANDROID_SDK_ROOT $ANDROID_HOME
    set --export ANDROID_NDK_HOME
end
set --export ARCHFLAGS "-arch x86_64"
set --export GPG_TTY (tty)
set --export GRADLE_HOME (brew_home gradle)/libexec
set --export GROOVY_HOME (brew_home groovy)/libexec
set --export HOMEBREW_BAT (command --search bat)
set --export ICLOUD_HOME $HOME"/Library/Mobile Documents"
set --export ICLOUD_DRIVE $ICLOUD_HOME"/com~apple~CloudDocs"
set --export JABBA_HOME ~/.jabba
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
set --export powerline_enabled 0
set --global --export sdkman_prefix ~/.sdkman

# Fix spacing for emoji and ambiguous characters
set -xg fish_emoji_width 2
set -xg fish_ambiguous_width 2

# OMF bobthefish theme options
# https://github.com/oh-my-fish/oh-my-fish/blob/master/docs/Themes.md#bobthefish

set -g theme_display_git yes
set -g theme_display_git_dirty yes
set -g theme_display_git_untracked yes
set -g theme_display_git_ahead_verbose yes
set -g theme_display_git_dirty_verbose yes
set -g theme_display_git_stashed_verbose yes
set -g theme_display_git_master_branch yes
set -g theme_git_worktree_support yes
set -g theme_display_vagrant yes
set -g theme_display_docker_machine no
set -g theme_display_k8s_context yes
set -g theme_display_hg yes
set -g theme_display_virtualenv no
set -g theme_display_ruby no
set -g theme_display_user ssh
set -g theme_display_hostname ssh
set -g theme_display_vi yes
set -g theme_display_nvm yes
set -g theme_display_date no
set -g theme_display_cmd_duration yes
set -g theme_title_display_process yes
set -g theme_title_display_path no
set -g theme_title_use_abbreviated_path no
set -g theme_date_format "+%a %H:%M"
set -g theme_avoid_ambiguous_glyphs yes
set -g theme_powerline_fonts yes
set -g theme_nerd_fonts yes
set -g theme_show_exit_status yes
set -g default_user phatblat
set -g theme_color_scheme gruvbox
set -g fish_prompt_pwd_dir_length 0
set -g theme_project_dir_length 1
set -g theme_newline_cursor no

# Editor
# After variables which depend on functions that define variables
set --export EDITOR_CLI "vim" # vi vim
set --export EDITOR_GUI "code" # atom (vs)code mate mvim subl
set --export CLI_WAIT_FLAG "-f"
set --export GUI_WAIT_FLAG "-w"

# EDITOR or VISUAL, only one defined
# Use EDITOR for non-console users (su someoneelse) and SSH connections
if not type -q $EDITOR_GUI; or not is_console_user; or is_ssh
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
    /usr/local/sbin \
    (brew_home ruby)/bin \
    (brew_home sqlite)/bin \
    $fish_user_paths

# PATH
set --export --global PATH \
    ./bin \
    ~/bin \
    (brew_home)/bin \
    (brew_home curl)/bin \
    (brew_home python)/libexec/bin \
    $PATH

if test -d (brew_home)/sbin
    set --export --global PATH $PATH \
        (brew_home)/sbin
end

if test -d (brew_home python)/libexec/bin
    set --export --global PATH $PATH \
        (brew_home python)/libexec/bin
end

set --export --global SWIFT_TOOLCHAIN ~/src/swift/current
if test -d "$SWIFT_TOOLCHAIN"
    set --export --global PATH $PATH \
        $SWIFT_TOOLCHAIN/usr/bin
end

if test -d "$ANDROID_HOME"
    set --export --global PATH \
        $ANDROID_HOME/tools/bin \
        $ANDROID_HOME/build-tools/* \
        $ANDROID_HOME/platform-tools \
        $PATH
end

set --export --global CHROME_DEPOT_TOOLS ~/dev/chromium/depot_tools
if test -d "$CHROME_DEPOT_TOOLS"
    set --export --global PATH $PATH \
        $CHROME_DEPOT_TOOLS
end

# Extra paths for budspencer omf theme
# https://github.com/oh-my-fish/oh-my-fish/blob/master/docs/Themes.md#budspencer
if test (uname -s) = "Darwin"
  set -gx PATH /usr/local/opt/coreutils/libexec/gnubin $PATH
  set -gx PATH /usr/local/opt/gnu-sed/libexec/gnubin $PATH
end

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
setjdk 1.8
