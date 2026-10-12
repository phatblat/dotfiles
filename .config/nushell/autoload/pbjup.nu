# pbjup - Upgrade personal jenkins formula and restart service
export def pbjup [] {
    ^brew update
    ^brew upgrade pbjenkins
    print "♻️ 👷🏻‍♂️ Restarting jenkins using admin privileges"
    ^sudo launchctl kickstart -kp system/pbjenkins
}
