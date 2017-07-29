function xcv --description='Displays the version of the currently selected Xcode.'
    set -l output (xcodebuild -version)

    set -l marketing_version (echo $output | awk '{print $2}')
    set -l build_version (echo $output | awk '{print $5}')
    set -l beta_version

    switch $build_version
        case 9M136h
            set beta_version "beta 1 "
        case 9M137d
            set beta_version "beta 2 "
        case 9M174d
            set beta_version "beta 3 "
        case 9M189t
            set beta_version "beta 4 "
    end


    echo "$marketing_version $beta_version($build_version)"
end
