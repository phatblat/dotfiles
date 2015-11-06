#!/usr/bin/env ruby
#-------------------------------------------------------------------------------
#
# xcode/register_device.rb
# Add devices to the Apple Developer Portal (because cupertino is broken)
# https://github.com/nomad/cupertino/issues/220#issuecomment-114537684
#
#-------------------------------------------------------------------------------

raise "Please use: `register_device UDID NAME USER [PASSWORD]`" unless ARGV.count >= 3

require 'spaceship'

Spaceship.login(ARGV, (ARGV[3] rescue nil))
Spaceship.device.create!(name: ARGV[1], udid: ARGV[0])
