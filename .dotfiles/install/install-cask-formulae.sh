#-------------------------------------------------------------------------------
#
# install/install-cask-formulae.sh
# Repeatable script which installs macOS apps through Homebrew Cask (http://caskroom.io)
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-cask-formulae"
echo

formulae=(
    atom
    charles
    cocoapods-app
    dayone-cli
    fauxpas
    geekbench
    github-desktop
    google-chrome
    hipchat
    intellij-idea
    ios-console
    istat-menus
    iterm2
    kaleidoscope
    macdown
    oclint
    omnigraffle
    omnipresence
    quickradar
    simpholders
    sublime-text
    textexpander
    things
    tower
    virtualbox

    # QuickLook plugins
    betterzipql
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
