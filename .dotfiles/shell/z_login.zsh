#-------------------------------------------------------------------------------
#
# shell/z_login.zsh
# Commands to be run for each terminal "login"
#
#-------------------------------------------------------------------------------

# Window title - for Timing.app <https://itunes.apple.com/us/app/timing/id431511738?mt=12>
echo -ne "\e]1;${USER}@${HOST%%.*}:${PWD/#$HOME/~}\a"

# SSH - Print out the fingerprint and comment of the default public key for this user@host
# sshkeyfingerprint
if (( $? != 0 )); then
  echo "No SSH key found"
  sshnewkey "${USER}@${HOST}"
fi

# Setup prompt, must be called after antigen is configured
install_powerline_prompt
