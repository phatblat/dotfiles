# realmos - Manage Realm Object Server
export def realmos [command: string = ""] {
    print "Realm Object Server"

    let ros_path = ($env.REALM_OBJECT_SERVER_PATH? | default "")
    if not ($ros_path | path exists) {
        error make { msg: $"No such path: ($ros_path)" }
    }

    match $command {
        "start" => {
            print $"Starting ROS at ($ros_path)"
            ^bash $"($ros_path)/start-object-server.command"
        }
        _ => {
            print "Usage: realmos [start]"
        }
    }
}
