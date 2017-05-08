# 
function gradledebug
      if [[ -z "${GRADLE_OPTS}" || $1 == "on" ]]; then
    export GRADLE_OPTS="${GRADLE_HEAP_SPACE} -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"
    echo "Gradle debugging on"
    echo "GRADLE_OPTS: ${GRADLE_OPTS}"
  else
    export GRADLE_OPTS="${GRADLE_HEAP_SPACE}"
    echo "Gradle debugging off"
  fi $argv
end
