#-------------------------------------------------------------------------------
#
# install/update.sh
# Admin update script for common packages.
#
#-------------------------------------------------------------------------------

echo ">>> install-update"
echo

# Xcode
xcode-select -p

# Homebrew (admins only)
dsmemberutil checkmembership -U "${USER}" -G "admin"
if [[ $? -eq 0 ]]; then
  brew update && brew upgrade
fi
