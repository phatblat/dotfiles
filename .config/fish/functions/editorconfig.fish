function editorconfig \
    --description='Generates an editorconfig.'

    set -l file_path (root)/.editorconfig

    if test -f $file_path
        error "EditorConfig file already exists at: $file_path"
        return 1
    end

    echo "\
# http://editorconfig.org
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{dart,yaml,yml}]
indent_size = 2

# Use 2 spaces for Ruby files
[{Podfile,Rakefile,*.{rb,podspec}}]
indent_size = 2
indent_style = space
max_line_length = 80

# Use tabs for property lists
[*.plist]
indent_style = tab

# JSON files contain newlines inconsistently
[*.json]
insert_final_newline = ignore

# Makefiles always use tabs for indentation
[Makefile]
indent_style = tab

# Trailing spaces have meaning in Markdown
[*.md]
trim_trailing_whitespace = false
" > $file_path

end
