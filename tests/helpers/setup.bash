# setup.bash
# Common setup for bats tests

# Load bats test helpers if available
if [[ -f "${BATS_TEST_DIRNAME}/../../node_modules/bats-support/load.bash" ]]; then
  load "${BATS_TEST_DIRNAME}/../../node_modules/bats-support/load.bash"
fi

if [[ -f "${BATS_TEST_DIRNAME}/../../node_modules/bats-assert/load.bash" ]]; then
  load "${BATS_TEST_DIRNAME}/../../node_modules/bats-assert/load.bash"
fi

# Set up test environment
export HOME="${HOME:-/Users/phatblat}"
export PATH="${HOME}/bin:${PATH}"

# Helper to source a zsh function for testing
source_zsh_function() {
  local func_name="$1"
  local func_file="${HOME}/.config/zsh/functions/${func_name}"
  if [[ -f "$func_file" ]]; then
    # shellcheck source=/dev/null
    source "$func_file"
  else
    echo "Function file not found: $func_file" >&2
    return 1
  fi
}

# Helper to check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}
