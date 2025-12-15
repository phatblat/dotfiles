# VS Code Executor

Execute Visual Studio Code CLI operations including extension management, file/folder operations, and command execution.

## Capability

This skill executes Visual Studio Code CLI commands for extension management, file/folder operations, workspace management, and command URI execution. It returns structured results with command output, installed extensions, and operation status.

## Supported Operations

### Extension Management
- **install-extension** - Install VS Code extensions
- **uninstall-extension** - Uninstall VS Code extensions
- **list-extensions** - List installed extensions
- **show-extension-versions** - Show available versions for extensions

### File & Folder Operations
- **open-file** - Open file in VS Code
- **open-folder** - Open folder/workspace in VS Code
- **open-diff** - Open diff view comparing two files
- **goto-line** - Open file at specific line and column

### Workspace Operations
- **add-folder** - Add folder to current workspace
- **new-window** - Open new VS Code window
- **wait** - Open file and wait for it to close

### Command Execution
- **execute-command** - Execute VS Code command via URI
- **open-settings** - Open VS Code settings UI
- **show-installed-extensions** - Open extensions view
- **format-document** - Format active document
- **open-terminal** - Open integrated terminal

## Usage Protocol

Agents invoke this skill by specifying operation parameters:

```json
{
  "action": "execute",
  "operation": "install-extension",
  "args": {
    "extensionId": "ms-vscode.cpptools"
  }
}
```

### Parameters

- **action** (required): `execute`
- **operation** (required): VS Code operation to perform
- **args** (required): Operation-specific arguments
- **timeout** (optional): Timeout in seconds (default: 30s)
- **newWindow** (optional): Open in new window (default: false)
- **forceNewInstance** (optional): Force new VS Code instance (default: false)
- **disableExtensions** (optional): Disable all extensions (default: false)
- **profile** (optional): Use specific profile name

## Extension Management

### Install Extension

```json
{
  "action": "execute",
  "operation": "install-extension",
  "args": {
    "extensionId": "ms-python.python",
    "force": false,
    "preRelease": false
  }
}
```

Executes: `code --install-extension ms-python.python`

### Uninstall Extension

```json
{
  "action": "execute",
  "operation": "uninstall-extension",
  "args": {
    "extensionId": "ms-python.python"
  }
}
```

Executes: `code --uninstall-extension ms-python.python`

### List Installed Extensions

```json
{
  "action": "execute",
  "operation": "list-extensions",
  "args": {
    "showVersions": true,
    "category": "all"
  }
}
```

Executes: `code --list-extensions --show-versions`

Returns list of extensions with IDs and versions.

### Show Extension Versions

```json
{
  "action": "execute",
  "operation": "show-extension-versions",
  "args": {
    "extensionId": "ms-vscode.cpptools"
  }
}
```

Executes: `code --show-versions --extension-id ms-vscode.cpptools`

## File & Folder Operations

### Open File

```json
{
  "action": "execute",
  "operation": "open-file",
  "args": {
    "filePath": "/path/to/file.txt",
    "newWindow": false,
    "reuseWindow": true
  }
}
```

Executes: `code /path/to/file.txt`

### Open Folder/Workspace

```json
{
  "action": "execute",
  "operation": "open-folder",
  "args": {
    "folderPath": "/path/to/project",
    "newWindow": false
  }
}
```

Executes: `code /path/to/project`

### Open Diff View

```json
{
  "action": "execute",
  "operation": "open-diff",
  "args": {
    "file1": "/path/to/original.txt",
    "file2": "/path/to/modified.txt"
  }
}
```

Executes: `code --diff /path/to/original.txt /path/to/modified.txt`

### Go to Line

```json
{
  "action": "execute",
  "operation": "goto-line",
  "args": {
    "filePath": "/path/to/file.cpp",
    "line": 42,
    "column": 15
  }
}
```

Executes: `code --goto /path/to/file.cpp:42:15`

## Workspace Operations

### Add Folder to Workspace

```json
{
  "action": "execute",
  "operation": "add-folder",
  "args": {
    "folderPath": "/path/to/folder"
  }
}
```

