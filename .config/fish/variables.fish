
# ~/.config/fish/variables.fish
# Dotfiles
#
# Exported variables in fish shell.
#

set --global --export fish_greeting ''
set --global simple_ass_prompt_greeting "Fish Shell version $version"
set --export KERNEL (uname)

# Upper case
if is_mac
    set --export ANDROID_HOME $HOME/Library/Android/sdk
else if is_linux
    set --export ANDROID_HOME $HOME/Android/Sdk
end

if is_arm
    set --export ARCHFLAGS "-arch arm64"
else
    set --export ARCHFLAGS "-arch x86_64"
end

set --export XDG_CONFIG_HOME $HOME/.config

set --export GPG_TTY (tty)
set --export GRADLE_HOME (brew_home gradle)/libexec
set --export GROOVY_HOME (brew_home groovy)/libexec
set --export HOMEBREW_BAT (command --search bat)
set --export HOMEBREW_CLEANUP_MAX_AGE_DAYS 30
set --export HOMEBREW_NO_ENV_HINTS 1
set --export ICLOUD_HOME $HOME"/Library/Mobile Documents"
set --export ICLOUD_DRIVE $ICLOUD_HOME"/com~apple~CloudDocs"
set --export JABBA_HOME $HOME/.jabba
set --export LANG en_US.UTF-8
set --export LANGUAGE en_US.UTF-8
set --export LC_ALL en_US.UTF-8
set --export LC_CTYPE en_US.UTF-8
set --export PING_IDENTITY_DEVOPS_HOME $HOME/dev/ping/devops
set --export PING_IDENTITY_DEVOPS_REGISTRY docker.io/pingidentity
set --export PING_IDENTITY_DEVOPS_TAG edge
set --export PING_IDENTITY_ACCEPT_EULA Y

set --export CC_wasm32_unknown_unknown (brew_home)"/opt/llvm/bin/clang"

# OpenSSL
set --export OPENSSL_ROOT (brew_home openssl@3)
fish_add_path $OPENSSL_ROOT/bin
# For compilers to find openssl@3 you may need to set:
set --export --global LDFLAGS "-L$OPENSSL_ROOT/lib"
set --export --global CPPFLAGS "-I$OPENSSL_ROOT/include"
set --export --global PKG_CONFIG_PATH "$OPENSSL_ROOT/lib/pkgconfig"

# ls command colors - http://osxdaily.com/2013/02/05/improve-terminal-appearance-mac-os-x/
set --export CLICOLOR 1
set --export LSCOLORS ExFxBxDxCxegedabagacad

# Lower case
set --export github_user phatblat
set --export powerline_enabled 0
set --global --export sdkman_prefix $HOME/.sdkman

# Fix spacing for emoji and ambiguous characters
set --export --global fish_emoji_width 2
set --export --global fish_ambiguous_width 2

# OMF bobthefish theme options
# https://github.com/oh-my-fish/theme-bobthefish#readme
set --global theme_display_git yes
set --global theme_display_git_dirty yes
set --global theme_display_git_untracked yes
set --global theme_display_git_ahead_verbose yes
set --global theme_display_git_dirty_verbose yes
set --global theme_display_git_stashed_verbose yes
set --global theme_display_git_default_branch yes
set --global theme_git_default_branches master main
# https://github.com/oh-my-fish/theme-bobthefish/issues/249
set --global theme_git_worktree_support no
set --global theme_use_abbreviated_branch_name yes
set --global theme_display_vagrant yes
set --global theme_display_docker_machine yes
set --global theme_display_k8s_context yes
set --global theme_display_k8s_namespace yes
set --global theme_display_hg yes
set --global theme_display_virtualenv yes
set --global theme_display_ruby yes
set --global theme_display_user ssh
set --global theme_display_hostname ssh
set --global theme_display_vi yes
set --global theme_display_node yes
set --global theme_display_date yes
set --global theme_display_cmd_duration yes
set --global theme_title_display_process yes
set --global theme_title_display_path no
set --global theme_title_use_abbreviated_path no
set --global theme_date_format "+%a %H:%M"
# set --global theme_date_timezone America/Los_Angeles
set --global theme_avoid_ambiguous_glyphs yes
set --global theme_powerline_fonts yes
set --global theme_nerd_fonts yes
set --global theme_show_exit_status yes
set --global theme_display_jobs_verbose yes
set --global default_user phatblat
# Color options
# dark. The default bobthefish theme.
# light. A lighter version of the default theme.
# solarized (or solarized-dark), solarized-light. Dark and light variants of Solarized.
# base16 (or base16-dark), base16-light. Dark and light variants of the default Base16 theme.
# zenburn. An adaptation of Zenburn.
# gruvbox. An adaptation of gruvbox.
# dracula. An adaptation of dracula.
# nord. An adaptation of nord.
set --global theme_color_scheme dracula
set --global fish_prompt_pwd_dir_length 0
set --global theme_project_dir_length 1
set --global theme_newline_cursor no
set --global theme_newline_prompt '$ '

