function pdo \
    --description='Quick nav to Ping DevOps projects' \
    --argument-names project

    # Examples:
    # - pingidentity-devops-getting-started"
    # - pingidentity-docker-builds"
    # - pingidentity-server-profiles"

    echo $project

    if test -z $project
        nav $PING_IDENTITY_DEVOPS_HOME
        return
    end

    nav $PING_IDENTITY_DEVOPS_HOME/$project
end
