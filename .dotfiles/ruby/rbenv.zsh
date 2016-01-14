#-------------------------------------------------------------------------------
#
# RBENV
# ruby/rbenv.zsh
#
#-------------------------------------------------------------------------------
export RBENV_ROOT=${HOME}/.rbenv

if which -s rbenv > /dev/null; then eval "$(rbenv init -)"; fi

ruby_version_file="${RBENV_ROOT}/version"
if [[ -f $ruby_version_file ]]; then
  ruby_version=$(cat $ruby_version_file)
  # echo "ruby $ruby_version"
  export PATH=${PATH}:${RBENV_ROOT}/versions/$ruby_version/bin
fi
