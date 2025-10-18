# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="sorin" # set by `omz`

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git brew)

# Install Oh My Zsh if missing
if [[ ! -f "$ZSH/oh-my-zsh.sh" ]]; then
    echo "Oh My Zsh not found. Installing..."
    (
        unset ZSH
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    )
fi

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Claude alias
alias claude='/Users/phatblat/.claude/local/claude'

# Auto-Warpify
[[ "$-" == *i* ]] && printf 'P$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh", "uname": "Darwin" }}�'

# Converted Fish functions

# git_clean
function git_clean() {
    git clean -xffd
}

# is_phatmini
function is_phatmini() {
    if [[ "$(hostname)" == *"phatmini"* ]]; then
        return 0
    else
        return 1
    fi
}

# function_template
function function_template() {
    local function_name="$1"
    local argname="$2"
    if [[ -z "$function_name" ]]; then
        echo "Usage: function_template function_name [argname]"
        return 1
    fi
    if [[ -z "$argname" ]]; then
        argname="argname"
    fi
    printf "function %s() {\n" "$function_name"
    printf "    # %s does something\n" "$function_name"
    printf "    if [[ -z \"\\$%s\" ]]; then\n" "$argname"
    printf "        echo 'Usage: %s [%s]'\n" "$function_name" "$argname"
    printf "        return 1\n"
    printf "    fi\n"
    printf "\n}\n"
}

# omf_update - Updates oh-my-fish and bundled packages (from 🐠_omf)
function omf_update() {
    echo "🐠 oh-my-fish - https://github.com/oh-my-fish/oh-my-fish"
    echo
    local base_dir=~/dev/shell/fish
    local local_dir="$base_dir/oh-my-fish"
    local repo_url="git@github.com:oh-my-fish/oh-my-fish.git"

    # Create parent directories
    mkdir -p "$base_dir"

    # Clone or pull (you'll need to implement clone_or_pull function)
    if [[ ! -d "$local_dir" ]]; then
        git clone "$repo_url" "$local_dir"
    else
        pushd "$local_dir" && git pull && popd
    fi

    # Install omf if necessary
    if ! command -v omf >/dev/null; then
        pushd "$local_dir"
        bin/install --offline
        popd
    fi

    # Update omf and installed plugins
    omf update
    omf install

    echo "Installed plugins: "
    omf list
    omf doctor
}

# sg - Quick dir navigation to SwiftGen
function sg() {
    pushd ~/dev/xcode/SwiftGen
}

# gpi - Runs podInstall gradle task
function gpi() {
    gw podInstall
}

# cball - Build all platforms using Carthage
function cball() {
    carthage build --platform all "$@"
}

# entitlements - Display entitlements in the codesign information of a bundle
function entitlements() {
    codesign -d --entitlements :- "$@"
}

# bi - Short alias for installing gems using Bundler
function bi() {
    bundle install "$@"
}

# xcbschemes - Displays schemes for an Xcode project
function xcbschemes() {
    local schemes=( $(xcblist | grep "Schemes:" -A 10 | tail -n +2 | sed -e 's/^[ \t]*//') )
    # Remove the last empty element
    schemes=("${schemes[@]:0:$((${#schemes[@]}-1))}")
    for scheme in "${schemes[@]}"; do
        echo "$scheme"
    done
}

# cont - Commit an in-progress git merge or continue a rebase, cherry-pick or am
function cont() {
    if [[ -e .git/MERGE_HEAD ]]; then
        echo "File exists"
        git commit >/dev/null
    elif [[ -e .git/REBASE_HEAD ]]; then
        git rebase --continue >/dev/null
    elif [[ -e .git/CHERRY_PICK_HEAD ]]; then
        git cherry-pick --continue "$@"
    else
        git am --continue >/dev/null
    fi
}

# cfrservice - Quick dir nav to CFR Service project
function cfrservice() {
    pushd ~/dev/realm/ClinicalFacilityRealmService
}

# pru - Update CocoaPod repos
function pru() {
    pod repo update "$@"
}

