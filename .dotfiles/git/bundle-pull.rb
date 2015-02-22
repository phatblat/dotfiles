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
  # puts "username: #{username}"

  hostname = `hostname`
  case
      when 'octoair.local'
          remote_hostname = 'imac.local'
      when 'imac.local'
          remote_hostname = 'octoair.local'
  end
  # puts "remote_hostname: #{remote_hostname}"

  repo_path = Dir.pwd
  # puts repo_path
  if !repo_path.start_with? "/Users/#{username}"
      puts 'This command can only be ran under your home directory.'
  end

  # SSH
  puts "ssh://#{username}@#{remote_hostname}:#{repo_path}"

  # put commands to send to the remote Ruby here...
  commands = [
    '/usr/bin/which ruby -v',

    # Move into repo dir
    'pwd',
    "cd #{repo_path}",
    'pwd',

    # Snapshot
    'git stash list',
    'git stash list -p',
    'git stash save "snapshot: $(date)"',

    # Returns only the SHA of the last stash (will need the next one back in history in order to restore staging area status)
    "git show --abbrev-commit --oneline refs/stash@{0} | head -1 | awk '{print $1}'",

    # Restore the dirty work tree
    'git stash apply "stash@{0}"',
  ]

  Net::SSH.start(remote_hostname, username) do |ssh|

    remote_ruby = ssh.exec!('/usr/bin/which ruby').chomp
    puts "remote ruby: #{remote_ruby}"

    ssh.open_channel do |ch|
      commands.each do |cmd|

        puts "sending: #{cmd}"
        channel_events(ch, cmd)

      end
    end # ssh channel

  end

end # bundle_pull()

# Net::SSH::Connection::Channel, string
def channel_events(channel, cmd)
  stdout = ''
  channel.exec cmd do |channel, success|
    puts "cmd: #{cmd}"
    puts "channel: #{channel}, success: #{success}"
    abort "could not execute '#{cmd}'" unless success

    channel.on_data do |channel, stream, data|
      # print data
      stdout << data if stream == :stdout
      puts "got stdout: #{stdout}"

      # if data =~ /sudo password: /
      #   ch.send_data("password\n")
      # end
    end

    channel.on_extended_data do |ch, type, data|
      puts "got stderr: #{data}"
    end

    channel.on_close do |ch|
      puts "got stdout: #{stdout}"
      stdout = ''
    end
  end
end

bundle_pull()
