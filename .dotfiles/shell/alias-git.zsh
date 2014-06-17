#-------------------------------------------------------------------------------
#
# alias-git.zsh
# Command-line aliases for git
#
#-------------------------------------------------------------------------------

# Informational
alias s='git status -sb'
alias sa='git status'
alias status='git status'
alias sha='git rev-parse HEAD'
alias d='git diff'
alias diff='git diff'
alias dc='git diff --cached'
alias l='git log --pretty=oneline --abbrev-commit --max-count=15'
alias lg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias lga="git log --all --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias review='git log -p --max-count=1'

# Add
alias a='git add'
alias aa='git add --update'
alias ap='git add --patch'
alias af='git add --force'

# Commit
alias commit='git commit --verbose'
alias amend='git commit --verbose --amend'
alias n='git commit --verbose --amend'

# Remotes
alias rv='git remote -v'
alias prun='git remote prune --dry-run'
alias prune='git remote prune'
alias cl='git clone'
alias f='git fetch'
alias pt='git push --tags'

# Checkout
alias c='git checkout'

# Branch
alias b='git branch -av'
alias bd='git branch -d'
alias bD='git branch -D'

# Merge
alias m='git merge'
alias r='git rebase --interactive HEAD~10'
alias cont='git rebase --continue'
alias abort='git merge --abort 2> /dev/null || git rebase --abort 2> /dev/null || git cherry-pick --abort'
alias ours='!f() { git checkout --ours $@ && git add $@; }; f'
alias theirs='!f() { git checkout --theirs $@ && git add $@; }; f'

# Cherry-pick
alias pick='git cherry-pick'

# Reset
alias pop='git reset --soft HEAD^'
alias mirror='git reset --hard'

# Assumed files
alias assumed='git ls-files -v | grep ^h | cut -c 3-'
alias assume='git update-index --assume-unchanged'
alias unassume='git update-index --no-assume-unchanged'

# Stash
alias snapshot='!git stash save "snapshot: $(date)" && git stash apply "stash@{0}"'