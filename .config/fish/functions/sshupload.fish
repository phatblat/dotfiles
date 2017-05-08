# 
function sshupload
      keyfile="~/.ssh/id_rsa.pub"
  if (($+1)); then
    keyfile="$1"
  fi

  # Upload default SSH key to GitHub
  echo "Uploading SSH public key to GitHub [${keyfile}]"
  echo -n "GitHub OTP code: "
  read otpcode
  curl -X POST \
    --user "phatblat" \
    --header "X-GitHub-OTP: ${otpcode}" \
    --data "{\"title\":\"${USER}@${HOST}_$(date +%Y%m%d%H%M%S)\",\"key\":\"$(cat $keyfile)\"}" \
    --verbose \
    "https://api.github.com/user/keys" $argv
end
