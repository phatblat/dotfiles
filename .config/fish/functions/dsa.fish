function dsa \
    --description='Stops all running docker containers'

    echo "Running command to: Stop all running containers"
    set -l running_containers (docker container ls --all --quiet)
    if set --query running_containers[1]
        docker container stop $running_containers
    else
        echo "No containers found to stop"
    end
end
