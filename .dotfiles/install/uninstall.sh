#-------------------------------------------------------------------------------
#
# install/uninstall.sh
# Cleans up a botched dotfiles install.
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-uninstall"
echo

echo "WARNING: This script will remove dotfiles from your home directory ($HOME)."
echo "Are you sure you wish to continue? (select number)"
select number in "Yes" "No"; do
  case $number in
    Yes ) break;;
    No ) exit;;
  esac
done

rm -rfv "$HOME/.git"
rm -rfv "$HOME/.dotfiles"
rm -rfv "$HOME/.gitconfig"
rm -rfv "$HOME/tmp/dotfiles"
