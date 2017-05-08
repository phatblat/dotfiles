#
# ~/.config/fish/variables.fish
# Dotfiles
#
# Exported variables in fish shell.
#

set --export GRADLE_HOME /usr/local/opt/gradle/libexec
set --export GRADLE_OPTS -Xmx1g
set --export GRADLE_HEAP_SPACE -Xmx1g
set --export GRADLE_OPTS ${GRADLE_HEAP_SPACE} -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005
set --export GRADLE_OPTS ${GRADLE_HEAP_SPACE}
set --export JAVA_HOME $(/usr/libexec/java_home -v 1.6)
set --export JAVA_HOME $(/usr/libexec/java_home -v 1.7)
set --export JAVA_HOME $(/usr/libexec/java_home -v 1.8)
set --export ANDROID_HOME /usr/local/opt/android-sdk
set --export GROOVY_HOME /usr/local/opt/groovy/libexec
set --export JAVA_HOME `${java_home_finder}`
set --export JAVA_OPTS -Xms256m -Xmx512m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m
set --export RBENV_ROOT ${HOME}/.rbenv
set --export PATH ${PATH}:${RBENV_ROOT}/versions/$ruby_version/bin
set --export _ANTIGEN_CACHE_PATH ${ANTIGEN_BASE_PATH}/.cache
set --export _ANTIGEN_LOG_PATH ${ANTIGEN_BASE_PATH}/antigen.log
set --export EDITOR vi
set --export VISUAL mate
set --export GPG_TTY $(tty)
set --export ZSH $HOME/.oh-my-zsh
set --export UPDATE_ZSH_DAYS 13
set --export EDITOR vim
set --export EDITOR mvim
set --export TERM xterm-256color
set --export LANGUAGE en_US.UTF-8
set --export LANG en_US.UTF-8
set --export LC_ALL en_US.UTF-8
set --export LC_CTYPE en_US.UTF-8
set --export PATH ./bin:~/bin:${PATH}
set --export phatblat_imac /Users/phatblat.bak/
set --export phatblat_external /Volumes/ThunderBay/Users/phatblat/
set --export ARCHFLAGS -arch x86_64