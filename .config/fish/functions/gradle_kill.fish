function gradle_kill \
    --description 'Kills all running gradle processes'

    psgrep gradle
    psgrep gradle | cut -w -f 2 | while read pid
        kill -9 $pid
    end

    set -l lockfile ~/.gradle/caches/journal-1/journal-1.lock
    if test -f lockfile
        then
        rm -v $lockfile
    end
end