# ra - Adds a git remote
function ra() {
    local name="$1"
    local url="$2"
    if [[ -z "$name" ]]; then
        echo "Remote name required"
        return 1
    fi

    # Add a fork of the project when only the remote name is given
    if [[ -z "$url" ]]; then
        local remote_url=$(git remote get-url $(git symbolic-ref --short HEAD | sed 's|.*/||'))
        # Drop scheme and host
        local path=${remote_url##*:}
        # Drop .git
        path=${path%%.git}
        local project=${path##*/}
        url="git@github.com:${name}/${project}.git"
    fi

    git remote add "$name" "$url"
    git fetch "$name"
}

# pushf - Force a git push
function pushf() {
    git push --force "$@"
}

# func - Prints colorized, indented source of a loaded function
function func() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: func name"
        return 1
    elif ! command -v "$name" >/dev/null && ! type "$name" >/dev/null; then
        echo "$name does not exist"
        return 2
    fi

    # For Zsh functions, use 'functions' command or 'type'
    if type "$name" | grep -q "function"; then
        type "$name"
    else
        echo "$name is not a function"
    fi
}

# Additional converted Fish functions (Batch 2)

# getudid - Prints and copies the UDID of the connected iOS device
function getudid() {
    local udid=$(system_profiler SPUSBDataType | \
        grep -A 11 -w "iPad\|iPhone\|iPad" | \
        grep "Serial Number" | \
        awk '{ print $3 }')

    if [[ -z "$udid" ]]; then
        echo "No device detected. Please ensure an iOS device is plugged in."
        return 1
    else
        for identifier in $udid; do
            echo -n "$identifier" | pbcopy
            echo "UDID: $identifier"
        done
    fi
}

# swift_pgp_key_import - Import the Swift PGP keys into your keyring
function swift_pgp_key_import() {
    gpg --keyserver hkp://pool.sks-keyservers.net \
        --recv-keys \
        '7463 A81A 4B2E EA1B 551F  FBCF D441 C977 412B 37AD' \
        '1BE1 E29A 084C B305 F397  D62A 9F59 7F4D 21A5 6D5F' \
        'A3BA FD35 56A5 9079 C068  94BD 63BC 1CFE 91D3 06C6' \
        '5E4D F843 FB06 5D7F 7E24  FBA2 EF54 30F0 71E1 B235' \
        '8513 444E 2DA3 6B7C 1659  AF4D 7638 F1FB 2B2B 08C4' \
        'A62A E125 BBBF BB96 A6E0  42EC 925C C1CC ED3D 1561' \
        '8A74 9566 2C3C D4AE 18D9  5637 FAF6 989E 1BC1 6FEA'

    # https://swift.org/download/#active-signing-keys
    gpg --keyserver hkp://pool.sks-keyservers.net \
        --recv-keys \
        '8A74 9566 2C3C D4AE 18D9  5637 FAF6 989E 1BC1 6FEA'

    gpg --keyserver hkp://pool.sks-keyservers.net \
        --recv-keys \
        'A62A E125 BBBF BB96 A6E0  42EC 925C C1CC ED3D 1561'
}

# unshallow - Converts a shallow git repo to full
function unshallow() {
    git fetch --unshallow "$@"
}

# sync - Synchronizes a git repo
function sync() {
    if git_repo_dirty; then
        echo "📥 Stashing changes"
        stsave
    fi

    local sync_branch="master"
    if [[ "$sync_branch" != "$(current_branch)" ]]; then
        git checkout "$sync_branch"
    fi

    pull

    local remote_name=$(remote_for_current_branch)
    prune "$remote_name"

    bra

    echo "prompt to delete any tracking branches that have lost their remotes, gone in bra output"
}

# gitconfig_setup - Sets git user.name and user.email in XDG_CONFIG_HOME
function gitconfig_setup() {
    local email="$1"
    local name="$2"

    echo "🗄 Git configuration"
    echo

    mkdir -p ~/.config/git
    local global_config=~/.config/git/config
    if [[ ! -f "$global_config" ]]; then
        touch "$global_config"
    fi

    # Just print the current config when values are set
    if git config --file "$global_config" user.name >/dev/null 2>&1 && \
       git config --file "$global_config" user.email >/dev/null 2>&1; then
        cat "$global_config"
        return 0
    fi

    # Prompt to add required values
    if [[ -z "$name" ]]; then
        echo -n "Git user.name: "
        read name
    fi

    if [[ -z "$email" ]]; then
        echo -n "Git user.email: "
        read email
    fi

    git config --file "$global_config" user.name "$name"
    git config --file "$global_config" user.email "$email"

    echo "$global_config"
    cat "$global_config"
}

# dss - Scale one or multiple replicated docker services
function dss() {
    docker service scale "$@"
}

# lgfind - Search through lightweight log `lg` for a specific pattern
function lgfind() {
    local search_term="$1"
    if [[ -z "$search_term" ]]; then
        echo "Usage: lgfind 'search term'"
        return 1
    fi

    lg -S "$search_term"
}

# ls - List files with colors and trailing slashes on directories
function ls() {
    # -p      Write a slash (`/') after each filename if that file is a directory.
    # -G      Enable colorized output.  This option is equivalent to defining
    # CLICOLOR in the environment.  (See lscolors.)
    command ls -p "$@"
}

# fishlog - View fish daemon log
function fishlog() {
    less "/tmp/fishd.log.$USER"
}

# ida - Launch IDA with elevated privileges
function ida() {
    local ida_path="/Applications/IDA Pro 7.5"

    if [[ ! -d "$ida_path" ]]; then
        echo "IDA is not installed"
        return 1
    fi

    sudo "$ida_path/idabin/ida64" "$@"
}

# Additional converted Fish functions (Batch 3)

# derived_data - Spins up a RAM disk for Xcode DerivedData
function derived_data() {
    local quiet="$1"
    local drive_name="DerivedData"
    local default_size=10
    local target_path="/Volumes/$drive_name"
    local icon_file="~/Pictures/Icons/Agua Onyx Icons/Onyx Media Drive.png"

    if [[ -d "$target_path" ]]; then
        echo "$drive_name already mounted"
        local output=$(diskutil list "$drive_name")
    else
        local output=$(ramdisk "$default_size" "$drive_name")
        fileicon set "$target_path" "$icon_file"
    fi

    if [[ -z "$quiet" ]]; then
        echo "$output"
    fi
}

# hgrep - Grep command history
function hgrep() {
    history | grep "$@"
}

# stash - Git stash
function stash() {
    git stash "$@"
}

# push - Git push
function push() {
    git push "$@"
}

# textmate - Manage TextMate bundles (converted from 📝_textmate)
function textmate() {
    echo "📝 TextMate - https://github.com/textmate/textmate"
    echo
    local bundles=(blackpearl dashmate editorconfig fish gradle kotlin tomorrow-theme ublime)
    local bundle_dev="~/dev/textmate"
    local bundle_dir="~/Library/Application Support/TextMate/Bundles"

    mkdir -p "$bundle_dev" "$bundle_dir"
    pushd "$bundle_dev"

    for bundle in "${bundles[@]}"; do
        if [[ ! -e "$bundle.tmbundle" ]]; then
            case "$bundle" in
                blackpearl)
                    clone_or_pull "$bundle.tmbundle/Themes" "git@github.com:ajwitte/textmate-goodies.git"
                    tmbundleplist \
                        "Black Pearl Theme" \
                        "Colorful and Black & White color schemes. Plist generated by tmbundleplist function." \
                        "git@github.com:ajwitte/textmate-goodies.git" \
                        > "$bundle.tmbundle/Info.plist"
                    ;;
                dashmate)
                    clone_or_pull "DashMate.tmbundle" "git@github.com:ram-nadella/DashMate.tmbundle.git"
                    ;;
                editorconfig)
                    clone_or_pull "$bundle" "git@github.com:Mr0grog/editorconfig-textmate.git"
                    local ec_version=0.3.1
                    curl -L -O -# "https://github.com/Mr0grog/editorconfig-textmate/releases/download/v$ec_version/editorconfig-textmate-$ec_version.tmplugin.zip"
                    local newest_file=$(ls -1t | head -n 1)
                    unzip -o "$newest_file"
                    rm -f "$newest_file"
                    [[ $(status is-login) ]] && open "editorconfig-textmate.tmplugin"
                    touch "$bundle.tmbundle"
                    ;;
                fish)
                    clone_or_pull "$bundle.tmbundle" "git@github.com:l15n/fish-tmbundle.git"
                    ;;
                gradle)
                    clone_or_pull "$bundle.tmbundle" "git@github.com:alkemist/gradle.tmbundle.git"
                    ;;
                kotlin)
                    clone_or_pull "$bundle" "git@github.com:sargunster/kotlin-textmate-bundle.git"
                    local bundle="$bundle/Kotlin"
                    ;;
                tomorrow-theme)
                    clone_or_pull "$bundle" "git@github.com:chriskempson/tomorrow-theme.git"
                    local bundle="tomorrow-theme/textmate2/Tomorrow Theme"
                    ;;
                ublime)
                    clone_or_pull "$bundle.tmbundle/Themes" "git@github.com:imagentleman/ublime.git"
                    tmbundleplist \
                        "Ublime Color Schemes" \
                        "Colorful and Black & White color schemes. Plist generated by tmbundleplist function." \
                        "git@github.com:imagentleman/ublime.git" \
                        > "$bundle.tmbundle/Info.plist"
                    ;;
            esac
        fi
        [[ $(filesize "$bundle.tmbundle") -gt 0 && $(status is-login) ]] && open "$bundle.tmbundle"
    done
    echo "$bundle_dev"
    ls
    popd
}

# delete-tag - Deletes a git tag from both the local and remote repos
function delete-tag() {
    local tag="$1"
    if [[ -z "$tag" ]]; then
        echo "Usage: delete-tag <tag>"
        return 1
    fi

    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    local current_remote=$(git config branch."$current_branch".remote)

    git tag --delete "$tag"
    git push "$current_remote" --delete refs/tags/"$tag"
}

# dpl - View output from docker containers
function dpl() {
    docker compose logs --follow "$@"
}

# ol - Quick dir navigation to Outlets
function ol() {
    pushd ~/dev/ios/pods/Outlets
}

# members - List members of the given group
function members() {
    local group="$1"
    if [[ -z "$group" ]]; then
        echo "Usage: members group"
        return 1
    fi

    for user in $(dscl . -list /Users); do
        if dsmemberutil checkmembership -U "$user" -G "$group" | grep -q "is a member"; then
            echo "$user"
        fi
    done
}

# brew_cache_purge - Purges the Homebrew cache
function brew_cache_purge() {
    rm -rf $(brew --cache)
}


# Additional converted Fish functions (Batch 5)

# erase - Erase fish functions
function erase() {
    functions --erase "$@"
}

# rubygems - Installs and updates Ruby gems (converted from 💎_rubygems)
function rubygems() {
    echo "💎 Updating Ruby Gems"
    echo

    if user_is_admin; then
        # Workaround to no access to /usr/bin on Sierra
        # Updating rubygems-update
        gem update --system
        gem update

        # Bundler
        gem install bundler
    fi
}

# untracked - Displays files not tracked in the current git repo
function untracked() {
    git ls-files --others --exclude-standard "$@"
}

# amendne - Amend previous commit without editing the message
function amendne() {
    git commit --verbose --amend --no-edit "$@"
}

# apv - Quick nav to ApplePlatformVersions dir
function apv() {
    local apv_dir="~/dev/ApplePlatformVersions"

    if [[ ! -d "$apv_dir" ]]; then
        cd ~/dev
        git clone git@github.com:phatblat/ApplePlatformVersions.git
    else
        cd "$apv_dir"
        git pull
    fi

    lg10
}

# be - Short alias for executing gems through Bundler
function be() {
    bundle exec "$@"
}

# realmos - Manage Realm Object Server
function realmos() {
    local command="$1"
    echo "Realm Object Server"

    if [[ ! -e "$REALM_OBJECT_SERVER_PATH" ]]; then
        echo "No such path: $REALM_OBJECT_SERVER_PATH"
        return 1
    fi

    case "$command" in
        start)
            echo "Starting ROS at $REALM_OBJECT_SERVER_PATH"
            eval "$REALM_OBJECT_SERVER_PATH/start-object-server.command"
            ;;
        *)
            echo "Usage: realmos [start]"
            ;;
    esac
}

# bisect - Git bisect
function bisect() {
    git bisect "$@"
}

# ccu - Update dependencies without building using Carthage
function ccu() {
    carthage update --no-use-binaries --no-build "$@"
}

