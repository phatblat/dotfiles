#-------------------------------------------------------------------------------
#
# bundle.rb
# Functions for complex git-bundle actions
#
#-------------------------------------------------------------------------------

require 'pathname'
require 'net/ssh' # gem install net-ssh

require 'monads/monad'
# require 'monads/eventually'

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
    # '/usr/bin/which ruby -v',

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

    command_string = commands.join(" && ")
    output = ssh.exec!(command_string).chomp
    puts output

    # ssh.open_channel do |ch|

    #   # eventually = Eventually.new do |success|
    #   #   Thread.new do
    #   #     sleep 5
    #   #     success.call('hello world')
    #   #   end
    #   # end

    #   commands.each do |cmd|

    #     puts "sending: #{cmd}"
    #     channel_events(ch, cmd)

    #   end
    # end # ssh channel

  end

end # bundle_pull()

# Net::SSH::Connection::Channel, string
def channel_events(channel, cmd)
  stdout = ''
  channel.exec cmd do |channel, success|
    puts "cmd: #{cmd}"
    puts "channel: #{channel}, success: #{success}"

    channel.on_data do |channel, stream, data|
      # print data
      #stdout << data if stream == :stdout
      puts "got stdout: #{data}"

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

    abort "could not execute '#{cmd}'" unless success
  end
end

module Monads
  Eventually = Struct.new(:block) do
    include Monad

    def initialize(&block)
      super(block)
    end

    def run(&success)
      block.call(success)
    end

    def and_then(&block)
      block = ensure_monadic_result(&block)

      Eventually.new do |success|
        run do |value|
          block.call(value).run(&success)
        end
      end
    end

    def self.from_value(value)
      Eventually.new do |success|
        success.call(value)
      end
    end
  end
end

bundle_pull()
