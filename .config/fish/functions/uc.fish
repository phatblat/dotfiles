# 
function uc
      find . -type f \( -name "*.h" -or -name "*.m" \) -exec \
  uncrustify -lOC -c ~/.uncrustify/uncrustify_obj_c.cfg --no-backup {} \; $argv
end
