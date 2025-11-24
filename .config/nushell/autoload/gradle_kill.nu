# Kills all running gradle processes
export def gradle_kill [] {
    let processes = (ps | where name =~ "gradle")
    $processes | each { |proc| print $proc }

    $processes | each { |proc|
        kill -9 $proc.pid
    }

    let lockfile = ($nu.home-path | path join ".gradle" "caches" "journal-1" "journal-1.lock")
    if ($lockfile | path exists) {
        rm -v $lockfile
    }
}
