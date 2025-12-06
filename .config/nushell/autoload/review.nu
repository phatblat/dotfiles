# Review a given commit, default: HEAD
export def review [commit?: string = "HEAD"] {
    let format = 'commit:    %Cgreen%H%Creset
date:      %Cgreen%ai%Creset
author:    %Cgreen%an%Creset <%Cgreen%ae%Creset>
committer: %Cgreen%cn%Creset <%Cgreen%ce%Creset>

    %s
'

    ^git log --max-count=1 $"--pretty=format:($format)" --stat --patch -m --unified=1 --no-prefix $commit
}