# OMF danger theme options
# https://github.com/oh-my-fish/theme-dangerous#readme
set -U fish_key_bindings fish_vi_key_bindings
set -U dangerous_nogreeting

# fish_user_paths
set --global fish_user_paths \
    /usr/local/sbin \
    (brew_home sqlite)/bin \
    $fish_user_paths

# PATH
set --export --global PATH \
    $HOME/bin \
    (brew_home)/bin \
    (brew_home curl)/bin \
    (brew_home python)/libexec/bin \
    /usr/local/bin \
    $PATH

# RVM
# if functions --query rvm
#     rvm default
# end

# Ruby
set --local brew_home (brew_home)
set --local ruby_home (brew_home ruby)
if test -d $ruby_home/bin
    fish_add_path $ruby_home/bin

    # set --export --global LDFLAGS "$LDFLAGS -L$ruby_home/lib"
    # set --export --global CFLAGS "-I $brew_home/include -I ext -I $ruby_home/include -L $brew_home/lib"
    # set --export --global CPPFLAGS $CFLAGS
    # set --export --global PKG_CONFIG_PATH "$PKG_CONFIG_PATH $ruby_home/lib/pkgconfig"
end

# Ruby Gems
set RUBY_VERSION 3.2.0
set -l GEM_PATH $ruby_home/lib/ruby/gems/$RUBY_VERSION/bin
if test -d $GEM_PATH
    fish_add_path $GEM_PATH
end

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

# set --export --global SWIFTENV_ROOT $HOME/.swiftenv
# set --export --global PATH $SWIFTENV_ROOT/bin $PATH
# if which swiftenv > /dev/null
#     status --is-interactive
#     and source (swiftenv init - | psub)
# end

# Xcode
set --export --global DERIVED_DATA $HOME/Library/Developer/Xcode/DerivedData

if test -d "$ANDROID_HOME"
    # Use the latest installed version of the build tools
    set --local BUILD_TOOLS_VERSION (ls -1r $ANDROID_HOME/build-tools/ | head -1)
    # NDK Versions
    # - 21.4.7075529
    # - 22.0.7026061
    # - 23.1.7779620
    # - 24.0.7956693
    # - 24.0.8215888
    # - 25.1.8937393
    set --export --global NDK_VERSION (ls -1r $ANDROID_HOME/ndk/ | head -1)
    set --export ANDROID_NDK_HOME $ANDROID_HOME/ndk/$NDK_VERSION

    set --export --global PATH \
        $ANDROID_HOME/cmdline-tools/latest/bin \
        $ANDROID_HOME/emulator \
        $ANDROID_HOME/tools \
        $ANDROID_HOME/tools/bin \
        $ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION \
        $ANDROID_HOME/platform-tools \
        $ANDROID_NDK_HOME \
        $PATH
end

# coreutils
if test -d (brew_home make)/libexec/gnubin
    fish_add_path (brew_home make)/libexec/gnubin
end

# rust/cargo
if test -d $HOME/.cargo/bin
    fish_add_path $HOME/.cargo/bin
end

# mint
if test -d $HOME/.mint/bin
    fish_add_path $HOME/.mint/bin
