# Fish to Nushell Migration Plan

This document catalogs all Fish shell functions, aliases, abbreviations, and variables that need to be converted to Nushell equivalents.

## Summary Statistics
- **Total Functions**: 707
- **Abbreviations**: 5 (directory navigation)
- **Environment Variables**: ~80+
- **Configuration Files**: 3 main files (config.fish, variables.fish, abbreviations.fish)

## Fish Functions by Category

### Git Functions (130+)
- [x] `a.fish` - git add
- [x] `aa.fish` - git add all
- [x] `abort.fish` - git abort operations
- [x] `add.fish` - git add
- [x] `amend.fish` - git commit amend
- [x] `amendne.fish` - git commit amend no edit
- [x] `ane.fish` - amend no edit
- [ ] `assume.fish` - git assume unchanged
- [ ] `assumed.fish` - list assumed files
- [x] `bisect.fish` - git bisect
- [x] `branch.fish` - git branch operations
- [x] `checkout.fish` - git checkout
- [x] `cherry-pick.fish` - git cherry-pick
- [x] `clone.fish` - git clone
- [ ] `clone_or_pull.fish` - clone or pull repo
- [x] `cmt.fish` - git commit
- [x] `cmtne.fish` - git commit no edit
- [x] `commit.fish` - git commit
- [ ] `cont.fish` - git continue
- [ ] `current_branch.fish` - show current branch
- [x] `delete-tag.fish` - delete git tag
- [ ] `deleted.fish` - show deleted files
- [x] `diff.fish` - git diff
- [x] `difftool.fish` - git difftool
- [ ] `dirty.fish` - check if repo is dirty
- [x] `fetch.fish` - git fetch
- [ ] `files_changed.fish` - list changed files
- [ ] `format-patch.fish` - git format-patch
- [x] `gc.fish` - git gc
- [x] `gd.fish` - git diff
- [ ] `gh_token_test.fish` - test GitHub token
- [ ] `gi.fish` - git init
- [ ] `ginit.fish` - git init
- [ ] `git-plist-filter.fish` - filter plist files
- [ ] `git_bundle_create.fish` - create git bundle
- [ ] `git_clean.fish` - git clean
- [ ] `git_inside_repo.fish` - check if inside git repo
- [ ] `git_repo_clean.fish` - check if repo is clean
- [ ] `git_repo_dirty.fish` - check if repo is dirty
- [ ] `gk.fish` - gitk
- [x] `gp.fish` - git push
- [x] `gpi.fish` - git pull
- [ ] `gpv.fish` - git push verbose
- [x] `gt.fish` - git status
- [ ] `gta.fish` - git status all
- [ ] `gv.fish` - git version
- [ ] `headsha.fish` - get HEAD SHA
- [ ] `headshort.fish` - get short HEAD SHA
- [ ] `ignore.fish` - add to gitignore
- [ ] `ignored.fish` - list ignored files
- [ ] `ignores.fish` - show ignores
- [ ] `index.fish` - git index operations
- [x] `init.fish` - git init
- [ ] `lfs.fish` - git lfs
- [x] `lg.fish` - git log graph
- [x] `lg1.fish` - git log oneline
- [x] `lg10.fish` - git log 10 commits
- [ ] `lga.fish` - git log all
- [ ] `lgfind.fish` - find in git log
- [ ] `lgg.fish` - git log grep
- [ ] `lggrep.fish` - grep git log
- [ ] `list-authors.fish` - list git authors
- [x] `log.fish` - git log
- [ ] `log1.fish` - git log oneline
- [x] `log10.fish` - git log 10
- [x] `ls-files.fish` - git ls-files
- [x] `ls-remote.fish` - git ls-remote
- [ ] `ls-tree.fish` - git ls-tree
- [x] `merge.fish` - git merge
- [ ] `merge-base.fish` - git merge-base
- [x] `mergetool.fish` - git mergetool
- [ ] `mirror.fish` - git mirror
- [ ] `ours.fish` - git checkout --ours
- [x] `pick.fish` - git cherry-pick
- [x] `pop.fish` - git stash pop
- [x] `prune.fish` - git prune
- [ ] `prunep.fish` - git prune packed
- [ ] `prunesvn.fish` - prune svn
- [x] `pull.fish` - git pull
- [ ] `pull_ssh_config.fish` - pull SSH config
- [x] `push.fish` - git push
- [x] `pushf.fish` - git push force
- [ ] `pusht.fish` - git push tags
- [ ] `pushtags.fish` - git push tags
- [x] `rebase.fish` - git rebase
- [ ] `ref.fish` - git ref
- [x] `reflog.fish` - git reflog
- [x] `remote.fish` - git remote
- [ ] `remote_for_current_branch.fish` - get remote for branch
- [x] `reset.fish` - git reset
- [x] `restore.fish` - git restore
- [ ] `rev-list.fish` - git rev-list
- [x] `rev-parse.fish` - git rev-parse
- [ ] `revert.fish` - git revert
- [ ] `rewrite.fish` - git rewrite
- [ ] `scrub.fish` - git scrub
- [ ] `sg.fish` - git status
- [ ] `sha.fish` - show SHA
- [ ] `sha1.fish` - SHA1 hash
- [ ] `sha256.fish` - SHA256 hash
- [ ] `shacopy.fish` - copy SHA
- [x] `shortlog.fish` - git shortlog
- [ ] `shortsha.fish` - short SHA
- [x] `show.fish` - git show
- [ ] `showgit.fish` - show git info
- [ ] `showgit_remote.fish` - show git remote
- [ ] `showsvn.fish` - show SVN info
- [ ] `skip.fish` - git skip
- [x] `st.fish` - git status
- [x] `stapply.fish` - git stash apply
- [x] `stash.fish` - git stash
- [ ] `status_current.fish` - current status
- [x] `stdrop.fish` - git stash drop
- [x] `stlist.fish` - git stash list
- [x] `stpop.fish` - git stash pop
- [x] `stsave.fish` - git stash save
- [x] `stshow.fish` - git stash show
- [ ] `stsnapshot.fish` - git stash snapshot
- [x] `submodule.fish` - git submodule
- [ ] `subrepo.fish` - git subrepo
- [ ] `subs.fish` - git submodules
- [ ] `sync.fish` - git sync
- [x] `tag.fish` - git tag
- [ ] `theirs.fish` - git checkout --theirs
- [x] `track.fish` - git track
- [ ] `tracked.fish` - list tracked files
- [ ] `tracking.fish` - show tracking
- [ ] `unassume.fish` - git unassume
- [ ] `unshallow.fish` - unshallow repo
- [ ] `unstage.fish` - git unstage
- [ ] `untracked.fish` - list untracked files
- [ ] `upstreamify.fish` - set upstream
- [ ] `wip.fish` - work in progress commit

