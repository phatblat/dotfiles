# Dependencies:
#   functions: none
#   builtins:  error is-empty
#   externals: rsync mkdir

# Rsync between two directories; pass "go" as third arg to do a real run (default: dry run)
export def psync [source_dir: string, destination_dir: string, dry_run?: string] {
    if ($source_dir | is-empty) or ($destination_dir | is-empty) {
        error make { msg: "Usage: sync source_dir/ destination_dir/" }
    }

    if $dry_run == "go" {
        print ("rsyncing " + $source_dir + " -> " + $destination_dir)
        ^mkdir -p $destination_dir
        ^rsync --archive --one-file-system --safe-links --partial --delete-after $source_dir $destination_dir
    } else {
        print ("rsyncing " + $source_dir + " -> " + $destination_dir + " (dry run)")
        ^rsync --archive --one-file-system --safe-links --verbose --dry-run $source_dir $destination_dir
    }
}
