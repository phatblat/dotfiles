#!/usr/bin/env fish
# https://www.everythingcli.org/find-exec-vs-find-xargs/
# https://stackoverflow.com/questions/6958689/calling-multiple-commands-with-xargs/6958957#6958957
function cleanall \
    --description='Recursively cleans all Gradle projects under the current dir.'

    find . -type f -name gradlew -print0 | \
        xargs -0 sh -c 'for arg do pushd `dirname "$arg"`; ./gradlew clean; popd >/dev/null; done' _
end
