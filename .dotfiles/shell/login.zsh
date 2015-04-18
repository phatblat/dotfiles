# Window title - for Timing.app <https://itunes.apple.com/us/app/timing/id431511738?mt=12>
echo -ne "\e]1;${USER}@${HOST%%.*}:${PWD/#$HOME/~}\a"

# SSH - Print out the fingerprint and comment of the default public key for this user@host
sshkeyfingerprint
if (( $? != 0 )); then
	echo "No SSH key found"
	sshnewkey "${USER}@${HOST}"
fi

# Update .dotfiles
# Check the time since the last fetch, continue if more than an hour
function fetch_dotfiles() {
	local current=`date +%s`
	local last_modified=$(stat -f "%c" $HOME/.git/FETCH_HEAD)

	# 3600 seconds in an hour
	if [ "$(($current - $last_modified))" -gt 3600 ]; then
		git fetch -v
	fi
}
#fetch_dotfiles
