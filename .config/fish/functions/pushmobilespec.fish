# Pushes a podspec to KPMobileSpecs.
function pushmobilespec --argument-names spec_file
    if test -z $spec_file
        # Attempt to locate spec in current dir when not file name provided
        set -l specs (ls -1 *.podspec | paste -sd " " -)
        set -l spec_count (count $specs)

        # If specs does not contain an array, spec_count will be a char count
        # if [[ ! $(declare -p specs 2> /dev/null | grep -q '^typeset \-a') ]]; then
        if test spec_count -eq 1
            set spec_file $specs
        else if test $spec_count -eq 0
            echo "No podspecs found in the current directory."
           return 1
        else
            echo "Multiple podspecs found in the current directory (${spec_count}). Please specify which spec you would like to publish.\n  pushmobilespec Pod.podspec"
            return 2
        end
    end

    set -l spec_repo_name "KPMobileSpecs"

    bundle exec "pod repo push \
        $spec_repo_name \
        $spec_file \
        --sources=git@github.kp.org:internal-pods/specs,git@github.kp.org:mirrored-pods/specs,git@github.kp.org:F978034/KPMobileSpecs \
        --use-libraries \
        --private \
        --allow-warnings \
        $argv"
end
