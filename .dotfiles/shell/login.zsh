git fetch -v

# SSH
sshkeyfingerprint
if (( $? != 0 )); then
	echo "No SSH key found"
	sshnewkey "${USER}@${HOST}"
fi
