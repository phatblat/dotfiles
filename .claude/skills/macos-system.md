# macOS System

Execute macOS system operations for configuration, automation, and information gathering.

## Capability

This skill executes macOS-specific system commands for managing preferences, services, applications, and system information. It returns structured results with command output, status codes, and parsed metadata.

## Supported Operations

### System Preferences
- **defaults** - Read/write system and application preferences
- **PlistBuddy** - Manipulate property list files
- **systemsetup** - Configure system settings

### Service Management
- **launchctl** - Manage launchd services and agents
- **launchd** - Configure launch daemons and agents

### Package Management
- **brew** - Homebrew package operations
- **mas** - Mac App Store CLI operations

### System Information
- **system_profiler** - Gather hardware and software information
- **sw_vers** - macOS version information
- **sysctl** - Kernel parameters and system information
- **diskutil** - Disk management and information

### AppleScript
- **osascript** - Execute AppleScript code
- **automator** - Run Automator workflows

### Application Management
- **open** - Open applications and files
- **killall** - Terminate applications
- **pkgutil** - Query and manage installed packages

## Usage Protocol

Agents invoke this skill by specifying operation parameters:

```json
{
  "action": "execute",
  "command": "defaults",
  "operation": "read",
  "args": {
    "domain": "com.apple.dock",
    "key": "autohide"
  }
}
```

### Parameters

- **action** (required): Always `"execute"`
- **command** (required): macOS command to execute
- **operation** (required): Specific operation (read, write, list, etc.)
- **args** (required): Command-specific arguments
- **sudo** (optional): Run with elevated privileges (default: false)
- **timeout** (optional): Timeout in seconds (default: 30s)

## System Preferences (defaults)

### Read Preference

```json
{
  "action": "execute",
  "command": "defaults",
  "operation": "read",
  "args": {
    "domain": "com.apple.dock",
    "key": "autohide"
  }
}
```

### Write Preference

```json
{
  "action": "execute",
  "command": "defaults",
  "operation": "write",
  "args": {
    "domain": "com.apple.dock",
    "key": "autohide",
    "value": true,
    "type": "bool"
  }
}
```

### Delete Preference

```json
{
  "action": "execute",
  "command": "defaults",
  "operation": "delete",
  "args": {
    "domain": "com.apple.dock",
    "key": "autohide"
  }
}
```

### List All Preferences for Domain

```json
{
  "action": "execute",
  "command": "defaults",
  "operation": "read",
  "args": {
    "domain": "com.apple.dock"
  }
}
```

### Find Preference Domain

```json
{
  "action": "execute",
  "command": "defaults",
  "operation": "domains"
}
```

## Property Lists (PlistBuddy)

### Read Plist Value

```json
{
  "action": "execute",
  "command": "PlistBuddy",
  "operation": "Print",
  "args": {
    "file": "~/Library/Preferences/com.apple.dock.plist",
    "key": "autohide"
  }
}
```

### Set Plist Value

```json
{
  "action": "execute",
  "command": "PlistBuddy",
  "operation": "Set",
  "args": {
    "file": "~/Library/Preferences/com.apple.dock.plist",
    "key": "autohide",
    "value": true
  }
}
```

### Add Plist Entry

```json
{
  "action": "execute",
  "command": "PlistBuddy",
  "operation": "Add",
  "args": {
    "file": "~/Library/Preferences/com.example.app.plist",
    "key": "NewKey",
    "type": "string",
    "value": "NewValue"
  }
}
```

## Service Management (launchctl)

### List Services

```json
{
  "action": "execute",
  "command": "launchctl",
  "operation": "list"
}
```

### Load Service

```json
{
  "action": "execute",
  "command": "launchctl",
  "operation": "load",
  "args": {
    "plist": "~/Library/LaunchAgents/com.example.service.plist"
  }
}
```

### Unload Service

```json
{
  "action": "execute",
  "command": "launchctl",
  "operation": "unload",
  "args": {
    "plist": "~/Library/LaunchAgents/com.example.service.plist"
  }
}
```

### Start Service

```json
{
  "action": "execute",
  "command": "launchctl",
  "operation": "start",
  "args": {
    "label": "com.example.service"
  }
}
```

### Stop Service

```json
{
  "action": "execute",
  "command": "launchctl",
  "operation": "stop",
  "args": {
    "label": "com.example.service"
  }
}
```

## Homebrew Operations

### Install Package

```json
{
  "action": "execute",
  "command": "brew",
  "operation": "install",
  "args": {
    "package": "wget",
    "options": ["--verbose"]
  }
}
```

### Update Homebrew

```json
{
  "action": "execute",
  "command": "brew",
  "operation": "update"
}
```

### Upgrade Packages

```json
{
  "action": "execute",
  "command": "brew",
  "operation": "upgrade",
  "args": {
    "packages": ["git", "node"]
  }
}
```

### List Installed Packages

```json
{
  "action": "execute",
  "command": "brew",
  "operation": "list",
  "args": {
    "format": "json"
  }
}
```

