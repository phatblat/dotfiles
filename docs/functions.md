# Shell Functions and Aliases Status

This document tracks the implementation status of all shell functions and aliases across the three configured shells.

## Summary

**Total: 540 unique functions/aliases across 3 shells**

**Shell Statistics:**

- Nushell: 285 aliases/functions (primary shell)
- Zsh: 380 functions (daily fallback)
- Bash: 13 functions (minimal usage)

**Shell Coverage:**

- Implemented in all 3 shells: 12
- Implemented in 2 shells: 161
- Implemented in 1 shell only: 320

**Functions Implemented in Multiple Shells:** 173

## Status Legend

- (blank) = Status unknown
- ➖ = Not implemented
- ✅ = Implemented
- 🐛 = Known bug or difference from other implementations

## Functions/Aliases Table

| Name                        | nu  | zsh | bash | Description                                          |
| --------------------------- | --- | --- | ---- | ---------------------------------------------------- |
| `DELETE`                    | ➖  | ➖  | ➖   | HTTP DELETE request helper                           |
| `GET`                       | ➖  | ➖  | ➖   | HTTP GET request helper                              |
| `HEAD`                      | ➖  | ➖  | ➖   | HTTP HEAD request helper                             |
| `OPTIONS`                   | ➖  | ➖  | ➖   | HTTP OPTIONS request helper                          |
| `PATCH`                     | ➖  | ➖  | ➖   | HTTP PATCH request helper                            |
| `POST`                      | ➖  | ➖  | ➖   | HTTP POST request helper                             |
| `PUT`                       | ➖  | ➖  | ➖   | HTTP PUT request helper                              |
| `_set_tab_title`            | ➖  | ✅  | ➖   | Set Warp tab title to git repo name or dir basename  |
| `aa`                        | ✅  | ✅  | ➖   | Add all modified tracked files to git staging        |
| `abort`                     | ✅  | ✅  | ➖   | Abort git merge/rebase/cherry-pick/am                |
| `add`                       | ✅  | ✅  | ➖   | Add files to git staging area                        |
| `adev`                      | ➖  | ➖  | ➖   | Android dev directory navigation                     |
| `af`                        | ✅  | ✅  | ➖   | Forced add files to git staging area                 |
| `ai`                        | ➖  | ✅  | ➖   | Interactively add files to git staging area          |
| `alcatraz_clean`            | ➖  | ➖  | ➖   | Zsh function                                         |
| `alcatraz_install`          | ➖  | ➖  | ➖   | Zsh function                                         |
| `alcatraz_uninstall`        | ➖  | ➖  | ➖   | Zsh function                                         |
| `alert`                     | ➖  | ➖  | ✅   | Alert notification for long running commands         |
| `allow_all_nginx`           | ➖  | ➖  | ➖   | Zsh function                                         |
| `amend`                     | ✅  | ✅  | ➖   | Amend previous git commit                            |
| `appcast_url`               | ➖  | ✅  | ➖   | Calculate appcast checkpoint                         |
| `apps`                      | ✅  | ➖  | ➖   | Lists macOS apps currently installed                 |
| `apv`                       | ✅  | ✅  | ➖   | Quick nav to ApplePlatformVersions dir               |
| `ap`                        | ✅  | ✅  | ➖   | Selectively add modifications to git staging         |
| `arp-fix`                   | ➖  | ✅  | ➖   | arp-fix                                              |
| `arpstatus`                 | ➖  | ✅  | ➖   | Shows current value of arp_unicast_lim               |
| `assumed`                   | ➖  | ✅  | ➖   | List files for which changes are ignored             |
| `assume`                    | ➖  | ✅  | ➖   | Ignore changes to given files                        |
| `aws_test`                  | ✅  | ➖  | ➖   | Test AWS credentials                                 |
| `a`                         | ✅  | ✅  | ➖   | Add files to git staging area                        |
| `bak`                       | ✅  | ✅  | ➖   | Backs up file by appending .bak extension            |
| `bashman`                   | ➖  | ➖  | ➖   | Zsh function                                         |
| `bconfig`                   | ✅  | ✅  | ➖   | Configures Bundler                                   |
| `bdm`                       | ➖  | ✅  | ➖   | Delete local branches which have been merged into    |
| `bD`                        | ✅  | ✅  | ➖   | Forcefully delete a branch from git                  |
| `bef`                       | ➖  | ✅  | ➖   | Short alias for executing Fastlane through Bundler   |
| `be`                        | ✅  | ✅  | ➖   | Short alias for executing gems through Bundler       |
| `bid`                       | ➖  | ✅  | ➖   | Get bundle ID for app name                           |
| `bigfiles`                  | ✅  | ✅  | ➖   | Lists the 10 biggest files in the current director   |
| `big`                       | ➖  | ✅  | ➖   | Install gem bundle using local Gemfile               |
| `binstall`                  | ✅  | ✅  | ➖   | Install Bundler with proper bindir                   |
| `biq`                       | ➖  | ✅  | ➖   | Quiet bundle install                                 |
| `bisect`                    | ✅  | ✅  | ➖   | Git bisect                                           |
| `bi`                        | ✅  | ✅  | ➖   | Short alias for installing gems using Bundler        |
| `blame`                     | ✅  | ➖  | ➖   | Git blame                                            |
| `bog`                       | ➖  | ✅  | ➖   | Update gem bundle using local Gemfile                |
| `bo`                        | ✅  | ✅  | ➖   | List outdated gems in the bundle                     |
| `bpx`                       | ➖  | ➖  | ➖   | Zsh function                                         |
| `bq`                        | ✅  | ✅  | ➖   | Query brew information                               |
| `branch`                    | ➖  | ✅  | ➖   | Manage git branches                                  |
| `bra`                       | ✅  | ✅  | ➖   | List all git branches                                |
| `brew_active_version`       | ✅  | ➖  | ➖   | brew_active_version                                  |
| `brew_cache_purge`          | ➖  | ✅  | ➖   | Purges Homebrew cache                                |
| `brew_deps`                 | ✅  | ➖  | ➖   | Lists dependencies of brew packages                  |
| `brew_home`                 | ✅  | ✅  | ➖   | Prints Homebrew home dir or cellar location          |
| `brew_installed`            | ✅  | ➖  | ➖   | Checks whether a formula is currently installed      |
| `brew_logs`                 | ➖  | ✅  | ➖   | Quick nav to Homebrew logs dir                       |
| `brew_test`                 | ✅  | ➖  | ➖   | Installs and tests Homebrew formula                  |
| `brew_versions`             | ➖  | ✅  | ➖   | Lists installed versions of a formula                |
| `br`                        | ✅  | ➖  | ➖   | This script was automatically generated by the bro   |
| `bub`                       | ➖  | ✅  | ➖   | Update locked version of bundler                     |
| `bundle-pull`               | ✅  | ➖  | ➖   | Migrated from bundle-pull.rb ruby script             |
| `bu`                        | ✅  | ✅  | ➖   | Update gems in bundle                                |
| `bvv`                       | ➖  | ✅  | ➖   | Display git branch with details                      |
| `bv`                        | ✅  | ✅  | ➖   | Display the version of bundler                       |
| `b`                         | ✅  | ✅  | ➖   | Manage git branch                                    |
| `cargo_target`              | ✅  | ✅  | ➖   | argparse 'h/help' 'n/name' -- $argv                  |
| `cask_audit`                | ➖  | ✅  | ➖   | Audits a Homebrew cask                               |
| `cask_cache`                | ➖  | ✅  | ➖   | Manage the Homebrew Cask cache. Without args the c   |
| `cask_dir`                  | ➖  | ✅  | ➖   | Quick nav to Homebrew Casks tap                      |
| `cask_edit`                 | ➖  | ✅  | ➖   | Manage Homebrew casks                                |
| `cask_token`                | ➖  | ✅  | ➖   | Generates a cask token for an app                    |
| `cball`                     | ➖  | ✅  | ➖   | Build all platforms using Carthage                   |
| `cc`                        | ✅  | ✅  | ➖   | Claude Code with --dangerously-skip-permissions      |
| `ccc`                       | ✅  | ✅  | ➖   | Continue a Claude Code session with default config   |
| `ccr`                       | ✅  | ✅  | ➖   | Resume a Claude Code session                         |
| `ccu`                       | ➖  | ✅  | ➖   | Update dependencies without building via Carthage  |
| `cdown`                     | ✅  | ➖  | ➖   | Alias for curl_download                              |
| `cfrmodel`                  | ➖  | ✅  | ➖   | Quick dir nav to CFR Model project                   |
| `cfrservice`                | ➖  | ✅  | ➖   | Quick dir nav to CFR Service project                 |
| `checkout`                  | ➖  | ✅  | ➖   | Perform a git checkout                               |
| `cherry-pick`               | ➖  | ✅  | ➖   | Perform a git cherry-pick                            |
| `chexe`                     | ✅  | ✅  | ➖   | Set executable permissions                           |
| `clone_or_pull`             | ✅  | ✅  | ➖   | Clone fresh or pull existing git repo                |
| `clone`                     | ✅  | ✅  | ➖   | Git clone, then configure repo user                  |
| `cmt`                       | ✅  | ✅  | ➖   | Commit with message                                  |
| `codesign_verify`           | ✅  | ✅  | ➖   | Verify the codesign of a bundle                      |
| `col1`                      | ➖  | ✅  | ➖   | Prints the first column of input (first argument) (n/a in nu — subsumed by structured pipelines) |
| `commit_count`              | ✅  | ✅  | ➖   | Count commits by date for a branch                   |
| `commit`                    | ✅  | ✅  | ➖   | Perform a git commit                                 |
| `configg`                   | ➖  | ✅  | ➖   | Manage global git configuration (~/.gitconfig)       |
| `console_user`              | ➖  | ✅  | ➖   | Prints username of console user                      |
| `continue`                  | ➖  | ➖  | ➖   | Zsh function                                         |
| `cont`                      | ✅  | ✅  | ➖   | Commit merge or continue rebase/cherry-pick          |
| `co`                        | ✅  | ➖  | ➖   | Git checkout operations                              |
| `createdirs`                | ✅  | ✅  | ➖   | Creates set of directories if missing                |
| `cron_edit`                 | ➖  | ✅  | ➖   | Opens cron file in editor                            |
| `cron_list`                 | ➖  | ✅  | ➖   | Prints cron file                                     |
| `cron_reload`               | ➖  | ✅  | ➖   | Reloads cron file                                    |
| `ctitle`                    | ➖  | ➖  | ➖   | Zsh function                                         |
| `curl_download`             | ✅  | ➖  | ➖   | Download a file using curl with the most common op   |
| `current-branch`            | ➖  | ➖  | ➖   | Zsh function                                         |
| `current_branch`            | ✅  | ➖  | ➖   | Displays current branch name                         |
| `cx`                        | ✅  | ✅  | ➖   | Launch Codex (main profile, no alt-screen)           |
| `cxc`                       | ✅  | ✅  | ➖   | Continue the last Codex session                      |
| `cxr`                       | ✅  | ✅  | ➖   | Resume a Codex session                                |
| `c`                         | ✅  | ✅  | ➖   | Performs git checkout                                |
| `dash`                      | ➖  | ✅  | ➖   | Dash shell integration                               |
| `date_iso8601`              | ➖  | ✅  | ➖   | Prints date in ISO-8601 format                       |
| `dce`                       | ➖  | ✅  | ➖   | Execute command in running container                 |
| `dci`                       | ➖  | ✅  | ➖   | Display detailed docker container info               |
| `dck`                       | ➖  | ✅  | ➖   | Alias for dcstop                                     |
| `dcl`                       | ➖  | ✅  | ➖   | List all docker containers                           |
| `dcp`                       | ✅  | ✅  | ➖   | Remove all stopped docker containers                 |
| `dcr`                       | ➖  | ✅  | ➖   | Remove running docker containers                     |
| `dcstart`                   | ➖  | ✅  | ➖   | Start stopped docker containers                      |
| `dcstop`                    | ➖  | ✅  | ➖   | Stop running docker containers                       |
| `dct`                       | ➖  | ✅  | ➖   | Display running processes of docker container        |
| `dcw`                       | ➖  | ✅  | ➖   | Diff the git staging area using word diff            |
| `dc`                        | ✅  | ✅  | ➖   | Diff the git staging area                            |
| `ddc`                       | ✅  | ✅  | ➖   | Docker deep clean                                    |
| `ddd`                       | ✅  | ✅  | ➖   | Delete Derived Data                                  |
| `debug`                     | ➖  | ✅  | ➖   | Prints args only when debug env var set              |
| `defaults_set`              | ✅  | ➖  | ➖   | --------------------------------------------------   |
| `deflate`                   | ➖  | ✅  | ➖   | Unzip git blobs                                      |
| `delete-tag`                | ➖  | ✅  | ➖   | Deletes a git tag from both the local and remote r   |
| `deleted`                   | ✅  | ➖  | ➖   | Lists files deleted from git history                 |
| `derived_data`              | ✅  | ✅  | ➖   | Spins up RAM disk for Xcode DerivedData              |
| `devices`                   | ➖  | ➖  | ➖   | Zsh function                                         |
| `dib`                       | ➖  | ✅  | ➖   | Build image from Dockerfile                          |
| `difftool`                  | ✅  | ✅  | ➖   | Perform a git diff using the configured tool (Kale   |
| `diff`                      | ✅  | ✅  | ➖   | Perform a git diff                                   |
| `dii`                       | ➖  | ✅  | ➖   | Display detailed docker image info                   |
| `dil`                       | ➖  | ✅  | ➖   | List docker images                                   |
| `din`                       | ➖  | ✅  | ➖   | Remove all docker images                             |
| `dip`                       | ✅  | ✅  | ➖   | Remove unused docker images                          |
| `dirty`                     | ➖  | ✅  | ➖   | Show repo dirty files                                |
| `dir`                       | ✅  | ✅  | ➖   | Remove docker images forcefully                      |
| `displays`                  | ✅  | ➖  | ➖   | Show info about connected displays                   |
| `dit`                       | ➖  | ✅  | ➖   | Create tag TARGET_IMAGE refers to SOURCE_IMAGE       |
| `diw`                       | ➖  | ✅  | ➖   | Remove all Ping Identity docker images               |
| `dlf`                       | ➖  | ✅  | ➖   | Alias of dlogs                                       |
| `dlogs`                     | ➖  | ✅  | ➖   | Fetch logs of docker container                       |
| `dnc`                       | ➖  | ✅  | ➖   | Create docker network                                |
| `dni`                       | ➖  | ✅  | ➖   | Display detailed docker network info                 |
| `dnl`                       | ➖  | ✅  | ➖   | List docker networks                                 |
| `dnp`                       | ✅  | ✅  | ➖   | Remove all unused docker networks                    |
| `dnr`                       | ➖  | ✅  | ➖   | Remove docker networks                               |
| `dnuke`                     | ➖  | ✅  | ➖   | Remove unused docker images not just dangling        |
| `doc`                       | ➖  | ✅  | ➖   | Quickly launch docker containers in current dir      |
| `dotfiles`                  | ✅  | ➖  | ➖   | Edit dotfiles                                        |
| `dpd`                       | ➖  | ✅  | ➖   | Stop containers and remove containers/networks       |
| `dpl`                       | ➖  | ✅  | ➖   | View output from docker containers                   |
| `dpp`                       | ➖  | ✅  | ➖   | List docker containers                               |
| `dpr`                       | ➖  | ✅  | ➖   | Restart services managed by docker compose           |
| `dps`                       | ➖  | ✅  | ➖   | List docker containers                               |
| `dpu`                       | ➖  | ✅  | ➖   | Build/create/start/attach containers for service     |
| `dra`                       | ➖  | ✅  | ➖   | Remove all stopped docker containers                 |
| `dsa`                       | ➖  | ✅  | ➖   | Stop all running docker containers                   |
| `dsl`                       | ➖  | ✅  | ➖   | List docker services                                 |
| `dsr`                       | ➖  | ✅  | ➖   | Remove docker services                               |
| `dss`                       | ➖  | ✅  | ➖   | Scale replicated docker services                     |
| `dsyminfo`                  | ➖  | ✅  | ➖   | Displays information for a Dwarf symbol file         |
| `dtc`                       | ➖  | ✅  | ➖   | Git difftool on cached/staged changes                |
| `dt`                        | ➖  | ✅  | ➖   | Git difftool shorthand                               |
| `dvc`                       | ➖  | ✅  | ➖   | Create docker volume                                 |
| `dvi`                       | ➖  | ✅  | ➖   | Display detailed docker volume info                  |
| `dvl`                       | ➖  | ✅  | ➖   | List docker volumes                                  |
| `dvp`                       | ✅  | ✅  | ➖   | Remove all unused local docker volumes               |
| `dvr`                       | ➖  | ✅  | ➖   | Remove docker volumes                                |
| `dw`                        | ➖  | ✅  | ➖   | Git diff with word diff                              |
| `d`                         | ✅  | ✅  | ✅   | Git diff                                             |
| `editorconfig`              | ➖  | ✅  | ➖   | Generates an editorconfig                            |
| `edit`                      | ✅  | ✅  | ➖   | Edit using configured VISUAL editor                  |
| `email_url`                 | ➖  | ✅  | ➖   | Determines appropriate contact for URL               |
| `en1`                       | ✅  | ➖  | ➖   | Shows en1 network interface                          |
| `entitlements`              | ➖  | ✅  | ➖   | Display entitlements in the codesign information o   |
| `epoc_date`                 | ✅  | ➖  | ➖   | Converts epoch timestamps to date                    |
| `error`                     | ✅  | ✅  | ➖   | Prints args to stderr (nu: `error-msg` — keyword collision) |
| `explain`                   | ➖  | ➖  | ➖   | Zsh function                                         |
| `e`                         | ✅  | ✅  | ➖   | Short alias for editing a file. Given no args, the   |
| `f`                         | ✅  | ✅  | ✅   | Invoke fork; given no args, defaults to '.'          |
| `fetch`                     | ✅  | ✅  | ✅   | Fetch branch from default git remote                 |
| `fg`                        | ✅  | ➖  | ➖   | Resume a frozen job in the foreground; resolves id from job list to work around nushell#16561 |
| `file_base`                 | ✅  | ➖  | ➖   | Prints base name after dropping extension            |
| `fileowner`                 | ✅  | ✅  | ➖   | Displays owner of file                               |
| `files_changed`             | ✅  | ➖  | ➖   | Shows files changed since treeish                    |
| `filesize`                  | ➖  | ✅  | ➖   | Prints size of file in bytes                         |
| `find_file`                 | ✅  | ➖  | ➖   | Finds files under given base_dir                     |
| `finddsym`                  | ➖  | ✅  | ➖   | Locates a dSYM file with the given UUID              |
| `finds`                     | ➖  | ➖  | ➖   | Zsh function                                         |
| `findup`                    | ✅  | ➖  | ➖   | Recursively searches up directory tree               |
| `fish_logo`                 | ✅  | ➖  | ➖   | Prints a colorful ASCII-art fish logo                |
| `fixperms`                  | ✅  | ➖  | ➖   | Sets all file and directory permissions to 644 and   |
| `flushdns`                  | ✅  | ✅  | ➖   | Flush macOS DNS cache                                |
| `fork`                      | ✅  | ✅  | ➖   | Launch Fork.app (inherits mise PATH)                 |
| `format-patch`              | ➖  | ✅  | ➖   | Git format-patch wrapper                             |
| `function_template`         | ➖  | ✅  | ➖   | Prints function_template                             |
| `func`                      | ➖  | ✅  | ➖   | Prints colorized indented source of function         |
| `funky`                     | ✅  | ✅  | ➖   | Options (ls style):                                  |
| `g_alias`                   | ✅  | ➖  | ➖   | Git command                                          |
| `ga`                        | ✅  | ➖  | ➖   | Git add                                              |
| `gbe`                       | ✅  | ➖  | ➖   | Shows Gradle build environment                       |
| `gc`                        | ✅  | ✅  | ➖   | Run git garbage collection                           |
| `gd`                        | ✅  | ➖  | ➖   | Launch gradle in debug mode                          |
| `gem_install`               | ✅  | ✅  | ➖   | Binstubs are installed to /usr/local/bin alongside   |
| `gem_pristine`              | ➖  | ✅  | ➖   | Runs pristine command for all gems                   |
| `gem_update`                | ➖  | ✅  | ➖   | Binstubs are installed to /usr/local/bin alongside   |
| `gemdir`                    | ➖  | ✅  | ➖   | Prints path to system gem dir                        |
| `genv`                      | ✅  | ✅  | ➖   | Grep environment                                     |
| `gh_token_test`             | ✅  | ➖  | ➖   | Tests GitHub personal access token                   |
| `ghostty`                   | ✅  | ➖  | ➖   | Wrapper for Ghostty terminal emulator                |
| `github-pat-refresh`        | ➖  | ➖  | ➖   | Extend fine-grained GitHub PAT expiration by N days  |
| `ginit`                     | ✅  | ➖  | ➖   | Git init                                             |
| `git-plist-filter`          | ➖  | ✅  | ➖   | Converts plist data to XML format                    |
| `git_bundle_create`         | ✅  | ✅  | ➖   | Creates a git bundle containing any changes in the   |
| `git_clean`                 | ✅  | ✅  | ➖   | Clean non-tracked files from working tree            |
| `git_inside_repo`           | ✅  | ✅  | ➖   | Detects whether $PWD is inside git repo              |
| `git_repo_clean`            | ✅  | ➖  | ➖   | Detects clean work tree                              |
| `git_repo_dirty`            | ✅  | ➖  | ➖   | Detects dirty work tree                              |
| `gitconfig_setup`           | ➖  | ✅  | ➖   | Sets git user.name and user.email in XDG_CONFIG_HOME |
| `gitalias`                  | ➖  | ➖  | ➖   | Zsh function                                         |
| `gi`                        | ✅  | ➖  | ➖   | Creates .gitignore file using gitignore.io           |
| `gl`                        | ✅  | ➖  | ➖   | Git pull                                             |
| `gpgcopypub`                | ➖  | ✅  | ➖   | Copies the public key for any GPG key found          |
| `gpgkeyid`                  | ➖  | ✅  | ➖   | This will return multiple 8-char values if there a   |
| `gpgrep`                    | ✅  | ➖  | ➖   | Grep for gradle properties                           |
| `gpgshow`                   | ➖  | ✅  | ➖   | List GPG keys with short keyid format                |
| `gpgtest`                   | ➖  | ✅  | ➖   | gpgtest                                              |
| `gpv`                       | ✅  | ➖  | ➖   | Quick nav to GooglePlatformVersions dir              |
| `gp`                        | ✅  | ➖  | ➖   | Edit current user Gradle properties                  |
| `gradle_cache_clean`        | ✅  | ➖  | ➖   | Cleans gradle cache                                  |
| `gradle_kill`               | ✅  | ➖  | ➖   | Kills all running gradle processes                   |
| `gradle_wrapper_add`        | ✅  | ➖  | ➖   | Updates build.gradle and runs wrapper task           |
| `gradle_wrapper`            | ✅  | ➖  | ➖   | Installs gradle wrapper                             |
| `gradle_debug`              | ➖  | ✅  | ➖   | Toggles Gradle remote debugging on/off               |
| `gradledebug`               | ➖  | ➖  | ➖   | Zsh function                                         |
| `gst`                       | ✅  | ➖  | ➖   | Git status                                           |
| `gs`                        | ✅  | ➖  | ➖   | Git status short format                              |
| `gta`                       | ✅  | ➖  | ➖   | Alias for gradle tasks --all                         |
| `gt`                        | ✅  | ✅  | ➖  | Gastown wrapper (zsh); gradle tasks alias (nu)       |
| `gv`                        | ✅  | ✅  | ➖   | > gradle --version                                   |
| `gwd`                       | ✅  | ➖  | ➖   | org.gradle.debug=true is the equivalent of: -Dorg    |
| `gwo`                       | ✅  | ✅  | ➖   | Gradle wrapper offline                               |
| `gwv`                       | ✅  | ✅  | ➖   | Prints version of gradle wrapper                     |
| `gw`                        | ✅  | ✅  | ➖   | Invokes build using Gradle wrapper script            |
| `g`                         | ✅  | ✅  | ➖   | Gradle alias                                         |
| `has_space`                 | ➖  | ✅  | ➖  | Checks whether a string contains spaces              |
| `hcopy`                     | ➖  | ➖  | ➖   | Zsh function                                         |
| `headsha`                   | ➖  | ✅  | ➖   | Prints the full SHA1 hash of the current HEAD comm   |
| `headshort`                 | ➖  | ✅  | ➖   | Prints a 7-character abbreviated sha1 hash of the    |
| `help`                      | ➖  | ➖  | ➖   | Git help alias                                       |
| `hgrep`                     | ✅  | ✅  | ➖   | Grep command history                                 |
| `home`                      | ✅  | ➖  | ➖   | Go home                                              |
| `htoptions`                 | ➖  | ✅  | ➖   | Send HTTP OPTIONS request using builtin socket     |
| `htstatus`                  | ➖  | ➖  | ➖   | Zsh function                                         |
| `h`                         | ➖  | ➖  | ➖   | History alias                                        |
| `icloud`                    | ➖  | ✅  | ➖   | Changes directory to ICLOUD_HOME                     |
| `ida`                       | ➖  | ✅  | ➖   | Launch IDA with elevated privileges                  |
| `idea`                      | ➖  | ➖  | ➖   | Open IntelliJ IDEA                                   |
| `ignored`                   | ✅  | ✅  | ➖   | Show files ignored by git                            |
| `ignores`                   | ✅  | ✅  | ✅   | Standard ignored files                               |
| `ignore`                    | ✅  | ✅  | ✅   | Adds lines to .gitignore                             |
| `index`                     | ➖  | ✅  | ➖   | Prints the index of a value in a list                |
| `init`                      | ✅  | ➖  | ➖   | Initialize new git repo in current/optional dir      |
| `install_powerline_prompt`  | ➖  | ➖  | ➖   | Zsh function                                         |
| `iphones`                   | ➖  | ✅  | ➖   | Show connected iOS devices                           |
| `ip`                        | ✅  | ➖  | ➖   | Show the current IPv4 address                        |
| `is_arm`                    | ➖  | ✅  | ➖   | Tests whether current system is arm                  |
| `is_console_user`           | ➖  | ✅  | ➖   | Tests whether current user logged into console       |
| `is_coreutils`              | ➖  | ✅  | ➖   | Tests whether coreutils is installed                 |
| `is_linux`                  | ✅  | ✅  | ➖   | Tests whether current computer running Linux         |
| `is_mac`                    | ✅  | ✅  | ➖   | Tests whether current computer running macOS         |
| `is_octodec`                | ➖  | ✅  | ➖   | Tests whether current computer is octodec            |
| `is_phatmini`               | ➖  | ✅  | ➖   | Tests whether current computer is phatmini           |
| `is_ssh`                    | ➖  | ✅  | ➖   | Tests whether current session is SSH                 |
| `itwire`                    | ➖  | ✅  | ➖   | Quick dir navigation                                 |
| `jdk`                       | ✅  | ✅  | ➖   | Manage installed JDKs                                |
| `jdk_current`               | ✅  | ✅  | ➖   | Shows current JDK version and JAVA_HOME              |
| `jdk_set`                   | ✅  | ✅  | ➖   | Sets JAVA_HOME and adds to PATH                      |
| `jobs`                      | ✅  | ➖  | ➖   | List background jobs (job list)                      |
| `jq`                        | ✅  | ✅  | ➖   | Wrapper around jq with input preservation on failure |
| `jv`                        | ✅  | ➖  | ➖   | Example output (goes to stderr!):                    |
| `j`                         | ✅  | ➖  | ➖   | Just command runner                                  |
| `killsim`                   | ✅  | ➖  | ➖   | Displays CoreSimulatorService info before removing   |
| `la`                        | ✅  | ✅  | ✅   | long list,show almost all,show type,human readable   |
| `ldot`                      | ➖  | ✅  | ➖   | List hidden files                                    |
| `lg10`                      | ✅  | ✅  | ➖   | Pretty history graph with ten commits                |
| `lg1`                       | ✅  | ✅  | ➖   | Pretty history graph with one commit                 |
| `lga`                       | ✅  | ✅  | ➖   | Pretty history graph showing all                     |
| `lgfind`                    | ➖  | ✅  | ➖   | Search through lightweight log lg for pattern        |
| `lggrep`                    | ➖  | ✅  | ➖   | Grep through lightweight log `lg` for a regex patt   |
| `lgg`                       | ➖  | ✅  | ➖   | Pretty history graph                                 |
| `lg`                        | ✅  | ✅  | ✅   | Launch lazygit                                       |
| `lh`                        | ➖  | ✅  | ➖   | List files with human-readable sizes                 |
| `license`                   | ✅  | ✅  | ➖   | Writes LICENSE.md, adds link to readme               |
| `list-authors`              | ✅  | ➖  | ➖   | Collect a list of all commit authors from the curr   |
| `list_codesign_identities`  | ✅  | ➖  | ➖  | Lists code-signing identities                        |
| `list`                      | ✅  | ✅  | ✅   | Prints a list with each element on a separate line   |
| `ll`                        | ✅  | ✅  | ✅   | Long list                                            |
| `log10`                     | ✅  | ✅  | ➖   | Alias for git log                                    |
| `log1`                      | ➖  | ✅  | ➖   | Show last git commit with full details               |
| `log`                       | ✅  | ✅  | ➖   | Alias for `git log`                                  |
| `ls-files`                  | ➖  | ✅  | ➖   | Git ls-files                                         |
| `ls-remote`                 | ✅  | ✅  | ➖   | Git ls-remote                                        |
| `lsym`                      | ✅  | ➖  | ➖   | List symbolic links in the current dir               |
| `ltime`                     | ➖  | ✅  | ➖  | Lists files with timestamps                          |
| `lt`                        | ➖  | ✅  | ➖   | long list,sorted by date,show type,human readable    |
| `l`                         | ✅  | ✅  | ✅   | Pretty git log graph with ten commits                |
| `macos`                     | ➖  | ✅  | ➖   | Manage macOS system updates                          |
| `masd`                      | ✅  | ✅  | ➖   | Quick nav to mas dir                                 |
| `maslink`                   | ✅  | ➖  | ➖   | Links debug build of mas into path                   |
| `masrm`                     | ✅  | ➖  | ➖   | Uninstall mas package                                |
| `masshow`                   | ✅  | ➖  | ➖   | Show which copy of mas is active                     |
| `mdk`                       | ➖  | ✅  | ➖   | Quick nav to MDK                                     |
| `mdp`                       | ✅  | ➖  | ➖   | Quick nav to mdp dir                                 |
| `members`                   | ➖  | ✅  | ➖   | List members of the given group                      |
| `merge-base`                | ➖  | ✅  | ➖   | Git merge-base wrapper                               |
| `mergetool`                 | ✅  | ✅  | ➖   | Perform a git merge using the configured tool (Kal   |
| `merge`                     | ✅  | ✅  | ➖   | Git merge                                            |
| `mirror`                    | ✅  | ➖  | ➖   | Reset the git staging area and working copy to mir   |
| `mise_activate`             | ✅  | ➖  | ➖   | Nushell function                                     |
| `mkdir`                     | ✅  | ➖  | ➖   | Create directory and set CWD (nu: `mkcd` — builtin collision) |
| `mkcd`                      | ✅  | ➖  | ➖   | Make dir and cd into it (nu rename of `mkdir` — builtin collision) |
| `moj_host`                  | ✅  | ➖  | ➖   | Prints emoji for current host                        |
| `moj_user`                  | ➖  | ✅  | ➖   | Prints emoji for current user                        |
| `mpv`                       | ✅  | ✅  | ➖   | Quick nav to MicrosoftPlatformVersions dir           |
| `mt`                        | ➖  | ✅  | ➖   | Short alias for git mergetool                        |
| `m`                         | ✅  | ➖  | ➖   | Git merge                                            |
| `nav`                       | ✅  | ➖  | ➖   | Quick nav to dir. Creates if not present             |
| `new_project`               | ➖  | ➖  | ➖   | Zsh function                                         |
| `new`                       | ✅  | ➖  | ➖   | List all new commits have been created with the pr   |
| `nix_install`               | ➖  | ✅  | ➖   | Installs nix tools                                   |
| `nixgc`                     | ✅  | ➖  | ➖   | Runs nix garbage collection and optimisation         |
| `nixtest`                   | ✅  | ✅  | ➖   | Tests Nix installation                               |
| `objg`                      | ➖  | ✅  | ➖   | Quick nav to Objective-Git                           |
| `octodec`                   | ✅  | ✅  | ➖   | SSH to octodec                                       |
| `oc`                        | ✅  | ✅  | ➖   | Launch opencode                                      |
| `ol`                        | ➖  | ✅  | ➖   | Quick dir navigation                                 |
| `openports`                 | ✅  | ✅  | ➖   | Lists open ports for the current user                |
| `osversion`                 | ✅  | ➖  | ➖   | Prints macOS version number                          |
| `ours`                      | ✅  | ➖  | ➖   | When checking out paths from the index, check out    |
| `ox`                        | ✅  | ➖  | ➖   | Open Xcode project in current dir                    |
| `o`                         | ✅  | ✅  | ➖   | Short alias for open                                 |
| `pai`                       | ➖  | ➖  | ➖   | PAI skill wrapper (Skipped: ~/.claude/skills/PAI/Tools/pai.ts not on disk; port deferred) |
| `path_add`                  | ✅  | ✅  | ➖  | Adds an entry to PATH                                |
| `path_show`                 | ✅  | ➖  | ➖  | Shows PATH entries                                    |
| `pbjup`                     | ➖  | ✅  | ➖   | Upgrade personal jenkins formula and restart         |
| `pborigin`                  | ✅  | ➖  | ➖   | Rename the 'origin' remote to 'phatblat'             |
| `pbsync`                    | ➖  | ➖  | ➖   | Zsh function                                         |
| `pcopy`                     | ✅  | ✅  | ➖   | Copy the current dir path into the pasteboard        |
| `phatmini`                  | ✅  | ➖  | ➖   | SSH to phatmini                                      |
| `pick`                      | ✅  | ✅  | ➖   | Short alias for cherry-pick                          |
| `pid`                       | ➖  | ✅  | ➖   | Get PID for a process name                           |
| `pip`                       | ✅  | ➖  | ➖   | https://stackoverflow.com/questions/58451650/pip-n   |
| `pkgexpand`                 | ➖  | ✅  | ➖   | Expands pkg file                                     |
| `pkgfiles`                  | ➖  | ✅  | ➖   | Shows files associated with the given installer pa   |
| `pkgfind`                   | ➖  | ✅  | ➖   | Scans through installer package identifiers for th   |
| `pkginfo`                   | ✅  | ✅  | ➖   | Shows metadata for the given installer package       |
| `pl_edit`                   | ➖  | ✅  | ➖   | Edit Powerline config files                          |
| `plcat`                     | ✅  | ✅  | ➖   | Show Divvy plist                                     |
| `pless`                     | ➖  | ✅  | ➖   | Use less to view the XML of a property list file     |
| `pop`                       | ✅  | ✅  | ➖   | Undo last commit but leave staging area              |
| `ports`                     | ➖  | ✅  | ➖   | Shows open TCP ports                                 |
| `powerlinetest`             | ➖  | ✅  | ➖   | Print special Powerline characters to test current   |
| `pp`                        | ✅  | ✅  | ➖   | Publish the phatblat branch                          |
| `prefs`                     | ✅  | ➖  | ➖   | Opens System Preferences to specific pane            |
| `prettyjson`                | ➖  | ✅  | ➖   | Prints a formatted version of a JSON file            |
| `print_profile`             | ➖  | ➖  | ➖   | Zsh function                                         |
| `profile_id`                | ➖  | ✅  | ➖   | Extracts the UUID from a .mobileprovision profile    |
| `provdir`                   | ➖  | ➖  | ➖   | Zsh function                                         |
| `provisioning_print`        | ✅  | ✅  | ➖   | Prints a text version of a provisioning profile      |
| `provisioning_uuid`         | ➖  | ✅  | ➖   | Prints the UUID from a provisioning profile          |
| `prune`                     | ✅  | ✅  | ➖   | Prune obsolete remote branches on given remote       |
| `psgrep`                    | ✅  | ✅  | ➖   | Wrapper for ps which isolates processes containing a given string |
| `psync`                     | ✅  | ➖  | ➖   | Syncs files between two directories. Without a 3rd   |
| `publish`                   | ✅  | ✅  | ➖   | Publishes the current branch to the named remote     |
| `pull_ssh_config`           | ✅  | ➖  | ➖   | Copies SSH config to local                           |
| `pull`                      | ✅  | ✅  | ➖   | Git pull                                             |
| `pushf`                     | ✅  | ✅  | ➖   | Force git push                                       |
| `push`                      | ✅  | ✅  | ➖   | Git push                                             |
| `qllist`                    | ➖  | ✅  | ➖   | List QuickLook plugins                               |
| `ramdisk`                   | ✅  | ➖  | ➖   | https://blog.macsales.com/46348-how-to-create-and-   |
| `ra`                        | ✅  | ✅  | ➖   | Adds git remote                                      |
| `realmos`                   | ➖  | ✅  | ➖   | Manage Realm Object Server                           |
| `rebase`                    | ✅  | ✅  | ➖   | Git rebase                                           |
| `reflog`                    | ✅  | ✅  | ➖   | Git reflog                                           |
| `ref`                       | ✅  | ➖  | ➖   | Prints the symbolic ref for the given treeish        |
| `reloadprofile`             | ➖  | ➖  | ➖   | Zsh function                                         |
| `reload`                    | ➖  | ✅  | ➖   | Reload a zsh autoload function by name               |
| `relo`                      | ➖  | ➖  | ➖   | Zsh function                                         |
| `remote-for-current-branch` | ➖  | ➖  | ➖   | Zsh function                                         |
| `remote`                    | ✅  | ✅  | ➖   | Git remote                                           |
| `repeatchar`                | ✅  | ➖  | ➖   | Repeats a character a fixed number of times          |
| `repo_new`                  | ➖  | ✅  | ➖   | Creates new GitHub repo using local dir as root      |
| `reset`                     | ✅  | ✅  | ➖   | Git reset                                            |
| `restart`                   | ✅  | ➖  | ➖   | Restarts the computer without prompt                 |
| `restore`                   | ✅  | ➖  | ➖   | Discards changes in working tree                     |
| `rev-list`                  | ➖  | ✅  | ➖   | Git rev-list                                         |
| `rev-parse`                 | ✅  | ✅  | ➖   | Git rev-parse                                        |
| `revert`                    | ➖  | ✅  | ➖   | Git revert                                           |
| `review`                    | ✅  | ✅  | ➖   | Review a given commit, default: HEAD                 |
| `rewrite`                   | ✅  | ✅  | ➖   | Rewrite commits changing author/committer info       |
| `ri`                        | ✅  | ➖  | ➖   | Interactive rebase for last N commits (default 10)   |
| `rl`                        | ✅  | ✅  | ➖   | Quick dir navigation                                 |
| `root`                      | ✅  | ✅  | ✅   | Display path to root of current git repo             |
| `ruby_upgrade`              | ➖  | ✅  | ➖   | Upgrades ruby across major versions                  |
| `rubygems`                  | ➖  | ✅  | ➖   | Installs and updates Ruby gems                       |
| `rv`                        | ✅  | ➖  | ➖   | List git remote details                              |
| `r`                         | ✅  | ✅  | ➖   | Interactive rebase for the last few commits, count   |
| `sa`                        | ✅  | ➖  | ➖   | Display git status                                   |
| `scrub`                     | ➖  | ✅  | ➖   | Deletes the given path and removes it from all git   |
| `search`                    | ➖  | ✅  | ➖   | Search for CLI tools through package managers        |
| `setJdk6`                   | ➖  | ➖  | ➖   | Zsh function                                         |
| `setJdk7`                   | ➖  | ➖  | ➖   | Zsh function                                         |
| `setJdk8`                   | ➖  | ➖  | ➖   | Zsh function                                         |
| `sethostname`               | ✅  | ➖  | ➖   | http://osxdaily.com/2012/10/24/set-the-hostname-co   |
| `sha1`                      | ✅  | ➖  | ➖   | Displays SHA1 hash of files                          |
| `sha256`                    | ✅  | ✅  | ➖   | Compute SHA-256 checksums of files                   |
| `shacopy`                   | ➖  | ✅  | ➖   | Copies the SHA1 hash of the HEAD commit to the gen   |
| `sha`                       | ➖  | ✅  | ➖   | Print the SHA1 of the HEAD commit                    |
| `shell_add`                 | ✅  | ➖  | ➖   | Register new shell in /etc/shells                    |
| `shell_choose`              | ✅  | ➖  | ➖   | Interactive prompting for choosing default shell     |
| `shell_switch`              | ✅  | ✅  | ➖   | Changes current $USER default shell                  |
| `shortlog`                  | ✅  | ✅  | ➖   | Alias for shortlog                                   |
| `shortsha`                  | ➖  | ✅  | ➖   | Print the first 9 chars of the SHA1 of the HEAD co   |
| `showcerts`                 | ➖  | ✅  | ➖   | Shows server certificate information                 |
| `showcert`                  | ➖  | ✅  | ➖   | Prints server certificate file details               |
| `showgit_remote`            | ➖  | ✅  | ➖   | Searches for .git repos, printing remote URL         |
| `showgit`                   | ➖  | ✅  | ➖   | Searches for .git repos recursively below            |
| `showjdks`                  | ➖  | ➖  | ➖   | Zsh function                                         |
| `showsvn`                   | ➖  | ✅  | ➖   | Show .svn directories in current directory tree    |
| `show`                      | ✅  | ✅  | ➖   | Git show                                             |
| `signing_cert_details`      | ✅  | ✅  | ➖   | Prints signing certificate details                   |
| `simclean`                  | ✅  | ✅  | ➖   | Deletes all unavailable simulators                   |
| `skip`                      | ✅  | ✅  | ➖   | Skip current commit in git rebase/cherry-pick (nu: `gskip` — builtin collision) |
| `sortdiff`                  | ✅  | ➖  | ➖   | Filter and sort a git diff showing only the change   |
| `spotlight_reload`          | ➖  | ✅  | ➖   | Reloads Spotlight triggering re-index                |
| `sshcopypub`                | ✅  | ✅  | ➖   | Copy SSH public key to pasteboard/clipboard          |
| `sshkeyfingerprint`         | ✅  | ✅  | ➖   | Show fingerprint of optional public key file, defa   |
| `sshkey`                    | ✅  | ✅  | ➖   | Find the public key file                             |
| `sshnewkey`                 | ✅  | ➖  | ➖  | Creates a new SSH key                                |
| `sshserverfingerprint`      | ➖  | ✅  | ➖   | Print fingerprint of server SSH key                  |
| `sshshowpub`                | ➖  | ✅  | ➖   | Print SSH public key                                 |
| `sshtest`                   | ✅  | ✅  | ➖   | Tests SSH connection to GitHub                       |
| `sshupload`                 | ➖  | ✅  | ➖   | Uploads public RSA SSH key to GitHub profile         |
| `stapply`                   | ✅  | ✅  | ➖   | Apply a git stash                                    |
| `starship_off`              | ✅  | ➖  | ➖   | Remove starship prompt                               |
| `starship_on`               | ✅  | ➖  | ➖   | Regenerate and load starship prompt                  |
| `stash`                     | ✅  | ✅  | ➖   | Git stash                                            |
| `status`                    | ✅  | ➖  | ➖   | Git status (full)                                    |
| `stdrop`                    | ✅  | ✅  | ➖   | Remove a git stash                                   |
| `stlist`                    | ✅  | ✅  | ➖   | List git stashes                                     |
| `stpop`                     | ✅  | ✅  | ➖   | Apply and remove the top git stash                   |
| `stsave`                    | ✅  | ✅  | ➖   | Save a git stash                                     |
| `stshow`                    | ✅  | ✅  | ➖   | Show a git stash                                     |
| `submodule`                 | ✅  | ✅  | ➖   | Git submodule                                        |
| `subrepo`                   | ✅  | ✅  | ➖   | Wrapper for git-subrepo                              |
| `surf`                      | ✅  | ➖  | ➖   | Opens Windsurf                                       |
| `suri`                      | ✅  | ✅  | ➖   | Init and update git submodules recursively           |
| `swift_pgp_key_import`      | ➖  | ✅  | ➖   | https://swift.org/download/#installation-1           |
| `swiftinfo`                 | ✅  | ➖  | ➖   | Print information about the current Swift toolchai   |
| `sync`                      | ➖  | ✅  | ➖   | Synchronizes git rep                                 |
| `sysinfo`                   | ✅  | ✅  | ➖   | Print system info                                    |
| `s`                         | ✅  | ✅  | ✅   | Display abbreviated git status                       |
| `tag`                       | ✅  | ✅  | ➖   | Manage git tags                                      |
| `tarball`                   | ✅  | ➖  | ➖   | Creates tarball                                      |
| `tarls`                     | ➖  | ✅  | ➖   | List contents of tarball                             |
| `textmate`                  | ➖  | ✅  | ➖   | Manage TextMate bundles                              |
| `theirs`                    | ➖  | ✅  | ➖   | When checking out paths from the index, check out    |
| `title`                     | ➖  | ✅  | ➖   | Sets window/tab title                                |
| `tminstall`                 | ➖  | ➖  | ➖   | Zsh function                                         |
| `tmsnapshots`               | ✅  | ➖  | ➖   | List Time Machine Snapshots                          |
| `todo`                      | ✅  | ➖  | ➖   | Edit rebase todo file                                |
| `toggle_wait`               | ✅  | ✅  | ➖   | Toggle the editor wait flag on VISUAL or EDITOR      |
| `tower`                     | ✅  | ✅  | ➖   | https://www.git-tower.com/help/mac/integration/cli   |
| `tracked`                   | ➖  | ✅  | ➖   | Displays files tracked in the current git repo       |
| `tracking`                  | ➖  | ✅  | ➖   | Display tracking info for current branch             |
| `track`                     | ✅  | ✅  | ➖   | Creates local tracking branch                        |
| `tube`                      | ➖  | ✅  | ➖   | Quick nav to Tube project                            |
| `unmount`                   | ➖  | ✅  | ➖   | Unmounts drive                                       |
| `unshallow`                 | ➖  | ✅  | ➖   | Converts shallow git repo to full                    |
| `unstage`                   | ✅  | ✅  | ➖   | Restores files in git index from HEAD                |
| `untar`                     | ✅  | ✅  | ➖   | Extracts tarball                                     |
| `untracked`                 | ✅  | ✅  | ➖   | Displays files not tracked in the current git repo   |
| `upstreamify`               | ✅  | ✅  | ➖   | Renames origin to upstream                           |
| `usage`                     | ✅  | ✅  | ➖   | Show disk usage for directory                        |
| `user.email`                | ✅  | ✅  | ➖   | Manages user.email git config setting                |
| `user.name`                 | ✅  | ✅  | ➖   | Manages user.name git config setting                 |
| `user.signingkey`           | ➖  | ✅  | ➖   | Manages user.signingkey git config setting           |
| `user_is_admin`             | ✅  | ✅  | ➖   | Tests whether USER is member of admin group          |
| `user_present`              | ➖  | ✅  | ➖   | Indicates whether a user is present                  |
| `user`                      | ➖  | ✅  | ➖   | Displays info about current user                     |
| `uuid_from_profile`         | ➖  | ➖  | ➖   | Zsh function                                         |
| `version_build`             | ➖  | ✅  | ➖   | Displays project version of current Xcode project    |
| `version_current`           | ➖  | ✅  | ➖   | Displays Xcode project version information           |
| `version_market`            | ➖  | ✅  | ➖   | Displays marketing version of current Xcode project  |
| `version`                   | ➖  | ✅  | ➖   | Manage version numbers for Xcode project             |
| `vi`                        | ✅  | ➖  | ➖   | Alias vi to nvim                                     |
| `vim`                       | ✅  | ➖  | ➖   | Alias vim to nvim                                    |
| `warpify`                   | ✅  | ➖  | ➖   | https://docs.warp.dev/features/subshells#automatic   |
| `whichjdk`                  | ➖  | ➖  | ➖   | Zsh function                                         |
| `wip`                       | ✅  | ➖  | ➖   | Commits WIP work                                     |
| `wt`                        | ✅  | ✅  | ➖   | Navigate to or create git worktrees (fzf/branch)     |
| `wt-env`                    | ✅  | ✅  | ➖   | Symlink env files from main worktree into current     |
| `xaccess`                   | ➖  | ✅  | ➖   | Read nginx access log                                |
| `xcbschemes`                | ➖  | ✅  | ➖   | Displays schemes for Xcode project                   |
| `xccheck`                   | ➖  | ✅  | ➖   | Validates Xcode application binary integrity using   |
| `xcinit`                    | ➖  | ✅  | ➖   | Runs Xcode new_project.rb ruby script                |
| `xclicense`                 | ➖  | ✅  | ➖   | Agree to Xcode license                               |
| `xclist`                    | ✅  | ✅  | ➖   | Prints a clean list of paths for all installed ver   |
| `xcode_plugin_update_uuid`  | ➖  | ➖  | ➖   | Zsh function                                         |
| `xcodes`                    | ➖  | ➖  | ➖   | Zsh function                                         |
| `xconfd`                    | ➖  | ✅  | ➖   | Quick dir navigation to nginx config dir             |
| `xconf`                     | ➖  | ✅  | ➖   | Edit nginx configuration files                       |
| `xcsp`                      | ✅  | ✅  | ➖   | Show the currently selected version of Xcode         |
| `xcss`                      | ✅  | ✅  | ➖   | Select a different version of Xcode                  |
| `xcswitch`                  | ✅  | ✅  | ➖   | Switch the active version of Xcode                   |
| `xcvall`                    | ✅  | ✅  | ➖   | Lists versions of all installed copies of Xcode      |
| `xcvmget`                   | ➖  | ✅  | ➖   | xcvmget                                              |
| `xcv`                       | ✅  | ✅  | ➖   | Displays version of currently selected Xcode         |
| `xc`                        | ✅  | ✅  | ➖   | Xcode wrapper function                               |
| `xcode`                     | ➖  | ✅  | ➖   | Installs and updates Xcode                           |
| `xerror`                    | ➖  | ✅  | ➖   | Read nginx error log                                 |
| `xlog`                      | ➖  | ✅  | ➖   | Quick nav to nginx log dir                           |
| `xps`                       | ➖  | ✅  | ➖   | Short alias for displaying nginx status              |
| `xp`                        | ➖  | ➖  | ➖   | Zsh function                                         |
| `xreload`                   | ➖  | ✅  | ➖   | Reload nginx configuration                           |
| `xstart`                    | ➖  | ✅  | ➖   | Starts nginx                                         |
| `xstatus`                   | ➖  | ✅  | ➖   | Displays nginx process information                   |
| `xstop`                     | ➖  | ✅  | ➖   | Stops nginx                                          |
| `xtest`                     | ➖  | ✅  | ➖   | Validate nginx config                                |
| `xtraffic`                  | ➖  | ✅  | ➖   | Display HTTP traffic stats using goaccess            |
| `xv`                        | ➖  | ✅  | ➖   | Prints Xcode version information                     |
| `yn`                        | ➖  | ✅  | ➖   | Prompt the user for a yes/no response. Returns 0 (   |
| `za`                        | ✅  | ➖  | ➖   | Zoxide add                                           |
| `zi`                        | ✅  | ➖  | ➖   | Zoxide interactive query                             |
| `zq`                        | ✅  | ➖  | ➖   | Zoxide query                                         |
| `zr`                        | ✅  | ➖  | ➖   | Zoxide remove                                        |
| `z`                         | ✅  | ➖  | ➖   | Nushell function                                     |

## Known Issues and Differences

This section documents known bugs (🐛) and implementation differences between shells.

_(Issues will be documented here as they are discovered during detailed comparison)_
