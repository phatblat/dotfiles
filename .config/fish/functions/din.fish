function din \
    --description 'Remove all docker images'

    echo "Running command to: Remove all Docker images"

    # Prune unused images
    dip

    set -l images (docker image ls --format '{{.ID}}')
    if set --query images[1]
        docker image rm $images
    else
        echo "***No images present to remove***"
    end
end
