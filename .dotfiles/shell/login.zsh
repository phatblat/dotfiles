# SSH
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
fetch_dotfiles
