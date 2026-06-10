def "parse vars" [] {
  $in | from csv --noheaders --no-infer | rename 'op' 'name' 'value'
}

def --env "update-env" [] {
  for $var in $in {
    if $var.op == "set" {
      if ($var.name | str upcase) == 'PATH' {
        $env.PATH = ($var.value | split row (char esep))
      } else {
        load-env {($var.name): $var.value}
      }
    } else if $var.op == "hide" and $var.name in $env {
      hide-env $var.name
    }
  }
}
export-env {
  
  'hide,CARGO_HOME,
hide,CLOUDSDK_ROOT_DIR,
hide,DOTNET_MULTILEVEL_LOOKUP,
hide,DOTNET_ROOT,
hide,GOBIN,
hide,GOROOT,
hide,JAVA_HOME,
hide,RUSTUP_HOME,
hide,RUSTUP_TOOLCHAIN,
set,PATH,/Applications/cmux.app/Contents/Resources/bin:/Users/phatblat/.antigravity-ide/antigravity-ide/bin:/Users/phatblat/.git-ai/bin:/Users/phatblat/.codeium/windsurf/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/Users/phatblat/scripts:/Users/phatblat/.local/bin:/usr/local/bin:/opt/homebrew/opt/llvm/bin:/Users/phatblat/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/phatblat/.local/share/mise/shims:/Users/phatblat/.puro/bin:/Users/phatblat/.puro/shared/pub_cache/bin:/Users/phatblat/.puro/envs/default/flutter/bin:/Users/phatblat/Library/Android/sdk/cmdline-tools/latest/bin:/Users/phatblat/Library/Android/sdk/emulator:/Users/phatblat/Library/Android/sdk/tools:/Users/phatblat/Library/Android/sdk/tools/bin:/Users/phatblat/Library/Android/sdk/build-tools/37.0.0:/Users/phatblat/Library/Android/sdk/platform-tools:/Users/phatblat/Library/Android/sdk/ndk/30.0.14904198:/Users/phatblat/.cache/lm-studio/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/clangd-lsp/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/claude-code-setup/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/claude-md-management/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/code-review/f1fe79394b04/bin:/Users/phatblat/.claude/plugins/cache/compound-engineering-plugin/compound-engineering/3.9.3/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/csharp-lsp/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/gopls-lsp/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/hookify/f1fe79394b04/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/jdtls-lsp/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/kotlin-lsp/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/linear-cli/linear-cli/2.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/lua-lsp/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/plugin-dev/f1fe79394b04/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/pyright-lsp/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/rust-analyzer-lsp/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/security-guidance/2.0.3/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/skill-creator/f1fe79394b04/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/swift-lsp/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-plugins-official/typescript-lsp/1.0.0/bin:/Users/phatblat/.claude/plugins/cache/claude-code-warp/warp/2.1.0/bin
hide,MISE_SHELL,
hide,__MISE_DIFF,
hide,__MISE_DIFF,' | parse vars | update-env
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

export def --env --wrapped main [command?: string, --help, ...rest: string] {
  let commands = ["deactivate", "shell", "sh"]

  if ($command == null) {
    ^"/Users/phatblat/.local/bin/mise"
  } else if ($command == "activate") {
    $env.MISE_SHELL = "nu"
  } else if ($command in $commands) {
    ^"/Users/phatblat/.local/bin/mise" $command ...$rest
    | parse vars
    | update-env
  } else {
    ^"/Users/phatblat/.local/bin/mise" $command ...$rest
  }
}

def --env mise_hook [] {
  ^"/Users/phatblat/.local/bin/mise" hook-env -s nu
    | parse vars
    | update-env
}