# shell_switch - Changes the current $USER's shell using dscl
function shell_switch() {
    local new_shell="$1"
    if [[ -z "$new_shell" ]]; then
        echo "Usage: shell_switch bash|zsh|fish"
        return 1
    fi

    local brew_binaries=$(brew --prefix)/bin
    local new_shell_path="$brew_binaries/$new_shell"

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        chsh --shell "$new_shell_path"
        return $?
    fi

    local cmd="sudo dscl . -change $HOME UserShell $SHELL $new_shell_path"

    if [[ "$(basename $SHELL)" != "$new_shell" ]]; then
        if user_is_admin; then
            eval "$cmd"
            echo -n "Changed "$(dscl . -read $HOME UserShell)
            echo
            eval "$new_shell_path"
        else
            echo "Have an admin run the following command:"
            echo "    $cmd"
            return
        fi
    else
        echo "No changes."
        return
    fi
}

# Additional converted Fish functions (Batch 8)

# shortlog - Alias for shortlog
function shortlog() {
    git shortlog
}

# cargo_target - Spins up a RAM disk for Cargo target output
function cargo_target() {
    local quiet="$1"
    local drive_name="CargoTarget"
    local default_size=50
    local target_path="/Volumes/$drive_name"
    local icon_file="~/Pictures/Icons/rustacean-flat-happy.webp"

    local output
    if [[ -d "$target_path" ]]; then
        echo "$drive_name already mounted"
        output=$(diskutil list "$drive_name")
    else
        output=$(ramdisk "$default_size" "$drive_name")
        fileicon set "/Volumes/$drive_name" "$icon_file"
    fi

    export CARGO_TARGET_DIR="$target_path"

    if [[ -z "$quiet" ]]; then
        echo "$output"
    fi
}

# octodec - SSH to octodec
function octodec() {
    ssh phatblat@octodec.local "$@"
}

# itwire - Quick dir navigation to ITWire
function itwire() {
    pushd ~/dev/bluemix/ITWire
}

# moj_user - Prints an emoji for the current user
function moj_user() {
    case "$USER" in
        admin)
            echo "🙆🏻‍♂️" ;;
        ben|f*)
            echo "🚶" ;;
        benchatelain|chatelain|zoltar)
            echo "👨🏻‍🚀" ;;
        phatblat)
            echo "🎧" ;;
        jenkins)
            echo "👷🏻‍♂️" ;;
        *)
            echo "${USER:0:1}❓" ;;
    esac
}

# ignores - Standard ignored files
function ignores() {
    cat <<EOF
# macOS
.DS_Store
# Xcode
*.xccheckout
*.xcscmblueprint
xcuserdata
Carthage/
Pods/
# Swift PM
.build/
.swiftpm/
# Bundler
.rubygems/
bin/
# Gradle
build/
.gradle/
gradlew.bat
# IntelliJ IDEA
.idea/
*.iml
*.hprof
# VS Code
.classpath
.project
.settings
.vscode/
# Rust
.target/
# CMake
.cxx/
cmake-build-debug/
.externalNativeBuild/
# Java
heapdump.*.phd
javacore.*.txt
# Rust/Cargo
target/
# Visual Studio, MSBuild
*.dll
.vs/
obj/
packages/
# Visual Studio, MSBuild
.vscode/
# Bazel
bazel-*
# Buck2
buck-out/
# Python
__pycache__/
# Node.js
node_modules/
# npm
.npm/
EOF
}

# is_octodec - Tests whether the current computer is octodec
function is_octodec() {
    [[ "$(hostname)" == *"octodec"* ]]
}

# openports - Lists open ports for the current user
function openports() {
    lsof -i | grep LISTEN
}