### Search Packages

```json
{
  "action": "execute",
  "command": "brew",
  "operation": "search",
  "args": {
    "query": "python"
  }
}
```

## Mac App Store (mas)

### List Installed Apps

```json
{
  "action": "execute",
  "command": "mas",
  "operation": "list"
}
```

### Install App

```json
{
  "action": "execute",
  "command": "mas",
  "operation": "install",
  "args": {
    "appId": "497799835"
  }
}
```

### Update Apps

```json
{
  "action": "execute",
  "command": "mas",
  "operation": "upgrade"
}
```

### Search Apps

```json
{
  "action": "execute",
  "command": "mas",
  "operation": "search",
  "args": {
    "query": "Xcode"
  }
}
```

## System Information

### Get System Profile

```json
{
  "action": "execute",
  "command": "system_profiler",
  "operation": "get",
  "args": {
    "dataType": "SPHardwareDataType",
    "format": "json"
  }
}
```

### Get macOS Version

```json
{
  "action": "execute",
  "command": "sw_vers",
  "operation": "info"
}
```

### Get Hardware Info

```json
{
  "action": "execute",
  "command": "sysctl",
  "operation": "get",
  "args": {
    "keys": ["hw.ncpu", "hw.memsize", "machdep.cpu.brand_string"]
  }
}
```

### Disk Information

```json
{
  "action": "execute",
  "command": "diskutil",
  "operation": "info",
  "args": {
    "disk": "disk0"
  }
}
```

### List Disks

```json
{
  "action": "execute",
  "command": "diskutil",
  "operation": "list",
  "args": {
    "format": "plist"
  }
}
```

## AppleScript Execution

### Run AppleScript

```json
{
  "action": "execute",
  "command": "osascript",
  "operation": "run",
  "args": {
    "script": "tell application \"Finder\"\n  activate\n  display dialog \"Hello World\"\nend tell"
  }
}
```

### Run AppleScript File

```json
{
  "action": "execute",
  "command": "osascript",
  "operation": "run-file",
  "args": {
    "file": "~/Scripts/my-script.scpt"
  }
}
```

### Execute JavaScript for Automation (JXA)

```json
{
  "action": "execute",
  "command": "osascript",
  "operation": "run",
  "args": {
    "language": "JavaScript",
    "script": "Application('Finder').activate()"
  }
}
```

## Application Management

### Open Application

```json
{
  "action": "execute",
  "command": "open",
  "operation": "application",
  "args": {
    "application": "Safari"
  }
}
```

### Open File

```json
{
  "action": "execute",
  "command": "open",
  "operation": "file",
  "args": {
    "file": "~/Documents/report.pdf",
    "application": "Preview"
  }
}
```

### Kill Application

```json
{
  "action": "execute",
  "command": "killall",
  "operation": "terminate",
  "args": {
    "application": "Safari"
  }
}
```

### List Running Applications

```json
{
  "action": "execute",
  "command": "osascript",
  "operation": "run",
  "args": {
    "script": "tell application \"System Events\" to get name of every process"
  }
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "command": "defaults",
    "operation": "read",
    "exitCode": 0,
    "duration": "0.1s",
    "status": "success",
    "stdout": "1",
    "metadata": {
      "domain": "com.apple.dock",
      "key": "autohide",
      "value": true,
      "type": "boolean"
    }
  }
}
```

### Successful Preference Read

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "command": "defaults",
    "operation": "read",
    "args": {
      "domain": "com.apple.dock",
      "key": "orientation"
    },
    "exitCode": 0,
    "duration": "0.08s",
    "status": "success",
    "stdout": "bottom",
    "metadata": {
      "domain": "com.apple.dock",
      "key": "orientation",
      "value": "bottom",
      "type": "string"
    }
  }
}
```

### System Information Result

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:31:00Z",
    "command": "system_profiler",
    "operation": "get",
    "args": {
      "dataType": "SPHardwareDataType"
    },
    "exitCode": 0,
    "duration": "2.3s",
    "status": "success",
    "metadata": {
      "modelName": "MacBook Pro",
      "modelIdentifier": "MacBookPro18,3",
      "processorName": "Apple M1 Pro",
      "processorSpeed": "3.2 GHz",
      "numberOfProcessors": 1,
      "totalNumberOfCores": 10,
      "memory": "16 GB",
      "serialNumber": "XXXXXXXXXXXXX"
    }
  }
}
```

### Homebrew Package List

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:32:00Z",
    "command": "brew",
    "operation": "list",
    "exitCode": 0,
    "duration": "1.2s",
    "status": "success",
    "metadata": {
      "packages": [
        {"name": "git", "version": "2.42.0"},
        {"name": "node", "version": "20.10.0"},
        {"name": "python@3.11", "version": "3.11.6"}
      ],
      "totalPackages": 3
    }
  }
}
```

### Service Status

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:33:00Z",
    "command": "launchctl",
    "operation": "list",
    "exitCode": 0,
    "duration": "0.5s",
    "status": "success",
    "metadata": {
      "services": [
        {
          "label": "com.apple.Safari",
          "pid": 1234,
          "status": 0
        },
        {
          "label": "com.example.service",
          "pid": "-",
          "status": 78,
          "lastExitStatus": "Service not loaded"
        }
      ],
      "totalServices": 2
    }
  }
}
```

