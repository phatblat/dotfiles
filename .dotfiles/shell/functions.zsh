#-------------------------------------------------------------------------------
#
# shell/functions.zsh
# Miscellaneous command-line functions
#
#-------------------------------------------------------------------------------


# Shell Help
function bashman {
  man bash | less -p "^       $1 ";
}

# title
# Sets a descriptive title for the current Terminal tab
#
# NOTE: oh-my-zsh, loaded in antigen.zsh also defines a title function. This is loaded later because this file is alphabetically sorted after it.
# title is a shell function from /Users/ben/.antigen/repos/https-COLON--SLASH--SLASH-github.com-SLASH-robbyrussell-SLASH-oh-my-zsh.git/lib/termsupport.zsh
function title {
  if [[ -z $1 ]]; then
    echo "Missing title"
    echo 'usage: title Tab Name'
    return 1
  fi
  echo -ne "\033]0;"$*"\0007"
}

# Find
# usage: finds "search string" /base/dir
function finds {
  if [[ -z $1 ]]; then
    echo "Missing search term"
    echo 'usage: finds "search string" /base/dir'
    return 1
  fi
  glob="$1"

  base_dir="."
  if [[ -n "$2" ]]; then
    base_dir="$2"
  fi
  if [[ ! -a "${base_dir}" ]]; then
    echo "'${base_dir}' does not exist"
    return 2
  fi

  echo "glob: ${glob}"
  echo "base_dir: ${base_dir}"
  find "${base_dir}" -name "${glob}" -print
}

# bak
# Renames the first argument, either appending ".bak" or stripping that extension
# if already present.
# - $1 - The file or folder to rename
function bak {
  if [[ ! -a "$1" ]]; then
    echo "'$1' does not exist"
    return 1
  fi

  # > h
  # >      Remove a trailing pathname component, leaving the head.  This
  # >      works like `dirname'.
  # >
  # > r
  # >      Remove a filename extension of the form `.XXX', leaving the root
  # >      name.
  # >
  # > e
  # >      Remove all but the extension.
  # >
  # > t
  # >      Remove all leading pathname components, leaving the tail.  This
  # >      works like `basename'.
  # http://www.zsh.org/mla/users/2006/msg00239.html
  if [[ "${1:e}" == "bak" ]]; then
    # Remove the .bak extension
    mv "$1" "${1:r}"
    echo "Renamed to '${1:r}'"
  else
    # Append a .bak extension
    mv "$1" "$1.bak"
    echo "Renamed to '$1.bak'"
  fi
}

OPENSSL_VERSION="1.0.2k"
OPENSSL_PATH="/usr/local/Cellar/openssl/${OPENSSL_VERSION}/bin/openssl"

function showcerts {
  local hostname="$1"
  local port="$2"

  if [[ -z "{$hostname}" ]]; then
    echo "Usage: savecerts hostname.com [443]"
    return 1
  fi

  if [[ -z "${port}" ]]; then
    # Set default port value
    port=443
  fi

  output=$("${OPENSSL_PATH}" s_client -connect "${hostname}":${port} -showcerts </dev/null 2>/dev/null)
  echo "${output}"
  return "${output}"
}

function savecerts {
  local hostname="$1"
  local port="$2"

  if [[ -z "{$hostname}" ]]; then
    echo "Usage: savecerts hostname.com [443]"
    return 1
  fi

  if [[ -z "${port}" ]]; then
    # Set default port value
    port=443
  fi

  # output=$(showcerts("${hostname}"))
  output=$("${OPENSSL_PATH}" s_client -connect "${hostname}":${port} -showcerts </dev/null 2>/dev/null)
  echo "${output}" | "${OPENSSL_PATH}" x509 -outform PEM >"${hostname}.pem"
}
