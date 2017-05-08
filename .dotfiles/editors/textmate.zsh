#-------------------------------------------------------------------------------
#
# editors/textmate.zsh
# TextMate aliases
#
#-------------------------------------------------------------------------------

lj info 'editors/textmate.zsh'

function tminstall {
  local bundle_dev="${HOME}/dev/textmate"
  local bundle_home="${HOME}/Library/Application\ Support/TextMate/Bundles"

  if [[ ! -d "${bundle_dev}" ]]; then
    mkdir -p "${bundle_dev}"
  fi
  if [[ ! -d "${bundle_home}" ]]; then
    mkdir -p "${bundle_home}"
  fi

  for file in $*; do
    if [[ "${file:e}" != "tmbundle" && "${file:e}" != "tmTheme" ]]; then
      echo "${file} doesn't appear to be a TextMate bundle or theme"
      return 1
    fi

    cp -v "${file}" "${bundle_dev}"
    ln -s "${bundle_dev}/${file}" "${bundle_home}/${file}"
  done
}
