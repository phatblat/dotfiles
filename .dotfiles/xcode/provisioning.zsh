#-------------------------------------------------------------------------------
#
# xcode/provisioning.zsh
# Command-line aliases for working with provisioning profiles
#
#-------------------------------------------------------------------------------

lj info 'xcode/provisioning.zsh'

alias provdir='open "${HOME}/Library/MobileDevice/Provisioning Profiles"'
alias plcat='plutil -convert xml1 -o /dev/stdout'
alias list_codesign_identities='security find-identity -v -p codesigning'
alias entitlements='codesign -d --entitlements :-'
alias codesign_verify="codesign --verify -vvvv -R='anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.1] exists and (certificate leaf[field.1.2.840.113635.100.6.1.2] exists or certificate leaf[field.1.2.840.113635.100.6.1.4] exists)'"

# Prints the mobileprovision profile XML
alias print_profile='security cms -D -i'

# Parses the mobileprovision profile XML, extracting the UUID
function uuid_from_profile {
  print_profile $1 | grep UUID -A 1 | tail -n 1 | cut -d ">" -f 2 | cut -d "<" -f 1
}

function profile_id {
  if [[ $# -ne 1 ]]; then
    echo "Usage: profile_id AppProfile.mobileprovision"
    return 1
  fi

  egrep -a -A 2 UUID $1 | grep string | sed -e 's/<string>//' -e 's/<\/string>//' -e 's/[ 	]//'
}
