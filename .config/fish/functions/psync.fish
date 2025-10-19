#!/usr/bin/env fish
# Syncs files between two directories. Without a 3rd argument, only does a dry run.
function psync --argument-names source_dir destination_dir dry_run
    if test -z $source_dir -o -z $destination_dir
        echo "Usage: sync source_dir/ destination_dir/"
        return 1
    end

    if test $dry_run = "go"
        # Output is suppressed when not connected to TTY
        [ -t 0 ]; and echo "rsyncing $source_dir -> $destination_dir"
        mkdir -p $destination_dir
        # Run (-aP)
        rsync --archive --one-file-system --safe-links --partial --delete-after \
             $source_dir $destination_dir
    else
        echo "rsyncing $source_dir -> $destination_dir (dry run)"
        # Test (-anv)
        rsync --archive --one-file-system --safe-links --verbose --dry-run \
            $source_dir $destination_dir
    end
end
