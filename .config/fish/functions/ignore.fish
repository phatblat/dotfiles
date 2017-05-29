# Append standard ignores to .gitignore file.
function ignore
    for pattern in (ignores)
        echo $pattern >> .gitignore
    end

    git add .gitignore
    git commit -m 'Ignore stuff'
end
