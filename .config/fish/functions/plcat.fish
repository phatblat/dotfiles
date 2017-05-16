# Print the contents of a property list in XML format.
function plcat
    plutil -convert xml1 -o - $argv
end
