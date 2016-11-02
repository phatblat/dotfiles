#-------------------------------------------------------------------------------
#
# install/install-brewcask.sh
# Repeatable script which installs macOS apps through Homebrew Cask (http://caskroom.io)
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-brewcask"
echo

formulae=(
    atom
    charles
    dayone-cli
    geekbench
    github-desktop
    google-chrome
    hipchat
    ios-console
    istat-menus
    iterm2
    kaleidoscope
    macdown
    quickradar
    simpholders
    sublime-text
    textexpander
    things
    tower

    # QuickLook plugins
    betterzipql
    cocoapods
    provisioning
    qlcolorcode
    qlimagesize
    qlmarkdown
    qlprettypatch
    qlstephen   # preview files without an extension as text
    quicklook-csv
    quicklook-json
    webpquicklook
)

brew cask install ${formulae[*]}
