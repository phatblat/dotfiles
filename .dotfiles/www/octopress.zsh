#-------------------------------------------------------------------------------
#
# www/octopress.zsh
# Octopress command-line aliases
#
#-------------------------------------------------------------------------------

lj info 'www/octopress.zsh'

# octopress 3 commands:
# init <PATH>         # Adds Octopress scaffolding to your site
# new <PATH>          # Like `jekyll new` + `octopress init`
# new post <TITLE>    # Add a new post to your site
# new page <PATH>     # Add a new page to your site
# new draft <TITLE>   # Add a new draft post to your site
# publish <POST>      # Publish a draft from _drafts to _posts
# unpublish <POST>    # Search for a post and convert it into a draft
# isolate [POST]      # Stash all posts but the one you're working on for a faster build
# integrate           # Restores all posts, doing the opposite of the isolate command
# deploy              # deploy your site via S3, Rsync, or to GitHub pages.

# Jekyll
alias serve='env $(cat .env | xargs) bundle exec jekyll serve'
alias servedraft='serve --draft'
alias served='serve --detach'
alias servedraftd='servedraft --detach'
