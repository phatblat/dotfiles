# Dependencies:
#   functions: none
#   builtins:  is-empty which print
#   externals: git git-filter-repo

# Rewrite commit author/committer email or name using git-filter-repo
export def rewrite [
    field: string,       # Field to rewrite: 'email' or 'name'
    old_value: string,   # Value to replace
    new_value: string,   # Replacement value
    limit?: string,      # Optional number of commits to rewrite (e.g. "10")
] {
    if ($limit != null and not ($limit | is-empty)) {
        if not ($limit =~ '^[0-9]+$') {
            print --stderr $"error: limit must be a positive integer, got: '($limit)'"
            return
        }
    }

    if $field not-in ["email", "name"] {
        print --stderr $"error: Unsupported field '($field)'. Supported fields: email, name"
        print --stderr "error: Usage: rewrite <email|name> old_value new_value [limit]"
        return
    }

    if (which git-filter-repo | is-empty) {
        print --stderr "error: git-filter-repo is not installed"
        return
    }

    let refs_arg = if ($limit != null and not ($limit | is-empty)) {
        ["--refs", $"HEAD~($limit)..HEAD"]
    } else {
        []
    }

    match $field {
        "email" => {
            ^git filter-repo --force ...$refs_arg --email-callback $"return email.replace\(b\"($old_value)\", b\"($new_value)\"\)"
        },
        "name" => {
            ^git filter-repo --force ...$refs_arg --name-callback $"return name.replace\(b\"($old_value)\", b\"($new_value)\"\)"
        },
    }
}
