#!/usr/bin/env bats
# nu-wave2-xcode.bats — Nushell port tests for wave-2 Xcode/macOS batch
# Functions: defaults_set, derived_data, plcat, provisioning_print,
#            signing_cert_details, xc, xclist, xcswitch, xcss, xcvall, pkginfo
# Also covers: gskip (git skip rename)

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# gskip (renamed from skip to avoid nu builtin collision)
# ---------------------------------------------------------------------------

@test "gskip: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/gskip.nu'"
    [ "$status" -eq 0 ]
}

@test "gskip: smoke — exits non-zero when no rebase/cherry-pick/am in progress" {
    # All three git commands fail when nothing is in progress; gskip propagates
    # the last non-zero exit. This confirms the logic runs without parse errors.
    run nu --no-config-file -c "
        source '$AUTOLOAD/gskip.nu'
        cd '$HOME'
        gskip
    " 2>&1
    # status should be non-zero since no operation is in progress
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# pkginfo
# ---------------------------------------------------------------------------

@test "pkginfo: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/pkginfo.nu'"
    [ "$status" -eq 0 ]
}

@test "pkginfo: smoke — returns info for CLTools package" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/pkginfo.nu'
        pkginfo com.apple.pkg.CLTools_Executables
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"package-id"* ]]
}

@test "pkginfo: error on missing package_id" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/pkginfo.nu'
        pkginfo ''
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: pkginfo"* ]]
}

# ---------------------------------------------------------------------------
# plcat
# ---------------------------------------------------------------------------

@test "plcat: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/plcat.nu'"
    [ "$status" -eq 0 ]
}

@test "plcat: smoke — converts and displays a plist file with bat" {
    local plist_file="$HOME/Library/Preferences/APMAnalyticsSuiteName.plist"
    if [ ! -f "$plist_file" ]; then
        skip "test plist file not found"
    fi
    run nu --no-config-file -c "
        source '$AUTOLOAD/plcat.nu'
        plcat '$plist_file'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"plist"* ]]
}

@test "plcat: error on missing file" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/plcat.nu'
        plcat '/nonexistent/file.plist'
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "plcat: error on no argument (empty string)" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/plcat.nu'
        plcat ''
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: plcat"* ]]
}

# ---------------------------------------------------------------------------
# provisioning_print
# ---------------------------------------------------------------------------

@test "provisioning_print: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/provisioning_print.nu'"
    [ "$status" -eq 0 ]
}

@test "provisioning_print: error on missing file" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/provisioning_print.nu'
        provisioning_print '/nonexistent.mobileprovision'
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"does not exist"* ]]
}

# ---------------------------------------------------------------------------
# signing_cert_details
# ---------------------------------------------------------------------------

@test "signing_cert_details: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/signing_cert_details.nu'"
    [ "$status" -eq 0 ]
}

@test "signing_cert_details: error on empty cert_name" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/signing_cert_details.nu'
        signing_cert_details ''
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: signing_cert_details"* ]]
}

# ---------------------------------------------------------------------------
# xclist
# ---------------------------------------------------------------------------

@test "xclist: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/xclist.nu'"
    [ "$status" -eq 0 ]
}

@test "xclist: smoke — lists installed Xcode versions" {
    run nu --no-config-file -c "source '$AUTOLOAD/xclist.nu'; xclist"
    [ "$status" -eq 0 ]
    # Should contain at least one Xcode path on a macOS dev machine
    [[ "$output" == *"Xcode"* ]] || [ "${#output}" -eq 0 ]
}

@test "xclist: --one-per-line flag exits 0" {
    run nu --no-config-file -c "source '$AUTOLOAD/xclist.nu'; xclist --one-per-line"
    [ "$status" -eq 0 ]
}

@test "xclist: -1 short flag exits 0" {
    run nu --no-config-file -c "source '$AUTOLOAD/xclist.nu'; xclist -1"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# xcss (mutating: calls sudo xcode-select — parse test only)
# ---------------------------------------------------------------------------

@test "xcss: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/xcss.nu'"
    [ "$status" -eq 0 ]
}

