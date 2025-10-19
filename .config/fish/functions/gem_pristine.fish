#!/usr/bin/env fish
function gem_pristine \
    --description='Runs the pristine command for all gems'

    # Fix gem write permissions
    # ERROR:  While executing gem ... (Errno::EACCES)
    #     Permission denied @ rb_sysopen - /opt/homebrew/Cellar/ruby/3.2.2_1/lib/ruby/gems/3.2.0/specifications/matrix-0.4.2.gemspec
    chmod u+w /opt/homebrew/Cellar/ruby/3.2.2_1/lib/ruby/gems/3.2.0/specifications/*

    gem pristine --all
end
