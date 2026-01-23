# opcode Integration with Home Manager

This document describes how the opcode Nix package has been integrated into your home-manager configuration.

## What Was Done

1. **Created Package Definition**: `packages/opcode.nix`
   - Complete Nix derivation for opcode v0.2.0
   - Two-stage build (frontend with Bun, backend with Rust/Tauri)
   - Platform support for Linux and macOS

2. **Integrated with Home Manager**: Modified `home.nix`
   - Added opcode to `home.packages` using `callPackage`
   - Package will be installed when you run `home-manager switch`

3. **Documentation**:
   - `packages/README.md` - Overview of custom packages directory
   - `packages/NIX-PACKAGE-README.md` - Detailed opcode usage guide
   - `packages/OPCODE-NIX-PACKAGE.md` - Implementation notes
   - `packages/build-opcode.sh` - Helper build script

## File Locations

```
~/.config/home-manager/
├── flake.nix                           # Home Manager flake (unchanged)
├── home.nix                            # Updated with opcode package
├── OPCODE-INTEGRATION.md               # This file
└── packages/
    ├── README.md                       # Custom packages overview
    ├── opcode.nix                      # opcode package definition
    ├── NIX-PACKAGE-README.md           # opcode usage guide
    ├── OPCODE-NIX-PACKAGE.md           # opcode implementation notes
    └── build-opcode.sh                 # Build helper script
```

## How It Works

### Package Definition

The `opcode.nix` file defines how to build opcode:

```nix
(pkgs.callPackage ./packages/opcode.nix { })
```

This calls the opcode package with all necessary dependencies from nixpkgs.

### Two-Stage Build

1. **Frontend Stage**: 
   - Uses Bun to build the TypeScript/React frontend
   - Produces static assets in `dist/`

2. **Backend Stage**:
   - Builds the Rust/Tauri backend
   - Links against the frontend assets
   - Produces the final executable

## First Build: Getting the Cargo Hash

⚠️ **Important**: The package needs the `cargoHash` filled in before it will build successfully.

### Steps:

1. Try to switch your home-manager configuration:
   ```bash
   home-manager switch
   ```

2. The build will fail with an error like:
   ```
   error: hash mismatch in fixed-output derivation
   specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
   got:       sha256-abc123def456...
   ```

3. Copy the correct hash (the "got:" value)

4. Edit `~/.config/home-manager/packages/opcode.nix`:
   ```nix
   cargoHash = "sha256-abc123def456...";  # Replace with correct hash
   ```

5. Run `home-manager switch` again - it should succeed this time

## Using opcode

Once installed via home-manager, opcode will be available in your PATH:

```bash
# Run opcode
opcode

# Check version
opcode --version
```

## Testing the Package

You can test building opcode without affecting your home-manager config:

```bash
cd ~/.config/home-manager/packages
./build-opcode.sh
```

This builds the package in isolation and creates a `result` symlink to the build output.

## Updating opcode

To update to a newer version:

1. Edit `packages/opcode.nix`
2. Update the `version` variable
3. Update the `hash` (source hash) using `nix-prefetch-url`
4. Clear the `cargoHash` and rebuild to get the new hash
5. Run `home-manager switch`

## Removing opcode

To remove opcode from your system:

1. Edit `home.nix`
2. Remove or comment out the line:
   ```nix
   (pkgs.callPackage ./packages/opcode.nix { })
   ```
3. Run `home-manager switch`

## Troubleshooting

### Build Fails with "hash mismatch"

This is expected on first build. Follow the "Getting the Cargo Hash" steps above.

### Darwin SDK Errors on macOS

If you see errors about `darwin.apple_sdk_11_0`, your nixpkgs may need updating:

```bash
nix-channel --update
home-manager switch
```

### Build Takes a Long Time

The first build downloads and compiles many dependencies. Subsequent builds are cached.

### Package Not Found After Install

Make sure your PATH includes the home-manager profile:

```bash
export PATH="$HOME/.nix-profile/bin:$PATH"
```

Add this to your shell config if not already present.

## Contributing to nixpkgs

Once the package is working, you can contribute it to nixpkgs:

1. Fill in the `cargoHash`
2. Test on both Linux and macOS (if possible)
3. Add yourself to `meta.maintainers`
4. Follow [nixpkgs contributing guide](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md)
5. Submit a PR with the package at `pkgs/by-name/op/opcode/package.nix`

## Resources

- [opcode GitHub](https://github.com/winfunc/opcode)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