@test "xcss: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/xcss.nu'; help xcss"
    [ "$status" -eq 0 ]
    [[ "$output" == *"xcode-select"* ]]
}

# ---------------------------------------------------------------------------
# xc
# ---------------------------------------------------------------------------

@test "xc: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/xc.nu'"
    [ "$status" -eq 0 ]
}

@test "xc: error when no Xcode project found in empty temp dir" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    run nu --no-config-file -c "
        source '$AUTOLOAD/xc.nu'
        cd '$tmpdir'
        xc
    " 2>&1
    rm -rf "$tmpdir"
    [ "$status" -ne 0 ]
    [[ "$output" == *"No Xcode projects found"* ]]
}

@test "xc: opens Package.swift when present (smoke with open suppressed)" {
    local tmpdir fakebindir
    tmpdir="$(mktemp -d)"
    fakebindir="$(mktemp -d)"
    touch "$tmpdir/Package.swift"
    # Stub out 'open' so Xcode doesn't actually launch
    printf '#!/bin/sh\nexit 0\n' > "$fakebindir/open"
    chmod +x "$fakebindir/open"
    run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
        source '$AUTOLOAD/xc.nu'
        cd '$tmpdir'
        xc
    " 2>&1
    rm -rf "$tmpdir" "$fakebindir"
    # Verify logic ran (not "No Xcode projects found")
    [ "$status" -eq 0 ] || [[ "$output" == *"Package.swift"* ]]
}

# ---------------------------------------------------------------------------
# xcswitch (mutating: calls xcss/sudo — parse test only)
# ---------------------------------------------------------------------------

@test "xcswitch: file parses without error" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        source '$AUTOLOAD/xcss.nu'
        source '$AUTOLOAD/xclist.nu'
        source '$AUTOLOAD/xcsp.nu'
        source '$AUTOLOAD/xcswitch.nu'
    "
    [ "$status" -eq 0 ]
}

@test "xcswitch: error on non-admin user or missing version" {
    # Test the empty-version error path (will fail on user_is_admin first on non-admin,
    # or on empty-version check if admin; both are non-zero exits)
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        source '$AUTOLOAD/xcss.nu'
        source '$AUTOLOAD/xclist.nu'
        source '$AUTOLOAD/xcsp.nu'
        source '$AUTOLOAD/xcswitch.nu'
        xcswitch ''
    " 2>&1
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# xcvall
# ---------------------------------------------------------------------------

@test "xcvall: file parses without error" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/pkginfo.nu'
        source '$AUTOLOAD/xcvall.nu'
    "
    [ "$status" -eq 0 ]
}

@test "xcvall: smoke — lists Xcode installations and CLI tools info" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/pkginfo.nu'
        source '$AUTOLOAD/xcvall.nu'
        xcvall
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"CLI tools"* ]]
}

# ---------------------------------------------------------------------------
# derived_data (mutating: mounts RAM disk — parse test only)
# ---------------------------------------------------------------------------

@test "derived_data: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/derived_data.nu'"
    [ "$status" -eq 0 ]
}

@test "derived_data: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/derived_data.nu'; help derived_data"
    [ "$status" -eq 0 ]
    [[ "$output" == *"RAM disk"* ]] || [[ "$output" == *"derived"* ]] || [[ "$output" == *"Derived"* ]]
}

# ---------------------------------------------------------------------------
# defaults_set (mutating: changes system prefs — parse test only)
# ---------------------------------------------------------------------------

@test "defaults_set: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/defaults_set.nu'"
    [ "$status" -eq 0 ]
}

@test "defaults_set: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/defaults_set.nu'; help defaults_set"
    [ "$status" -eq 0 ]
    [[ "$output" == *"macOS"* ]] || [[ "$output" == *"defaults"* ]] || [[ "$output" == *"preferences"* ]]
}
