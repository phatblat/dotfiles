#!/usr/bin/env fish
# Runs powerline-lint on custom config only.
#
# powerline-lint options:
#
# -p PATH, --config-path PATH
#                       Paths where configuration should be checked, in order.
#                       You must supply all paths necessary for powerline to
#                       work, checking partial (e.g. only user overrides)
#                       configuration is not supported.
# -d, --debug           Display additional information. Used for debugging
#                       `powerline-lint' itself, not for debugging
#                       configuration.
function pllint
    powerline-lint --config-path ~/.config/powerline
end
