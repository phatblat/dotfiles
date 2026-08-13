# Dependencies:
#   functions: none
#   builtins:  error match lines where is-empty each path basename
#   externals: find

# List installed macOS apps as structured records
export def apps [option?: string = "default"] {
    match $option {
        "default" => {
            ^find /Applications -iname "*.app" -maxdepth 1
                | lines
                | where {|p| not ($p | is-empty) }
                | each {|p| {name: ($p | path basename), path: $p} }
        },
        "all" => {
            ^find /Applications -iname "*.app"
                | lines
                | where {|p| not ($p | is-empty) }
                | each {|p| {name: ($p | path basename), path: $p} }
        },
        "mas" | "appstore" | "app-store" => {
            ^find /Applications -path "*Contents/_MASReceipt/receipt" -maxdepth 4 -print
                | lines
                | where {|p| not ($p | is-empty) }
                | each {|p|
                    let app_path = ($p | str replace ".app/Contents/_MASReceipt/receipt" ".app")
                    {name: ($app_path | str replace "/Applications/" ""), path: $app_path}
                }
        },
        _ => {
            error make { msg: "Usage: apps [all|mas]" }
        },
    }
}
