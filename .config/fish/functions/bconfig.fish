#!/usr/bin/env fish
# Configures Bundler.
function bconfig
    bundle config --local clean true
    bundle config --local disable_shared_gems true
    bundle config --local path .rubygems
    bundle config --local bin bin
    bundle config --local jobs 8
end
