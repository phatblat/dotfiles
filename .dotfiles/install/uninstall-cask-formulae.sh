#-------------------------------------------------------------------------------
#
# install/uninstall-cask-formulae.sh
# Repeatable script which removes macOS apps no longer desired.
#
#-------------------------------------------------------------------------------

echo
echo ">>> uninstall-cask-formulae"
echo

formulae=(
  battery-guardian
  cocoapods-app
)

brew cask uninstall ${formulae[*]}
