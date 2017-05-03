#-------------------------------------------------------------------------------
#
# Objective-C Source Code Formatting
# xcode/uncrustify.zsh
#
#-------------------------------------------------------------------------------

lj info 'xcode/uncrustify.zsh'

function uc {
  find . -type f \( -name "*.h" -or -name "*.m" \) -exec \
  uncrustify -lOC -c ~/.uncrustify/uncrustify_obj_c.cfg --no-backup {} \;
}
