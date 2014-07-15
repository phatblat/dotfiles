#-------------------------------------------------------------------------------
#
# alias-git.zsh
# Command-line aliases for git
#
#-------------------------------------------------------------------------------

# Init
alias init='git init'

# Informational
alias s='git status -sb'
alias sa='git status'
alias status='git status'
alias sha='git rev-parse HEAD'
alias d='git diff'
alias diff='git diff'
alias dc='git diff --cached'
alias difftool='git difftool'
alias dt='git difftool'
alias dtc='git difftool --cached'
alias mergetool='git mergetool'
alias mt='git mergetool'
alias log='git log'
alias l='git log --pretty=oneline --abbrev-commit --max-count=15'
alias lg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias lga="git log --all --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias review='git log -p --max-count=1'
alias tracked='git ls-tree -r --name-only HEAD'
alias untracked='git ls-files --others'

# Config
alias config='git config'
alias user.email='git config user.email'

# Add
alias a='git add'
alias add='git add'
alias aa='git add --update'
alias ap='git add --patch'
alias af='git add --force'

# Commit
alias commit='git commit --verbose'
alias amend='git commit --verbose --amend'
alias n='git commit --verbose --amend'
alias tag='git tag'

# Remotes
alias rv='git remote -v'
alias prun='git remote prune --dry-run'
alias prune='git remote prune'
alias cl='git clone'
alias clone='git clone'
alias f='git fetch'
alias fetch='git fetch'
alias pl='git pull'
alias pull='git pull'
alias p='git push'
alias push='git push'
alias pt='git push --tags'
alias pushtags='git push --tags'

# Submodules
alias submodule='git submodule'

# Checkout
alias c='git checkout'
alias checkout='git checkout'
alias reset='git reset'

# Branch
alias branch='git branch'
alias b='git branch'
alias bra='git branch -av'
alias bd='git branch -d'
alias bD='git branch -D'

# Merge
alias m='git merge'
alias merge='git merge'
alias r='git rebase --interactive HEAD~10'
alias rebase='git rebase'
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
alias stash='git stash'
alias snapshot='!git stash save "snapshot: $(date)" && git stash apply "stash@{0}"'

# Experimental
alias rewriteauthor="git filter-branch --env-filter 'if [ $GIT_AUTHOR_EMAIL = ben.d.chatelain@kp.org ]; then GIT_AUTHOR_EMAIL=benchatelain@gmail.com; fi; export GIT_AUTHOR_EMAIL'"