### Homebrew/Package Management Functions (30+)
- [ ] `🍺_brew.fish` - Homebrew updates
- [ ] `🍻_cask.fish` - Homebrew Cask
- [ ] `brew_active_version.fish` - show active version
- [ ] `brew_cache_purge.fish` - purge cache
- [ ] `brew_core.fish` - Homebrew core
- [ ] `brew_deps.fish` - show dependencies
- [ ] `brew_edit.fish` - edit formula
- [ ] `brew_home.fish` - Homebrew home
- [ ] `brew_installed.fish` - list installed
- [ ] `brew_logs.fish` - show logs
- [ ] `brew_test.fish` - test formula
- [ ] `brew_versions.fish` - show versions
- [ ] `cask_audit.fish` - audit cask
- [ ] `cask_cache.fish` - cask cache
- [ ] `cask_dir.fish` - cask directory
- [ ] `cask_edit.fish` - edit cask
- [ ] `cask_token.fish` - cask token
- [ ] `mas_tap.fish` - Mac App Store tap
- [ ] `masd.fish` - MAS download
- [ ] `maslink.fish` - MAS link
- [ ] `masrm.fish` - MAS remove
- [ ] `masshow.fish` - MAS show
- [ ] `📺_mas.fish` - Mac App Store updates

### Docker Functions (30+)
- [ ] `d.fish` - Docker
- [ ] `dc.fish` - docker-compose
- [ ] `dce.fish` - docker-compose exec
- [ ] `dci.fish` - docker-compose images
- [ ] `dck.fish` - docker-compose kill
- [ ] `dcl.fish` - docker-compose logs
- [ ] `dcp.fish` - docker-compose ps
- [ ] `dcr.fish` - docker-compose run
- [ ] `dcstart.fish` - docker-compose start
- [ ] `dcstop.fish` - docker-compose stop
- [ ] `dct.fish` - docker-compose top
- [ ] `dcw.fish` - docker-compose watch
- [ ] `ddc.fish` - Docker Desktop commands
- [ ] `ddd.fish` - Docker Desktop daemon
- [ ] `dib.fish` - Docker image build
- [ ] `dii.fish` - Docker image inspect
- [ ] `dil.fish` - Docker image list
- [ ] `din.fish` - Docker inspect
- [ ] `dip.fish` - Docker image prune
- [ ] `dit.fish` - Docker image tag
- [ ] `diw.fish` - Docker image watch
- [ ] `dlf.fish` - Docker logs follow
- [ ] `dlogs.fish` - Docker logs
- [ ] `dnc.fish` - Docker network create
- [ ] `dni.fish` - Docker network inspect
- [ ] `dnl.fish` - Docker network list
- [ ] `dnp.fish` - Docker network prune
- [ ] `dnr.fish` - Docker network remove
- [ ] `dnuke.fish` - Docker nuke all
- [ ] `dpd.fish` - Docker prune dangling
- [ ] `dpl.fish` - Docker pull
- [ ] `dpp.fish` - Docker port
- [ ] `dpr.fish` - Docker prune
- [ ] `dps.fish` - Docker ps
- [ ] `dpu.fish` - Docker push
- [ ] `dra.fish` - Docker run attach
- [ ] `dsa.fish` - Docker stop all
- [ ] `dsl.fish` - Docker service list
- [ ] `dsr.fish` - Docker service remove
- [ ] `dss.fish` - Docker service scale
- [ ] `dtc.fish` - Docker tag current
- [ ] `dvc.fish` - Docker volume create
- [ ] `dvi.fish` - Docker volume inspect
- [ ] `dvl.fish` - Docker volume list
- [ ] `dvp.fish` - Docker volume prune
- [ ] `dvr.fish` - Docker volume remove
- [ ] `dw.fish` - Docker watch

