function xcv --description='Displays the version of the currently selected Xcode.'
    set -l output (xcodebuild -version)

    set -l marketing_version (echo $output | awk '{print $2}')
    set -l build_version (echo $output | awk '{print $5}')
    set -l beta_version

    switch $build_version
        #    9.0    9.1  9.2   9.3   9.4
        case 9M136h 9B37 9C32c 9Q98q 9Q1004a
            set beta_version "beta 1 "
        case 9M137d 9B46 9C34b 9Q107o
            set beta_version "beta 2 "
        case 9M174d           9Q117m
            set beta_version "beta 3 "
        case 9M189t           9Q127n
            set beta_version "beta 4 "
        case 9M202q
            set beta_version "beta 5 "
        case 9M214v
            set beta_version "beta 6 "
        # 9.0 GA is the same build as the GM seed.
        # case 9A235
        #     set beta_version "GM seed "
    end

    echo "$marketing_version $beta_version($build_version)"
end
