# Runs uncrustify on all Objective-C files under the current dir.
function uc
    find . \
        -type f \
        \( -name "*.h" -or -name "*.m" \) \
        -exec \
        uncrustify \
            -lOC \
            -c ~/.uncrustify/uncrustify_obj_c.cfg \
            --no-backup \
        {} \;
end
