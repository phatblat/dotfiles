#!/usr/bin/env ruby
#-------------------------------------------------------------------------------
#
# xcode/new_project.rb
# Creates a new Xcode project
# http://rubydoc.info/gems/xcodeproj/Xcodeproj/Project
#
#-------------------------------------------------------------------------------

require 'fileutils'
require 'xcodeproj'

puts Dir.pwd

# Collect information
product_name = 'App'
target_name = product_name
project_name = "#{target_name}.xcodeproj"
workspace_name = "#{target_name}.xcworkspace"
deployment_target = '9.0'

# Testing: Clean previous project
FileUtils.rm_rf(project_name)
FileUtils.rm_rf(workspace_name)

# Create the project with structure:
#   App.xcodeproj/project.pbxproj
#   App.xcodeproj/project.xcworkspace/contents.xcworkspacedata
#   App/AppDelegate.swift
#   App/Assets.xcassets/AppIcon.appiconset/Contents.json
#   App/Base.lproj/LaunchScreen.storyboard
#   App/Base.lproj/Main.storyboard
#   App/Info.plist
#   App/ViewController.swift
#   AppTests/AppTests.swift
#   AppTests/Info.plist
#   AppUITests/AppUITests.swift
#   AppUITests/Info.plist

puts "Creating project #{project_name}"
project = Xcodeproj::Project.new(project_name)

app_target = project.new_target(:application, target_name, :ios, deployment_target)

header_ref = project.main_group.new_file('./Class.h')
implm_ref = project.main_group.new_file('./Class.m')
app_target.add_file_references([implm_ref])

project.save(project_name)

puts "Creating workspace #{workspace_name}"
workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspace_name)
workspace.save_as(workspace_name)
