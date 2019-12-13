# Defined in /var/folders/n8/__3mw5v17hqfpf6ycpb6b7_h0000gn/T//fish.y9KJ4D/ungate.fish @ line 2
function ungate --description 'Remvoe gatekeeper protection from extended attributes.'
    # http://furbo.org/2014/09/03/xcode-vs-gatekeeper/
	xattr -d com.apple.quarantine $argv
end
