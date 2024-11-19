function showgit_remote \
    --description='Searches for .git repos recursively below the current dir, printing remote URL'
    find . -type d -name .git $argv

    for git_dir in (showgit)
        set -l dir (dirname $git_dir)
        echo $dir
        pushd $dir
        grep url .git/config
        popd
    end
end
