function gradle_cache_clean \
    --description 'Cleans the gradle cache'

    # not init.d/ wrappers/ or gradle.properties
    set --local folders \
                    7.5.1 \
                    android \
                    build-scan-data \
                    buildOutputCleanup \
                    caches \
                    daemon \
                    jdks \
                    kotlin-profile \
                    native \
                    notifications \
                    undefined-build \
                    vcs-1 \
                    workers \
                    android.lock \
                    file-system.probe

    for folder in $folders
        echo $folder
        if test -z "$folder"
            error "$folder is empty"
        end
        rm -rf ~/.gradle/$folder
    end
end
