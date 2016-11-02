#-------------------------------------------------------------------------------
#
# install/uninstall-brewcask.sh
# Repeatable script which removes macOS apps no longer desired.
#
#-------------------------------------------------------------------------------

echo
echo ">>> uninstall-brewcask"
echo

formulae=(
)

brew cask uninstall ${formulae[*]}
