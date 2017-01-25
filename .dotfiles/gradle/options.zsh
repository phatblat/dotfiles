#-------------------------------------------------------------------------------
#
# gradle/options.zsh
# Gradle options management.
#
#-------------------------------------------------------------------------------


function gradledebug {
  if [[ -z "${GRADLE_OPTS}" || $1 == "on" ]]; then
    export GRADLE_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"
    echo "Gradle debugging on"
    echo "GRADLE_OPTS: ${GRADLE_OPTS}"
  else
    export GRADLE_OPTS=
    echo "Gradle debugging off"
  fi
}