# func_count - Prints a count of all functions
function func_count() {
    local all=$(functions | wc -l | xargs)
    local custom=$(find ~/.config/fish/functions -type f -maxdepth 1 -name '*.fish' | wc -l | xargs)
    local plugins=$(find ~/.config/fish/functions -type l -maxdepth 1 -name '*.fish' | wc -l | xargs)
    local autoloaded=$(ls -1 ~/.config/fish/functions/*.fish | wc -l | xargs)

    echo "Functions: $all ($custom custom, $plugins plugins, $autoloaded autoloaded)"
}

# r - Interactive rebase for the last few commits
function r() {
    local count=${1:-10}

    toggle_wait on

    git rebase --interactive HEAD~$count

    toggle_wait off
}
# Additional converted Fish functions (Batch 4)

# fileowner - Displays the owner of a file
function fileowner() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "Usage: fileowner file"
        return 1
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        ls -ld "$file" | awk '{print $3}'
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        stat --format=%U "$file"
    fi
}

# dil - List docker images
function dil() {
    docker images "$@"
}

# user.name - Manages the user.name git configuration setting
function user.name() {
    git config user.name "$@"
}

# xc - Xcode wrapper function
function xc() {
    if [[ -f Package.swift ]]; then
        echo "Opening swift package"
        open Package.swift "$@"
        return
    fi

    # Find workspaces (ignore ones inside xcodeproj bundle)
    local workspaces=( $(find . -name "*.xcworkspace" -not -path "*/project.xcworkspace*" 2>/dev/null) )
    if [[ ${#workspaces[@]} -gt 0 ]]; then
        printf '%s\n' "${workspaces[@]}"
        if [[ -d "${workspaces[1]}" ]]; then
            echo "Opening first workspace"
            open "${workspaces[1]}" "$@"
            return
        fi
    fi

    # Find projects (ignore CocoaPods projects)
    local projects=( $(find . -name "*.xcodeproj" -not -name "Pods.xcodeproj" 2>/dev/null) )
    if [[ ${#projects[@]} -gt 0 ]]; then
        printf '%s\n' "${projects[@]}"
        if [[ -d "${projects[1]}" ]]; then
            echo "Opening first project"
            open "${projects[1]}" "$@"
            return
        fi
    fi

    echo "No Xcode projects found in the current directory."
    return 1
}

# xcvmget - Show a live list of Xcode versions available to download
function xcvmget() {
    bundle exec ruby -e "
        class Xcode
          attr_reader :date_modified
          attr_reader :name
          attr_reader :path
          attr_reader :url
          attr_reader :version
          attr_reader :release_notes_url

          def initialize(json, url = nil, release_notes_url = nil)
            if url.nil?
              @date_modified = json['dateModified'].to_i
              @name = json['name'].gsub(/^Xcode /, '')
              @path = json['files'].first['remotePath']
              url_prefix = 'https://developer.apple.com/devcenter/download.action?path='
              @url = \"#{url_prefix}#{@path}\"
              @release_notes_url = \"#{url_prefix}#{json['release_notes_path']}\" if json['release_notes_path']
            else
              @name = json
              @path = url.split('/').last
              url_prefix = 'https://developer.apple.com/'
              @url = \"#{url_prefix}#{url}\"
              @release_notes_url = \"#{url_prefix}#{release_notes_url}\"
            end

            begin
              @version = Gem::Version.new(@name.split(' ')[0])
            rescue
              @version = Gem::Version.new('4.3')
            end
          end

          def to_s
            \"Xcode #{version} -- #{url}\"
          end

          def ==(other)
            date_modified == other.date_modified && name == other.name && path == other.path &&
              url == other.url && version == other.version
          end

          def self.new_prerelease(version, url, release_notes_path)
            new('name' => version,
                'files' => [{ 'remotePath' => url.split('=').last }],
                'release_notes_path' => release_notes_path)
          end
        end

        require 'spaceship'

        def spaceship
          @spaceship ||= begin
            begin
              Spaceship.login(ENV['XCODE_INSTALL_USER'], ENV['XCODE_INSTALL_PASSWORD'])
            rescue Spaceship::Client::InvalidUserCredentialsError
              \$stderr.puts 'The specified Apple developer account credentials are incorrect.'
              exit(1)
            rescue Spaceship::Client::NoUserCredentialsError
              \$stderr.puts 'Please provide your Apple developer account credentials via the XCODE_INSTALL_USER and XCODE_INSTALL_PASSWORD environment variables.'
              exit(1)
            end

            if ENV.key?('XCODE_INSTALL_TEAM_ID')
              Spaceship.client.team_id = ENV['XCODE_INSTALL_TEAM_ID']
            end
            Spaceship.client
          end
        end

        json = spaceship.send(:request, :get,
                                '/services-account/QH65B2/downloadws/listDownloads.action',
                                start: '0',
                                limit: '1000',
                                sort: 'dateModified',
                                dir: 'DESC',
                                searchTextField: '',
                                searchCategories: '',
                                search: 'false').body

        def parse_seedlist(seedlist)
          seeds = Array(seedlist['downloads']).select do |t|
            /^Xcode [0-9]/.match(t['name'])
          end

          minimum_version = Gem::Version.new('4.3')
          xcodes = seeds.map { |x| Xcode.new(x) }.reject { |x| x.version < minimum_version }.sort do |a, b|
            a.date_modified <=> b.date_modified
          end

          xcodes.select { |x| x.url.end_with?('.dmg') || x.url.end_with?('.xip') }
        end

        xcodes = parse_seedlist(json)
        puts xcodes.map(&:name)
    "
}

# dnr - Remove one or more docker networks
function dnr() {
    docker network rm "$@"
}

# pick - Short alias for cherry-pick
function pick() {
    git cherry-pick "$@"
}

# objg - Quick nav to Objective-Git
function objg() {
    pushd ~/dev/libgit2/objective-git
}

# merge-base - Git merge-base wrapper
function merge-base() {
    git merge-base "$@"
}

# bog - Update gem bundle using the local Gemfile
function bog() {
    bo --gemfile=Gemfile
}

# mpv - Quick nav to MicrosoftPlatformVersions dir
function mpv() {
    local mpv_dir=~/dev/MicrosoftPlatformVersions

    if [[ ! -d "$mpv_dir" ]]; then
        cd ~/dev
        git clone git@github.com:phatblat/MicrosoftPlatformVersions.git
    else
        cd "$mpv_dir"
        git pull
    fi

    lg10
}

# dpu - Builds, (re)creates, starts, and attaches to containers for a service
function dpu() {
    docker compose up --detach "$@"
}

# gpgtest - Test GPG key with passphrase
function gpgtest() {
    local key_id="$1"
    local passphrase="$2"
    if [[ -z "$key_id" ]]; then
        echo "Usage: gpgtest key_id passphrase"
        return 1
    fi

    echo "$passphrase" | \
        gpg -o /dev/null \
            --local-user "$key_id" \
            -as - \
        && echo "The correct passphrase was entered for this key"
}

# prune - Prune obsolete remote branches on the given remote
function prune() {
    git remote prune "$@"
}

# Additional converted Fish functions (Batch 5)

# erase - Erase fish functions
function erase() {
    functions --erase "$@"
}

# rubygems - Installs and updates Ruby gems (converted from 💎_rubygems)
function rubygems() {
    echo "💎 Updating Ruby Gems"
    echo

    if user_is_admin; then
        # Workaround to no access to /usr/bin on Sierra
        # Updating rubygems-update
        gem update --system
        gem update

        # Bundler
        gem install bundler
    fi
}

# untracked - Displays files not tracked in the current git repo
function untracked() {
    git ls-files --others --exclude-standard "$@"
}

# amendne - Amend previous commit without editing the message
function amendne() {
    git commit --verbose --amend --no-edit "$@"
}

# apv - Quick nav to ApplePlatformVersions dir
function apv() {
    local apv_dir="~/dev/ApplePlatformVersions"

    if [[ ! -d "$apv_dir" ]]; then
        cd ~/dev
        git clone git@github.com:phatblat/ApplePlatformVersions.git
    else
        cd "$apv_dir"
        git pull
    fi

    lg10
}

# be - Short alias for executing gems through Bundler
function be() {
    bundle exec "$@"
}

# realmos - Manage Realm Object Server
function realmos() {
    local command="$1"
    echo "Realm Object Server"

    if [[ ! -e "$REALM_OBJECT_SERVER_PATH" ]]; then
        echo "No such path: $REALM_OBJECT_SERVER_PATH"
        return 1
    fi

    case "$command" in
        start)
            echo "Starting ROS at $REALM_OBJECT_SERVER_PATH"
            eval "$REALM_OBJECT_SERVER_PATH/start-object-server.command"
            ;;
        *)
            echo "Usage: realmos [start]"
            ;;
    esac
}

# bisect - Git bisect
function bisect() {
    git bisect "$@"
}

# ccu - Update dependencies without building using Carthage
function ccu() {
    carthage update --no-use-binaries --no-build "$@"
}

# shell_switch - Changes the current $USER's shell using dscl
function shell_switch() {
    local new_shell="$1"
    if [[ -z "$new_shell" ]]; then
        echo "Usage: shell_switch bash|zsh|fish"
        return 1
    fi

    local brew_binaries=$(brew --prefix)/bin
    local new_shell_path="$brew_binaries/$new_shell"

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        chsh --shell "$new_shell_path"
        return $?
    fi

    local cmd="sudo dscl . -change $HOME UserShell $SHELL $new_shell_path"

    if [[ "$(basename $SHELL)" != "$new_shell" ]]; then
        if user_is_admin; then
            eval "$cmd"
            echo -n "Changed "$(dscl . -read $HOME UserShell)
            echo
            eval "$new_shell_path"
        else
            echo "Have an admin run the following command:"
            echo "    $cmd"
            return
        fi
    else
        echo "No changes."
        return
    fi
}

# Additional converted Fish functions (Batch 6)

# clone - Performs a git clone, then configures repo user
function clone() {
    local url="$1"
    local dir="$2"

    if [[ -z "$url" ]]; then
        echo "Usage: clone url [dir]"
        return 1
    fi

    if [[ -z "$dir" ]]; then
        # Extract directory name from URL (remove .git extension and get basename)
        dir=$(basename "$url" .git)
    fi

    git clone -- "$url" "$dir" && \
    pushd "$dir" && \
    git config user.email "$(email_url "$url")" && \
    user
}

# macos - Manage macOS system updates (converted from 🖥_macos)
function macos() {
    echo "🖥  macOS"

    # Only install Rosetta 2 on M1 if not already installed
    if [[ "$(uname -m)" == "arm64" && ! -f "/Library/Apple/usr/share/rosetta/rosetta" ]]; then
        echo
        echo "🌍  Rosetta 2"
        sudo softwareupdate --install-rosetta
    fi

    echo
    echo "⌛️  Recently installed macOS system updates"
    softwareupdate --history

    echo
    echo "🔎  Checking macOS system updates"
    softwareupdate --list

    echo
    echo "⬆️  Updating macOS system software"

    # Download all updates before install
    local output=$(softwareupdate --download --all --no-scan 2>&1)

    # Exit when "No updates are available."
    if [[ -n "$output" ]]; then
        echo "$output"
        return
    fi

    # sudo will prompt for password allowing one way to avoid a restart
    sudo softwareupdate --install --all --no-scan --restart
}

# dcw - Diff the git staging area using word diff
function dcw() {
    git diff --cached --word-diff "$@"
}

# bpie - Install pods for Example app
function bpie() {
    bundle exec pod install \
        --project-directory=Example \
        "$@"
}

# dlogs - Fetch the logs of a docker container
function dlogs() {
    docker logs --follow "$@"
}

# ltime - Time last command took to complete
function ltime() {
    if [[ -n "$CMD_DURATION" ]]; then
        echo "$(echo "scale=3; $CMD_DURATION / 1000" | bc)s"
    else
        echo "No command duration available"
    fi
}

# nix_install - Installs nix tools (converted from ❄️_nix)
function nix_install() {
    echo "❄️ Nix - https://nixos.org/download.html#nix-install-macos"
    echo

    if ! command -v nix-channel >/dev/null 2>&1; then
        echo "❄️ Installing nix..."
        curl -L https://nixos.org/nix/install | sh -s -- --daemon

        nixtest

        nix-channel --add https://github.com/nix-community/home-manager/archive/release-22.05.tar.gz home-manager
        nix-channel --update
    fi
}

# brew_versions - Lists installed versions of a formula
function brew_versions() {
    local formula="$1"
    if [[ -z "$formula" ]]; then
        echo "Usage: brew_versions formula"
        return 1
    elif ! brew list "$formula" >/dev/null 2>&1; then
        echo "$formula is not installed." >&2
        return 2
    fi

    # brew list --versions ruby output:
    # ruby 2.3.3 2.4.1_1
    brew list --versions "$formula" | cut -d' ' -f2-
}

# pil - Special "local" pod install for KP Mobile
function pil() {
    LOCAL=1 pod install "$@"
}

# is_linux - Tests whether the current computer is running Linux
function is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}
# Additional converted Fish functions (Batch 7)

# gpgcopypub - Copies the public key for any GPG key found
function gpgcopypub() {
    local keyid=$(gpgkeyid)
    local gpg_key_ascii=$(gpg --armor --export "$keyid")
    echo "$gpg_key_ascii" | pbcopy
    echo "GPG key copied to pasteboard (keyid: $keyid)"
}

# gw - Invokes a build using the Gradle wrapper script
function gw() {
    if [[ -e ./gradlew ]]; then
        ./gradlew "$@"
        return
    fi

    echo "There is no Gradle wrapper in the current dir."
    gradle "$@"
}

# provisioning_print - Prints a text version of a provisioning profile
function provisioning_print() {
    local profile_path="$1"
    if [[ -z "$profile_path" ]]; then
        echo "Usage: provisioning_print path/to/profile.mobileprovision"
        return 1
    fi

    if [[ ! -e "$profile_path" ]]; then
        echo "$profile_path does not exist"
        return 2
    fi

    security cms -D -i "$profile_path" 2>/dev/null
}

# appcast_url - Calculate appcast checkpoint
function appcast_url() {
    local url="$1"
    if [[ -z "$url" ]]; then
        echo "Usage: appcast_url url"
        return 1
    fi

    brew cask _appcast_checkpoint --calculate "$url"
}

# xv - Prints Xcode version information
function xv() {
    xcodebuild -version "$@"
}

# edit - Edit using the configured VISUAL editor (TextMate) for GUI terminal sessions or EDITOR for CLI (SSH) sessions
function edit() {
    local editor_cmd

    # Determine which editor to use
    if [[ -n "$VISUAL" ]]; then
        editor_cmd="$VISUAL"
    elif [[ -n "$EDITOR" ]]; then
        editor_cmd="$EDITOR"
    else
        # Default to editors in order of preference: zed, void, windsurf, cursor, code, nvim, vim
        if command -v zed >/dev/null 2>&1; then
            editor_cmd="zed"
        elif command -v void >/dev/null 2>&1; then
            editor_cmd="void"
        elif command -v windsurf >/dev/null 2>&1; then
            editor_cmd="windsurf"
        elif command -v cursor >/dev/null 2>&1; then
            editor_cmd="cursor"
        elif command -v code >/dev/null 2>&1; then
            editor_cmd="code"
        elif command -v nvim >/dev/null 2>&1; then
            editor_cmd="nvim"
        elif command -v vim >/dev/null 2>&1; then
            editor_cmd="vim"
        else
            echo "No editor found. Please set VISUAL or EDITOR environment variable."
            return 1
        fi
    fi

    # Execute the editor with the provided arguments
    $editor_cmd "$@"
}

# e - Short alias for editing a file. Given no args, the current folder will be opened
function e() {
    if [[ -z "$1" ]]; then
        edit .
    else
        edit "$@"
    fi
}

# upmodule - Optionally invokes an upstall module (converted from ⬆️_upmodule)
function upmodule() {
    local module_function="$1"
    local display_name="$2"
    local include_flag="$3"
    local skip_flag="$4"
    shift 4
    local original_args=("$@")

    # no args
    if [[ -z "$module_function" ]]; then
        echo "Usage: upmodule module_function [display_name include_flag skip_flag original_args]"
        return 1
    fi

    if ! command -v "$module_function" >/dev/null 2>&1; then
        echo "Unknown function: $module_function"
        return 2
    fi

    # 1 arg
    if [[ $# -eq 0 && -z "$display_name" ]]; then
        repeatchar -
        eval "$module_function"

    # 4+ args
    elif [[ -n "$display_name" && -n "$include_flag" && -n "$skip_flag" ]]; then
        if ! command -v "$module_function" >/dev/null 2>&1; then
            echo "Unknown function: $module_function"
            return 4
        fi

        if [[ " ${original_args[*]} " =~ " $skip_flag " ]]; then
            # Skip module if skip flag was given
            repeatchar -
            echo "$display_name (skipped)"
        elif [[ " ${original_args[*]} " =~ " $include_flag " ]]; then
            # Run module if asked for
            repeatchar -
            eval "$module_function"
        else
            # Otherwise, skip
            # echo "$display_name (skipped)"
            :
        fi
    else
        echo "Usage: upmodule module_function [display_name include_flag skip_flag original_args]"
        return 2
    fi
}

# s - Display abbreviated git status
function s() {
    git status -sb "$@"
}

# fq - Check for existence of a function
function fq() {
    local function_name="$1"
    local file="~/.config/fish/functions/$function_name.fish"

    command -v "$function_name" >/dev/null 2>&1 || [[ -e "$file" ]]
}

# branch - Manage git branches
function branch() {
    git branch "$@"
}
# Additional converted Fish functions (Batch 8)

# shortlog - Alias for shortlog
function shortlog() {
    git shortlog
}

# cargo_target - Spins up a RAM disk for Cargo target output
function cargo_target() {
    local quiet="$1"
    local drive_name="CargoTarget"
    local default_size=50
    local target_path="/Volumes/$drive_name"
    local icon_file="~/Pictures/Icons/rustacean-flat-happy.webp"

    local output
    if [[ -d "$target_path" ]]; then
        echo "$drive_name already mounted"
        output=$(diskutil list "$drive_name")
    else
        output=$(ramdisk "$default_size" "$drive_name")
        fileicon set "/Volumes/$drive_name" "$icon_file"
    fi

    export CARGO_TARGET_DIR="$target_path"

    if [[ -z "$quiet" ]]; then
        echo "$output"
    fi
}

# octodec - SSH to octodec
function octodec() {
    ssh phatblat@octodec.local "$@"
}

# itwire - Quick dir navigation to ITWire
function itwire() {
    pushd ~/dev/bluemix/ITWire
}

# moj_user - Prints an emoji for the current user
function moj_user() {
    case "$USER" in
        admin)
            echo "🙆🏻‍♂️" ;;
        ben|f*)
            echo "🚶" ;;
        benchatelain|chatelain|zoltar)
            echo "👨🏻‍🚀" ;;
        phatblat)
            echo "🎧" ;;
        jenkins)
            echo "👷🏻‍♂️" ;;
        *)
            echo "${USER:0:1}❓" ;;
    esac
}

