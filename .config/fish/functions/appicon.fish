function appicon \
    --description='Resizes AppIcon' \
    --argument-names file

    if test -z "$file"
        echo "Please provide a file name to resize"
        return 1
    else if not test -e $file
        echo "$file does not exist"
        return 2
    end

    set -l all_sizes 20 29 40 58 60 80 76 87 120 152 167 180 1024

    for size in $all_sizes
        set -l new_file AppIcon-$size.png
        convert $file -resize $size"x"$size $new_file
        echo $new_file (identify -format "%wx%h" $new_file)
    end
end
