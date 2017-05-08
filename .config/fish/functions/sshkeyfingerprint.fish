# 
function sshkeyfingerprint
      file=~/.ssh/id_rsa.pub;
  if (($+1)); then
    file="$1"
  fi

  echo -n "sshkeyfingerprint [${file}] "
  ssh-keygen -lf "${file}"; $argv
end
