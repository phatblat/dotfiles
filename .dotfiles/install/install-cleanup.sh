#-------------------------------------------------------------------------------
#
# install/install-cleanup.sh
# Cleans up a botched dotfiles install.
#
#-------------------------------------------------------------------------------

echo "WARNING: This script will delete dotfiles in your home directory."
echo "Are you sure you wish to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

rm -rf "${HOME}/.dotfiles"
rm -rf "${HOME}/.git"