### Xcode/iOS Development Functions (50+)
- [ ] `🔨_xcode.fish` - Xcode updates
- [ ] `derived_data.fish` - Xcode DerivedData
- [ ] `developer_mode.fish` - toggle developer mode
- [ ] `dsym_uuid.fish` - dSYM UUID
- [ ] `dsyminfo.fish` - dSYM info
- [ ] `entitlements.fish` - show entitlements
- [ ] `finddsym.fish` - find dSYM
- [ ] `getudid.fish` - get UDID
- [ ] `iphones.fish` - list iPhones
- [ ] `killsim.fish` - kill simulator
- [ ] `register_device.fish` - register device
- [ ] `simclean.fish` - clean simulators
- [ ] `xaccess.fish` - Xcode access
- [ ] `xc.fish` - Xcode
- [ ] `xcb.fish` - Xcode build
- [ ] `xcblist.fish` - Xcode build list
- [ ] `xcbschemes.fish` - Xcode build schemes
- [ ] `xccheck.fish` - Xcode check
- [ ] `xcdevices.fish` - Xcode devices
- [ ] `xcdl.fish` - Xcode download
- [ ] `xcfl.fish` - Xcode file list
- [ ] `xcinit.fish` - Xcode init
- [ ] `xclicense.fish` - Xcode license
- [ ] `xclist.fish` - Xcode list
- [ ] `xcodeplugin.fish` - Xcode plugin
- [ ] `xconf.fish` - Xcode config
- [ ] `xconfd.fish` - Xcode config debug
- [ ] `xcsp.fish` - Xcode select path
- [ ] `xcss.fish` - Xcode select switch
- [ ] `xcswitch.fish` - Xcode switch
- [ ] `xcv.fish` - Xcode version
- [ ] `xcvall.fish` - Xcode version all
- [ ] `xcvmcache.fish` - Xcode VM cache
- [ ] `xcvmget.fish` - Xcode VM get
- [ ] `xcvmlist.fish` - Xcode VM list
- [ ] `xerror.fish` - Xcode error
- [ ] `xlog.fish` - Xcode log
- [ ] `xps.fish` - Xcode process
- [ ] `xreload.fish` - Xcode reload
- [ ] `xstart.fish` - Xcode start
- [ ] `xstatus.fish` - Xcode status
- [ ] `xstop.fish` - Xcode stop
- [ ] `xtest.fish` - Xcode test
- [ ] `xtraffic.fish` - Xcode traffic
- [ ] `xv.fish` - Xcode version

### Android Development Functions (10+)
- [ ] `adev.fish` - Android development
- [ ] `adevices.fish` - Android devices
- [ ] `aks.fish` - Android keystore
- [ ] `gradle_cache_clean.fish` - clean Gradle cache
- [ ] `gradle_kill.fish` - kill Gradle daemon
- [ ] `gradle_wrapper.fish` - Gradle wrapper
- [ ] `gradle_wrapper_add.fish` - add Gradle wrapper
- [ ] `gw.fish` - Gradle wrapper
- [ ] `gwd.fish` - Gradle wrapper daemon
- [ ] `gwv.fish` - Gradle wrapper version

### Build/Package Functions (20+)
- [ ] `b.fish` - build
- [ ] `be.fish` - bundle exec
- [ ] `bef.fish` - bundle exec foreman
- [ ] `bi.fish` - bundle install
- [ ] `bo.fish` - bundle outdated
- [ ] `bpi.fish` - bundle package install
- [ ] `bpie.fish` - bundle package install example
- [ ] `bpiru.fish` - bundle package install redownload unreachable
- [ ] `bpiv.fish` - bundle package install verbose
- [ ] `bpo.fish` - bundle package outdated
- [ ] `bpru.fish` - bundle package redownload unreachable
- [ ] `bprum.fish` - bundle package redownload unreachable missing
- [ ] `bpu.fish` - bundle package update
- [ ] `bpuru.fish` - bundle package update redownload unreachable
- [ ] `bpx.fish` - bundle package exec
- [ ] `bu.fish` - bundle update
- [ ] `bub.fish` - bundle update bundler
- [ ] `bug.fish` - bundle upgrade
- [ ] `build_dir.fish` - build directory
- [ ] `bundle-pull.fish` - bundle pull

### Swift/Rust/Cargo Functions (20+)
- [ ] `cargo_target.fish` - Cargo target
- [ ] `swift_make.fish` - Swift make
- [ ] `swift_pgp_key_import.fish` - Swift PGP key import
- [ ] `swift_releases.fish` - Swift releases
- [ ] `swift_verify.fish` - Swift verify
- [ ] `swiftinfo.fish` - Swift info
- [ ] `swiftpm.fish` - Swift Package Manager
- [ ] `🦀_rustup.fish` - Rust updates

### Ruby/Gem Functions (10+)
- [ ] `💎_rubygems.fish` - RubyGems updates
- [ ] `gem-userdir.fish` - Gem user directory
- [ ] `gem_install.fish` - Gem install
- [ ] `gem_pristine.fish` - Gem pristine
- [ ] `gem_update.fish` - Gem update
- [ ] `gemdir.fish` - Gem directory
- [ ] `ruby_upgrade.fish` - Ruby upgrade

### Python Functions (5+)
- [ ] `🐍_pip.fish` - pip updates
- [ ] `pip.fish` - pip wrapper

### Node.js/npm Functions (5+)
- [ ] `🕸_npm.fish` - npm updates
- [ ] `update_nvm.fish` - update NVM

### .NET Functions (5+)
- [ ] `🥅_dotnet.fish` - .NET updates
- [ ] `find_dotnet.fish` - find .NET

