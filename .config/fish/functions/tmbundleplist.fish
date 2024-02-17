# Generates the XML contents for a minimal TextMate bundle Info.plist.
# Content goes to stdout. Redirect to a file after previewing results.
function tmbundleplist --argument-names bundle_name bundle_description git_url
    if test -z $bundle_name
        echo Usage: tmbundleplist name description [git_url]
        return 1
    end

    set -l uuid (uuidgen)

    set -l content \
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>name</key>
	<string>$bundle_name</string>
	<key>description</key>
	<string>$bundle_description</string>
	<key>uuid</key>
	<string>$uuid</string>"

    # Add source section if url provided
    if test -n "$git_url"
        set content $content \
            "	<key>source</key>
	<dict>
		<key>method</key>
		<string>git</string>
		<key>url</key>
		<string>$git_url</string>
	</dict>"
    end

    set content $content \
        "</dict>
</plist>"

    echo $content\n
end
