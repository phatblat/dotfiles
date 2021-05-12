
# ~/.config/fish/variables.fish
# Dotfiles
#
# Exported variables in fish shell.
#

set --export KERNEL (uname)

# Upper case
if is_mac
    set --export ANDROID_HOME $HOME/Library/Android/sdk
    set --export ANDROID_SDK_ROOT $ANDROID_HOME
    set --export ANDROID_NDK_HOME (brew_home)/share/android-ndk
else if is_linux
    set --export ANDROID_HOME $HOME/Android/Sdk
    set --export ANDROID_SDK_ROOT $ANDROID_HOME
    set --export ANDROID_NDK_HOME
end

if is_arm
    set --export ARCHFLAGS "-arch arm64"
else
    set --export ARCHFLAGS "-arch x86_64"
end

set --export GPG_TTY (tty)
set --export GRADLE_HOME (brew_home gradle)/libexec
set --export GROOVY_HOME (brew_home groovy)/libexec
set --export HOMEBREW_BAT (command --search bat)
set --export HOMEBREW_CLEANUP_MAX_AGE_DAYS 30
set --export ICLOUD_HOME $HOME"/Library/Mobile Documents"
set --export ICLOUD_DRIVE $ICLOUD_HOME"/com~apple~CloudDocs"
set --export JABBA_HOME $HOME/.jabba
set --export LANG en_US.UTF-8
set --export LANGUAGE en_US.UTF-8
set --export LC_ALL en_US.UTF-8
set --export LC_CTYPE en_US.UTF-8
set --export OPENSSL_PATH (brew_home openssl)/bin/openssl
set --export PING_IDENTITY_DEVOPS_HOME $HOME/dev/ping/devops
set --export PING_IDENTITY_DEVOPS_REGISTRY docker.io/pingidentity
set --export PING_IDENTITY_DEVOPS_TAG edge
set --export PING_IDENTITY_ACCEPT_EULA Y
# So rubygems native extension builds can find macOS headers
set --export SDKROOT (xcrun --show-sdk-path)

# ls command colors - http://osxdaily.com/2013/02/05/improve-terminal-appearance-mac-os-x/
set --export CLICOLOR 1
set --export LSCOLORS ExFxBxDxCxegedabagacad

# Lower case
set --export github_user phatblat
set --export powerline_enabled 0
set --global --export sdkman_prefix $HOME/.sdkman

# Fix spacing for emoji and ambiguous characters
set -xg fish_emoji_width 2
set -xg fish_ambiguous_width 2

# OMF bobthefish theme options
# https://github.com/oh-my-fish/theme-bobthefish#readme
set -g theme_display_git yes
set -g theme_display_git_dirty yes
set -g theme_display_git_untracked yes
set -g theme_display_git_ahead_verbose yes
set -g theme_display_git_dirty_verbose yes
set -g theme_display_git_stashed_verbose yes
set -g theme_display_git_default_branch yes
set -g theme_git_default_branches master main
# https://github.com/oh-my-fish/theme-bobthefish/issues/249
set -g theme_git_worktree_support no
set -g theme_use_abbreviated_branch_name yes
set -g theme_display_vagrant yes
set -g theme_display_docker_machine yes
set -g theme_display_k8s_context yes
set -g theme_display_k8s_namespace yes
set -g theme_display_hg yes
set -g theme_display_virtualenv yes
set -g theme_display_ruby yes
set -g theme_display_user ssh
set -g theme_display_hostname ssh
set -g theme_display_vi yes
set -g theme_display_node yes
set -g theme_display_date yes
set -g theme_display_cmd_duration yes
set -g theme_title_display_process yes
set -g theme_title_display_path no
set -g theme_title_use_abbreviated_path no
set -g theme_date_format "+%a %H:%M"
# set -g theme_date_timezone America/Los_Angeles
set -g theme_avoid_ambiguous_glyphs yes
set -g theme_powerline_fonts yes
set -g theme_nerd_fonts yes
set -g theme_show_exit_status yes
set -g theme_display_jobs_verbose yes
set -g default_user phatblat
# Color options
# dark. The default bobthefish theme.
# light. A lighter version of the default theme.
# solarized (or solarized-dark), solarized-light. Dark and light variants of Solarized.
# base16 (or base16-dark), base16-light. Dark and light variants of the default Base16 theme.
# zenburn. An adaptation of Zenburn.
# gruvbox. An adaptation of gruvbox.
# dracula. An adaptation of dracula.
# nord. An adaptation of nord.
set -g theme_color_scheme dracula
set -g fish_prompt_pwd_dir_length 0
set -g theme_project_dir_length 1
set -g theme_newline_cursor no
set -g theme_newline_prompt '$ '

# OMF danger theme options
# https://github.com/oh-my-fish/theme-dangerous#readme
set -U fish_key_bindings fish_vi_key_bindings
set -U dangerous_nogreeting

# fish_user_paths
set --global fish_user_paths \
    /usr/local/sbin \
    (brew_home ruby)/bin \
    (brew_home sqlite)/bin \
    $fish_user_paths

# PATH
set --export --global PATH \
    $HOME/bin \
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

set --export --global SWIFT_TOOLCHAIN $HOME/src/swift/current
if test -d "$SWIFT_TOOLCHAIN"
    set --export --global PATH $PATH \
        $SWIFT_TOOLCHAIN/usr/bin
end

set --export --global SWIFTENV_ROOT $HOME/.swiftenv
set --export --global PATH $SWIFTENV_ROOT/bin $PATH
if which swiftenv > /dev/null
    status --is-interactive
    and source (swiftenv init - | psub)
end

if test -d "$ANDROID_HOME"
    set --export --global PATH \
        $ANDROID_HOME/tools/bin \
        $ANDROID_HOME/build-tools/* \
        $ANDROID_HOME/platform-tools \
        $PATH
end

set --export --global CHROME_DEPOT_TOOLS $HOME/dev/chromium/depot_tools
if test -d "$CHROME_DEPOT_TOOLS"
    set --export --global PATH $PATH \
        $CHROME_DEPOT_TOOLS
end

# Extra paths for budspencer omf theme
# https://github.com/oh-my-fish/oh-my-fish/blob/master/docs/Themes.md#budspencer
if is_mac
    and if is_coreutils
        set --export --global PATH /usr/local/opt/coreutils/libexec/gnubin $PATH
        set --export --global PATH /usr/local/opt/gnu-sed/libexec/gnubin $PATH
    end
end

# MongoDB Realm
set --export --global MONGODB_HOME $HOME/dev/mongodb/current
if test -d "$MONGODB_HOME"
    set --export --global PATH \
        "$MONGODB_HOME/bin" \
        $PATH
end

set --export NVM_DIR "$HOME/.nvm"
[ -s "(brew_home nvm)/nvm.sh" ] && . "/(brew_home nvm)/nvm.sh"  # This loads nvm
[ -s "(brew_home nvm)/etc/bash_completion.d/nvm" ] && . "(brew_home nvm)/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

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

# ls color formatting - LS_COLWIDTHS
#
# If this variable is set, it is considered to be a colon-delimited list of
# minimum column widths.  Unreasonable and insufficient widths are ignored
# (thus zero signifies a dynamically sized column).  Not all columns have
# changeable widths.  The fields are, in order: inode, block count,
# number of links, user name, group name, flags, file size, file name.
set --export LS_COLWIDTHS 0:10:0:10:0:0:10:0

# Java
setjdk
