# 
function showcerts
      local hostname="$1"
  local port="$2"

  if [[ -z "{$hostname}" ]]; then
    echo "Usage: savecerts hostname.com [443]"
    return 1
  fi

  if [[ -z "${port}" ]]; then
    # Set default port value
    port=443
  fi

  output=$("${OPENSSL_PATH}" s_client -connect "${hostname}":${port} -showcerts </dev/null 2>/dev/null)
  echo "${output}"
  return "${output}" $argv
end
