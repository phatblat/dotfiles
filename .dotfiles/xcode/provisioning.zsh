#-------------------------------------------------------------------------------
#
# xcode/provisioning.zsh
# Command-line aliases for working with provisioning profiles
#
#-------------------------------------------------------------------------------

alias provdir='open "${HOME}/Library/MobileDevice/Provisioning Profiles"'
alias plcat='plutil -convert xml1 -o /dev/stdout'
alias list_codesign_identities='security find-identity -v -p codesigning'
alias entitlements='codesign -d --entitlements :-'
alias print_profile='security cms -D -i'
alias codesign_verify="codesign --verify -vvvv -R='anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.1] exists and (certificate leaf[field.1.2.840.113635.100.6.1.2] exists or certificate leaf[field.1.2.840.113635.100.6.1.4] exists)'"
