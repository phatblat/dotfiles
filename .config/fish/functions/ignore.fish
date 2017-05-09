# Append standard ignores to .gitignore file.
function ignore
    set -l ignores '.DS_Store' '*.xccheckout' '*.xcscmblueprint' 'xcuserdata' 'Carthage/' 'Pods/' '.rubygems/' 'bin/'
 
    for pattern in $ignores
        echo $pattern >> .gitignore
    end

    git add .gitignore
    git commit -m 'Ignore stuff'
end
