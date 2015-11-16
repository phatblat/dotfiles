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
local antigen_dir="$(brew --prefix)/Cellar/antigen/1/share"
source "${antigen_dir}/antigen.zsh"
antigen use oh-my-zsh
# Override the oh-my-zsh 'd' alias
unalias d && alias d='git diff'

# Antigen Bundles
antigen bundle common-aliases
antigen bundle milkbikis/powerline-shell
antigen bundle robbyrussell/oh-my-zsh plugins/ruby
antigen bundle zsh-users/zsh-syntax-highlighting

# Antigen Themes
antigen theme gnzh

antigen apply

# Setup prompt, must be called after antigen is configured
install_powerline_prompt
