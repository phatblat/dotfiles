#!/usr/bin/env fish
# xcvmget
#
# Show a live list versions of Xcode versions available to download.
# https://github.com/KrauseFx/xcode-install/blob/bfc7d418606543d6c985a5ece21543b33c7abcd0/lib/xcode/install.rb#L218

# ruby
#      -e command     Specifies script from command-line while telling Ruby not to search the rest of the arguments for a script file name.
#      -r library     Causes Ruby to load the library using require.  It is useful when using -n or -p.
# require 'spaceship'

#  def spaceship
#       @spaceship ||= begin
#         begin
#           Spaceship.login(ENV['XCODE_INSTALL_USER'], ENV['XCODE_INSTALL_PASSWORD'])
#         rescue Spaceship::Client::InvalidUserCredentialsError
#           $stderr.puts 'The specified Apple developer account credentials are incorrect.'
#           exit(1)
#         rescue Spaceship::Client::NoUserCredentialsError
#           $stderr.puts <<-HELP
# Please provide your Apple developer account credentials via the
# XCODE_INSTALL_USER and XCODE_INSTALL_PASSWORD environment variables.
# HELP
#           exit(1)
#         end
#
#         if ENV.key?('XCODE_INSTALL_TEAM_ID')
#           Spaceship.client.team_id = ENV['XCODE_INSTALL_TEAM_ID']
#         end
#         Spaceship.client
#       end
#     end

# def fetch_seedlist
#   @xcodes = parse_seedlist(spaceship.send(:request, :get,
#                                           '/services-account/QH65B2/downloadws/listDownloads.action',
#                                           start: '0',
#                                           limit: '1000',
#                                           sort: 'dateModified',
#                                           dir: 'DESC',
#                                           searchTextField: '',
#                                           searchCategories: '',
#                                           search: 'false').body)

# def parse_seedlist(seedlist)
#   seeds = Array(seedlist['downloads']).select do |t|
#     /^Xcode [0-9]/.match(t['name'])
#   end
#
#   xcodes = seeds.map { |x| Xcode.new(x) }.reject { |x| x.version < MINIMUM_VERSION }.sort do |a, b|
#     a.date_modified <=> b.date_modified
#   end
#
#   xcodes.select { |x| x.url.end_with?('.dmg') || x.url.end_with?('.xip') }
# end

# names = @xcodes.map(&:name)
# @xcodes += prereleases.reject { |pre| names.include?(pre.name) }

function xcvmget

    bundle exec ruby -e " \
        class Xcode; \
          attr_reader :date_modified; \
          attr_reader :name; \
          attr_reader :path; \
          attr_reader :url; \
          attr_reader :version; \
          attr_reader :release_notes_url; \
\
          def initialize(json, url = nil, release_notes_url = nil); \
            if url.nil?; \
              @date_modified = json['dateModified'].to_i; \
              @name = json['name'].gsub(/^Xcode /, ''); \
              @path = json['files'].first['remotePath']; \
              url_prefix = 'https://developer.apple.com/devcenter/download.action?path='; \
              @url = \"#{url_prefix}#{@path}\"; \
              @release_notes_url = \"#{url_prefix}#{json['release_notes_path']}\" if json['release_notes_path']; \
            else; \
              @name = json; \
              @path = url.split('/').last; \
              url_prefix = 'https://developer.apple.com/'; \
              @url = \"#{url_prefix}#{url}\"; \
              @release_notes_url = \"#{url_prefix}#{release_notes_url}\"; \
            end; \
\
            begin; \
              @version = Gem::Version.new(@name.split(' ')[0]); \
            rescue; \
              @version = Installer::MINIMUM_VERSION; \
            end; \
          end; \
\
          def to_s; \
            \"Xcode #{version} -- #{url}\"; \
          end; \
\
          def ==(other); \
            date_modified == other.date_modified && name == other.name && path == other.path && \
              url == other.url && version == other.version; \
          end; \
\
          def self.new_prerelease(version, url, release_notes_path); \
            new('name' => version, \
                'files' => [{ 'remotePath' => url.split('=').last }], \
                'release_notes_path' => release_notes_path); \
          end; \
        end; \
\
        require 'spaceship'; \
\
    def spaceship; \
      @spaceship ||= begin; \
        begin; \
          Spaceship.login(ENV['XCODE_INSTALL_USER'], ENV['XCODE_INSTALL_PASSWORD']); \
        rescue Spaceship::Client::InvalidUserCredentialsError; \
          \$stderr.puts 'The specified Apple developer account credentials are incorrect.'; \
          exit(1); \
        rescue Spaceship::Client::NoUserCredentialsError; \
          \$stderr.puts 'Please provide your Apple developer account credentials via the XCODE_INSTALL_USER and XCODE_INSTALL_PASSWORD environment variables.'; \
 \
          exit(1); \
        end; \
 \
        if ENV.key?('XCODE_INSTALL_TEAM_ID'); \
          Spaceship.client.team_id = ENV['XCODE_INSTALL_TEAM_ID']; \
        end; \
        Spaceship.client; \
      end; \
    end; \
\
    json = spaceship.send(:request, :get, \
                            '/services-account/QH65B2/downloadws/listDownloads.action', \
                            start: '0', \
                            limit: '1000', \
                            sort: 'dateModified', \
                            dir: 'DESC', \
                            searchTextField: '', \
                            searchCategories: '', \
                            search: 'false').body; \
\
    def parse_seedlist(seedlist); \
      seeds = Array(seedlist['downloads']).select do |t|; \
        /^Xcode [0-9]/.match(t['name']); \
      end; \
\
      minimum_version = Gem::Version.new('4.3'); \
      xcodes = seeds.map { |x| Xcode.new(x) }.reject { |x| x.version < minimum_version }.sort do |a, b|; \
        a.date_modified <=> b.date_modified; \
      end; \
\
      xcodes.select { |x| x.url.end_with?('.dmg') || x.url.end_with?('.xip') }; \
    end; \
\
    xcodes = parse_seedlist(json); \
    puts xcodes.map(&:name)
    "
end
