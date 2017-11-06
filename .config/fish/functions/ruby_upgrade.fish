function ruby_upgrade --description='Upgrades ruby across major versions' 
    brew update
    brew info ruby
    brew unlink ruby
    brew cleanup ruby
    brew install ruby
    brew link --overwrite ruby

    rm -rf /usr/local/lib/ruby/gems/2.4.0/gems
    rm -rf /usr/local/lib/ruby/gems/2.4.0/extensions

    set -l tmpfile (mktemp /tmp/ruby_upgrade.XXXXXX)
    gem --version >/dev/null 2> $tmpfile

# Ignoring bigdecimal-1.3.2 because its extensions are not built. Try: gem pristine bigdecimal --version 1.3.2
# Ignoring executable-hooks-1.3.2 because its extensions are not built. Try: gem pristine executable-hooks --version 1.3.2
# Ignoring json-2.1.0 because its extensions are not built. Try: gem pristine json --version 2.1.0
# Ignoring openssl-2.0.6 because its extensions are not built. Try: gem pristine openssl --version 2.0.6
# Ignoring openssl-2.0.4 because its extensions are not built. Try: gem pristine openssl --version 2.0.4
# Ignoring psych-2.2.4 because its extensions are not built. Try: gem pristine psych --version 2.2.4
# Ignoring unf_ext-0.0.7.4 because its extensions are not built. Try: gem pristine unf_ext --version 0.0.7.4

    echo "Looping over gem errors"
    while read line
        set -l pristine_cmd (string split "Try: " $line)[2]
        eval $pristine_cmd
    end < $tmpfile
    rm $tmpfile

    gem update --system
    binstall
end
