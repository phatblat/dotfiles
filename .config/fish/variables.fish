#
# ~/.config/fish/variables.fish
# Dotfiles
#
# Exported variables in fish shell.
#

set --export GRADLE_HOME /usr/local/opt/gradle/libexec
set --export GRADLE_OPTS -Xmx1g
set --export GRADLE_HEAP_SPACE -Xmx1g
# TODO: Port gradledebug function
# set --export GRADLE_OPTS ${GRADLE_HEAP_SPACE} -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005
# set --export GRADLE_OPTS ${GRADLE_HEAP_SPACE}
set --export ANDROID_HOME /usr/local/opt/android-sdk
set --export GROOVY_HOME /usr/local/opt/groovy/libexec
set --export JAVA_OPTS "-Xms256m -Xmx512m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
set --export PATH ./bin ~/bin $PATH
set --export EDITOR vi # vim # mvim
set --export VISUAL mate # subl
set --export GPG_TTY (tty)
set --export TERM xterm-256color
set --export LANGUAGE en_US.UTF-8
set --export LANG en_US.UTF-8
set --export LC_ALL en_US.UTF-8
set --export LC_CTYPE en_US.UTF-8
set --export phatblat_imac /Users/phatblat.bak/
set --export phatblat_external /Volumes/ThunderBay/Users/phatblat/
set --export ARCHFLAGS "-arch x86_64"
set --export ICLOUD_HOME "$HOME/Library/Mobile Documents"
set --export ICLOUD_DRIVE "$ICLOUD_HOME/com~apple~CloudDocs"
