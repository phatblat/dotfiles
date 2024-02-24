function jftemplate \
    --description 'Create a new repo based on JenkinsfileTemplate' \
    --argument-names repoName

    if test -z $repoName
        error "Usage: jftemplate repoName"
        return 1
    end

    set -l baseDir ~/dev/mini
    set -l repoDir $baseDir/$repoName

    if test -d $repoDir
        error "$repoDir already exists"
        return 2
    end

    nav $baseDir
    clone git@github.com:LogDashG/JenkinsfileTemplate.git $repoName
    git remote rename origin template

    echo "✨ Creating repo LogDashG/$repoName"
    hub create --copy LogDashG/$repoName
    # --copy option puts new repo URL in pasteboard
    set -l url (pbpaste)

    git remote add origin $url
    publish origin
end
