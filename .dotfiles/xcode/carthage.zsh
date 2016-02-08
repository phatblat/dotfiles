#-------------------------------------------------------------------------------
#
# ios/carthage.zsh
# Carthage aliases
#
#-------------------------------------------------------------------------------
alias carthage-clean='rm -rf ~/Library/Caches/org.carthage.CarthageKit'

# Bootstrap
alias cbootios='carthage bootstrap --no-use-binaries --platform iOS'

# Checkout / Update
alias cco='carthage checkout --no-use-binaries'
alias ccos='cco --use-ssh'
alias ccoss='ccos --use-submodules'
alias ccu='carthage update --no-use-binaries --no-build'
alias ccus='ccu --use-ssh'
alias ccuss='ccus --use-submodules'

# Build
alias cbios="carthage build --platform iOS"
alias cbmac="carthage build --platform Mac"
alias cball="carthage build --platform all"

# Verbose variants
alias ccov='cco --verbose'
alias ccuv='ccu --verbose'
alias cbiosv="cbios --verbose"
alias cbmacv="cbmac --verbose"
alias cballv="cball --verbose"
