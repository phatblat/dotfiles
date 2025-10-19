#!/usr/bin/env fish
function gi --description='Creates a .gitignore file using gitignore.io.'
    curl -L -s https://www.gitignore.io/api/$argv
end
