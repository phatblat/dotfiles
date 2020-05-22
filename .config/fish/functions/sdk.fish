# Copied from omf. Using from there gets sourced before config/variables, yielding error:
# > bash: /bin/sdkman-init.sh: No such file or directory
# Defined in /Users/phatblat/.local/share/omf/pkg/sdk/functions/sdk.fish @ line 1
function sdk \
        --wraps=sdk \
        --description 'Software Development Kit Manager'
    bash -c "source $sdkman_prefix/bin/sdkman-init.sh && sdk $argv"
end
