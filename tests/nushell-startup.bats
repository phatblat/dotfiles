#!/usr/bin/env bats
# Nushell startup regression tests

load helpers/setup

@test "nushell env prompt does not inherit zsh starship markers" {
  command_exists starship || skip "starship not installed"

  run nu --no-config-file -c "
    \$env.STARSHIP_SHELL = 'zsh'
    \$env.MISE_SHELL = 'zsh'
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