### File/Directory Functions (40+)
- [ ] `bak.fish` - backup file
- [x] `bd.fish` - back directory
- [ ] `big.fish` - find big files
- [ ] `bigfiles.fish` - list big files
- [ ] `cat.fish` - cat wrapper
- [ ] `cd.fish` - cd wrapper (with multiple dots)
- [ ] `cd..fish` through `cd.......fish` - parent directory navigation
- [ ] `col1.fish` - first column
- [ ] `createdirs.fish` - create directories
- [ ] `deflate.fish` - deflate file
- [ ] `dir.fish` - directory
- [x] `e.fish` - edit
- [ ] `edit.fish` - edit file
- [ ] `editw.fish` - edit and wait
- [ ] `faccess.fish` - file access
- [ ] `file_base.fish` - file base name
- [ ] `fileowner.fish` - file owner
- [ ] `filesize.fish` - file size
- [ ] `find_file.fish` - find file
- [ ] `findup.fish` - find up
- [ ] `fixperms.fish` - fix permissions
- [x] `l.fish` - list
- [x] `la.fish` - list all
- [ ] `ldir.fish` - list directories
- [ ] `ldot.fish` - list dot files
- [ ] `ldotdir.fish` - list dot directories
- [ ] `lh.fish` - list human readable
- [ ] `line.fish` - show line
- [x] `ll.fish` - long list
- [ ] `lr.fish` - list recursive
- [ ] `ls.fish` - ls wrapper
- [ ] `lscolors.fish` - ls colors
- [ ] `lsym.fish` - list symlinks
- [ ] `lt.fish` - list by time
- [ ] `ltime.fish` - list with time
- [ ] `md.fish` - make directory
- [ ] `mkdir.fish` - mkdir wrapper
- [x] `o.fish` - open
- [ ] `tarball.fish` - create tarball
- [ ] `tarls.fish` - list tarball
- [ ] `untar.fish` - extract tarball

### System/macOS Functions (50+)
- [ ] `🖥_macos.fish` - macOS updates
- [ ] `appcast_url.fish` - app cast URL
- [ ] `appicon.fish` - app icon
- [ ] `apps.fish` - list applications
- [ ] `ard_enable.fish` - Apple Remote Desktop enable
- [ ] `ard_restart.fish` - ARD restart
- [ ] `arp-fix.fish` - ARP fix
- [ ] `arpstatus.fish` - ARP status
- [ ] `bootcamp.fish` - Boot Camp
- [ ] `chrome.fish` - Chrome
- [ ] `chromei.fish` - Chrome incognito
- [ ] `cleanall.fish` - clean all
- [ ] `console_user.fish` - console user
- [ ] `cron_edit.fish` - cron edit
- [ ] `cron_list.fish` - cron list
- [ ] `cron_reload.fish` - cron reload
- [ ] `date_iso8601.fish` - ISO 8601 date
- [ ] `defaults_set.fish` - defaults set
- [ ] `displays.fish` - list displays
- [ ] `dropboxfinderreset.fish` - Dropbox Finder reset
- [ ] `epoc_date.fish` - epoch date
- [ ] `firewall.fish` - firewall
- [ ] `firewall_allow_nginx.fish` - firewall allow nginx
- [ ] `firewall_toggle.fish` - firewall toggle
- [ ] `firewalladd.fish` - firewall add
- [ ] `fixopenwith.fish` - fix Open With
- [ ] `flushdns.fish` - flush DNS
- [ ] `icloud.fish` - iCloud
- [ ] `iclouddrive.fish` - iCloud Drive
- [ ] `ip.fish` - IP address
- [ ] `is_arm.fish` - check if ARM
- [ ] `is_bash_login.fish` - check if bash login
- [ ] `is_console_user.fish` - check if console user
- [ ] `is_coreutils.fish` - check if coreutils
- [ ] `is_linux.fish` - check if Linux
- [ ] `is_mac.fish` - check if macOS
- [ ] `is_octodec.fish` - check if Octodec
- [ ] `is_phatmini.fish` - check if phatmini
- [ ] `is_ssh.fish` - check if SSH
- [ ] `machine_id.fish` - machine ID
- [ ] `osversion.fish` - OS version
- [ ] `phatmini.fish` - phatmini
- [ ] `ports.fish` - list ports
- [ ] `powerlinetest.fish` - Powerline test
- [ ] `qllist.fish` - Quick Look list
- [ ] `qlreload.fish` - Quick Look reload
- [ ] `ramdisk.fish` - RAM disk
- [ ] `restart.fish` - restart
- [ ] `sethostname.fish` - set hostname
- [ ] `spotlight_disable.fish` - Spotlight disable
- [ ] `spotlight_enable.fish` - Spotlight enable
- [ ] `spotlight_reload.fish` - Spotlight reload
- [ ] `sysinfo.fish` - system info
- [ ] `tmbundleplist.fish` - TextMate bundle plist
- [ ] `tmdelete.fish` - Time Machine delete
- [ ] `tmsnapshots.fish` - Time Machine snapshots
- [ ] `touchbar_restart.fish` - Touch Bar restart
- [ ] `unmount.fish` - unmount

### Network Functions (20+)
- [ ] `curl_download.fish` - curl download
- [ ] `en1.fish` - en1 interface
- [ ] `htdelete.fish` - HTTP DELETE
- [ ] `htget.fish` - HTTP GET
- [ ] `hthead.fish` - HTTP HEAD
- [ ] `htoptions.fish` - HTTP OPTIONS
- [ ] `htpatch.fish` - HTTP PATCH
- [ ] `htpost.fish` - HTTP POST
- [ ] `htput.fish` - HTTP PUT
- [ ] `openports.fish` - open ports
- [ ] `ping1.fish` - ping once
- [ ] `pingdownload.fish` - ping download
- [ ] `pingmini.fish` - ping mini
- [ ] `serve.fish` - serve directory
- [ ] `served.fish` - serve directory
- [ ] `servedraft.fish` - serve draft
- [ ] `servedraftd.fish` - serve draft daemon

