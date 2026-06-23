# Dependencies:
#   functions: none
#   builtins:  none
#   externals: codesign

# Verify the codesign of a bundle against the Apple certificate requirement
export def --wrapped codesign_verify [...rest] {
    ^codesign --verify -vvvv "-R=anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.1] exists and (certificate leaf[field.1.2.840.113635.100.6.1.2] exists or certificate leaf[field.1.2.840.113635.100.6.1.4] exists)" ...$rest
}