Executes: `code --add /path/to/folder`

### Open New Window

```json
{
  "action": "execute",
  "operation": "new-window",
  "args": {
    "folderPath": "/path/to/project"
  }
}
```

Executes: `code --new-window /path/to/project`

### Wait for File to Close

```json
{
  "action": "execute",
  "operation": "wait",
  "args": {
    "filePath": "/path/to/file.txt"
  }
}
```

Executes: `code --wait /path/to/file.txt`

Blocks until file is closed in VS Code.

## Command Execution

### Execute Command via URI

```json
{
  "action": "execute",
  "operation": "execute-command",
  "args": {
    "command": "workbench.action.openSettings"
  }
}
```

Executes: `code --open-url 'vscode://command/workbench.action.openSettings'`

### Open Settings

```json
{
  "action": "execute",
  "operation": "open-settings",
  "args": {}
}
```

Executes command URI: `vscode://command/workbench.action.openSettings`

### Show Installed Extensions

```json
{
  "action": "execute",
  "operation": "show-installed-extensions",
  "args": {}
}
```

Executes command URI: `vscode://command/workbench.extensions.action.showInstalledExtensions`

### Format Document

```json
{
  "action": "execute",
  "operation": "format-document",
  "args": {}
}
```

Executes command URI: `vscode://command/editor.action.formatDocument`

### Open Terminal

```json
{
  "action": "execute",
  "operation": "open-terminal",
  "args": {}
}
```

Executes command URI: `vscode://command/workbench.action.terminal.new`

## Profile Management

### Use Specific Profile

```json
{
  "action": "execute",
  "operation": "open-folder",
  "args": {
    "folderPath": "/path/to/project"
  },
  "profile": "work-profile"
}
```

Executes: `code --profile "work-profile" /path/to/project`

### Disable Extensions

```json
{
  "action": "execute",
  "operation": "open-folder",
  "args": {
    "folderPath": "/path/to/project"
  },
  "disableExtensions": true
}
```

Executes: `code --disable-extensions /path/to/project`

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "action": "execute",
    "operation": "install-extension",
    "args": {
      "extensionId": "ms-python.python"
    },
    "exitCode": 0,
    "duration": "2.3s",
    "status": "success",
    "stdout": "Extension 'ms-python.python' was successfully installed.",
    "stderr": ""
  }
}
```

### Successful Extension Installation

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "action": "execute",
    "operation": "install-extension",
    "args": {
      "extensionId": "ms-python.python"
    },
    "exitCode": 0,
    "duration": "3.1s",
    "status": "success",
    "stdout": "Extension 'ms-python.python' v2024.18.0 was successfully installed.",
    "metadata": {
      "extensionId": "ms-python.python",
      "version": "2024.18.0",
      "publisher": "ms-python",
      "alreadyInstalled": false
    }
  }
}
```

### List Extensions Result

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:31:00Z",
    "action": "execute",
    "operation": "list-extensions",
    "args": {
      "showVersions": true
    },
    "exitCode": 0,
    "duration": "0.8s",
    "status": "success",
    "stdout": "ms-python.python@2024.18.0\nms-vscode.cpptools@1.18.5\nesbenp.prettier-vscode@10.4.0",
    "metadata": {
      "extensionCount": 3,
      "extensions": [
        {
          "id": "ms-python.python",
          "version": "2024.18.0",
          "publisher": "ms-python",
          "name": "Python"
        },
        {
          "id": "ms-vscode.cpptools",
          "version": "1.18.5",
          "publisher": "ms-vscode",
          "name": "C/C++"
        },
        {
          "id": "esbenp.prettier-vscode",
          "version": "10.4.0",
          "publisher": "esbenp",
          "name": "Prettier - Code formatter"
        }
      ]
    }
  }
}
```

### File Opened Successfully

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:32:00Z",
    "action": "execute",
    "operation": "open-file",
    "args": {
      "filePath": "/Users/dev/project/main.cpp"
    },
    "exitCode": 0,
    "duration": "0.5s",
    "status": "success",
    "metadata": {
      "filePath": "/Users/dev/project/main.cpp",
      "fileExists": true,
      "windowOpened": true
    }
  }
}
```