### SSH/Security Functions (20+)
- [ ] `auth.fish` - authentication
- [ ] `codesign_verify.fish` - codesign verify
- [ ] `create_cert_localhost.fish` - create localhost cert
- [ ] `gpgcopypub.fish` - GPG copy public key
- [ ] `gpgkeyid.fish` - GPG key ID
- [ ] `gpgrep.fish` - GPG grep
- [ ] `gpgshow.fish` - GPG show
- [ ] `gpgtest.fish` - GPG test
- [ ] `list_codesign_identities.fish` - list codesign identities
- [ ] `renew_certificates.fish` - renew certificates
- [ ] `savecerts.fish` - save certificates
- [ ] `showcert.fish` - show certificate
- [ ] `showcerts.fish` - show certificates
- [ ] `signing_cert_details.fish` - signing cert details
- [ ] `sshcopypub.fish` - SSH copy public key
- [ ] `sshkey.fish` - SSH key
- [ ] `sshkeyfingerprint.fish` - SSH key fingerprint
- [ ] `sshnewkey.fish` - SSH new key
- [ ] `sshserverfingerprint.fish` - SSH server fingerprint
- [ ] `sshshowpub.fish` - SSH show public key
- [ ] `sshtest.fish` - SSH test
- [ ] `sshupload.fish` - SSH upload
- [ ] `u2f_key_add.fish` - U2F key add

### AWS Functions (5+)
- [ ] `assume.fish` - AWS assume role
- [ ] `aws_id.fish` - AWS ID
- [ ] `aws_test.fish` - AWS test