# ignores - Standard ignored files
function ignores() {
    cat <<EOF
*.dll
*.hprof
*.iml
*.xccheckout
*.xcscmblueprint
.DS_Store
.build/
.classpath
.cxx/
.externalNativeBuild/
.gradle/
.idea/
.npm/
.project
.rubygems/
.settings
.swiftpm/
.target/
.vs/
.vscode/
.vscode/
Carthage/
Pods/
__pycache__/
bazel-*
bin/
buck-out/
build/
cmake-build-debug/
gradlew.bat
heapdump.*.phd
javacore.*.txt
node_modules/
obj/
packages/
target/
xcuserdata
EOF
}

# is_octodec - Tests whether the current computer is octodec
function is_octodec() {
    [[ "$(hostname)" == *"octodec"* ]]
}

# openports - Lists open ports for the current user
function openports() {
    lsof -i | grep LISTEN
}

# func_count - Prints a count of all functions
function func_count() {
    local all=$(functions | wc -l | xargs)
    local custom=$(find ~/.config/fish/functions -type f -maxdepth 1 -name '*.fish' | wc -l | xargs)
    local plugins=$(find ~/.config/fish/functions -type l -maxdepth 1 -name '*.fish' | wc -l | xargs)
    local autoloaded=$(ls -1 ~/.config/fish/functions/*.fish | wc -l | xargs)

    echo "Functions: $all ($custom custom, $plugins plugins, $autoloaded autoloaded)"
}

# r - Interactive rebase for the last few commits
function r() {
    local count=${1:-10}

    toggle_wait on

    git rebase --interactive HEAD~$count

    toggle_wait off
}
# Additional converted Fish functions (Batch 9)

# showsvn - Show .svn directories in the current directory tree
function showsvn() {
    find . -type d -name .svn "$@"
}

# xps - Short alias for displaying nginx status
function xps() {
    xstatus "$@"
}

# log - Alias for `git log`
function log() {
    git log --pretty=fuller "$@"
}

# gwo - Gradle wrapper offline
function gwo() {
    gw "$@" --offline
}

# showcert - Prints server certificate file details
function showcert() {
    local cert_file="$1"
    if [[ ! -e "$cert_file" ]]; then
        echo "Usage: showcert cert_file"
        return 1
    fi

    eval "$OPENSSL_PATH x509 -in $cert_file -inform DER -text -noout"
}

# gv - Prints gradle version
function gv() {
    local output=$(gradle --version)
    local gradle_version=$(echo "$output" | sed -n '3p' | awk '{print $2}')
    echo "$gradle_version"
}

# htoptions - Send an HTTP request using the OPTIONS method using burl
function htoptions() {
    burl OPTIONS "$@"
}

# brew_logs - Quick nav to Homebrew logs dir
function brew_logs() {
    pushd ~/Library/Logs/Homebrew/
}

# mdk - Quick nav to MDK
function mdk() {
    local platform="$1"
    local path="~/dev/mdk"

    if [[ -n "$platform" ]]; then
        case "$platform" in
            i|ios)
                path="$path/ios" ;;
            a|android)
                path="$path/android" ;;
        esac
    fi

    pushd "$path"
}

# lggrep - Grep through lightweight log `lg` for a regex pattern
function lggrep() {
    local pattern="$1"
    if [[ -z "$pattern" ]]; then
        echo "Usage: lggrep '.*'"
        return 1
    fi

    lg -G "$pattern"
}

# assume - Ignore changes to the given files
function assume() {
    git update-index --assume-unchanged "$@"
}

# bq - Query brew information
function bq() {
    if [[ -z "$*" ]]; then
        cat <<EOF
Usage: bq [formula_name] [-- jq_filter]
Filter examples:
  formula                                                                           (raw json, filter with grep to find keys)
  formula -- .[0].name                                                              (formula name)
  formula -- .[0].linked_keg                                                        (active version)
  --installed -- 'map(select(.keg_only == true and .linked_keg != null) | .name)'   (names of linked keg-only formulae)
EOF
        return 1
    fi

    local brew_args=()
    local jq_args=()
    local collecting_jq=false

    for arg in "$@"; do
        if [[ "$arg" == "--" ]]; then
            collecting_jq=true
            continue
        fi

        if [[ "$collecting_jq" == true ]]; then
            jq_args+=("$arg")
        else
            brew_args+=("$arg")
        fi
    done

    if [[ ${#jq_args[@]} -eq 0 ]]; then
        jq_args=(".")
    fi

    brew info --json=v1 "${brew_args[@]}" | jq "${jq_args[@]}"
}

# configg - Manage global git configuration (~/.gitconfig)
function configg() {
    git config --global "$@"
}

# spotlight_reload - Reloads Spotlight which triggers a re-index
function spotlight_reload() {
    spotlight_disable

    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist

    spotlight_enable
}

# icloud - Changes directory to ICLOUD_HOME
function icloud() {
    pushd "$ICLOUD_HOME" "$@"
}

# ane - Git amend, without changing the commit message
function ane() {
    git commit --amend --no-edit
}

# reload - Reloads a single function or the entire fish shell
function reload() {
    local function_name="$1"
    local file="~/.config/fish/functions/$function_name.fish"

    if [[ -z "$function_name" ]]; then
        source ~/.zshrc
        return
    elif [[ -e "$file" ]]; then
        source "$file"
        if [[ $? -ne 0 ]]; then
            return $?
        fi
        # TODO: Show diff of function (memory vs file system)
        # func $function_name
    else
        echo "$function_name does not exist in function autoload dir."
        return 1
    fi
}

# gc - Run git garbage collection
function gc() {
    git gc --prune=now
}

# stsave - Save a git stash
function stsave() {
    git stash push --include-untracked "$@"
}

# chexe - Set executable permissions
function chexe() {
    local files="$*"
    if [[ -z "$files" ]]; then
        files="*.sh"
    fi
    chmod +x $files
}
# Additional converted Fish functions (Batch 11)

# debug - Prints args only when debug env var is set
function debug() {
    if [[ -n "$debug" ]]; then
        echo "DEBUG:" "$@"
    fi
}

# dash - Dash shell integration
function dash() {
    local query="$1"
    if [[ -z "$query" ]]; then
        echo "Usage: dash query   (prefix query with 'docset_name:' to limit)"
        return 1
    fi

    open "dash://$query"
}

# tube - Quick nav to Tube project
function tube() {
    pushd ~/dev/jenkins/Tube
}

# mt - Short alias for git mergetool
function mt() {
    git mergetool "$@"
}

# gpgkeyid - Prints the long format key identifiers of all GPG keys found
function gpgkeyid() {
    gpg --list-secret-keys \
            --keyid-format short \
        | egrep -o "^sec.*/\w+" \
        | cut -d "/" -f 2
}

# dit - Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
function dit() {
    docker image tag "$@"
}

# suri - Init and update git submodules recursively
function suri() {
    git submodule update --recursive --init "$@"
}

# rebase - Git rebase
function rebase() {
    git rebase "$@"
}

# pcopy - Copy the current dir path into the pasteboard
function pcopy() {
    pwd | xargs echo -n | pbcopy
}

# cfrmodel - Quick dir nav to CFR Model project
function cfrmodel() {
    pushd ~/dev/realm/ClinicalFacilityRealmModel
}

# xcinit - Runs Xcode new_project.rb ruby script
function xcinit() {
    ~/.dotfiles/xcode/new_project.rb "$@"
}

# git_inside_repo - Detects whether $PWD is inside a git repo or not
function git_inside_repo() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# ddd - Delete Derived Data
function ddd() {
    if [[ -z "$DERIVED_DATA" ]]; then
        echo "DERIVED_DATA is not set"
        return 1
    fi

    if [[ -d "$DERIVED_DATA" ]]; then
        echo "Deleting derived data directory $DERIVED_DATA"
        rm -rf "$DERIVED_DATA"
    else
        echo "Derived data directory does not exist"
    fi
}

# xcsp - Show the currently selected version of Xcode
function xcsp() {
    xcode-select --print-path "$@"
}

# masd - Quick nav to mas dir
function masd() {
    local repo_url="git@github.com:mas-cli/mas.git"
    local base_dir="~/dev/mas-cli"
    local local_dir="$base_dir/mas"

    # Create parent directories
    mkdir -p "$base_dir"

    clone_or_pull "$local_dir" "$repo_url"

    pushd "$local_dir"
}

# cat - Wrapper for bat because I can never remember
function cat() {
    bat "$@"
}

# big - Install gem bundle using the local Gemfile
function big() {
    bundle install --gemfile=Gemfile
}

# git-plist-filter - Converts plist data to XML format (stdin->stdout)
function git-plist-filter() {
    # had to do this because git doesn't like attaching stdin and out to plutil (waitpid error)

    # TMPDIR isn't set for ssh logins!
    local TMPDIR="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR)}"
    local function_name="git-plist-filter"

    local TMPFILE=$(mktemp "$TMPDIR/$function_name.XXXXXX")

    # Drop stdin to temp file
    cat > "$TMPFILE"
    plutil -convert xml1 "$TMPFILE"
    cat "$TMPFILE"
    rm "$TMPFILE"
}

# headshort - Prints a 7-character abbreviated sha1 hash of the current HEAD commit
function headshort() {
    git rev-parse --short HEAD
}

# log10 - Alias for git log
function log10() {
    git log -10 --pretty=fuller "$@"
}
# Additional converted Fish functions (Batch 10)

# dvl - List docker volumes
function dvl() {
    docker volume ls "$@"
}

# qllist - List QuickLook plugins
function qllist() {
    qlmanage -m plugins "$@"
}

# bd - Forcefully delete a branch from git
function bd() {
    git branch -D "$@"
}

# pbjup - Upgrade personal jenkins formula and restart service
function pbjup() {
    brew update
    brew upgrade pbjenkins
    echo "♻️ 👷🏻‍♂️ Restarting jenkins using admin privileges"
    sudo launchctl kickstart -kp system/pbjenkins
}

# ruby_upgrade - Upgrades ruby across major versions
function ruby_upgrade() {
    brew update
    brew info ruby
    brew unlink ruby
    brew cleanup ruby
    brew install ruby
    brew link --overwrite ruby

    rm -rf /usr/local/lib/ruby/gems/2.4.0/gems
    rm -rf /usr/local/lib/ruby/gems/2.4.0/extensions

    local tmpfile=$(mktemp /tmp/ruby_upgrade.XXXXXX)
    gem --version >/dev/null 2>"$tmpfile"

    echo "Looping over gem errors"
    while read -r line; do
        local pristine_cmd=$(echo "$line" | sed 's/.*Try: //')
        if [[ -n "$pristine_cmd" ]]; then
            eval "$pristine_cmd"
        fi
    done < "$tmpfile"
    rm "$tmpfile"

    gem update --system
    gem install bundler
}

# format-patch - Git format-patch wrapper
function format-patch() {
    git format-patch "$@"
}

# rl - Quick dir navigation to reflog
function rl() {
    pushd ~/dev/www/reflog/www
}

# pu - Update Pods without updating repos
function pu() {
    pod update --no-repo-update "$@"
}

# clone_or_pull - Clones a fresh copy or pulls an existing git repo
function clone_or_pull() {
    local folder_name="$1"
    local git_url="$2"
    local branch="$3"

    if [[ -z "$folder_name" || -z "$git_url" ]]; then
        echo "Usage: clone_or_pull folder url [branch]"
        return 1
    fi

    if [[ ! -d "$folder_name" ]]; then
        git clone "$git_url" "$folder_name"

        # Checkout branch
        if [[ -n "$branch" ]]; then
            pushd "$folder_name"
            git checkout "$branch"
            popd
        fi
    else
        pushd "$folder_name"
        if [[ -n "$branch" && "$branch" != "$(git rev-parse --abbrev-ref HEAD)" ]]; then
            echo "WARNING: $folder_name currently has the $(git rev-parse --abbrev-ref HEAD) branch checked out (!=$branch)"
        fi
        git pull
        popd
    fi
}

# editorconfig - Generates an editorconfig
function editorconfig() {
    local file_path="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.editorconfig"

    if [[ -f "$file_path" ]]; then
        echo "EditorConfig file already exists at: $file_path"
        return 1
    fi

    cat > "$file_path" <<'EOF'
# http://editorconfig.org
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{dart,yaml,yml}]
indent_size = 2

# Use 2 spaces for Ruby files
[{Podfile,Rakefile,*.{rb,podspec}}]
indent_size = 2
indent_style = space
max_line_length = 80

# Use tabs for property lists
[*.plist]
indent_style = tab

# JSON files contain newlines inconsistently
[*.json]
insert_final_newline = ignore

# Makefiles always use tabs for indentation
[Makefile]
indent_style = tab

# Trailing spaces have meaning in Markdown
[*.md]
trim_trailing_whitespace = false
EOF
}

