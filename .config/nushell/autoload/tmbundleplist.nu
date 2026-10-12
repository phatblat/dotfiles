# tmbundleplist - Generates the XML contents for a minimal TextMate bundle Info.plist.
# Content goes to stdout. Redirect to a file after previewing results.
export def tmbundleplist [bundle_name?: string, bundle_description?: string, git_url?: string] {
    if ($bundle_name | is-empty) {
        error make { msg: "Usage: tmbundleplist name description [git_url]" }
    }

    let uuid = (^uuidgen | str trim)
    # Escape XML special characters (descriptions like "Black & White")
    let esc = {|t| $t | str replace --all '&' '&amp;' | str replace --all '<' '&lt;' | str replace --all '>' '&gt;' }
    let name = (do $esc $bundle_name)
    let description = (do $esc ($bundle_description | default ""))
    let url = (do $esc ($git_url | default ""))

    let head = $"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
\t<key>name</key>
\t<string>($name)</string>
\t<key>description</key>
\t<string>($description)</string>
\t<key>uuid</key>
\t<string>($uuid)</string>"

    # Add source section if url provided
    let source = if ($git_url | is-empty) { "" } else {
        $"\n\t<key>source</key>
\t<dict>
\t\t<key>method</key>
\t\t<string>git</string>
\t\t<key>url</key>
\t\t<string>($url)</string>
\t</dict>"
    }

    $"($head)($source)\n</dict>\n</plist>\n"
}
