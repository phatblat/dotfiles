#-------------------------------------------------------------------------------
#
# java/options.zsh
# Java Environment Options
# http://docs.ubmatrix.com/webhelp/xda/1_0_1/Configure_Java_Environment_Options_(JAVA_OPTS).htm
#
#-------------------------------------------------------------------------------

java_home_finder="/usr/libexec/java_home"
export JAVA_HOME=`${java_home_finder}`

if [ -z "${JAVA_HOME}" ]; then
  ${java_home_finder} --request
fi

export JAVA_OPTS="-Xms256m -Xmx512m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