# xcode - Installs and updates Xcode (converted from 🔨_xcode)
function xcode() {
    echo "🔨 Xcode"
    echo

    if [[ -z "$XCODE_INSTALL_USER" && -n "$(git config user.email)" ]]; then
        export XCODE_INSTALL_USER="$(git config user.email)"
    fi

    # Currently selected version
    xcode-select --print-path

    # Update the list of available versions to install
    xcversion update

    # Install the CLI tools, if necessary
    if [[ ! -e "/Library/Developer/CommandLineTools/usr/lib/libxcrun.dylib" ]]; then
        xcversion install-cli-tools
    fi

    echo "Available:"
    xcversion list
    local installed=$(xcversion list)
    local newest_version=$(echo "$installed" | tail -n 1)
    if [[ ! "$newest_version" == *"(installed)"* ]]; then
        local options=(--no-show-release-notes)

        # Don't activate beta versions automatically
        if [[ "$newest_version" == *"beta"* ]]; then
            options+=("--no-switch")
        fi

        xcversion install "$newest_version" "${options[@]}"

        # Clean out old simulators
        xcrun simctl delete unavailable
    fi

    echo
    echo "Installed:"
    xclist

    echo
    echo "Themes"
    local xcode_themes_dir=~/Library/Developer/Xcode/UserData/FontAndColorThemes
    local xcode_dev_dir=~/dev/xcode
    local repo_dir="$xcode_dev_dir/xcode-themes"
    mkdir -p "$xcode_themes_dir" "$xcode_dev_dir"
    clone_or_pull "$repo_dir" "git@github.com:hdoria/xcode-themes.git"
    pushd "$repo_dir"
    for theme in *.dvtcolortheme; do
        if [[ ! -e "$xcode_themes_dir/$theme" ]]; then
            # Only copy new themes
            cp -v "$theme" "$xcode_themes_dir"
        fi
    done
    popd
}