### Diff View Opened

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:33:00Z",
    "action": "execute",
    "operation": "open-diff",
    "args": {
      "file1": "/path/original.txt",
      "file2": "/path/modified.txt"
    },
    "exitCode": 0,
    "duration": "0.6s",
    "status": "success",
    "metadata": {
      "file1": "/path/original.txt",
      "file2": "/path/modified.txt",
      "diffViewOpened": true
    }
  }
}
```

### Command Executed via URI

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:34:00Z",
    "action": "execute",
    "operation": "execute-command",
    "args": {
      "command": "workbench.action.openSettings"
    },
    "exitCode": 0,
    "duration": "0.4s",
    "status": "success",
    "metadata": {
      "commandUri": "vscode://command/workbench.action.openSettings",
      "commandExecuted": true
    }
  }
}
```

## Error Handling

Returns structured error information for:

- **Extension not found**: Extension ID doesn't exist in marketplace
- **Extension already installed**: Attempting to install already-installed extension
- **Extension installation failed**: Network issues, incompatible version
- **File not found**: Specified file doesn't exist
- **Folder not found**: Specified folder doesn't exist
- **Invalid command**: Unknown VS Code command URI
- **VS Code not found**: code command not in PATH

Example error response:

```json
{
  "error": {
    "type": "extension-not-found",
    "operation": "install-extension",
    "extensionId": "invalid-publisher.invalid-extension",
    "message": "Extension 'invalid-publisher.invalid-extension' not found",
    "exitCode": 1,
    "solution": "Verify the extension ID at https://marketplace.visualstudio.com/vscode"
  }
}
```

### Extension Not Found

```json
{
  "error": {
    "type": "extension-not-found",
    "operation": "install-extension",
    "extensionId": "nonexistent.extension",
    "message": "Extension 'nonexistent.extension' not found",
    "exitCode": 1,
    "stderr": "Error: Extension 'nonexistent.extension' not found.",
    "solution": "Check extension ID spelling or search marketplace: https://marketplace.visualstudio.com/vscode"
  }
}
```

### Extension Already Installed

```json
{
  "error": {
    "type": "already-installed",
    "operation": "install-extension",
    "extensionId": "ms-python.python",
    "message": "Extension 'ms-python.python' is already installed",
    "currentVersion": "2024.18.0",
    "solution": "Use --force to reinstall or update to latest version"
  }
}
```

### File Not Found

```json
{
  "error": {
    "type": "file-not-found",
    "operation": "open-file",
    "filePath": "/nonexistent/file.txt",
    "message": "File not found: /nonexistent/file.txt",
    "exitCode": 1,
    "solution": "Verify the file path exists"
  }
}
```

### VS Code Not Found

```json
{
  "error": {
    "type": "command-not-found",
    "command": "code",
    "message": "VS Code CLI 'code' command not found in PATH",
    "exitCode": 127,
    "solution": "Install VS Code or add 'code' command to PATH: Command Palette > 'Shell Command: Install 'code' command in PATH'"
  }
}
```

### Invalid Command URI

```json
{
  "error": {
    "type": "invalid-command",
    "operation": "execute-command",
    "command": "invalid.command",
    "message": "Unknown command: 'invalid.command'",
    "exitCode": 1,
    "solution": "Verify command ID or see available commands: https://code.visualstudio.com/api/references/commands"
  }
}
```

## Common Command URIs

### UI Navigation
- **Open Settings**: `workbench.action.openSettings`
- **Open Keybindings**: `workbench.action.openGlobalKeybindings`
- **Show All Commands**: `workbench.action.showCommands`
- **Open Extensions**: `workbench.extensions.action.showInstalledExtensions`

### Editor Actions
- **Format Document**: `editor.action.formatDocument`
- **Format Selection**: `editor.action.formatSelection`
- **Organize Imports**: `editor.action.organizeImports`
- **Go to Definition**: `editor.action.revealDefinition`
- **Find All References**: `editor.action.goToReferences`
- **Rename Symbol**: `editor.action.rename`

