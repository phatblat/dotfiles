
# null
function serve
    env $(cat .env | xargs) bundle exec jekyll serve
end
