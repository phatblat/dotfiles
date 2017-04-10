#-------------------------------------------------------------------------------
#
# install/uninstall-brew-formulae.sh
# Repeatable script which removes command-line tools no longer desired
#
#-------------------------------------------------------------------------------

echo
echo ">>> uninstall-brew-formulae"
echo

#-------------------------------------------------------------------------------

formulae=(
  hub
  pivotal/tap/cloudfoundry-cli
)

brew uninstall --force ${formulae[*]}
