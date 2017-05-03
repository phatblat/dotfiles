#-------------------------------------------------------------------------------
#
# shell/gpg.zsh
# GPG command-line aliases
#
#-------------------------------------------------------------------------------

lj info 'shell/gpg.zsh'

# Fix for gpg2
# https://www.gnupg.org/(it)/documentation/manuals/gnupg/Common-Problems.html
export GPG_TTY=$(tty)

alias gpgshow='gpg --list-keys --keyid-format long'
alias gpgkeyid='gpg --list-keys --keyid-format long | egrep -o "^pub.*/\w+" | cut -d "/" -f 2'

function gpgcopypub {
  keyid=$(gpgkeyid)
  gpg_key_ascii=$(gpg --armor --export ${keyid})
  echo ${gpg_key_ascii} | pbcopy
  echo "GPG key copied to pasteboard (keyid: ${keyid})"
}
