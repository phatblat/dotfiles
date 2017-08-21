function realmos --argument-names command
    echo Realm Object Server

    if not test -e $REALM_OBJECT_SERVER_PATH
        error No such path: $REALM_OBJECT_SERVER_PATH
        return 1
    end

    switch "$command"
    #     case 'status'
    #         error 'status' subcommand not implemented
        case start
            echo Starting ROS at $REALM_OBJECT_SERVER_PATH
            eval $REALM_OBJECT_SERVER_PATH/start-object-server.command
    #     case stop
    #         error 'stop' subcommand not implemented
        case '*'
            echo "Usage: realmos [status|start|stop]"
    end
end
