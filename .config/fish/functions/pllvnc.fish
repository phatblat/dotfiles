function pllvnc \
    --description 'Lint a pod in the current directory with verbose output,
    leaving the resulting Xcode project intact if there is an error.'

    pod lib lint --verbose --no-clean $argv
end
