#-------------------------------------------------------------------------------
#
# shell/gpg.zsh
# GPG command-line aliases
#
#-------------------------------------------------------------------------------

alias gpgshow='gpg --list-keys'

function gpgcopypub {
  output=$(gpg --list-keys | head -n 3 | tail -n 1)
  # tokens=${output/\// }
  # Split on spaces
  key_info=${output[(ws: :)2]}
  echo $key_info
  # Split on slash
  key=${key_info[(ws:/:)2]}
  gpg_key_ascii=$(gpg --armor --export $key)
  echo $gpg_key_ascii | pbcopy $gpg_key_ascii
  echo "GPG key copied to pasteboard"
}
