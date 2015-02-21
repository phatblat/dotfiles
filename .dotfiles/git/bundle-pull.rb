#-------------------------------------------------------------------------------
#
# bundle.rb
# Functions for complex git-bundle actions
#
#-------------------------------------------------------------------------------

require 'pathname'
require 'net/ssh' # gem install net-ssh

# bundle-pull
#
# Usage: bundle-pull
#
# Ensure clean work tree before start, abort if dirty.
#
# - SSH in
# - stash changes (snapshot)
# - get HEAD SHA
# - git stash
# - get stash SHA
# - bundle create (& verify)
# - end SSH
# - git fetch OTHER_HOST $USER/REPO_PATH/BUNDLE_FILE bundle_branch
#   - User dir is used as root (so can't get to system files, less typing)
def bundle_pull()
  command = 'bundle-pull'

  # Ensure current dir is in a clean git repo
  if !`git rev-parse --is-inside-work-tree >/dev/null 2>&1`
      puts "The #{command} command must be run inside a git repo"
      return
  end

  # TODO: Remove ! when done testing
  if !`git status --porcelain`
      puts "The work tree is dirty, aborting."
      return
  end

  # determine remote_hostname
  username = ENV['USER']
  puts "username: #{username}"

  hostname = `hostname`
  case
      when 'octoair.local'
          remote_hostname = 'imac.local'
      when 'imac.local'
          remote_hostname = 'octoair.local'
  end
  puts "remote_hostname: #{remote_hostname}"

  # puts Dir.pwd
  if !Dir.pwd.start_with? "/Users/#{username}"
      puts 'This command can only be ran in your home directory.'
  end

  # SSH
  #
  # put commands to send to the remote Ruby here...
  # def CMDs = [
  #   '-v'
  # ]

  Net::SSH.start(remote_hostname, username) do |ssh|

    # remote_ruby = ssh.exec!('/usr/bin/which ruby').chomp
    # puts 'Using remote Ruby: "%s"' % remote_ruby

    # CMDs.each do |cmd|

    #   puts 'Sending: "%s"' % cmd

    #   stdout = ''
    #   ssh.exec!("#{ remote_ruby } #{ cmd }") do |channel, stream, data|
    #     stdout << data if stream == :stdout
    #   end

    #   puts 'Got: %s' % stdout
    #   puts
    # end

    stdout = ''
    ssh.exec!("pwd") do |channel, stream, data|
      stdout << data if stream == :stdout
    end

    puts stdout

  end

  # git snapshot
  # git stash save "snapshot: $(date)" && git stash apply "stash@{0}"

end

bundle_pull()