## Error Handling

Returns structured error information for:

- **Permission denied**: Insufficient privileges for operation
- **Domain not found**: Invalid preference domain
- **Key not found**: Preference key doesn't exist
- **Invalid value**: Type mismatch or invalid value
- **Service not found**: Launch service doesn't exist
- **Command not found**: Tool not installed
- **File not found**: Plist or script file missing

Example error response:

```json
{
  "error": {
    "type": "permission-denied",
    "command": "defaults",
    "operation": "write",
    "domain": "/Library/Preferences/SystemConfiguration/com.apple.smb.server",
    "message": "Could not write domain; permission denied",
    "exitCode": 1,
    "solution": "Use sudo: Set sudo=true in request or run manually with sudo"
  }
}
```

### Key Not Found

```json
{
  "error": {
    "type": "key-not-found",
    "command": "defaults",
    "operation": "read",
    "domain": "com.apple.dock",
    "key": "nonexistent",
    "message": "The domain/default pair of (com.apple.dock, nonexistent) does not exist",
    "exitCode": 1,
    "solution": "Verify key name. List all keys with: defaults read com.apple.dock"
  }
}
```

### Service Error

```json
{
  "error": {
    "type": "service-error",
    "command": "launchctl",
    "operation": "load",
    "plist": "~/Library/LaunchAgents/com.example.service.plist",
    "message": "Load failed: 5: Input/output error",
    "exitCode": 5,
    "solution": "Check plist syntax: plutil -lint ~/Library/LaunchAgents/com.example.service.plist"
  }
}
```

### Command Not Found

```json
{
  "error": {
    "type": "command-not-found",
    "command": "mas",
    "message": "mas command not found",
    "exitCode": 127,
    "solution": "Install mas-cli: brew install mas"
  }
}
```

## macOS Version Compatibility

### Commands by macOS Version

**All Versions**:
- defaults, PlistBuddy, open, killall, sw_vers

**macOS 10.10+**:
- launchctl (new syntax)

**macOS 10.11+**:
- System Integrity Protection (SIP) restrictions

**macOS 10.13+**:
- APFS support in diskutil

**macOS 10.15+**:
- TCC (Transparency, Consent, Control) restrictions
- Notarization requirements

**macOS 11.0+**:
- Apple Silicon support
- Rosetta 2 commands

## Security Considerations

### System Integrity Protection (SIP)
- Cannot modify /System, /usr (except /usr/local), macOS apps
- Some preferences require disabling SIP
- Skill warns when attempting SIP-protected operations

### Transparency, Consent, Control (TCC)
- User approval required for:
  - Full Disk Access
  - Accessibility features
  - Screen recording
  - Input monitoring
- Skill reports TCC permission requirements

### Elevated Privileges
- Use `sudo: true` sparingly
- Only for system-wide configuration
- User prompted for password

## Tool Requirements

### Pre-installed (macOS)
- defaults, PlistBuddy, launchctl, systemsetup
- system_profiler, sw_vers, sysctl, diskutil
- osascript, open, killall

### Optional (install via Homebrew)
- **mas**: `brew install mas`
- **Homebrew**: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

## Constraints

This skill does NOT:
- Diagnose system issues or performance problems
- Recommend configuration changes
- Make architectural decisions
- Provide troubleshooting guidance
- Explain macOS features or concepts
- Design automation workflows
- Select applications or tools
- Migrate data between systems
- Interpret system logs or crash reports
- Make security decisions

## Common macOS Workflows

### Enable Dock Autohide

```json
{
  "action": "execute",
  "command": "defaults",
  "operation": "write",
  "args": {
    "domain": "com.apple.dock",
    "key": "autohide",
    "value": true,
    "type": "bool"
  }
}
```

Then restart Dock:
```json
{
  "action": "execute",
  "command": "killall",
  "operation": "terminate",
  "args": {
    "application": "Dock"
  }
}
```

### Get System Hardware Info

```json
{
  "action": "execute",
  "command": "system_profiler",
  "operation": "get",
  "args": {
    "dataType": "SPHardwareDataType",
    "format": "json"
  }
}
```

### Install App from App Store

```json
{
  "action": "execute",
  "command": "mas",
  "operation": "install",
  "args": {
    "appId": "497799835"
  }
}
```

### Load Launch Agent

```json
{
  "action": "execute",
  "command": "launchctl",
  "operation": "load",
  "args": {
    "plist": "~/Library/LaunchAgents/com.example.agent.plist",
    "waitForStart": true
  }
}
```

### Show Notification

```json
{
  "action": "execute",
  "command": "osascript",
  "operation": "run",
  "args": {
    "script": "display notification \"Task completed\" with title \"Automation\""
  }
}
```
