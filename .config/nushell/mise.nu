hide,GOBIN,
hide,GOROOT,
set,PATH,/opt/homebrew/bin:/Users/phatblat/.git-ai/bin:/Users/phatblat/.cache/lm-studio/bin:/Applications/Warp.app/Contents/Resources/bin:/Users/phatblat/Library/Android/sdk/cmdline-tools/latest/bin:/Users/phatblat/Library/Android/sdk/emulator:/Users/phatblat/Library/Android/sdk/tools:/Users/phatblat/Library/Android/sdk/tools/bin:/Users/phatblat/Library/Android/sdk/build-tools/36.0.0/:/Users/phatblat/Library/Android/sdk/platform-tools:/Users/phatblat/Library/Android/sdk/ndk/28.2.13676358/:/Users/phatblat/.codeium/windsurf/bin:/Users/phatblat/.local/bin:/usr/local/bin:/opt/homebrew/opt/openjdk@17/bin:/Users/phatblat/fvm/default/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/pmk/env/global/bin:/Library/Apple/usr/bin:/Applications/Little Snitch.app/Contents/Components:/opt/homebrew/opt/openjdk@17/bin:/Users/phatblat/.cargo/bin:/Users/phatblat/.puro/bin:/Users/phatblat/.puro/shared/pub_cache/bin:/Users/phatblat/.puro/envs/default/flutter/bin:/Users/phatblat/Library/Application Support/JetBrains/Toolbox/scripts
hide,MISE_SHELL,
hide,__MISE_DIFF,
hide,__MISE_DIFF,
export-env {
  
  $env.MISE_SHELL = "nu"
  let mise_hook = {
    condition: { "MISE_SHELL" in $env }
    code: { mise_hook }
  }
  add-hook hooks.pre_prompt $mise_hook
  add-hook hooks.env_change.PWD $mise_hook
}

def --env add-hook [field: cell-path new_hook: any] {
  let field = $field | split cell-path | update optional true | into cell-path
  let old_config = $env.config? | default {}
  let old_hooks = $old_config | get $field | default []
  $env.config = ($old_config | upsert $field ($old_hooks ++ [$new_hook]))
}

def "parse vars" [] {
  $in | from csv --noheaders --no-infer | rename 'op' 'name' 'value'
}

export def --env --wrapped main [command?: string, --help, ...rest: string] {
  let commands = ["deactivate", "shell", "sh"]

  if ($command == null) {
    ^"/opt/homebrew/bin/mise"
  } else if ($command == "activate") {
    $env.MISE_SHELL = "nu"
  } else if ($command in $commands) {
    ^"/opt/homebrew/bin/mise" $command ...$rest
    | parse vars
    | update-env
  } else {
    ^"/opt/homebrew/bin/mise" $command ...$rest
  }
}

def --env "update-env" [] {
  for $var in $in {
    if $var.op == "set" {
      if ($var.name | str upcase) == 'PATH' {
        $env.PATH = ($var.value | split row (char esep))
      } else {
        load-env {($var.name): $var.value}
      }
    } else if $var.op == "hide" {
      hide-env $var.name
    }
  }
}

def --env mise_hook [] {
  ^"/opt/homebrew/bin/mise" hook-env -s nu
    | parse vars
    | update-env
}

