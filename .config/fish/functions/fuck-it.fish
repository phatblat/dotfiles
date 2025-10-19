#!/usr/bin/env fish
# When you had enough
function fuck-it
    set --export THEFUCK_REQUIRE_CONFIRMATION=False
    fuck
    set --export THEFUCK_REQUIRE_CONFIRMATION=True
end
