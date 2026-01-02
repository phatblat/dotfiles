# Nushell Environment Config File
#
# version = "0.106.0"

$env.ENABLE_LSP_TOOL = 1
$env.XDG_CONFIG_HOME = $nu.home-path | path join '.config'
$env.XDG_DATA_DIRS = $env.XDG_CONFIG_HOME
$env.XDG_DATA_HOME = $env.XDG_CONFIG_HOME

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = {|| create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| "〉" }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "〉" }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

# If you want previously entered commands to have a different prompt from the usual one,
# you can uncomment one or more of the following lines.
# This can be useful if you have a 2-line prompt and want to change the prompt indicator for ease of browsing.
# $env.TRANSIENT_PROMPT_COMMAND = {|| "〉 " }
# $env.TRANSIENT_PROMPT_INDICATOR = {|| "〉 " }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| ": " }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| "〉 " }

# Directories to search for scripts when calling source or use
$env.NU_LIB_DIRS = [
    # Add paths to your script directories here
    # ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
]

# Directories to search for plugin binaries when calling register
$env.NU_PLUGIN_DIRS = [
    # Add paths to your plugin directories here
    # ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
    ($nu.current-exe | path dirname)
    ...$NU_PLUGIN_DIRS
]

# Vendor autoload directories
$env.NU_VENDOR_AUTOLOAD_DIRS = [
    ($env.XDG_CONFIG_HOME | path join 'nushell' 'vendor' 'autoload')
]

# Add homebrew to PATH
$env.PATH = ($env.PATH | prepend "/opt/homebrew/bin")

# Editor configuration
$env.EDITOR = "zed"
$env.VISUAL = "zed"

# Starship prompt
if (which starship | is-not-empty) {
    let starship_cache = ($nu.home-path | path join '.cache' 'starship')
    mkdir $starship_cache
    starship init nu | save -f ($starship_cache | path join 'init.nu')
}

def create_left_prompt [] {
    if (which starship | is-not-empty) {
        starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
    } else {
        let dir = match (do --ignore-errors { $env.PWD | path relative-to $nu.home-path }) {
            null => $env.PWD
            '' => '~'
            $relative_pwd => ([~ $relative_pwd] | path join)
        }

        let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
        let separator_color = (if (is-admin) { ansi light_red } else { ansi light_green })
        let path_segment = $"($path_color)($dir)"

        $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
    }
}

def create_right_prompt [] {
    # create a right prompt in magenta with green separators and am/pm underlined
    let time_segment = ([
        (ansi reset)
        (ansi magenta)
        (date now | format date '%x %X') # try to respect user's locale
    ] | str join | str replace --regex --all "([/:])" $"(ansi green)${1}(ansi magenta)" |
        str replace --regex --all "([AP]M)" $"(ansi magenta_underline)${1}")

    let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {([
        (ansi rb)
        ($env.LAST_EXIT_CODE)
    ] | str join)
    } else { "" }

    ([$last_exit_code, (char space), $time_segment] | str join)
}

# Initialize direnv if available
# NOTE: Commented out until direnv adds support for Nushell
# if (which direnv | is-not-empty) {
#     let direnv_cache = ($nu.home-path | path join '.cache' 'direnv')
#     mkdir $direnv_cache
#     direnv hook nu | save -f ($direnv_cache | path join 'init.nu')
# }

# Add common paths
$env.PATH = ($env.PATH | split row (char esep) | prepend [
    ($nu.home-path | path join 'bin')
    ($nu.home-path | path join '.local' 'bin')
    ($nu.home-path | path join '.cargo' 'bin')
] | uniq)
