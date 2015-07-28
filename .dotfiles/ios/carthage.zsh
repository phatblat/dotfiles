#-------------------------------------------------------------------------------
#
# ios/carthage.zsh
# Carthage aliases
#
#-------------------------------------------------------------------------------
alias carthage-clean='rm -rf ~/Library/Caches/org.carthage.CarthageKit'

# Checkout / Update
alias cco='carthage checkout --use-submodules --no-use-binaries'
alias ccu='carthage update --use-submodules --no-use-binaries --no-build'

# Build
alias cbios="carthage build --platform iOS"
alias cbmac="carthage build --platform Mac"
alias cball="carthage build --platform all"

# Verbose variants
alias cbiosv="cbios --verbose"
alias cbmacv="cbmac --verbose"
alias cballv="cball --verbose"