# xlog - Quick nav to nginx log dir
function xlog() {
    local subdir="$1"
    pushd "$(brew --prefix)/var/log/nginx/$subdir"
}

# g - Gradle alias
function g() {
    gradle "$@"
}

# fe - Edit a function
function fe() {
    local function_name="$1"
    local file="~/.config/fish/functions/${function_name}.fish"

    if [[ ! -e "$file" && ! $(functions "$function_name") ]]; then
        if yn "Function "$function_name" does not exist. Create?"; then
            touch "$file"
        fi
        return
    fi

    if [[ -e "$file" ]]; then
        # Edit an autoloaded function
        $EDITOR "$file"
        source "$file"
    else
        # Edit a builtin function, save to autoload
        funced "$function_name"
        funcsave "$function_name"
    fi

    if [[ $? -eq 0 ]]; then
        echo "$function_name function reloaded."
    else
        echo "Error reloading $function_name. Please check your syntax in $file"
    fi
}

# ldot - List hidden files
function ldot() {
    ls -ld .* "$@"
}

# checkout - Perform a git checkout
function checkout() {
    git checkout "$@"
}

# arp-fix - Disables unicast ARP cache validation
function arp-fix() {
    if ! user_is_admin; then
        echo "You must be an admin to run this command."
        return 1
    fi

    sw_vers -productVersion

    local arp_status=$(sysctl net.link.ether.inet.arp_unicast_lim | awk '{print $2}')
    echo "net.link.ether.inet.arp_unicast_lim: $arp_status"

    local arp_fixed="net.link.ether.inet.arp_unicast_lim=0"

    if [[ $arp_status -ne 0 ]]; then
        sudo sysctl -w $arp_fixed
        arp_status=$(sysctl net.link.ether.inet.arp_unicast_lim | awk '{print $2}')

        # After installation, run the command if it now exists
        if [[ $arp_status -eq 0 ]]; then
            echo "Fixed ARP issue"
        else
            echo "Something went wrong"
            echo "net.link.ether.inet.arp_unicast_lim: $arp_status"
            return 1
        fi
    else
        echo "Runtime ARP status is correct"
    fi

    local sysctl_file="/etc/sysctl.conf"
    if [[ ! -e "$sysctl_file" ]]; then
        echo "$arp_fixed" | sudo tee "$sysctl_file"
        echo "ARP fix added to $sysctl_file"
    elif ! grep -q "$arp_fixed" "$sysctl_file"; then
        echo "$arp_fixed" | sudo tee -a "$sysctl_file"
        echo "ARP fix added to $sysctl_file"
    else
        echo "$sysctl_file already contains the ARP fix."
    fi
}

# powerlinetest - Print special Powerline characters to test current font's support
function powerlinetest() {
    echo "⮀ ± ⭠ ➦ ✔ ✘ ⚡"
}

# theirs - Checkout theirs for unmerged paths
function theirs() {
    git checkout --theirs "$@" && git add "$@"
}

# pl_edit - Edit Powerline config files
function pl_edit() {
    echo "Kill the powerline-daemon (-k) to see changes."
    psgrep powerline-daemon
    $EDITOR ~/.config/powerline
}

# Additional converted Fish functions (Batch 12)

# l - List files showing size, show type, human readable
function l() {
    ls -lFh "$@"
}

# la - Long list, show almost all, show type, human readable
function la() {
    ls -laFh "$@"
}

# ll - Long list
function ll() {
    ls -l "$@"
}

# lt - Long list, sorted by date, show type, human readable
function lt() {
    ls -otFh "$@"
}

# g - Gradle alias
function g() {
    gradle "$@"
}

# s - Display abbreviated git status
function s() {
    git status -sb "$@"
}

# d - Git diff with custom formatting
function d() {
    # --unified: Context lines
    # --no-prefix: Do not show any source or destination prefix. (e.g. "a/" "b/")
    # --no-indent-heuristic: Disable the default heuristic that shifts diff hunk boundaries to make patches easier to read.
    git diff \
        --unified=1 \
        --no-prefix \
        "$@"

        # word diff conflicts with diff-so-fancy
        # --word-diff=color \
        # --word-diff-regex='[^[:space:]]' \
        # --diff-algorithm=default \
        # --no-indent-heuristic \
        # --ignore-cr-at-eol \
}

# a - Add files to git staging area
function a() {
    git add "$@"
}

# c - Performs a git checkout
function c() {
    git checkout "$@"
}

