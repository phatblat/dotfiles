#-------------------------------------------------------------------------------
#
# install/uninstall.sh
# Cleans up a botched dotfiles install.
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-uninstall"
echo

echo "WARNING: This script will remove dotfiles from your home directory."
echo "Are you sure you wish to continue?"
select yn in "Yes" "No"; do
  case $yn in
    Yes ) break;;
    No ) exit;;
  esac
done

rm -rf "${HOME}/.git"
rm -rf "${HOME}/.dotfiles"
rm -rf "${HOME}/tmp/dotfiles"
