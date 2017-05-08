# 
function gpgcopypub
      keyid=$(gpgkeyid)
  gpg_key_ascii=$(gpg --armor --export ${keyid})
  echo ${gpg_key_ascii} | pbcopy
  echo "GPG key copied to pasteboard (keyid: ${keyid})" $argv
end