### Utility Functions (100+)
- [ ] `__direnv_export_eval.fish` - direnv helper
- [ ] `__prev_token.fish` - previous token
- [ ] `__re_extension.fish` - regex extension
- [ ] `abbreviations.fish` - abbreviations
- [ ] `af.fish` - alias finder
- [ ] `ai.fish` - AI assistant
- [ ] `ap.fish` - Ansible playbook
- [ ] `apv.fish` - Ansible playbook verbose
- [ ] `as.fish` - alias search
- [ ] `asv.fish` - alias search verbose
- [ ] `battleapp.fish` - Battle.net app
- [ ] `bconfig.fish` - bundle config
- [ ] `bdm.fish` - bd match
- [ ] `bid.fish` - bundle ID
- [ ] `bindings.fish` - key bindings
- [ ] `binstall.fish` - binary install
- [ ] `biq.fish` - bundle install quiet
- [ ] `bq.fish` - bundle query
- [ ] `br.fish` - broot
- [ ] `bra.fish` - branch all
- [ ] `bv.fish` - bundle version
- [ ] `bvv.fish` - bundle version verbose
- [x] `c.fish` - clear
- [ ] `carthage-clean.fish` - Carthage clean
- [ ] `cballv.fish` - call verbose
- [ ] `cbios.fish` - clipboard iOS
- [ ] `cbiosv.fish` - clipboard iOS verbose
- [ ] `cbmac.fish` - clipboard Mac
- [ ] `cbmacv.fish` - clipboard Mac verbose
- [ ] `cbootios.fish` - clipboard boot iOS
- [ ] `cco.fish` - checkout
- [ ] `ccos.fish` - checkout staging
- [ ] `ccoss.fish` - checkout staging show
- [ ] `ccov.fish` - checkout verbose
- [ ] `ccus.fish` - checkout upstream
- [ ] `ccuss.fish` - checkout upstream show
- [ ] `ccuv.fish` - checkout upstream verbose
- [ ] `cdown.fish` - countdown
- [ ] `cfrmodel.fish` - Core Foundation model
- [ ] `cfrservice.fish` - Core Foundation service
- [ ] `changelog.fish` - changelog
- [ ] `chat.fish` - chat
- [ ] `clamp.fish` - clamp value
- [x] `claude.fish` - Claude AI
- [ ] `clv.fish` - clear verbose
- [ ] `config.fish` - config
- [ ] `configg.fish` - config global
- [ ] `configxg.fish` - config exclude global
- [ ] `dash.fish` - Dash app
- [ ] `debug.fish` - debug
- [ ] `delivery.fish` - delivery
- [ ] `demangle.fish` - demangle
- [ ] `deploy.fish` - deploy
- [ ] `ditto_debug.fish` - Ditto debug
- [ ] `doc.fish` - documentation
- [ ] `dotfiles.fish` - dotfiles
- [ ] `dreamhost.fish` - DreamHost
- [ ] `ebw.fish` - ebook writer
- [ ] `ej.fish` - eject
- [ ] `email_url.fish` - email URL
- [ ] `emoji.fish` - emoji
- [ ] `emoji_map.fish` - emoji map
- [ ] `erase.fish` - erase
- [ ] `error.fish` - error
- [ ] `fc.fish` - fc command
- [ ] `fe.fish` - file explorer
- [ ] `ferror.fish` - format error
- [ ] `ff.fish` - Firefox
- [ ] `find_appcast.fish` - find appcast
- [ ] `fish_format.fish` - Fish format
- [ ] `fish_prompt.fish` - Fish prompt
- [ ] `fish_right_prompt.fish` - Fish right prompt
- [ ] `fish_user_key_bindings.fish` - Fish key bindings
- [ ] `fish_vendor_functions_dir.fish` - Fish vendor functions
- [ ] `fishconfig.fish` - Fish config
- [ ] `fishfiles.fish` - Fish files
- [ ] `fishlog.fish` - Fish log
- [ ] `fk.fish` - fuzzy kill
- [ ] `fl.fish` - file list
- [ ] `fn.fish` - function
- [ ] `format.fish` - format
- [ ] `fq.fish` - find quick
- [ ] `fs.fish` - file system
- [ ] `fuck-it.fish` - fuck it
- [ ] `func_count.fish` - function count
- [ ] `funky.fish` - funky
- [x] `g.fish` - git
- [ ] `gbe.fish` - git branch edit
- [ ] `genv.fish` - git env
- [ ] `has_space.fish` - has space
- [ ] `hgrep.fish` - history grep
- [ ] `home.fish` - home
- [ ] `ida.fish` - IDA Pro
- [ ] `install_choices.fish` - install choices
- [ ] `itwire.fish` - IT Wire
- [ ] `jabba.fish` - Jabba
- [ ] `java_ports.fish` - Java ports
- [ ] `jdk.fish` - JDK
- [ ] `jenkins_restart.fish` - Jenkins restart
- [ ] `jftemplate.fish` - JF template
- [ ] `jv.fish` - Java version
- [ ] `kpm.fish` - KPM
- [ ] `ldg.fish` - log debug
- [ ] `license.fish` - license
- [ ] `list.fish` - list
- [ ] `logo.fish` - logo
- [x] `m.fish` - make
- [ ] `mdk.fish` - MDK
- [ ] `mdp.fish` - Markdown preview
- [ ] `members.fish` - members
- [ ] `minecraft_server_port.fish` - Minecraft server port
- [ ] `mini.fish` - mini
- [ ] `minic.fish` - mini C
- [ ] `mirrored-pods.fish` - mirrored pods
- [ ] `moj.fish` - Mojang
- [ ] `moj_host.fish` - Mojang host
- [ ] `moj_user.fish` - Mojang user
- [ ] `mp.fish` - media player
- [ ] `mt.fish` - mate
- [ ] `multipass-start.fish` - Multipass start
- [ ] `mvn_local.fish` - Maven local
- [ ] `nav.fish` - navigate
- [ ] `new.fish` - new
- [ ] `nimble.fish` - Nimble
- [ ] `nixgc.fish` - Nix garbage collect
- [ ] `nixtest.fish` - Nix test
- [ ] `nodef.fish` - node default
- [ ] `nv.fish` - Neovim
- [ ] `octodec.fish` - Octodec
- [ ] `octopad.fish` - Octopad
- [ ] `og.fish` - original
- [ ] `ol.fish` - online
- [ ] `onyx.fish` - Onyx
- [ ] `ow.fish` - overwrite
- [ ] `ox.fish` - ox editor
- [ ] `path_add.fish` - path add
- [ ] `path_show.fish` - path show
- [ ] `pbjup.fish` - PBJ up
- [ ] `pborigin.fish` - pasteboard origin
- [ ] `pcopy.fish` - copy
- [ ] `pdo.fish` - pod outdated
- [ ] `pdob.fish` - pod outdated brief
- [ ] `pdog.fish` - pod outdated grep
- [ ] `pdos.fish` - pod outdated show
- [ ] `pi.fish` - pod install
- [ ] `pid.fish` - process ID
- [ ] `pie.fish` - pod install example
- [ ] `piev.fish` - pod install example verbose
- [ ] `pil.fish` - pod install local
- [ ] `pinkit.fish` - Pink It
- [ ] `pipeline.fish` - pipeline
- [ ] `piq.fish` - pod install quiet
- [ ] `piru.fish` - pod install repo update
- [ ] `piv.fish` - pod install verbose
- [ ] `pkgexpand.fish` - package expand
- [ ] `pkgfiles.fish` - package files
- [ ] `pkgfind.fish` - package find
- [ ] `pkginfo.fish` - package info
- [ ] `pl_edit.fish` - plist edit
- [ ] `play.fish` - play
- [ ] `plcat.fish` - plist cat
- [ ] `pless.fish` - plist less
- [ ] `plformat.fish` - plist format
- [ ] `pll.fish` - plist list
- [ ] `pllint.fish` - plist lint
- [ ] `pllvnc.fish` - plist launch VNC
- [ ] `pls_edit.fish` - plists edit
- [ ] `po.fish` - pod outdated
- [ ] `pod.fish` - CocoaPods
- [ ] `poe.fish` - pod outdated edit
- [ ] `pp.fish` - pretty print
- [ ] `prefs.fish` - preferences
- [ ] `prettyjson.fish` - pretty JSON
- [ ] `profile_id.fish` - profile ID
- [ ] `provisioning_dir.fish` - provisioning directory
- [ ] `provisioning_print.fish` - provisioning print
- [ ] `provisioning_uuid.fish` - provisioning UUID
- [ ] `pru.fish` - pod repo update
- [ ] `prum.fish` - pod repo update master
- [ ] `prun.fish` - pod run
- [ ] `psgrep.fish` - ps grep
- [ ] `psl.fish` - PowerShell
- [ ] `psync.fish` - pod sync
- [ ] `pu.fish` - pod update
- [ ] `publish.fish` - publish
- [ ] `pue.fish` - pod update edit
- [ ] `pul.fish` - pull
- [ ] `pv.fish` - pod version
- [ ] `quick.fish` - quick
- [ ] `r.fish` - reload
- [ ] `ra.fish` - radar
- [ ] `radars.fish` - radars
- [ ] `realm.fish` - Realm
- [ ] `realmos.fish` - Realm OS
- [ ] `register_device.fish` - register device
- [ ] `release.fish` - release
- [ ] `reload.fish` - reload
- [ ] `repeatchar.fish` - repeat character
- [ ] `repo_new.fish` - new repo
- [ ] `review.fish` - review
- [ ] `rl.fish` - reload
- [ ] `root.fish` - root
- [ ] `rp.fish` - replace
- [x] `rv.fish` - Ruby version
- [ ] `s.fish` - search
- [ ] `sa.fish` - search all
- [ ] `search.fish` - search
- [ ] `seed.fish` - seed
- [ ] `shell_add.fish` - shell add
- [ ] `shell_choose.fish` - shell choose
- [ ] `shellexec.fish` - shell exec
- [ ] `sort.fish` - sort
- [ ] `sortdiff.fish` - sort diff
- [ ] `spmgenx.fish` - SPM gen X
- [ ] `spmplugin.fish` - SPM plugin
- [ ] `stat.fish` - stat
- [ ] `strip_teams.fish` - strip teams
- [ ] `sur.fish` - super user
- [ ] `surf.fish` - surf
- [ ] `suri.fish` - Safari URI
- [ ] `testpro.fish` - test pro
- [ ] `title.fish` - title
- [ ] `todo.fish` - todo
- [ ] `toggle_wait.fish` - toggle wait
- [ ] `tower.fish` - Tower
- [ ] `tredecim.fish` - tredecim
- [ ] `tube.fish` - YouTube
- [ ] `uc.fish` - uppercase
- [ ] `ungate.fish` - ungate
- [ ] `upstall.fish` - update and install
- [ ] `usage.fish` - usage
- [ ] `user.fish` - user
- [ ] `user.email.fish` - user email
- [ ] `user.name.fish` - user name
- [ ] `user.signingkey.fish` - user signing key
- [ ] `user_is_admin.fish` - user is admin
- [ ] `user_present.fish` - user present
- [ ] `version.fish` - version
- [ ] `version_build.fish` - version build
- [ ] `version_current.fish` - version current
- [ ] `version_enable.fish` - version enable
- [ ] `version_market.fish` - version market
- [ ] `vimode.fish` - vi mode
- [ ] `warpify.fish` - warpify
- [ ] `xamarin_version.fish` - Xamarin version
- [ ] `yn.fish` - yes/no
- [ ] `⏫_upstall.fish` - upstall
- [ ] `▶️_powerline.fish` - Powerline
- [ ] `⚛️_apm.fish` - Atom package manager
- [ ] `❄️_nix.fish` - Nix
- [ ] `⬆️_upmodule.fish` - update module
- [ ] `🆚_vscode.fish` - VS Code
- [ ] `🌱_mint.fish` - Mint
- [ ] `🗒_vundle.fish` - Vundle
- [ ] `📦_apt.fish` - APT

