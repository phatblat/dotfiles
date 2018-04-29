#!/usr/bin/ruby
#-------------------------------------------------------------------------------
#
# xcode/enable-versioning.rb
# Sets VERSIONING_SYSTEM to "apple-generic" and sets an initial
# CURRENT_PROJECT_VERSION so that agvtool can be used to manage the versions
# for the project located in the current directory.
#
#-------------------------------------------------------------------------------

require 'rubygems'
require 'xcodeproj' # https://github.com/CocoaPods/Xcodeproj

# Find.find('.') do |path|
#   project_path = path if path =~ /.*\.xcodeproj$/
# end

project_path = Dir.glob("*.xcodeproj").first

if (!project_path) then
  puts "No Xcode projects found in the current directory."
  return
end

puts project_path

project = Xcodeproj::Project.open(project_path)

currentVersioningSystem = project.build_configuration_list.get_setting("VERSIONING_SYSTEM")["Debug"]
currentProjectVersion = project.build_configuration_list.get_setting("CURRENT_PROJECT_VERSION")["Debug"]

# Project level versioning system
if (currentVersioningSystem) then
  puts "Versioning is already enabled at the project level"
  puts "    VERSIONING_SYSTEM: #{currentVersioningSystem}"
else
  project.build_configuration_list.set_setting "VERSIONING_SYSTEM", "apple-generic"
  project.save
  currentVersioningSystem = project.build_configuration_list.get_setting("VERSIONING_SYSTEM")["Debug"]
  puts "Versioning system set to #{currentVersioningSystem}"
end

# Project version at project level
if (currentProjectVersion) then
  puts "Project version is already set"
  puts "    CURRENT_PROJECT_VERSION: #{currentProjectVersion}"
else
  project.build_configuration_list.set_setting "CURRENT_PROJECT_VERSION", "1"
  project.save
  currentProjectVersion = project.build_configuration_list.get_setting("CURRENT_PROJECT_VERSION")["Debug"]
  puts "Project version set to #{currentProjectVersion}"
end
