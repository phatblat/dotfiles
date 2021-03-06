#-------------------------------------------------------------------------------
#
# install/install-cask-formulae.sh
# Repeatable script which installs macOS apps through Homebrew Cask (https://formulae.brew.sh/cask/)
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-cask-formulae"
echo

formulae=(
    atom
    charles
    cloudapp
    dayone-cli
    fauxpas
    geekbench
    github-desktop
    google-chrome
    gpgtools
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
    textmate
    webpquicklook
)

# TODO: Use reinstall?
brew cask install ${formulae[*]}