## Fish Abbreviations

These are Fish's lightweight aliases that expand inline:

- [ ] `=` → `pushd` - Push directory
- [ ] `_` → `dirs` - Show directory stack
- [ ] `__` → `dirs -c` - Clear directory stack
- [ ] `-` → `prevd --list` - Previous directory with list
- [ ] `+` → `nextd --list` - Next directory with list

## Environment Variables

### System/Shell Variables
- `fish_greeting` - Empty (disabled)
- `simple_ass_prompt_greeting` - Fish Shell version message
- `KERNEL` - uname output
- `fish_emoji_width` - 2 (emoji spacing)
- `fish_ambiguous_width` - 2 (character spacing)
- `fish_key_bindings` - fish_vi_key_bindings
- `dangerous_nogreeting` - Set for danger theme

### Development Tools
- `ANDROID_HOME` - Android SDK location (platform-specific)
- `ANDROID_NDK_HOME` - Android NDK location
- `NDK_VERSION` - NDK version
- `ARCHFLAGS` - Architecture flags (ARM64 or x86_64)
- `JAVA_HOME` - Java home directory
- `GRADLE_HOME` - Gradle home
- `GROOVY_HOME` - Groovy home
- `SWIFT_TOOLCHAIN` - Swift toolchain path
- `DERIVED_DATA` - Xcode DerivedData path
- `BOOST_VERSION` - Boost library version
- `BOOST_INCLUDE_DIR` - Boost include directory
- `CMAKE_OSX_SYSROOT` - macOS SDK path
- `CMAKE_BUILD_TYPE` - Debug
- `DOTNET_ROOT` - .NET root directory
- `MONO_GAC_PREFIX` - Mono GAC prefix
- `BUN_INSTALL` - Bun installation directory

### Package Managers
- `HOMEBREW_BAT` - bat command location
- `HOMEBREW_CLEANUP_MAX_AGE_DAYS` - 30
- `HOMEBREW_NO_ENV_HINTS` - 1
- `sdkman_prefix` - SDKMAN prefix
- `NIX_PATH` - Nix channels path

