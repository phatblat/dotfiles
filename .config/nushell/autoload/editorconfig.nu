# editorconfig - Generates an editorconfig
export def editorconfig [] {
    let repo_root = (try { ^git rev-parse --show-toplevel | str trim } catch { pwd })
    let file_path = $"($repo_root)/.editorconfig"

    if ($file_path | path exists) {
        print $"EditorConfig file already exists at: ($file_path)"
        error make { msg: "editorconfig already exists" }
    }

    let content = "# http://editorconfig.org
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
"

    $content | save $file_path
}
