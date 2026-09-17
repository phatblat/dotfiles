mod actions;
mod overlay;
mod repo;

use std::path::PathBuf;
use std::process::ExitCode;

const USAGE: &str = "\
usage: wt [<branch>] | wt <action> [<branch>] [flags]

actions:
  path <branch>       print the path that would be used; mutates nothing
  resolve <branch>    print the registered worktree path, or exit 3
  switch <branch>     resolve, else create; print the path
  create <branch>     create only; exit 4 if already registered
  remove <branch>     git worktree remove + prune; never touches the branch
  list                one <path>\\t<branch> line per worktree
  verify <branch>     HOME-remapped `just check` (implies --allow-home)
  shell <branch>      HOME-remapped interactive zsh (implies --allow-home)
  overlay [<branch>]  apply this repo's link manifest to the worktree

flags, accepted in any position:
  --allow-home        opt in to worktrees for the repo at $HOME
  --repo <dir>        derive the repo from <dir> instead of the cwd
  --force             remove: pass --force to `git worktree remove`
  --cd-file <path>    switch: also write the resolved directory to <path>
  -h, --help          print this text

With no action and no branch, wt runs an fzf picker over the repo's worktrees.
The first positional is an action only when it is exactly one of the nine verbs
above; anything else is a branch and the action is `switch`. A branch named
`list` must be written `wt switch list`.
";

const ACTIONS: &[&str] = &[
    "path", "resolve", "switch", "create", "remove", "list", "verify", "shell", "overlay",
];

pub struct Args {
    pub action: String,
    pub branch: Option<String>,
    pub allow_home: bool,
    pub force: bool,
    pub repo: Option<PathBuf>,
    pub cd_file: Option<PathBuf>,
}

fn usage_error(msg: Option<&str>) -> ExitCode {
    if let Some(msg) = msg {
        eprintln!("{msg}");
    } else {
        eprint!("{USAGE}");
    }
    ExitCode::from(2)
}

fn parse_args(raw: &[String]) -> Result<Args, ExitCode> {
    let mut positionals: Vec<String> = Vec::new();
    let mut allow_home = false;
    let mut force = false;
    let mut repo: Option<PathBuf> = None;
    let mut cd_file: Option<PathBuf> = None;

    let mut i = 0;
    while i < raw.len() {
        let arg = &raw[i];
        match arg.as_str() {
            "-h" | "--help" => {
                print!("{USAGE}");
                return Err(ExitCode::SUCCESS);
            }
            "--allow-home" => allow_home = true,
            "--force" => force = true,
            "--repo" => {
                let Some(v) = raw.get(i + 1) else {
                    return Err(usage_error(None));
                };
                repo = Some(PathBuf::from(v));
                i += 1;
            }
            "--cd-file" => {
                let Some(v) = raw.get(i + 1) else {
                    return Err(usage_error(None));
                };
                cd_file = Some(PathBuf::from(v));
                i += 1;
            }
            _ if arg.starts_with("--") => {
                return Err(usage_error(Some(&format!("wt: unknown flag: {arg}"))));
            }
            _ => positionals.push(arg.clone()),
        }
        i += 1;
    }

    if positionals.len() > 2 {
        return Err(usage_error(None));
    }

    let (action, branch): (String, Option<String>) = match positionals.as_slice() {
        [] => ("picker".to_string(), None),
        [first] if ACTIONS.contains(&first.as_str()) => (first.clone(), None),
        [first] => ("switch".to_string(), Some(first.clone())),
        [first, second] if ACTIONS.contains(&first.as_str()) => {
            (first.clone(), Some(second.clone()))
        }
        _ => return Err(usage_error(None)),
    };

    let allow_home = allow_home || action == "verify" || action == "shell";

    if action == "verify" && repo.is_some() {
        return Err(usage_error(Some(
            "wt: verify is dotfiles-only; omit --repo and run your own test command (e.g. just check) for other repos",
        )));
    }

    Ok(Args {
        action,
        branch,
        allow_home,
        force,
        repo,
        cd_file,
    })
}

fn main() -> ExitCode {
    let raw: Vec<String> = std::env::args().skip(1).collect();
    let args = match parse_args(&raw) {
        Ok(args) => args,
        Err(code) => return code,
    };

    let requires_branch = matches!(
        args.action.as_str(),
        "path" | "resolve" | "switch" | "create" | "remove" | "verify" | "shell"
    );
    if requires_branch && args.branch.is_none() {
        eprintln!("wt: {} requires a branch argument", args.action);
        return ExitCode::from(2);
    }

    match actions::dispatch(&args) {
        Ok(()) => ExitCode::SUCCESS,
        Err(code) => ExitCode::from(code as u8),
    }
}
