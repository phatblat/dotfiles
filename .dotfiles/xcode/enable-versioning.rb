#!/usr/bin/ruby

require 'rubygems'
require 'zerg_xcode' # https://github.com/zerglings/zerg_xcode

project = ZergXcode.load(".")
# puts project.attrs

build_configurations = project["buildConfigurationList"]["buildConfigurations"]
build_settings = build_configurations[0]["buildSettings"]

# Project level versioning system
if (build_settings["VERSIONING_SYSTEM"]) then
    puts "Versioning is already enabled at the project level"
    puts "    VERSIONING_SYSTEM: " + build_settings["VERSIONING_SYSTEM"]
else
    build_configurations.each do |config|
        config["buildSettings"]["VERSIONING_SYSTEM"] = "apple-generic"
    end
    project.save!
    puts "Versioning system set to " + build_settings["VERSIONING_SYSTEM"]
end

# Project version at project level
if (build_settings["CURRENT_PROJECT_VERSION"]) then
    puts "Project version is already set"
    puts "    CURRENT_PROJECT_VERSION: " + build_settings["CURRENT_PROJECT_VERSION"]
else
    build_configurations.each do |config|
        config["buildSettings"]["CURRENT_PROJECT_VERSION"] = "1"
    end
    project.save!
    puts "Project version set to " + build_settings["CURRENT_PROJECT_VERSION"]
end

