# > gradle --version                                                                                                              ⌚️ 17:04:40
#
# ------------------------------------------------------------
# Gradle 4.3
# ------------------------------------------------------------
#
# Build time:   2017-10-30 15:43:29 UTC
# Revision:     c684c202534c4138b51033b52d871939b8d38d72
#
# Groovy:       2.4.12
# Ant:          Apache Ant(TM) version 1.9.6 compiled on June 29 2015
# JVM:          1.8.0_111 (Oracle Corporation 25.111-b14)
# OS:           Mac OS X 10.13.1 x86_64
#
function gv --description 'Prints gradle version'
    set --local output (gradle --version)
    set --local gradle_version (string split " " $output[3])[2]
    echo $gradle_version
end
