function gradle_kill \
    --description='Kills all running gradle processes'

    psgrep gradle
    psgrep gradle | cut -w -f 2 | while read pid
        kill -9 $pid
    end
end
