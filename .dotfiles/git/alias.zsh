#-------------------------------------------------------------------------------
#
# git/alias.zsh
# Command-line aliases for git
#
#-------------------------------------------------------------------------------

# Hub - use hub as entry point for git command
# alias git='hub'

# Init
alias init='git init'

# Informational
alias gitalias='alias | grep git | less'
alias help='git help'

### Work Area
alias s='git status -sb'
alias sa='git status'
alias status='git status'
alias diff='git diff'
# d - conflicts with omz alias (redefined in shell/antigen.zsh)
alias d='git diff'
alias dw='git diff --word-diff'
alias dc='git diff --cached'
alias dcw='git diff --cached --word-diff'
alias sortdiff='git diff "$@" | grep "^[+-]" | sort --key=1.2 | uniq -u -s1'
alias difftool='git difftool'
alias dt='git difftool'
alias dtc='git difftool --cached'
alias mergetool='git mergetool'
alias mt='git mergetool'
alias tracked='git ls-tree -r --name-only HEAD'
alias ls-tree='git ls-tree'
alias untracked='git ls-files --others --exclude-standard'
alias ls-files='git ls-files'

## Log
alias show="git show"
alias review='git log -p --max-count=1'
alias new='git log $1@{1}..$1@{0} "$@"'
alias rev-list='git rev-list'
alias rev-parse='git rev-parse'
alias sha='git rev-parse HEAD'
alias shortsha='git rev-parse --short HEAD'
alias ldg='git log -g'
alias reflog='git reflog'

# Config
alias config='git config'
alias user.name='git config user.name'
alias user.email='git config user.email'
alias user.signingkey='git config user.signingkey'
alias user='printf "%s: %s <%s> [signingKey: %s]\n" $USER "$(user.name)" "$(user.email)" "$(user.signingkey)"'

# Add
alias a='git add'
alias add='git add'
alias ai='git add --interactive'
alias aa='git add --update'
alias ap='git add --patch'
alias af='git add --force'

# Commit
alias cmt='git commit -m'
alias commit='git commit --verbose'
alias amend='git commit --verbose --amend'
alias tag='git tag'

# Remotes
alias ls-remote='git ls-remote'
alias remote='git remote'
alias rv='git remote -v'
alias prun='git remote prune --dry-run'
alias prune='git remote prune'
alias clone='git clone'
alias fetch='git fetch'
alias pull='git pull'
alias push='git push'
alias pushtags='git push --tags'

# Submodules
alias submodule='git submodule'
alias subs='git ls-files --stage | grep 160000' # shows special submodule entries in index
alias sur='git submodule update --recursive'
alias suri='git submodule update --recursive --init'

# Checkout
alias c='git checkout'
alias checkout='git checkout'
alias reset='git reset'
alias rp='git reset --patch'
alias bisect='git bisect'

# Branch
alias branch='git branch'
alias b='git branch'
alias bvv='git branch -vv'
alias bra='git branch -av'
alias bd='git branch -d'
alias bD='git branch -D'
alias current-branch='git rev-parse --abbrev-ref HEAD'
alias tracking='git rev-parse --abbrev-ref --symbolic-full-name @{u}'
alias remote-for-current-branch='current_branch=$(git rev-parse --abbrev-ref HEAD) && config branch.${current_branch}.remote'

## Delete local branches merged into master
# http://stackoverflow.com/questions/6127328/how-can-i-delete-all-git-branches-which-have-been-merged#answer-6127884
alias bdm='git branch -d $(git branch --merged | grep -v "^*" | grep -v "master" | tr -d "\n")'

# Merge
alias m='git merge'
alias merge='git merge'
alias r='git rebase --interactive HEAD~10'
alias rebase='git rebase'
alias continue='if [[ -f .git/MERGE_HEAD ]]; then git commit; fi 2> /dev/null || git rebase --continue 2> /dev/null || git cherry-pick --continue'
alias skip='git rebase --skip'
alias abort='git merge --abort 2> /dev/null || git rebase --abort 2> /dev/null || git cherry-pick --abort 2> /dev/null || git am --abort'
alias ours='git checkout --ours $@ && git add $@'
alias theirs='git checkout --theirs $@ && git add $@'

# Cherry-pick
alias pick='git cherry-pick'
alias cherry-pick='git cherry-pick'

# Reset
alias reset='git reset'
alias pop='git reset --soft HEAD^'
alias mirror='git reset --hard'

# Revert
alias revert='git revert'

# Assumed files
alias assumed='git ls-files -v | grep ^h | cut -c 3-'
alias assume='git update-index --assume-unchanged'
alias unassume='git update-index --no-assume-unchanged'

# Stash
alias stash='git stash'
alias st='git stash'
alias stsave='git stash save'
alias stlist='git stash list'
alias stshow='git stash show -p'
alias stsnapshot='git stash save "snapshot: $(date)" && git stash apply "stash@{0}"'
alias stapply='git stash apply'
alias stpop='git stash pop'
alias stdrop='git stash drop'

# Patch
alias format-patch='git format-patch'

# LFS
alias lfs='git lfs'

# Experimental

alias ref='git symbolic-ref'
alias root='git rev-parse --show-toplevel'

alias bundle-pull="bundle exec ${HOME}/.dotfiles/git/bundle-pull.rb"