# o - Short alias for open
function o() {
    if [[ -z "$1" ]]; then
        open .
    else
        # -t  Causes the given path to be opened with the default app, as determined via LaunchServices
        open -t "$@"
    fi
}

# Added by Windsurf
export PATH="/Users/phatblat/.codeium/windsurf/bin:$PATH"

# System kernel detection
export KERNEL=$(uname)

# System detection functions
function is_mac() {
    [[ "$KERNEL" == "Darwin" ]]
}

function is_linux() {
    [[ "$KERNEL" == "Linux" ]]
}

function is_arm() {
    [[ "$(uname -m)" == "arm64" ]]
}

# Android SDK configuration
if is_mac; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
elif is_linux; then
    export ANDROID_HOME="$HOME/Android/Sdk"
fi

if [[ -d "$ANDROID_HOME" ]]; then
    local BUILD_TOOLS_VERSION=$(ls -1r "$ANDROID_HOME/build-tools/" 2>/dev/null | head -1)
    export NDK_VERSION=$(ls -1r "$ANDROID_HOME/ndk/" 2>/dev/null | head -1)
    export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$NDK_VERSION"

    if [[ -n "$BUILD_TOOLS_VERSION" ]]; then
        export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION:$ANDROID_HOME/platform-tools:$ANDROID_NDK_HOME:$PATH"
    fi
fi

# Git and file utilities
function root() {
    git rev-parse --show-toplevel "$@"
}

function filesize() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "Usage: filesize filename" >&2
        return 1
    fi

    if is_mac; then
        stat -f '%z' "$file"
    elif is_linux; then
        stat --format=%s "$file"
    fi
}

function list() {
    if [[ -z "$@" ]]; then
        echo "Usage: list [-s] 1 2 3 4 ..." >&2
        return 1
    fi

    local items=("$@")
    if [[ "$1" == "-s" ]]; then
        if [[ ${#@} -lt 2 ]]; then
            echo "Usage: list -s 1 2 3 4 ..." >&2
            return 2
        fi
        shift
        items=($@)
    fi

    printf '%s\n' "${items[@]}"
}

function ignores() {
    list -s \
        ".DS_Store" \
        "*.xccheckout" \
        "*.xcscmblueprint" \
        "xcuserdata" \
        "Carthage/" \
        "Pods/" \
        ".build/" \
        ".swiftpm/" \
        ".rubygems/" \
        "bin/" \
        "build/" \
        ".gradle/" \
        "gradlew.bat" \
        ".idea/" \
        "*.iml" \
        "*.hprof" \
        ".classpath" \
        ".project" \
        ".settings" \
        ".vscode/" \
        "target/" \
        ".cxx/" \
        "cmake-build-debug/" \
        ".externalNativeBuild/" \
        "heapdump.*.phd" \
        "javacore.*.txt" \
        "*.dll" \
        ".vs/" \
        "obj/" \
        "packages/" \
        "bazel-*" \
        "buck-out/" \
        "__pycache__/" \
        "node_modules/" \
        ".npm/"
}

function ignore() {
    local gitignore="$(root)/.gitignore"
    local ignore_list
    local commit_message

    touch "$gitignore"

    if [[ -s "$gitignore" ]]; then
        ignore_list=$(cat "$gitignore")
    else
        ignore_list=$(ignores)
        commit_message="chore: add standard ignores"
        echo "Creating .gitignore"
    fi

    if [[ -n "$@" ]]; then
        ignore_list="$@ $ignore_list"
        commit_message="chore: ignore $@"
    fi

    {
        while IFS= read -r pattern; do
            echo "$pattern"
        done <<< "$ignore_list"
    } | sort -u > "$gitignore"

    if [[ -z "$commit_message" ]]; then
        echo "Nothing new added to ignores, just sorted and removed duplicates."
        return
    fi

    git add "$gitignore"
    git commit -m "$commit_message"
}

function ignored() {
    git status --ignored --porcelain 2>/dev/null
}

# JDK management functions
function path_add() {
    local directory="$1"
    if [[ -z "$directory" ]]; then
        echo "Usage: path_add <directory>" >&2
        return 1
    elif [[ -d "$directory" ]]; then
        export PATH="$directory:$PATH"
    else
        echo "Directory not found: $directory" >&2
        return 2
    fi
}

function has_space() {
    local string="$1"
    [[ "$string" =~ " " ]]
}

function jdk() {
    local command="$1"
    local jdk_path="$2"
    local quiet="$3"

    if is_linux; then
        which java
        java -version
        return
    fi

    local ANDROID_STUDIO_PRERELEASE=""
    local ANDROID_STUDIO="$HOME/Applications/Android Studio${ANDROID_STUDIO_PRERELEASE}.app"

    case "$command" in
        list)
            echo "🖥 /usr/libexec/java_home"
            /usr/libexec/java_home --verbose "$@"

            echo
            echo "🖥 /Library/Java/JavaVirtualMachines"
            ls -1 /Library/Java/JavaVirtualMachines

            if [[ -d "$ANDROID_STUDIO" ]]; then
                echo
                echo "🤖 Android Studio"
                echo "$ANDROID_STUDIO/Contents/jbr/Contents/Home"
            fi

            local jabba_path="$HOME/.jabba/jdk"
            if [[ -d "$jabba_path" ]]; then
                echo
                echo "🐸 Jabba Java candidates in $jabba_path"
                ls -1 "$jabba_path"
            fi
            ;;
        set)
            jdk_set "$jdk_path" "$quiet"
            ;;
        studio)
            jdk_set "$ANDROID_STUDIO/Contents/jbr/Contents/Home" "$quiet"
            ;;
        *)
            jdk_current
            ;;
    esac
}

function jdk_set() {
    local jdk_path="$1"
    local quiet="$2"

    if [[ "$jdk_path" == "-" ]]; then
        echo "Skipping jdk_path check"
    elif [[ ! -d "$jdk_path" ]]; then
        echo "Path not found: $jdk_path" >&2
        return 2
    elif [[ ! -f "$jdk_path/bin/java" ]]; then
        echo "No java binary found at path: $jdk_path/bin/java" >&2
        return 3
    fi

    export JAVA_HOME="$jdk_path"
    path_add "$JAVA_HOME/bin"

    if ! has_space "$jdk_path"; then
        export CPPFLAGS="$CPPFLAGS -I$jdk_path/include"
    fi
}

function jdk_current() {
    local java_cmd
    java_cmd=$(which java)
    echo "JAVA_HOME: $JAVA_HOME"
    echo "which java: $java_cmd"
    lipo -info "$java_cmd"
    java -version
    echo "CPPFLAGS: $CPPFLAGS"
}

# Git log functions - pretty history graph

# lg - Alias for lg10
function lg() {
    lg10 "$@"
}

# lg1 - Pretty history graph with one commit
function lg1() {
    local commit_count=1
    local format='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'

    git log \
        -$commit_count \
        --graph \
        --abbrev-commit \
        --date=relative \
        --pretty=format:"$format" \
        "$@"
}

# lg10 - Pretty history graph with ten commits
function lg10() {
    local commit_count=10

    git log \
        -$commit_count \
        --graph \
        --abbrev-commit \
        --date=relative \
        --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' \
        "$@"
}

# lga - Pretty history graph showing all
function lga() {
    git log \
        --all \
        --graph \
        --abbrev-commit \
        --date=relative \
        --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' \
        "$@"
}

# lgg - Pretty history graph
function lgg() {
    git log \
        --graph \
        --abbrev-commit \
        --date=relative \
        --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' \
        "$@"
}

# review - Review a given commit with detailed information and diff
function review() {
    local commit="$1"
    local format='commit:    %Cgreen%H%Creset
date:      %Cgreen%ai%Creset
author:    %Cgreen%an%Creset <%Cgreen%ae%Creset>
committer: %Cgreen%cn%Creset <%Cgreen%ce%Creset>

    %s
'

    # --unified: Context lines
    # --no-prefix: Do not show any source or destination prefix. (e.g. "a/" "b/")
    # -m: For merge commits, show full diff
    git log \
        --max-count=1 \
        --pretty=format:"$format" \
        --stat \
        --patch \
        -m \
        --unified=1 \
        --no-prefix \
        $commit
}

# Initialize zoxide - a smarter cd command
eval "$(zoxide init zsh)"

# Initialize mise - version manager for tools
eval "$(mise activate zsh)"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/phatblat/.cache/lm-studio/bin"
# End of LM Studio CLI section
