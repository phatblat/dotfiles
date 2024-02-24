
# https://blog.macsales.com/46348-how-to-create-and-use-a-ram-disk-with-your-mac-warnings-included/
function ramdisk \
    --description ramdisk \
    --argument-names disk_size drive_name

    # disk_size is integer gigabytes
    if test -z $disk_size
        echo 'Usage: ramdisk [size] [drive_name]'
        return 1
    end

    if test -z $drive_name
        set drive_name "RAMDisk_$disk_size"GB
    end

    # 1 block = 1 MB
    set -l block_size 2048
    set -l mb_in_gb 1024
    set -l memory_blocks (math $disk_size x $mb_in_gb x $block_size)

    # Captures the device path such as '/dev/disk12'
    # Must trim trailing spaces from output!
    set -l hdiutil_output (string trim (hdiutil attach -nomount ram://$memory_blocks))
    and diskutil erasevolume HFS+ "$drive_name" $hdiutil_output

    if test $status != 0
        return $status
    end

    echo RAM disk created with $disk_size GB
end