end

# chromium depot
set --export --global CHROME_DEPOT_TOOLS $HOME/dev/chromium/depot_tools
if test -d "$CHROME_DEPOT_TOOLS"
    set --export --global PATH $PATH \
        $CHROME_DEPOT_TOOLS
end

# Extra paths for budspencer omf theme
# https://github.com/oh-my-fish/oh-my-fish/blob/master/docs/Themes.md#budspencer
if is_mac
    and if is_coreutils
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

# set --export NVM_DIR "$HOME/.nvm"
# [ -s "(brew_home nvm)/nvm.sh" ] && . "/(brew_home nvm)/nvm.sh"  # This loads nvm
# [ -s "(brew_home nvm)/etc/bash_completion.d/nvm" ] && . "(brew_home nvm)/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Editor
# After variables which depend on functions that define variables
set --export EDITOR_CLI "vim" # vi vim
set --export EDITOR_GUI "windsurf --new-window" # code, cursor, void, windsurf
set --export WAIT_FLAG_CLI "--nofork"
set --export WAIT_FLAG_GUI "--wait"

# EDITOR or VISUAL, only one defined
# Use EDITOR for non-console users (su someoneelse) and SSH connections
if is_ssh; or not is_console_user
    set --export EDITOR $EDITOR_CLI
    set --export WAIT_FLAG $WAIT_FLAG_CLI
    set --erase VISUAL
else
    set --export VISUAL $EDITOR_GUI
    set --export WAIT_FLAG $WAIT_FLAG_GUI
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

# Java JDK
if is_mac
    # Use latest JDK
    if test -d "/Users/phatblat/Applications/Android Studio.app/Contents/jbr/Contents/Home"
        jdk studio
    else if test -d /Library/Java/JavaVirtualMachines/openjdk.jdk
        jdk set /Library/Java/JavaVirtualMachines/openjdk.jdk/Contents/Home
    else if test -d /Library/Java/JavaVirtualMachines/openjdk-17.jdk
        jdk set /Library/Java/JavaVirtualMachines/openjdk-17.jdk/Contents/Home
    else
        error "JDK dir not found"
    end
else if is_linux
    jdk set /home/linuxbrew/.linuxbrew/Cellar/openjdk/18.0.2.1
end

# .NET
if test -d $HOME/.dotnet/tools
    fish_add_path $HOME/.dotnet/tools
    set --export DOTNET_ROOT $HOME/.dotnet
end
set --export MONO_GAC_PREFIX (brew_home)

# Flutter/Dart
if test -d $HOME/.pub-cache/bin
    fish_add_path $HOME/.pub-cache/bin
end
if test -d $HOME/fvm/default/bin
    fish_add_path $HOME/fvm/default/bin
end

# Xamarin.iOS tools
set --local XAMARIN_IOS_BIN_DIR /Library/Frameworks/Xamarin.iOS.framework/Versions/Current/bin
if test -d $XAMARIN_IOS_BIN_DIR
    fish_add_path $XAMARIN_IOS_BIN_DIR
end

# Bun
set -Ux BUN_INSTALL $HOME/.bun
set -px --path PATH $HOME/.bun/bin

if is_mac
    set --export --global CMAKE_OSX_SYSROOT (xcode-select --print-path)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
    set --export --global CMAKE_BUILD_TYPE Debug
end

# Split on underscore to ignore the revision number
# find_package called with invalid argument "1.79.0_1"
set --export --global BOOST_VERSION (string split --fields 1 '_' (brew_active_version boost))
set --export --global BOOST_INCLUDE_DIR (brew_home)/include

# Nix
set --export --global NIX_PATH $HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels

# Go
# GOPATH is automatically set by mise, but we can set additional Go environment variables
set --export GOPRIVATE "github.com/phatblat/*"

# Ensure Go binaries are in PATH (this is handled by mise but we keep it for compatibility)
fish_add_path $HOME/go/bin

# Set GOPATH if not set by mise
if not set -q GOPATH
    set --export GOPATH $HOME/go
end
