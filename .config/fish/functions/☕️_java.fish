# http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
# https://support.apple.com/kb/dl1572?locale=en_US
#
# Redirects
# 1. https://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-macosx-x64.dmg
# 2. https://edelivery.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-macosx-x64.dmg
# 3. http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-macosx-x64.dmg?AuthParam=1494782728_c178605a1daa320f359ffa3d47b0cc2d
#
# Cookie set by JavaScript after clicking the "Agree" radio button
# - oraclelicense	accept-securebackup-cookie	.oracle.com	/	5/14/2017, 11:56:38 AM	39 B
#
# Notes:
# - `java_version` and `download_url` both need to be manually updated
#
# Sequencing
# - After: brew (has newer curl)
function ☕️__java \
    --description='Installs and updates the Java SDK.'

    echo "☕️  Java"
    echo

    set -l java_version 1.8.0_131

    # Check to see if update is necessary
    if test "$java_version" = (jv)
        showjdks
        return
    end

    set -l download_url http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-macosx-x64.dmg
    set -l dmg_file (basename $download_url)

    pushd ~/Downloads

    # Download
    curl_download --cookie oraclelicense=accept-securebackup-cookie $download_url

    # Mount the .dmg
    # -nobrowse          render any volumes invisible in applications such as the macOS Finder.
    set -l output (hdiutil attach $dmg_file)

    # Mount pout is the first column of the last line of output from hdiutil
    # Example:
    # expected   CRC32 $09D78DD5
    # /dev/disk2              GUID_partition_scheme
    # /dev/disk2s1            Apple_HFS                          /Volumes/JDK 8 Update 131
    set -l mount_point (col1 $output[-1])
    ls -o /Volumes/JDK*/JDK*.pkg

    # Run the install package
    sudo installer -target / -pkg /Volumes/JDK*/JDK*.pkg

    # Unmount the install volume
    hdiutil detach $mount_point

    # Switch active JDK
    showjdks
    setjdk 1.8

    # Show version info
    whichjdk
    java -version

    popd
end
