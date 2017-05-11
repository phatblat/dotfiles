#
# ~/.config/fish/variables.fish
# Dotfiles
#
# Exported variables in fish shell.
#

# Editor
set --export EDITOR_CLI "vim" # vi vim
set --export EDITOR_GUI "mate" # subl atom mvim
set --export CLI_WAIT_FLAG "--remote-wait"
set --export GUI_WAIT_FLAG "-w"

# EDITOR or VISUAL, only one defined
if test -n "$SSH_CLIENT" -o -n "$SSH_TTY"
    set --export EDITOR $EDITOR_CLI
    set --export WAIT_FLAG $CLI_WAIT_FLAG
else
    set --export VISUAL $EDITOR_GUI
    set --export WAIT_FLAG $GUI_WAIT_FLAG
end

set --export ANDROID_HOME /usr/local/opt/android-sdk
set --export ARCHFLAGS "-arch x86_64"
set --export GPG_TTY (tty)
set --export GRADLE_HOME /usr/local/opt/gradle/libexec
set --export GRADLE_OPTS -Xmx1g
set --export GRADLE_HEAP_SPACE -Xmx1g
set --export GROOVY_HOME /usr/local/opt/groovy/libexec
set --export JAVA_HOME (/usr/libexec/java_home)
set --export JAVA_OPTS "-Xms256m -Xmx512m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
set --export ICLOUD_HOME "~/Library/Mobile Documents"
set --export ICLOUD_DRIVE $ICLOUD_HOME"/com~apple~CloudDocs"
set --export LANG en_US.UTF-8
set --export LANGUAGE en_US.UTF-8
set --export LC_ALL en_US.UTF-8
set --export LC_CTYPE en_US.UTF-8
set --export OPENSSL_VERSION (echo (brew info openssl)[1] | string split ' ')[3]
set --export OPENSSL_PATH "/usr/local/Cellar/openssl/$OPENSSL_VERSION/bin/openssl"
set --export PATH ./bin ~/bin $PATH
set --export TERM xterm-256color

# Obsolete rsync variables
set --export phatblat_imac /Users/phatblat.bak/
set --export phatblat_external /Volumes/ThunderBay/Users/phatblat/
