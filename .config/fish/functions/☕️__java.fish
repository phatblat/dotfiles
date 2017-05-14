# Installs and updates the Java SDK.
# http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
# https://support.apple.com/kb/dl1572?locale=en_US
#
# Redirects
# 1.  https://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-macosx-x64.dmg
# 2.  https://edelivery.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-macosx-x64.dmg
# 3.  http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-macosx-x64.dmg?AuthParam=1494782728_c178605a1daa320f359ffa3d47b0cc2d
#
# Cookie set by JavaScript after clicking the "Agree" radio button
# - oraclelicense	accept-securebackup-cookie	.oracle.com	/	5/14/2017, 11:56:38 AM	39 B
#
# Sequencing
# - After: brew (has newer curl)
function ☕️__java
    echo "☕️  Java"
    echo

    set -l download_url http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-macosx-x64.dmg
    set -l dmg_file (basename $download_url)

    pushd ~/Downloads

    # Download
    curl_download --cookie oraclelicense=accept-securebackup-cookie $download_url

    # Mount the .dmg
    hdiutil attach $dmg_file
    ls -o /Volumes/JDK*/JDK*.pkg

    # Run the install package
    sudo installer -target / -pkg /Volumes/JDK*/JDK*.pkg

    # Switch active JDK
    showjdks
    setjdk 1.8

    # Show version info
    whichjdk
    java -version

    popd
end
