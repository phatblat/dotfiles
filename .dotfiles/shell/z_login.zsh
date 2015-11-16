#-------------------------------------------------------------------------------
#
# shell/z_login.zsh
# Commands to be run for each terminal "login"
#
#-------------------------------------------------------------------------------

# Window title - for Timing.app <https://itunes.apple.com/us/app/timing/id431511738?mt=12>
echo -ne "\e]1;${USER}@${HOST%%.*}:${PWD/#$HOME/~}\a"

# SSH - Print out the fingerprint and comment of the default public key for this user@host
sshkeyfingerprint
if (( $? != 0 )); then
	echo "No SSH key found"
	sshnewkey "${USER}@${HOST}"
fi

# Antigen
local antigen_dir="~/dev/shell/antigen"

# Install antigen
if [ ! -d "$antigen_dir" ]; then
	echo "*** Installing antigen"
	git clone https://github.com/zsh-users/antigen.git "$antigen_dir"
fi

source "$antigen_dir/antigen.zsh"
antigen use oh-my-zsh
# Override the oh-my-zsh 'd' alias
unalias d && alias d='git diff'

# Antigen Bundles
antigen bundle common-aliases
# antigen bundle nojhan/liquidprompt
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle robbyrussell/oh-my-zsh plugins/ruby

# Antigen Themes
antigen theme gnzh

antigen apply

# Setup prompt, must be called after antigen is configured
install_powerline_prompt
