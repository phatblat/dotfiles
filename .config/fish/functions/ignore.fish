# 
function ignore
      ignores=(
    '.DS_Store'
    '*.xccheckout'
    '*.xcscmblueprint'
    'xcuserdata'
    'Carthage/'
    'Pods/'
    '.rubygems/'
    'bin/'
  )
  for pattern in $ignores; do
    echo "$pattern" >> .gitignore
  done

  git add .gitignore
  git commit -m 'Ignore stuff' $argv
end