### Cloud/Services
- `ICLOUD_HOME` - iCloud home directory
- `ICLOUD_DRIVE` - iCloud Drive directory
- `PING_IDENTITY_DEVOPS_HOME` - Ping Identity DevOps home
- `PING_IDENTITY_DEVOPS_REGISTRY` - docker.io/pingidentity
- `PING_IDENTITY_DEVOPS_TAG` - edge
- `PING_IDENTITY_ACCEPT_EULA` - Y
- `CHROME_DEPOT_TOOLS` - Chromium depot tools path
- `MONGODB_HOME` - MongoDB home

### Paths/Directories
- `XDG_CONFIG_HOME` - ~/.config
- `JABBA_HOME` - ~/.jabba
- `OPENSSL_ROOT` - OpenSSL installation

### Locale/Display
- `LANG` - en_US.UTF-8
- `LANGUAGE` - en_US.UTF-8
- `LC_ALL` - en_US.UTF-8
- `LC_CTYPE` - en_US.UTF-8
- `CLICOLOR` - 1
- `LSCOLORS` - ExFxBxDxCxegedabagacad
- `LS_COLWIDTHS` - Column widths for ls

### Compilation Flags
- `LDFLAGS` - Linker flags
- `CPPFLAGS` - C++ preprocessor flags
- `CFLAGS` - C compiler flags
- `PKG_CONFIG_PATH` - pkg-config paths
- `CC_wasm32_unknown_unknown` - WASM compiler

### Editor Configuration
- `EDITOR_CLI` - vim
- `EDITOR_GUI` - windsurf --new-window
- `WAIT_FLAG_CLI` - --nofork
- `WAIT_FLAG_GUI` - --wait
- `EDITOR` or `VISUAL` - Conditional based on SSH/console

### Security
- `GPG_TTY` - TTY for GPG

### User Settings
- `github_user` - phatblat
- `powerline_enabled` - 0
- `default_user` - phatblat

### Theme Settings (bobthefish)
- `theme_display_git` - yes
- `theme_display_git_dirty` - yes
- `theme_display_git_untracked` - yes
- `theme_display_git_ahead_verbose` - yes
- `theme_display_git_dirty_verbose` - yes
- `theme_display_git_stashed_verbose` - yes
- `theme_display_git_default_branch` - yes
- `theme_git_default_branches` - master main
- `theme_git_worktree_support` - no
- `theme_use_abbreviated_branch_name` - yes
- `theme_display_vagrant` - yes
- `theme_display_docker_machine` - yes
- `theme_display_k8s_context` - yes
- `theme_display_k8s_namespace` - yes
- `theme_display_hg` - yes
- `theme_display_virtualenv` - yes
- `theme_display_ruby` - yes
- `theme_display_user` - ssh
- `theme_display_hostname` - ssh
- `theme_display_vi` - yes
- `theme_display_node` - yes
- `theme_display_date` - yes
- `theme_display_cmd_duration` - yes
- `theme_title_display_process` - yes
- `theme_title_display_path` - no
- `theme_title_use_abbreviated_path` - no
- `theme_date_format` - +%a %H:%M
- `theme_avoid_ambiguous_glyphs` - yes
- `theme_powerline_fonts` - yes
- `theme_nerd_fonts` - yes
- `theme_show_exit_status` - yes
- `theme_display_jobs_verbose` - yes
- `theme_color_scheme` - dracula
- `fish_prompt_pwd_dir_length` - 0
- `theme_project_dir_length` - 1
- `theme_newline_cursor` - no
- `theme_newline_prompt` - $ 

### PATH Configuration
The PATH is built from multiple sources:
1. User paths (`fish_user_paths`)
2. Home bin directories
3. Homebrew directories
4. Language-specific paths (Ruby, Python, Swift, etc.)
5. Android SDK tools
6. Cargo/Rust binaries
7. Various tool-specific bin directories

## Migration Strategy

### Phase 1: Core Configuration
1. Convert basic environment variables
2. Set up PATH configuration
3. Configure prompt (Starship works with both)
4. Set up directory navigation (zoxide works with both)

### Phase 2: Simple Functions
1. Convert single-command aliases/functions
2. Convert directory navigation shortcuts
3. Convert basic git aliases

### Phase 3: Complex Functions
1. Convert multi-command functions
2. Convert functions with logic/conditionals
3. Convert functions with arguments

### Phase 4: Tool-Specific Functions
1. Convert package manager wrappers
2. Convert development tool functions
3. Convert system utility functions

### Phase 5: Final Migration
1. Test all converted functions
2. Update any scripts that depend on Fish functions
3. Migrate remaining edge cases

## Notes

- Many functions are simple wrappers around commands (candidates for Nushell aliases)
- Some functions use Fish-specific features that need careful translation
- The emoji-prefixed update functions (🍺, 🐠, etc.) are package manager updaters
- Many git functions could be replaced with git aliases or a tool like lazygit
- Consider which functions are actually used vs. accumulated cruft

## Priority Functions for Migration

Based on the CLAUDE.md, these appear to be the most critical functions:

1. **Shell/System**: `is_mac`, `is_linux`, `is_arm`, `is_ssh`, `is_console_user`
2. **Development**: `jdk`, `gradle`/`gw` commands, `xc*` (Xcode), `dc*` (Docker)
3. **Git**: Core git aliases (`g`, `gs`, `gp`, `gpi`, `gc`, `gb`, etc.)
4. **Package Management**: `🍺_brew`, `mise` integration
5. **Navigation**: `cd` variants, `z` (zoxide), directory shortcuts
6. **Build Tools**: `just`, `make`, cargo commands