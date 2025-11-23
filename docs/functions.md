# Shell Functions and Aliases Status

This document tracks the implementation status of all shell functions and aliases across the four configured shells.

## Summary

**Total: 510 aliases/functions across 4 shells**

**Shell Statistics:**

- Fish: 405 functions (most comprehensive)
- Zsh: 156 functions
- Nushell: 76 aliases/functions (actively being configured)
- Bash: 2 aliases (minimal usage)

**Shell Coverage:**

- Implemented in all 4 shells: 1
- Implemented in 3 shells: 15
- Implemented in 2 shells: 96
- Implemented in 1 shell only: 398

**Functions Implemented in Multiple Shells:** 112

## Status Legend

- (blank) = Status unknown
- ➖ = Not implemented
- ✅ = Implemented
- 🐛 = Known bug or difference from other implementations

## Functions/Aliases Table

| Name                        | nu  | fish | zsh | bash | Description                                         |
| --------------------------- | --- | ---- | --- | ---- | --------------------------------------------------- |
| `__prev_token`              | ➖  | ✅   | ➖  | ➖   | Repeats last token on command line                  |
| `__re_extension`            | ➖  | ✅   | ➖  | ➖   | Remove extension from word under/before cursor      |
| `a`                         | ✅  | ✅   | ✅  | ➖   | Add files to git staging area                       |
| `aa`                        | ✅  | ✅   | ➖  | ➖   | Add all modified tracked files to git staging       |
| `abort`                     | ✅  | ✅   | ➖  | ➖   | Abort git merge/rebase/cherry-pick/am               |
| `add`                       | ✅  | ✅   | ➖  | ➖   | Add files to git staging area                       |
| `af`                        | ➖  | ✅   | ➖  | ➖   | Forced add files to git staging area                |
| `ai`                        | ➖  | ✅   | ➖  | ➖   | Interactively add files to git staging area         |
| `aks`                       | ➖  | ✅   | ➖  | ➖   | AKS related function                                |
| `amend`                     | ✅  | ✅   | ➖  | ➖   | Amend previous git commit                           |
| `amendne`                   | ✅  | ✅   | ✅  | ➖   | Amend commit without editing message                |
| `ane`                       | ✅  | ✅   | ✅  | ➖   | Git amend without changing commit message           |
| `ap`                        | ➖  | ✅   | ➖  | ➖   | Selectively add modifications to git staging        |
| `appcast_url`               | ➖  | ➖   | ✅  | ➖   | Calculate appcast checkpoint                        |
| `appicon`                   | ➖  | ✅   | ➖  | ➖   | Resizes AppIcon                                     |
| `apps`                      | ➖  | ✅   | ➖  | ➖   | Lists macOS apps currently installed                |
| `apv`                       | ➖  | ✅   | ✅  | ➖   | Quick nav to ApplePlatformVersions dir              |
| `ard_enable`                | ➖  | ✅   | ➖  | ➖   | Enables Apple Remote Desktop                        |
| `ard_restart`               | ➖  | ✅   | ➖  | ➖   | Restart ARD                                         |
| `arp-fix`                   | ➖  | ✅   | ✅  | ➖   | Disables unicast ARP cache validation               |
| `arpstatus`                 | ➖  | ✅   | ➖  | ➖   | Shows current value of arp_unicast_lim              |
| `as`                        | ➖  | ✅   | ➖  | ➖   | Open project in Android Studio                      |
| `assume`                    | ➖  | ✅   | ✅  | ➖   | Ignore changes to given files                       |
| `assumed`                   | ➖  | ✅   | ➖  | ➖   | List files for which changes are ignored            |
| `asv`                       | ➖  | ✅   | ➖  | ➖   | Quick nav to ApplePlatformVersions dir              |
| `auth`                      | ➖  | ✅   | ➖  | ➖   | Quick nav to KPAuth                                 |
| `aws_id`                    | ➖  | ✅   | ➖  | ➖   | AWS ID related function                             |
| `aws_test`                  | ➖  | ✅   | ➖  | ➖   | Test AWS credentials                                |
| `b`                         | ✅  | ➖   | ➖  | ➖   | Manage git branch                                   |
| `bak`                       | ➖  | ✅   | ✅  | ➖   | Backs up file by appending .bak extension           |
| `battleapp`                 | ➖  | ✅   | ➖  | ➖   | Quick nav to BattleApp dir                          |
| `bconfig`                   | ➖  | ✅   | ➖  | ➖   | Broot config                                        |
| `bd`                        | ✅  | ➖   | ✅  | ➖   | Forcefully delete branch from git                   |
| `bdm`                       | ➖  | ✅   | ➖  | ➖   | Build dependency management                         |
| `be`                        | ➖  | ➖   | ✅  | ➖   | Execute gems through Bundler                        |
| `bef`                       | ➖  | ✅   | ➖  | ➖   | Bundler exec function                               |
| `bi`                        | ➖  | ➖   | ✅  | ➖   | Install gems using Bundler                          |
| `bid`                       | ➖  | ✅   | ➖  | ➖   | Bundle ID related                                   |
| `big`                       | ➖  | ✅   | ✅  | ➖   | Install gem bundle using local Gemfile              |
| `bigfiles`                  | ➖  | ✅   | ➖  | ➖   | Find big files                                      |
| `bindings`                  | ➖  | ✅   | ➖  | ➖   | Show key bindings                                   |
| `binstall`                  | ➖  | ✅   | ➖  | ➖   | Install Bundler with proper bindir                  |
| `biq`                       | ➖  | ✅   | ➖  | ➖   | Bundle install quiet                                |
| `bisect`                    | ✅  | ➖   | ✅  | ➖   | Git bisect                                          |
| `blame`                     | ✅  | ➖   | ➖  | ➖   | Git blame                                           |
| `bo`                        | ➖  | ✅   | ➖  | ➖   | Bundle open                                         |
| `bog`                       | ➖  | ✅   | ✅  | ➖   | Update gem bundle using local Gemfile               |
| `bootcamp`                  | ➖  | ✅   | ➖  | ➖   | Restarts to Windows bootcamp                        |
| `bpi`                       | ➖  | ✅   | ➖  | ➖   | Run pod install through Bundler                     |
| `bpie`                      | ➖  | ✅   | ✅  | ➖   | Install pods for Example app                        |
| `bpiru`                     | ➖  | ✅   | ➖  | ➖   | Pod install through Bundler, update repos           |
| `bpiv`                      | ➖  | ✅   | ➖  | ➖   | Verbose pod install through Bundler                 |
| `bpo`                       | ➖  | ✅   | ➖  | ➖   | Bundle pod open                                     |
| `bpru`                      | ➖  | ✅   | ➖  | ➖   | Update CocoaPod repos                               |
| `bprum`                     | ➖  | ✅   | ➖  | ➖   | Update master CocoaPods repo                        |
| `bpu`                       | ➖  | ✅   | ➖  | ➖   | Update pods without updating repos                  |
| `bpuru`                     | ➖  | ✅   | ➖  | ➖   | Update pods after updating repos                    |
| `bpx`                       | ➖  | ✅   | ➖  | ➖   | Install bundle, pods, open in Xcode                 |
| `bq`                        | ➖  | ➖   | ✅  | ➖   | Query brew information                              |
| `br`                        | ➖  | ✅   | ➖  | ➖   | Broot launcher script                               |
| `bra`                       | ➖  | ✅   | ➖  | ➖   | Branch related                                      |
| `branch`                    | ➖  | ➖   | ✅  | ➖   | Manage git branches                                 |
| `brew_active_version`       | ➖  | ✅   | ➖  | ➖   | Show active brew version                            |
| `brew_cache_purge`          | ➖  | ✅   | ✅  | ➖   | Purges Homebrew cache                               |
| `brew_core`                 | ➖  | ✅   | ➖  | ➖   | Quick nav to homebrew-core dir                      |
| `brew_deps`                 | ➖  | ✅   | ➖  | ➖   | Lists dependencies of brew packages                 |
| `brew_edit`                 | ➖  | ✅   | ➖  | ➖   | Manages Homebrew formulae                           |
| `brew_home`                 | ➖  | ✅   | ➖  | ➖   | Prints Homebrew home dir or cellar location         |
| `brew_installed`            | ➖  | ✅   | ➖  | ➖   | List installed brew packages                        |
| `brew_logs`                 | ➖  | ✅   | ✅  | ➖   | Quick nav to Homebrew logs dir                      |
| `brew_test`                 | ➖  | ✅   | ➖  | ➖   | Installs and tests Homebrew formula                 |
| `brew_versions`             | ➖  | ➖   | ✅  | ➖   | Lists installed versions of formula                 |
| `bu`                        | ➖  | ✅   | ➖  | ➖   | Update gems in bundle                               |
| `bub`                       | ➖  | ✅   | ➖  | ➖   | Update locked version of bundler                    |
| `bug`                       | ➖  | ✅   | ➖  | ➖   | Update gem bundle using local Gemfile               |
| `build_dir`                 | ➖  | ✅   | ➖  | ➖   | Displays Xcode build dir of current project         |
| `bundle-pull`               | ➖  | ✅   | ➖  | ➖   | Copies dirty working copy between hosts             |
| `butler`                    | ➖  | ✅   | ➖  | ➖   | Butler related                                      |
| `bv`                        | ➖  | ✅   | ➖  | ➖   | Bundle version                                      |
| `bvv`                       | ➖  | ✅   | ➖  | ➖   | Bundle verbose version                              |
| `c`                         | ✅  | ✅   | ✅  | ➖   | Performs git checkout                               |
| `cargo_target`              | ➖  | ✅   | ✅  | ➖   | Spins up RAM disk for Cargo target output           |
| `carthage-clean`            | ➖  | ✅   | ➖  | ➖   | Clean Carthage                                      |
| `cask_audit`                | ➖  | ✅   | ➖  | ➖   | Audit Homebrew cask                                 |
| `cask_cache`                | ➖  | ✅   | ➖  | ➖   | Cask cache location                                 |
| `cask_dir`                  | ➖  | ✅   | ➖  | ➖   | Quick nav to Homebrew Casks tap                     |
| `cat`                       | ➖  | ✅   | ✅  | ➖   | Wrapper for bat                                     |
| `cball`                     | ➖  | ➖   | ✅  | ➖   | Build all platforms using Carthage                  |
| `cbootios`                  | ➖  | ✅   | ➖  | ➖   | Bootstrap Carthage dependencies for iOS             |
| `cco`                       | ➖  | ✅   | ➖  | ➖   | Checkout source of dependencies using Carthage      |
| `ccos`                      | ➖  | ✅   | ➖  | ➖   | Checkout source using Carthage over SSH             |
| `ccoss`                     | ➖  | ✅   | ➖  | ➖   | Checkout into submodules using Carthage SSH         |
| `ccu`                       | ➖  | ➖   | ✅  | ➖   | Update dependencies without building Carthage       |
| `ccuss`                     | ➖  | ✅   | ➖  | ➖   | Update in submodules without build Carthage SSH     |
| `cfrmodel`                  | ➖  | ✅   | ✅  | ➖   | Quick dir nav to CFR Model project                  |
| `cfrservice`                | ➖  | ✅   | ✅  | ➖   | Quick dir nav to CFR Service project                |
| `changelog`                 | ➖  | ✅   | ➖  | ➖   | Create changelog                                    |
| `chat`                      | ➖  | ✅   | ➖  | ➖   | Chat function                                       |
| `checkout`                  | ➖  | ➖   | ✅  | ➖   | Perform git checkout                                |
| `cherry-pick`               | ✅  | ➖   | ➖  | ➖   | Git cherry-pick                                     |
| `chexe`                     | ➖  | ✅   | ✅  | ➖   | Set executable permissions                          |
| `clamp`                     | ➖  | ✅   | ➖  | ➖   | Quick nav to Clamp project dir                      |
| `cleanall`                  | ➖  | ✅   | ➖  | ➖   | Recursively clean all Gradle projects               |
| `clone`                     | ✅  | ✅   | ✅  | ➖   | Git clone, then configure repo user                 |
| `clone_or_pull`             | ➖  | ✅   | ✅  | ➖   | Clone fresh or pull existing git repo               |
| `cmt`                       | ✅  | ✅   | ➖  | ➖   | Commit with message                                 |
| `cmtne`                     | ✅  | ✅   | ➖  | ➖   | Commit with default message                         |
| `co`                        | ✅  | ➖   | ➖  | ➖   | Git checkout operations                             |
| `commit`                    | ✅  | ➖   | ➖  | ➖   | Git commit                                          |
| `configg`                   | ➖  | ➖   | ✅  | ➖   | Manage global git configuration                     |
| `console_user`              | ➖  | ✅   | ➖  | ➖   | Prints username of console user                     |
| `cont`                      | ➖  | ✅   | ✅  | ➖   | Commit merge or continue rebase/cherry-pick         |
| `create_cert_localhost`     | ➖  | ✅   | ➖  | ➖   | Create self-signed cert for localhost               |
| `createdirs`                | ➖  | ✅   | ➖  | ➖   | Creates set of directories if missing               |
| `cron_edit`                 | ➖  | ✅   | ➖  | ➖   | Opens cron file in editor                           |
| `cron_list`                 | ➖  | ✅   | ➖  | ➖   | Prints cron file                                    |
| `cron_reload`               | ➖  | ✅   | ➖  | ➖   | Reloads cron file                                   |
| `current_branch`            | ➖  | ✅   | ➖  | ➖   | Displays current branch name                        |
| `d`                         | ✅  | ✅   | ✅  | ➖   | Git diff                                            |
| `dash`                      | ➖  | ➖   | ✅  | ➖   | Dash shell integration                              |
| `dce`                       | ➖  | ✅   | ➖  | ➖   | Execute command in running container                |
| `dci`                       | ➖  | ✅   | ➖  | ➖   | Display detailed docker container info              |
| `dck`                       | ➖  | ✅   | ➖  | ➖   | Alias for dcstop                                    |
| `dcl`                       | ➖  | ✅   | ➖  | ➖   | List all docker containers                          |
| `dcp`                       | ➖  | ✅   | ➖  | ➖   | Remove all stopped docker containers                |
| `dcr`                       | ➖  | ✅   | ➖  | ➖   | Remove running docker containers                    |
| `dcstart`                   | ➖  | ✅   | ➖  | ➖   | Start stopped docker containers                     |
| `dcstop`                    | ➖  | ✅   | ➖  | ➖   | Stop running docker containers                      |
| `dct`                       | ➖  | ✅   | ➖  | ➖   | Display running processes of docker container       |
| `dcw`                       | ➖  | ➖   | ✅  | ➖   | Diff git staging area using word diff               |
| `ddc`                       | ➖  | ✅   | ➖  | ➖   | Docker deep clean                                   |
| `ddd`                       | ➖  | ✅   | ✅  | ➖   | Delete Derived Data                                 |
| `debug`                     | ➖  | ✅   | ✅  | ➖   | Prints args only when debug env var set             |
| `deflate`                   | ➖  | ✅   | ➖  | ➖   | Unzip git blobs                                     |
| `delete-tag`                | ✅  | ➖   | ✅  | ➖   | Delete git tag locally and remotely                 |
| `deleted`                   | ➖  | ✅   | ➖  | ➖   | Lists files deleted from git history                |
| `delivery`                  | ➖  | ✅   | ➖  | ➖   | Quick nav to shared library project                 |
| `deploy`                    | ➖  | ✅   | ➖  | ➖   | Builds and deploys static content                   |
| `derived_data`              | ➖  | ✅   | ✅  | ➖   | Spins up RAM disk for Xcode DerivedData             |
| `dib`                       | ➖  | ✅   | ➖  | ➖   | Build image from Dockerfile                         |
| `difftool`                  | ✅  | ➖   | ➖  | ➖   | Git diff tool                                       |
| `dii`                       | ➖  | ✅   | ➖  | ➖   | Display detailed docker image info                  |
| `dil`                       | ➖  | ✅   | ✅  | ➖   | List docker images                                  |
| `din`                       | ➖  | ✅   | ➖  | ➖   | Remove all docker images                            |
| `dip`                       | ➖  | ✅   | ➖  | ➖   | Remove unused docker images                         |
| `dir`                       | ➖  | ✅   | ➖  | ➖   | Remove docker images forcefully                     |
| `displays`                  | ➖  | ✅   | ➖  | ➖   | Show info about connected displays                  |
| `dit`                       | ➖  | ✅   | ✅  | ➖   | Create tag TARGET_IMAGE refers to SOURCE_IMAGE      |
| `ditto_debug`               | ➖  | ✅   | ➖  | ➖   | Toggles DITTO_DEBUG flag                            |
| `diw`                       | ➖  | ✅   | ➖  | ➖   | Remove all Ping Identity docker images              |
| `dlf`                       | ➖  | ✅   | ➖  | ➖   | Alias of dlogs                                      |
| `dlogs`                     | ➖  | ✅   | ✅  | ➖   | Fetch logs of docker container                      |
| `dnc`                       | ➖  | ✅   | ➖  | ➖   | Create docker network                               |
| `dni`                       | ➖  | ✅   | ➖  | ➖   | Display detailed docker network info                |
| `dnl`                       | ➖  | ✅   | ➖  | ➖   | List docker networks                                |
| `dnp`                       | ➖  | ✅   | ➖  | ➖   | Remove all unused docker networks                   |
| `dnr`                       | ➖  | ✅   | ✅  | ➖   | Remove docker networks                              |
| `dnuke`                     | ➖  | ✅   | ➖  | ➖   | Remove unused docker images not just dangling       |
| `doc`                       | ➖  | ✅   | ➖  | ➖   | Quickly launch docker containers in current dir     |
| `dotfiles`                  | ➖  | ✅   | ➖  | ➖   | Edit dotfiles                                       |
| `dpd`                       | ➖  | ✅   | ➖  | ➖   | Stop containers and remove containers/networks      |
| `dpl`                       | ➖  | ✅   | ✅  | ➖   | View output from docker containers                  |
| `dpp`                       | ➖  | ✅   | ➖  | ➖   | List docker containers                              |
| `dpr`                       | ➖  | ✅   | ➖  | ➖   | Restart services managed by docker compose          |
| `dps`                       | ➖  | ✅   | ➖  | ➖   | List docker containers                              |
| `dpu`                       | ➖  | ✅   | ✅  | ➖   | Build/create/start/attach containers for service    |
| `dra`                       | ➖  | ✅   | ➖  | ➖   | Remove all stopped docker containers                |
| `dsa`                       | ➖  | ✅   | ➖  | ➖   | Stop all running docker containers                  |
| `dsl`                       | ➖  | ✅   | ➖  | ➖   | List docker services                                |
| `dsr`                       | ➖  | ✅   | ➖  | ➖   | Remove docker services                              |
| `dss`                       | ➖  | ✅   | ✅  | ➖   | Scale replicated docker services                    |
| `dvc`                       | ➖  | ✅   | ➖  | ➖   | Create docker volume                                |
| `dvi`                       | ➖  | ✅   | ➖  | ➖   | Display detailed docker volume info                 |
| `dvl`                       | ➖  | ✅   | ✅  | ➖   | List docker volumes                                 |
| `dvp`                       | ➖  | ✅   | ➖  | ➖   | Remove all unused local docker volumes              |
| `dvr`                       | ➖  | ✅   | ➖  | ➖   | Remove docker volumes                               |
| `e`                         | ✅  | ➖   | ✅  | ➖   | Edit file (opens folder if no args)                 |
| `edit`                      | ➖  | ✅   | ✅  | ➖   | Edit using configured VISUAL editor                 |
| `editorconfig`              | ➖  | ✅   | ✅  | ➖   | Generates an editorconfig                           |
| `email_url`                 | ➖  | ✅   | ➖  | ➖   | Determines appropriate contact for URL              |
| `en1`                       | ➖  | ✅   | ➖  | ➖   | Shows en1 network interface                         |
| `entitlements`              | ➖  | ➖   | ✅  | ➖   | Display entitlements in codesign info               |
| `epoc_date`                 | ➖  | ✅   | ➖  | ➖   | Converts epoch timestamps to date                   |
| `erase`                     | ➖  | ➖   | ✅  | ➖   | Erase fish functions                                |
| `error`                     | ➖  | ✅   | ➖  | ➖   | Prints args to stderr                               |
| `fe`                        | ➖  | ✅   | ✅  | ➖   | Edit a function                                     |
| `fetch`                     | ✅  | ✅   | ➖  | ➖   | Fetch branch from default git remote                |
| `ff`                        | ➖  | ✅   | ➖  | ➖   | Edit fish dotfiles                                  |
| `file_base`                 | ➖  | ✅   | ➖  | ➖   | Prints base name after dropping extension           |
| `fileowner`                 | ➖  | ✅   | ✅  | ➖   | Displays owner of file                              |
| `files_changed`             | ➖  | ✅   | ➖  | ➖   | Shows files changed since treeish                   |
| `filesize`                  | ➖  | ✅   | ➖  | ➖   | Prints size of file in bytes                        |
| `find_appcast`              | ➖  | ✅   | ➖  | ➖   | Alias for Homebrew find_appcast script              |
| `find_dotnet`               | ➖  | ✅   | ➖  | ➖   | Locates all copies of dotnet command                |
| `find_file`                 | ➖  | ✅   | ➖  | ➖   | Finds files under given base_dir                    |
| `findup`                    | ➖  | ✅   | ➖  | ➖   | Recursively searches up directory tree              |
| `firewall`                  | ➖  | ✅   | ➖  | ➖   | Firewall function                                   |
| `fish_vendor_functions_dir` | ➖  | ✅   | ➖  | ➖   | Prints path to fish vendor_functions.d              |
| `fishfiles`                 | ➖  | ✅   | ➖  | ➖   | Edit fish dotfiles                                  |
| `fishlog`                   | ➖  | ➖   | ✅  | ➖   | View fish daemon log                                |
| `format-patch`              | ➖  | ➖   | ✅  | ➖   | Git format-patch wrapper                            |
| `fq`                        | ➖  | ➖   | ✅  | ➖   | Check for existence of function                     |
| `func`                      | ➖  | ✅   | ✅  | ➖   | Prints colorized indented source of function        |
| `func_count`                | ➖  | ➖   | ✅  | ➖   | Prints count of all functions                       |
| `function_template`         | ➖  | ✅   | ➖  | ➖   | Prints function_template                            |
| `funky`                     | ➖  | ✅   | ➖  | ➖   | Searches for functions with string in def           |
| `g`                         | ✅  | ✅   | ✅  | ➖   | Gradle alias                                        |
| `ga`                        | ✅  | ➖   | ➖  | ➖   | Git add                                             |
| `gbe`                       | ➖  | ✅   | ➖  | ➖   | Shows Gradle build environment                      |
| `gc`                        | ✅  | ✅   | ✅  | ➖   | Run git garbage collection                          |
| `gd`                        | ✅  | ✅   | ➖  | ➖   | Launch gradle in debug mode                         |
| `gem_install`               | ➖  | ✅   | ➖  | ➖   | Installs Ruby gem at system level                   |
| `gem_pristine`              | ➖  | ✅   | ➖  | ➖   | Runs pristine command for all gems                  |
| `gem_update`                | ➖  | ✅   | ➖  | ➖   | Updates Ruby gem at system level                    |
| `gemdir`                    | ➖  | ✅   | ➖  | ➖   | Prints path to system gem dir                       |
| `genv`                      | ➖  | ✅   | ➖  | ➖   | Grep environment                                    |
| `getudid`                   | ➖  | ✅   | ✅  | ➖   | Prints and copies UDID of connected iOS device      |
| `gh_token_test`             | ➖  | ✅   | ➖  | ➖   | Tests GitHub personal access token                  |
| `gi`                        | ➖  | ✅   | ➖  | ➖   | Creates .gitignore file using gitignore.io          |
| `ginit`                     | ➖  | ✅   | ➖  | ➖   | Git init                                            |
| `git-plist-filter`          | ➖  | ✅   | ✅  | ➖   | Converts plist data to XML format                   |
| `git_clean`                 | ➖  | ✅   | ➖  | ➖   | Clean non-tracked files from working tree           |
| `git_inside_repo`           | ➖  | ✅   | ✅  | ➖   | Detects whether $PWD is inside git repo             |
| `git_repo_clean`            | ➖  | ✅   | ➖  | ➖   | Detects clean work tree                             |
| `git_repo_dirty`            | ➖  | ✅   | ➖  | ➖   | Detects dirty work tree                             |
| `gitconfig_setup`           | ➖  | ➖   | ✅  | ➖   | Sets git user.name and user.email in XDG            |
| `gk`                        | ➖  | ✅   | ➖  | ➖   | Quick launch for GitKraken                          |
| `gl`                        | ✅  | ➖   | ➖  | ➖   | Git pull                                            |
| `gp`                        | ✅  | ✅   | ➖  | ➖   | Edit current user Gradle properties                 |
| `gpgcopypub`                | ➖  | ➖   | ✅  | ➖   | Copies public key for any GPG key found             |
| `gpgkeyid`                  | ➖  | ✅   | ✅  | ➖   | Prints long format key IDs of all GPG keys          |
| `gpgrep`                    | ➖  | ✅   | ➖  | ➖   | Grep for gradle properties                          |
| `gpgtest`                   | ➖  | ➖   | ✅  | ➖   | Test GPG key with passphrase                        |
| `gpi`                       | ➖  | ✅   | ✅  | ➖   | Runs podInstall gradle task                         |
| `gpv`                       | ➖  | ✅   | ➖  | ➖   | Quick nav to GooglePlatformVersions dir             |
| `gradle_cache_clean`        | ➖  | ✅   | ➖  | ➖   | Cleans gradle cache                                 |
| `gradle_kill`               | ➖  | ✅   | ➖  | ➖   | Kills all running gradle processes                  |
| `gradle_wrapper`            | ➖  | ✅   | ➖  | ➖   | Upstalls gradle wrapper                             |
| `gradle_wrapper_add`        | ➖  | ✅   | ➖  | ➖   | Updates build.gradle and runs wrapper task          |
| `gs`                        | ✅  | ➖   | ➖  | ➖   | Git status short format                             |
| `gst`                       | ✅  | ➖   | ➖  | ➖   | Git status                                          |
| `gt`                        | ➖  | ✅   | ➖  | ➖   | Alias for gradle tasks                              |
| `gta`                       | ➖  | ✅   | ➖  | ➖   | Alias for gradle tasks --all                        |
| `gv`                        | ➖  | ✅   | ✅  | ➖   | Prints gradle version                               |
| `gw`                        | ➖  | ✅   | ✅  | ➖   | Invokes build using Gradle wrapper script           |
| `gwd`                       | ➖  | ✅   | ➖  | ➖   | Debug gradle                                        |
| `gwo`                       | ➖  | ✅   | ✅  | ➖   | Gradle wrapper offline                              |
| `gwv`                       | ➖  | ✅   | ✅  | ➖   | Prints version of gradle wrapper                    |
| `headshort`                 | ➖  | ➖   | ✅  | ➖   | Prints 7-char abbreviated sha1 of HEAD              |
| `hgrep`                     | ➖  | ✅   | ✅  | ➖   | Grep command history                                |
| `home`                      | ➖  | ✅   | ➖  | ➖   | Go home                                             |
| `htoptions`                 | ➖  | ➖   | ✅  | ➖   | Send HTTP request using OPTIONS method              |
| `icloud`                    | ➖  | ➖   | ✅  | ➖   | Changes directory to ICLOUD_HOME                    |
| `ida`                       | ➖  | ✅   | ✅  | ➖   | Launch IDA with elevated privileges                 |
| `ignore`                    | ➖  | ✅   | ➖  | ➖   | Adds lines to .gitignore                            |
| `ignored`                   | ➖  | ✅   | ➖  | ➖   | Show files ignored by git                           |
| `init`                      | ✅  | ✅   | ➖  | ➖   | Initialize new git repo in current/optional dir     |
| `is_arm`                    | ➖  | ✅   | ➖  | ➖   | Tests whether current system is arm                 |
| `is_console_user`           | ➖  | ✅   | ➖  | ➖   | Tests whether current user logged into console      |
| `is_coreutils`              | ➖  | ✅   | ➖  | ➖   | Tests whether coreutils is installed                |
| `is_linux`                  | ➖  | ✅   | ➖  | ➖   | Tests whether current computer running Linux        |
| `is_mac`                    | ➖  | ✅   | ➖  | ➖   | Tests whether current computer running macOS        |
| `is_octodec`                | ➖  | ✅   | ✅  | ➖   | Tests whether current computer is octodec           |
| `is_phatmini`               | ➖  | ✅   | ➖  | ➖   | Tests whether current computer is phatmini          |
| `is_ssh`                    | ➖  | ✅   | ➖  | ➖   | Tests whether current session is SSH                |
| `itwire`                    | ➖  | ➖   | ✅  | ➖   | Quick dir navigation to ITWire                      |
| `j`                         | ✅  | ➖   | ➖  | ➖   | Just command runner                                 |
| `jabba`                     | ➖  | ✅   | ➖  | ➖   | Fish shell wrapper for jabba                        |
| `jdk`                       | ➖  | ✅   | ➖  | ➖   | Manage installed JDKs                               |
| `jftemplate`                | ➖  | ✅   | ➖  | ➖   | Create new repo based on JenkinsfileTemplate        |
| `jv`                        | ➖  | ✅   | ➖  | ➖   | Displays Java version number                        |
| `kpm`                       | ➖  | ✅   | ➖  | ➖   | Quick dir navigation to kpmobile                    |
| `l`                         | ✅  | ➖   | ✅  | ➖   | List files showing size, show type, human read      |
| `la`                        | ✅  | ➖   | ✅  | ✅   | Long list, almost all, show type, human read        |
| `ldot`                      | ➖  | ➖   | ✅  | ➖   | List hidden files                                   |
| `lg`                        | ✅  | ✅   | ✅  | ➖   | Alias for lg10                                      |
| `lg1`                       | ✅  | ✅   | ✅  | ➖   | Pretty history graph with one commit                |
| `lg10`                      | ✅  | ✅   | ✅  | ➖   | Pretty history graph with ten commits               |
| `lga`                       | ➖  | ✅   | ✅  | ➖   | Pretty history graph showing all                    |
| `lgfind`                    | ➖  | ✅   | ✅  | ➖   | Search through lightweight log lg for pattern       |
| `lgg`                       | ➖  | ✅   | ✅  | ➖   | Pretty history graph                                |
| `lggrep`                    | ➖  | ➖   | ✅  | ➖   | Grep through lightweight log lg for regex           |
| `license`                   | ➖  | ✅   | ➖  | ➖   | Writes LICENSE.md, adds link to readme              |
| `line`                      | ➖  | ✅   | ➖  | ➖   | Extracts single line of stdin                       |
| `list`                      | ➖  | ✅   | ➖  | ➖   | Prints list with each element on separate line      |
| `ll`                        | ✅  | ✅   | ✅  | ✅   | Long list                                           |
| `log`                       | ✅  | ➖   | ✅  | ➖   | Alias for git log                                   |
| `log1`                      | ➖  | ✅   | ➖  | ➖   | Alias for git log                                   |
| `log10`                     | ✅  | ✅   | ✅  | ➖   | Alias for git log                                   |
| `ls`                        | ➖  | ✅   | ✅  | ➖   | List files with colors and trailing slashes         |
| `ls-files`                  | ✅  | ➖   | ➖  | ➖   | Git ls-files                                        |
| `ls-remote`                 | ✅  | ➖   | ➖  | ➖   | Git ls-remote                                       |
| `lt`                        | ➖  | ➖   | ✅  | ➖   | Long list sorted by date, show type, human read     |
| `ltime`                     | ➖  | ✅   | ✅  | ➖   | Time last command took to complete                  |
| `m`                         | ✅  | ➖   | ➖  | ➖   | Git merge                                           |
| `macos`                     | ➖  | ➖   | ✅  | ➖   | Manage macOS system updates                         |
| `mas_tap`                   | ➖  | ✅   | ➖  | ➖   | Prints path to installed mas tap                    |
| `masd`                      | ➖  | ✅   | ✅  | ➖   | Quick nav to mas dir                                |
| `maslink`                   | ➖  | ✅   | ➖  | ➖   | Links debug build of mas into path                  |
| `masrm`                     | ➖  | ✅   | ➖  | ➖   | Uninstall mas package                               |
| `masshow`                   | ➖  | ✅   | ➖  | ➖   | Show which copy of mas is active                    |
| `md`                        | ➖  | ✅   | ➖  | ➖   | Make dir and pushd into it                          |
| `mdk`                       | ➖  | ✅   | ✅  | ➖   | Quick nav to MDK                                    |
| `mdp`                       | ➖  | ✅   | ➖  | ➖   | Quick nav to mdp dir                                |
| `members`                   | ➖  | ➖   | ✅  | ➖   | List members of given group                         |
| `merge`                     | ✅  | ➖   | ➖  | ➖   | Git merge                                           |
| `merge-base`                | ➖  | ➖   | ✅  | ➖   | Git merge-base wrapper                              |
| `mergetool`                 | ✅  | ➖   | ➖  | ➖   | Git merge tool                                      |
| `minic`                     | ➖  | ✅   | ➖  | ➖   | SSH into mini as chatelain                          |
| `mirrored-pods`             | ➖  | ✅   | ➖  | ➖   | Jump to kp-mirrored-pods dir                        |
| `mkdir`                     | ➖  | ✅   | ➖  | ➖   | Create directory and set CWD                        |
| `moj_host`                  | ➖  | ✅   | ➖  | ➖   | Prints emoji for current host                       |
| `moj_user`                  | ➖  | ✅   | ✅  | ➖   | Prints emoji for current user                       |
| `mpv`                       | ➖  | ✅   | ✅  | ➖   | Quick nav to MicrosoftPlatformVersions dir          |
| `mt`                        | ➖  | ➖   | ✅  | ➖   | Short alias for git mergetool                       |
| `multipass-start`           | ➖  | ✅   | ➖  | ➖   | Starts multipass service and GUI app                |
| `mvn_local`                 | ➖  | ✅   | ➖  | ➖   | Displays path to Maven local repo                   |
| `nav`                       | ➖  | ✅   | ➖  | ➖   | Quick nav to dir. Creates if not present            |
| `nix_install`               | ➖  | ➖   | ✅  | ➖   | Installs nix tools                                  |
| `nixgc`                     | ➖  | ✅   | ➖  | ➖   | Runs nix garbage collection and optimisation        |
| `nixtest`                   | ➖  | ✅   | ➖  | ➖   | Tests Nix installation                              |
| `nodef`                     | ➖  | ✅   | ➖  | ➖   | Removes default.profraw file                        |
| `nv`                        | ➖  | ✅   | ➖  | ➖   | nv function                                         |
| `o`                         | ✅  | ➖   | ✅  | ➖   | Short alias for open                                |
| `objg`                      | ➖  | ✅   | ✅  | ➖   | Quick nav to Objective-Git                          |
| `octodec`                   | ➖  | ✅   | ✅  | ➖   | SSH to octodec                                      |
| `octopad`                   | ➖  | ✅   | ➖  | ➖   | Quick nav to Octopad project                        |
| `ol`                        | ➖  | ➖   | ✅  | ➖   | Quick dir navigation to Outlets                     |
| `omf_update`                | ➖  | ➖   | ✅  | ➖   | Updates oh-my-fish and bundled packages             |
| `onyx`                      | ➖  | ✅   | ➖  | ➖   | Opens Onyx Icons folder in Finder                   |
| `openports`                 | ➖  | ➖   | ✅  | ➖   | Lists open ports for current user                   |
| `osversion`                 | ➖  | ✅   | ➖  | ➖   | Prints macOS version number                         |
| `ow`                        | ➖  | ✅   | ➖  | ➖   | Opens Xcode workspace in current or subdir          |
| `ox`                        | ➖  | ✅   | ➖  | ➖   | Open Xcode project in current dir                   |
| `pbjup`                     | ➖  | ✅   | ✅  | ➖   | Upgrade personal jenkins formula and restart        |
| `pcopy`                     | ➖  | ➖   | ✅  | ➖   | Copy current dir path into pasteboard               |
| `pdo`                       | ➖  | ✅   | ➖  | ➖   | Quick nav to Ping DevOps projects                   |
| `pdob`                      | ➖  | ✅   | ➖  | ➖   | Quick nav to pingidentity-docker-builds             |
| `pdog`                      | ➖  | ✅   | ➖  | ➖   | Quick nav to pingidentity-devops-getting-started    |
| `pdos`                      | ➖  | ✅   | ➖  | ➖   | Quick nav to pingidentity-server-profiles           |
| `phatmini`                  | ➖  | ✅   | ➖  | ➖   | SSH to phatmini                                     |
| `pi`                        | ➖  | ✅   | ➖  | ➖   | Runs pod install                                    |
| `pick`                      | ✅  | ➖   | ✅  | ➖   | Short alias for cherry-pick                         |
| `pie`                       | ➖  | ✅   | ➖  | ➖   | Install pods for Example app                        |
| `piev`                      | ➖  | ✅   | ➖  | ➖   | Install pods for Example with verbose output        |
| `pil`                       | ➖  | ✅   | ✅  | ➖   | Special "local" pod install for KP Mobile           |
| `ping1`                     | ➖  | ✅   | ➖  | ➖   | Sends single ping to host                           |
| `pingdownload`              | ➖  | ✅   | ➖  | ➖   | Downloads Ping DevOps tools                         |
| `pingmini`                  | ➖  | ✅   | ➖  | ➖   | Check network status of mini                        |
| `pinkit`                    | ➖  | ✅   | ➖  | ➖   | Quick nav to PinKit dir                             |
| `pip`                       | ➖  | ✅   | ➖  | ➖   | Wrapper for pip                                     |
| `pipeline`                  | ➖  | ✅   | ➖  | ➖   | Quick nav to pipeline plugin project                |
| `piq`                       | ➖  | ✅   | ➖  | ➖   | Quiet pod install                                   |
| `piru`                      | ➖  | ✅   | ➖  | ➖   | Install pods after updating repos                   |
| `piv`                       | ➖  | ✅   | ➖  | ➖   | Install pods with verbose output                    |
| `pkgexpand`                 | ➖  | ✅   | ➖  | ➖   | Expands pkg file                                    |
| `pl_edit`                   | ➖  | ➖   | ✅  | ➖   | Edit Powerline config files                         |
| `play`                      | ➖  | ✅   | ➖  | ➖   | Open Xcode playground                               |
| `plcat`                     | ➖  | ✅   | ➖  | ➖   | Show Divvy plist                                    |
| `plformat`                  | ➖  | ✅   | ➖  | ➖   | Format plist files                                  |
| `pll`                       | ➖  | ✅   | ➖  | ➖   | Lint pod library in current directory               |
| `pllvnc`                    | ➖  | ✅   | ➖  | ➖   | Lint pod in current dir with verbose output         |
| `po`                        | ➖  | ✅   | ➖  | ➖   | List outdated pods                                  |
| `pod`                       | ➖  | ✅   | ➖  | ➖   | Display local version of CocoaPods                  |
| `poe`                       | ➖  | ✅   | ➖  | ➖   | Show outdated pods for example app                  |
| `pop`                       | ✅  | ✅   | ➖  | ➖   | Undo last commit but leave staging area             |
| `ports`                     | ➖  | ✅   | ➖  | ➖   | Shows open TCP ports                                |
| `powerlinetest`             | ➖  | ➖   | ✅  | ➖   | Print special Powerline characters test font        |
| `pp`                        | ➖  | ✅   | ➖  | ➖   | Publish the phatblat branch                         |
| `prefs`                     | ➖  | ✅   | ➖  | ➖   | Opens System Preferences to specific pane           |
| `provisioning_print`        | ➖  | ➖   | ✅  | ➖   | Prints text version of provisioning profile         |
| `pru`                       | ➖  | ✅   | ✅  | ➖   | Update CococaPod repos                              |
| `prum`                      | ➖  | ✅   | ➖  | ➖   | Update master CocoaPods repo                        |
| `prune`                     | ✅  | ✅   | ✅  | ➖   | Prune obsolete remote branches on given remote      |
| `prunep`                    | ➖  | ✅   | ➖  | ➖   | Prunes phatblat remote                              |
| `pu`                        | ➖  | ✅   | ✅  | ➖   | Update Pods without updating repos                  |
| `pue`                       | ➖  | ✅   | ➖  | ➖   | Update example app pods without updating repos      |
| `pul`                       | ➖  | ✅   | ➖  | ➖   | Special "local" pod update for KP Mobile            |
| `pull`                      | ✅  | ➖   | ➖  | ➖   | Git pull                                            |
| `pull_ssh_config`           | ➖  | ✅   | ➖  | ➖   | Copies SSH config to local                          |
| `push`                      | ✅  | ➖   | ✅  | ➖   | Git push                                            |
| `pushf`                     | ✅  | ✅   | ✅  | ➖   | Force git push                                      |
| `pusht`                     | ➖  | ✅   | ➖  | ➖   | Push git tags                                       |
| `pv`                        | ➖  | ✅   | ➖  | ➖   | Display local version of CocoaPods                  |
| `qllist`                    | ➖  | ➖   | ✅  | ➖   | List QuickLook plugins                              |
| `r`                         | ✅  | ➖   | ✅  | ➖   | Interactive rebase for last few commits             |
| `ra`                        | ➖  | ➖   | ✅  | ➖   | Adds git remote                                     |
| `ramdisk`                   | ➖  | ✅   | ➖  | ➖   | Ramdisk function                                    |
| `realmos`                   | ➖  | ➖   | ✅  | ➖   | Manage Realm Object Server                          |
| `rebase`                    | ✅  | ➖   | ✅  | ➖   | Git rebase                                          |
| `reflog`                    | ✅  | ➖   | ➖  | ➖   | Git reflog                                          |
| `reload`                    | ➖  | ✅   | ✅  | ➖   | Reloads single function or entire fish shell        |
| `remote`                    | ✅  | ➖   | ➖  | ➖   | Git remote                                          |
| `remote_for_current_branch` | ➖  | ✅   | ➖  | ➖   | Displays name of remote for current branch          |
| `renew_certificates`        | ➖  | ✅   | ➖  | ➖   | Renews certificates on servers                      |
| `repo_new`                  | ➖  | ✅   | ➖  | ➖   | Creates new GitHub repo using local dir as root     |
| `reset`                     | ✅  | ➖   | ➖  | ➖   | Git reset                                           |
| `restore`                   | ✅  | ✅   | ➖  | ➖   | Discards changes in working tree                    |
| `rev-parse`                 | ✅  | ➖   | ➖  | ➖   | Git rev-parse                                       |
| `review`                    | ➖  | ➖   | ✅  | ➖   | Review given commit with detailed info and diff     |
| `rewrite`                   | ➖  | ✅   | ➖  | ➖   | Rewrite commits changing author/committer info      |
| `ri`                        | ✅  | ➖   | ➖  | ➖   | Interactive rebase for last N commits (default 10)  |
| `rl`                        | ➖  | ➖   | ✅  | ➖   | Quick dir navigation to reflog                      |
| `root`                      | ➖  | ✅   | ➖  | ➖   | Display path to root of current git repo            |
| `ruby_upgrade`              | ➖  | ✅   | ✅  | ➖   | Upgrades ruby across major versions                 |
| `rubygems`                  | ➖  | ➖   | ✅  | ➖   | Installs and updates Ruby gems                      |
| `rv`                        | ✅  | ➖   | ➖  | ➖   | List git remote details                             |
| `s`                         | ✅  | ➖   | ✅  | ➖   | Display abbreviated git status                      |
| `search`                    | ➖  | ✅   | ➖  | ➖   | Search for CLI tools through package managers       |
| `seed`                      | ➖  | ✅   | ➖  | ➖   | Wrapper for macOS seedutil                          |
| `serve`                     | ➖  | ✅   | ➖  | ➖   | Runs Jekyll server in foreground                    |
| `served`                    | ➖  | ✅   | ➖  | ➖   | Runs Jekyll server in background                    |
| `servedraft`                | ➖  | ✅   | ➖  | ➖   | Runs Jekyll server showing drafts                   |
| `servedraftd`               | ➖  | ✅   | ➖  | ➖   | Runs Jekyll server in background showing drafts     |
| `sethostname`               | ➖  | ✅   | ➖  | ➖   | Sets system hostname in all various places          |
| `sha1`                      | ➖  | ✅   | ➖  | ➖   | Displays SHA1 hash of files                         |
| `shell_add`                 | ➖  | ✅   | ➖  | ➖   | Register new shell in /etc/shells                   |
| `shell_choose`              | ➖  | ✅   | ➖  | ➖   | Interactive prompting for choosing default shell    |
| `shell_switch`              | ➖  | ✅   | ✅  | ➖   | Changes current $USER default shell                 |
| `shellexec`                 | ➖  | ✅   | ➖  | ➖   | Quick nav to ShellExec project                      |
| `shortlog`                  | ✅  | ➖   | ✅  | ➖   | Alias for shortlog                                  |
| `show`                      | ✅  | ➖   | ➖  | ➖   | Git show                                            |
| `showcert`                  | ➖  | ➖   | ✅  | ➖   | Prints server certificate file details              |
| `showgit`                   | ➖  | ✅   | ➖  | ➖   | Searches for .git repos recursively below           |
| `showgit_remote`            | ➖  | ✅   | ➖  | ➖   | Searches for .git repos, printing remote URL        |
| `showsvn`                   | ➖  | ➖   | ✅  | ➖   | Show .svn directories in current directory tree     |
| `signing_cert_details`      | ➖  | ✅   | ➖  | ➖   | Prints signing certificate details                  |
| `simclean`                  | ➖  | ✅   | ➖  | ➖   | Deletes all unavailable simulators                  |
| `skip`                      | ➖  | ✅   | ➖  | ➖   | Skip current commit in git rebase/cherry-pick       |
| `sort`                      | ➖  | ✅   | ➖  | ➖   | Wrapper for sort forcing byte ordering              |
| `spotlight_disable`         | ➖  | ✅   | ➖  | ➖   | Disables Spotlight indexing                         |
| `spotlight_enable`          | ➖  | ✅   | ➖  | ➖   | Enables Spotlight indexing                          |
| `spotlight_reload`          | ➖  | ✅   | ✅  | ➖   | Reloads Spotlight triggering re-index               |
| `sshserverfingerprint`      | ➖  | ✅   | ➖  | ➖   | Print fingerprint of server SSH key                 |
| `sshtest`                   | ➖  | ✅   | ➖  | ➖   | Tests SSH connection to GitHub                      |
| `sshupload`                 | ➖  | ✅   | ➖  | ➖   | Uploads public RSA SSH key to GitHub profile        |
| `stapply`                   | ✅  | ➖   | ➖  | ➖   | Apply git stash without removing it                 |
| `stash`                     | ✅  | ➖   | ✅  | ➖   | Git stash                                           |
| `stat`                      | ➖  | ✅   | ➖  | ➖   | Disabled wrapper for stat                           |
| `status`                    | ✅  | ➖   | ➖  | ➖   | Git status (full)                                   |
| `stdrop`                    | ✅  | ➖   | ➖  | ➖   | Drop git stash                                      |
| `stlist`                    | ✅  | ➖   | ➖  | ➖   | List git stashes                                    |
| `stpop`                     | ✅  | ➖   | ➖  | ➖   | Apply and remove top git stash                      |
| `strip_teams`               | ➖  | ✅   | ➖  | ➖   | Strip codesign from Teams app                       |
| `stsave`                    | ✅  | ➖   | ✅  | ➖   | Save git stash                                      |
| `stshow`                    | ✅  | ➖   | ➖  | ➖   | Show git stash contents                             |
| `submodule`                 | ✅  | ➖   | ➖  | ➖   | Git submodule                                       |
| `subrepo`                   | ➖  | ✅   | ➖  | ➖   | Wrapper for git-subrepo                             |
| `surf`                      | ➖  | ✅   | ➖  | ➖   | Opens Windsurf                                      |
| `suri`                      | ➖  | ➖   | ✅  | ➖   | Init and update git submodules recursively          |
| `swift_make`                | ➖  | ✅   | ➖  | ➖   | Adds template Makefile for Swift projects           |
| `swift_pgp_key_import`      | ➖  | ✅   | ✅  | ➖   | Import Swift PGP keys into keyring                  |
| `swift_releases`            | ➖  | ✅   | ➖  | ➖   | Check for Swift releases                            |
| `swift_verify`              | ➖  | ✅   | ➖  | ➖   | Swift verify function                               |
| `swiftpm`                   | ➖  | ✅   | ➖  | ➖   | Quick nav to SwiftPM-Plugin project                 |
| `sync`                      | ➖  | ✅   | ✅  | ➖   | Synchronizes git rep                                |
| `tag`                       | ✅  | ➖   | ➖  | ➖   | Git tag                                             |
| `tarball`                   | ➖  | ✅   | ➖  | ➖   | Creates tarball                                     |
| `tarls`                     | ➖  | ✅   | ➖  | ➖   | List contents of tarball                            |
| `textmate`                  | ➖  | ➖   | ✅  | ➖   | Manage TextMate bundles                             |
| `theirs`                    | ➖  | ➖   | ✅  | ➖   | Checkout theirs for unmerged paths                  |
| `tmdelete`                  | ➖  | ✅   | ➖  | ➖   | Delete Time Machine snapshot                        |
| `tmsnapshots`               | ➖  | ✅   | ➖  | ➖   | List Time Machine Snapshots                         |
| `todo`                      | ➖  | ✅   | ➖  | ➖   | Edit rebase todo file                               |
| `toggle_wait`               | ➖  | ✅   | ➖  | ➖   | Toggles editor wait flag                            |
| `touchbar_restart`          | ➖  | ✅   | ➖  | ➖   | Restarts TouchBar server                            |
| `tower`                     | ➖  | ✅   | ✅  | ➖   | Open current repo in Tower                          |
| `track`                     | ✅  | ✅   | ➖  | ➖   | Creates local tracking branch                       |
| `tracking`                  | ➖  | ✅   | ➖  | ➖   | Display tracking info for current branch            |
| `tube`                      | ➖  | ✅   | ✅  | ➖   | Quick nav to Tube project                           |
| `u2f_key_add`               | ➖  | ✅   | ➖  | ➖   | Add U2F key                                         |
| `unmount`                   | ➖  | ✅   | ➖  | ➖   | Unmounts drive                                      |
| `unshallow`                 | ➖  | ✅   | ✅  | ➖   | Converts shallow git repo to full                   |
| `unstage`                   | ➖  | ✅   | ➖  | ➖   | Restores files in git index from HEAD               |
| `untar`                     | ➖  | ✅   | ➖  | ➖   | Extracts tarball                                    |
| `untracked`                 | ➖  | ➖   | ✅  | ➖   | Displays files not tracked in current git repo      |
| `upmodule`                  | ➖  | ➖   | ✅  | ➖   | Optionally invokes upstall module                   |
| `upstall`                   | ➖  | ✅   | ➖  | ➖   | Alias for ⏫_upstall                                |
| `upstreamify`               | ➖  | ✅   | ➖  | ➖   | Renames origin to upstream                          |
| `usage`                     | ➖  | ✅   | ➖  | ➖   | Show disk usage for directory                       |
| `user`                      | ➖  | ✅   | ➖  | ➖   | Displays info about current user                    |
| `user.email`                | ➖  | ✅   | ➖  | ➖   | Manages user.email git config setting               |
| `user.name`                 | ➖  | ✅   | ✅  | ➖   | Manages user.name git config setting                |
| `user.signingkey`           | ➖  | ✅   | ➖  | ➖   | Manages user.signingkey git config setting          |
| `user_is_admin`             | ➖  | ✅   | ➖  | ➖   | Tests whether USER is member of admin group         |
| `version`                   | ➖  | ✅   | ➖  | ➖   | Manage version numbers for Xcode project            |
| `version_build`             | ➖  | ✅   | ➖  | ➖   | Displays project version of current Xcode project   |
| `version_current`           | ➖  | ✅   | ➖  | ➖   | Displays Xcode project version information          |
| `version_enable`            | ➖  | ✅   | ➖  | ➖   | Runs enable-versioning.rb ruby script               |
| `version_market`            | ➖  | ✅   | ➖  | ➖   | Displays marketing version of current Xcode project |
| `wip`                       | ➖  | ✅   | ➖  | ➖   | Commits WIP work                                    |
| `xamarin_version`           | ➖  | ✅   | ➖  | ➖   | Determines current version Xamarin                  |
| `xc`                        | ➖  | ✅   | ✅  | ➖   | Xcode wrapper function                              |
| `xcb`                       | ➖  | ✅   | ➖  | ➖   | Alias for xcodebuild                                |
| `xcblist`                   | ➖  | ✅   | ➖  | ➖   | Lists info about first Xcode project found          |
| `xcbschemes`                | ➖  | ✅   | ✅  | ➖   | Displays schemes for Xcode project                  |
| `xcinit`                    | ➖  | ➖   | ✅  | ➖   | Runs Xcode new_project.rb ruby script               |
| `xclicense`                 | ➖  | ✅   | ➖  | ➖   | Agree to Xcode license                              |
| `xcode`                     | ➖  | ➖   | ✅  | ➖   | Installs and updates Xcode                          |
| `xcodeplugin`               | ➖  | ✅   | ➖  | ➖   | Quick nav to xcodePlugin project                    |
| `xconf`                     | ➖  | ✅   | ➖  | ➖   | Edit nginx configuration files                      |
| `xcsp`                      | ➖  | ➖   | ✅  | ➖   | Show currently selected version of Xcode            |
| `xcv`                       | ➖  | ✅   | ➖  | ➖   | Displays version of currently selected Xcode        |
| `xcvall`                    | ➖  | ✅   | ➖  | ➖   | Lists versions of all installed copies of Xcode     |
| `xcvmget`                   | ➖  | ➖   | ✅  | ➖   | Show live list of Xcode versions to download        |
| `xlog`                      | ➖  | ✅   | ✅  | ➖   | Quick nav to nginx log dir                          |
| `xps`                       | ➖  | ➖   | ✅  | ➖   | Short alias for displaying nginx status             |
| `xtest`                     | ➖  | ✅   | ➖  | ➖   | Validate nginx config                               |
| `xv`                        | ➖  | ➖   | ✅  | ➖   | Prints Xcode version information                    |
| `⏫_upstall`                | ➖  | ✅   | ➖  | ➖   | Updates/installs system and shell dependencies      |
| `▶️_powerline`              | ➖  | ✅   | ➖  | ➖   | Upstalls Powerline                                  |
| `⚛️_apm`                    | ➖  | ✅   | ➖  | ➖   | Updates Atom packages                               |
| `❄️_nix`                    | ➖  | ✅   | ➖  | ➖   | Installs rust tools                                 |
| `⬆️_upmodule`               | ➖  | ✅   | ➖  | ➖   | Optionally invokes upstall module                   |
| `🆚_vscode`                 | ➖  | ✅   | ➖  | ➖   | Manages VS Code extensions                          |
| `🌱_mint`                   | ➖  | ✅   | ➖  | ➖   | Updates Mint and installed packages                 |
| `🍺_brew`                   | ➖  | ✅   | ➖  | ➖   | Updates Homebrew and installed formulae             |
| `🍻_cask`                   | ➖  | ✅   | ➖  | ➖   | Updates Homebrew Casks and installed apps           |
| `🐍_pip`                    | ➖  | ✅   | ➖  | ➖   | Manages python packages using pip                   |
| `🐠_omf`                    | ➖  | ✅   | ➖  | ➖   | Updates oh-my-fish and bundled packages             |
| `💎_rubygems`               | ➖  | ✅   | ➖  | ➖   | Installs and updates Ruby gems                      |
| `📝_textmate`               | ➖  | ✅   | ➖  | ➖   | Manage TextMate bundles                             |
| `📦_apt`                    | ➖  | ✅   | ➖  | ➖   | Updates APM packages Linux                          |
| `📺_mas`                    | ➖  | ✅   | ➖  | ➖   | Manage Mac App Store apps                           |
| `🔨_xcode`                  | ➖  | ✅   | ➖  | ➖   | Installs and updates Xcode                          |
| `🕸_npm`                    | ➖  | ✅   | ➖  | ➖   | Installs and updates npm packages                   |
| `🖥_macos`                  | ➖  | ✅   | ➖  | ➖   | Manage macOS system updates                         |
| `🗄_gitconfig`              | ➖  | ✅   | ➖  | ➖   | Sets git user.name and user.email in XDG            |
| `🗒_vundle`                 | ➖  | ✅   | ➖  | ➖   | Installs and updates Vundle plugin manager          |
| `🥅_dotnet`                 | ➖  | ✅   | ➖  | ➖   | Installs .NET tools and workpacks                   |
| `🦀_rustup`                 | ➖  | ✅   | ➖  | ➖   | Installs rust tools                                 |

## Known Issues and Differences

This section documents known bugs (🐛) and implementation differences between shells.

_(Issues will be documented here as they are discovered during detailed comparison)_
