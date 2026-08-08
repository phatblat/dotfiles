#!/usr/bin/env bats
# Nushell startup regression tests

load helpers/setup

@test "nushell env prompt does not inherit zsh starship markers" {
  command_exists starship || skip "starship not installed"

  # bats runs with TERM=dumb, which makes starship bail out before rendering.
  # Force a real terminal so the prompt path under test actually runs.
  #
  # nushell populates CMD_DURATION_MS and LAST_EXIT_CODE for a real prompt but
  # a bare -c invocation does not. Without them env.nu errors on a missing
  # column, and the test would only pass where a nushell login shell had
  # leaked them into the environment.
  run env TERM=xterm-256color nu --no-config-file -c "
    \$env.STARSHIP_SHELL = 'zsh'
    \$env.MISE_SHELL = 'zsh'
    \$env.CMD_DURATION_MS = '0'
    \$env.LAST_EXIT_CODE = 0
    source '$HOME/.config/nushell/env.nu'
    do \$env.PROMPT_COMMAND
  "

  [ "$status" -eq 0 ]
  [[ "$output" != *"%{"* ]]
  [[ "$output" != *"%}"* ]]
  [[ "$output" == *"nu"* ]]
}

@test "nushell startup files avoid version-sensitive str case aliases" {
  local forbidden='str (uppercase|lowercase|upcase|downcase)'

  run nu --no-config-file -c "
    let files = [
      '$HOME/.config/nushell/mise.nu'
      '$HOME/.config/nushell/autoload/toggle_wait.nu'
    ]

    let matches = (
      \$files
      | each {|file|
        open \$file
        | lines
        | enumerate
        | where item =~ '$forbidden'
        | each {|match| \$'(\$file):(\$match.index + 1):(\$match.item)' }
      }
      | flatten
    )

    if (\$matches | is-not-empty) {
      \$matches | str join (char newline)
      exit 1
    }
  "

  [ "$status" -eq 0 ]
}