### Terminal Actions
- **New Terminal**: `workbench.action.terminal.new`
- **Toggle Terminal**: `workbench.action.terminal.toggleTerminal`
- **Kill Terminal**: `workbench.action.terminal.kill`

### Git Actions
- **Open Source Control**: `workbench.view.scm`
- **Stage Changes**: `git.stage`
- **Commit**: `git.commit`
- **Push**: `git.push`
- **Pull**: `git.pull`

### File Actions
- **New File**: `workbench.action.files.newUntitledFile`
- **Save**: `workbench.action.files.save`
- **Save All**: `workbench.action.files.saveAll`
- **Close Editor**: `workbench.action.closeActiveEditor`

## CLI Options Reference

### Window Options
- `--new-window, -n` - Force new window
- `--reuse-window, -r` - Reuse existing window
- `--wait, -w` - Wait for file to close
- `--locale <locale>` - Set display language

### Extension Options
- `--install-extension <ext-id>` - Install extension
- `--uninstall-extension <ext-id>` - Uninstall extension
- `--list-extensions` - List installed extensions
- `--show-versions` - Show extension versions
- `--disable-extensions` - Disable all extensions
- `--disable-extension <ext-id>` - Disable specific extension

### File Options
- `--goto <file:line:column>` - Open file at location
- `--diff <file1> <file2>` - Open diff editor
- `--add <folder>` - Add folder to workspace
- `--merge <file1> <file2> <base> <result>` - Open merge editor

### Profile Options
- `--profile <name>` - Open with specific profile
- `--profile-temp` - Use temporary profile

### Advanced Options
- `--force-new-window` - Force new instance
- `--user-data-dir <dir>` - User data directory
- `--extensions-dir <dir>` - Extensions directory
- `--verbose` - Enable verbose logging
- `--log <level>` - Set log level

## Platform Differences

### macOS
Command: `/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code` (usually aliased as `code`)

### Linux
Command: `/usr/bin/code` or `/usr/share/code/bin/code`

### Windows
Command: `C:\Program Files\Microsoft VS Code\bin\code.cmd` (added to PATH during installation)

This skill auto-detects platform and uses appropriate command paths.

## Constraints

This skill does NOT:
- Create or modify VS Code configuration files (settings.json, keybindings.json, launch.json, tasks.json)
- Write extension code or provide extension development guidance
- Implement Language Server Protocol servers
- Create custom debugger adapters
- Design or recommend VS Code configurations
- Troubleshoot VS Code issues (beyond command execution errors)
- Optimize VS Code performance settings
- Provide guidance on IntelliSense setup or C++ configuration
- Create custom themes, snippets, or language grammars
- Make recommendations about which extensions to use
- Explain VS Code concepts or features

For configuration guidance, extension development, LSP implementation, or customization advice, agents should use general reasoning capabilities along with this skill for executing operations.

## Usage Examples

### Install Multiple Extensions

```json
{
  "action": "batch-execute",
  "operations": [
    {
      "operation": "install-extension",
      "args": {"extensionId": "ms-python.python"}
    },
    {
      "operation": "install-extension",
      "args": {"extensionId": "ms-vscode.cpptools"}
    },
    {
      "operation": "install-extension",
      "args": {"extensionId": "esbenp.prettier-vscode"}
    }
  ]
}
```

### Open Project in New Window with Profile

```json
{
  "action": "execute",
  "operation": "open-folder",
  "args": {
    "folderPath": "/Users/dev/my-project"
  },
  "newWindow": true,
  "profile": "work"
}
```

### Compare Two Files

```json
{
  "action": "execute",
  "operation": "open-diff",
  "args": {
    "file1": "package.json",
    "file2": "package-lock.json"
  }
}
```

### Check Installed Extensions

```json
{
  "action": "execute",
  "operation": "list-extensions",
  "args": {
    "showVersions": true
  }
}
```
