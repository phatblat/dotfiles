# Linux System

Execute Linux system operations for configuration, monitoring, and information gathering.

## Capability

This skill executes Linux-specific system commands for managing services, packages, system information, performance monitoring, and log analysis. It returns structured results with command output, status codes, and parsed metadata.

## Supported Operations

### System Information
- **uname** - Kernel and system information
- **/proc** - Process and kernel information
- **/sys** - Kernel and device information
- **lsb_release** - Distribution information
- **hostnamectl** - System hostname and metadata

### Service Management
- **systemctl** - Systemd service control
- **service** - Init.d service control (legacy)
- **journalctl** - Systemd journal logs

### Package Management
- **apt** - Debian/Ubuntu package manager
- **yum** - RHEL/CentOS package manager (legacy)
- **dnf** - Fedora/RHEL package manager
- **pacman** - Arch Linux package manager
- **zypper** - openSUSE package manager

### Performance Monitoring
- **top** - Process monitoring
- **htop** - Interactive process viewer
- **vmstat** - Virtual memory statistics
- **iostat** - I/O statistics
- **sar** - System activity reporter
- **free** - Memory usage
- **df** - Disk space usage

### Network Configuration
- **ip** - Network configuration (modern)
- **ifconfig** - Network configuration (legacy)
- **ss** - Socket statistics
- **netstat** - Network statistics (legacy)

### System Configuration
- **sysctl** - Kernel parameters
- **hostnamectl** - Hostname configuration
- **timedatectl** - Time and date settings
- **localectl** - Locale settings

## Usage Protocol

Agents invoke this skill by specifying operation parameters:

```json
{
  "action": "execute",
  "command": "systemctl",
  "operation": "status",
  "args": {
    "service": "nginx"
  }
}
```

### Parameters

- **action** (required): Always `"execute"`
- **command** (required): Linux command to execute
- **operation** (required): Specific operation
- **args** (required): Command-specific arguments
- **sudo** (optional): Run with elevated privileges (default: false)
- **timeout** (optional): Timeout in seconds (default: 30s)

## System Information

### Get Kernel Information

```json
{
  "action": "execute",
  "command": "uname",
  "operation": "all"
}
```

### Get Distribution Information

```json
{
  "action": "execute",
  "command": "lsb_release",
  "operation": "all"
}
```

### Read /proc Entry

```json
{
  "action": "execute",
  "command": "proc",
  "operation": "read",
  "args": {
    "path": "/proc/meminfo"
  }
}
```

### Get System Hostname

```json
{
  "action": "execute",
  "command": "hostnamectl",
  "operation": "status"
}
```

## Service Management (systemctl)

### Check Service Status

```json
{
  "action": "execute",
  "command": "systemctl",
  "operation": "status",
  "args": {
    "service": "nginx"
  }
}
```

### Start Service

```json
{
  "action": "execute",
  "command": "systemctl",
  "operation": "start",
  "args": {
    "service": "nginx"
  },
  "sudo": true
}
```

### Stop Service

```json
{
  "action": "execute",
  "command": "systemctl",
  "operation": "stop",
  "args": {
    "service": "nginx"
  },
  "sudo": true
}
```

### Restart Service

```json
{
  "action": "execute",
  "command": "systemctl",
  "operation": "restart",
  "args": {
    "service": "nginx"
  },
  "sudo": true
}
```

### Enable Service (Auto-start)

```json
{
  "action": "execute",
  "command": "systemctl",
  "operation": "enable",
  "args": {
    "service": "nginx"
  },
  "sudo": true
}
```

### Disable Service

```json
{
  "action": "execute",
  "command": "systemctl",
  "operation": "disable",
  "args": {
    "service": "nginx"
  },
  "sudo": true
}
```

### List All Services

```json
{
  "action": "execute",
  "command": "systemctl",
  "operation": "list-units",
  "args": {
    "type": "service"
  }
}
```

## Package Management

### APT (Debian/Ubuntu)

#### Update Package Lists

```json
{
  "action": "execute",
  "command": "apt",
  "operation": "update",
  "sudo": true
}
```

#### Install Package

```json
{
  "action": "execute",
  "command": "apt",
  "operation": "install",
  "args": {
    "packages": ["nginx", "curl"],
    "assumeYes": true
  },
  "sudo": true
}
```

#### Remove Package

```json
{
  "action": "execute",
  "command": "apt",
  "operation": "remove",
  "args": {
    "package": "nginx",
    "purge": false
  },
  "sudo": true
}
```

#### Search Packages

```json
{
  "action": "execute",
  "command": "apt",
  "operation": "search",
  "args": {
    "query": "python3"
  }
}
```

#### List Installed Packages

```json
{
  "action": "execute",
  "command": "apt",
  "operation": "list",
  "args": {
    "installed": true
  }
}
```

### DNF/YUM (Fedora/RHEL)

#### Install Package

```json
{
  "action": "execute",
  "command": "dnf",
  "operation": "install",
  "args": {
    "packages": ["nginx"],
    "assumeYes": true
  },
  "sudo": true
}
```

#### Update System

```json
{
  "action": "execute",
  "command": "dnf",
  "operation": "upgrade",
  "args": {
    "assumeYes": true
  },
  "sudo": true
}
```

### Pacman (Arch Linux)

#### Install Package

```json
{
  "action": "execute",
  "command": "pacman",
  "operation": "install",
  "args": {
    "packages": ["nginx"],
    "noConfirm": true
  },
  "sudo": true
}
```

#### Update System

```json
{
  "action": "execute",
  "command": "pacman",
  "operation": "upgrade",
  "args": {
    "sysUpgrade": true
  },
  "sudo": true
}
```

## Performance Monitoring

### Memory Usage

```json
{
  "action": "execute",
  "command": "free",
  "operation": "info",
  "args": {
    "human": true
  }
}
```

### Disk Usage

```json
{
  "action": "execute",
  "command": "df",
  "operation": "info",
  "args": {
    "human": true,
    "type": "ext4"
  }
}
```

### Process List

```json
{
  "action": "execute",
  "command": "top",
  "operation": "batch",
  "args": {
    "iterations": 1,
    "sortBy": "cpu"
  }
}
```

### Virtual Memory Stats

```json
{
  "action": "execute",
  "command": "vmstat",
  "operation": "info",
  "args": {
    "interval": 1,
    "count": 5
  }
}
```

### I/O Statistics

```json
{
  "action": "execute",
  "command": "iostat",
  "operation": "info",
  "args": {
    "extended": true,
    "interval": 1,
    "count": 5
  }
}
```

## Log Analysis

### Query Systemd Journal

```json
{
  "action": "execute",
  "command": "journalctl",
  "operation": "query",
  "args": {
    "unit": "nginx",
    "since": "1 hour ago",
    "lines": 100
  }
}
```

### Follow Logs

```json
{
  "action": "execute",
  "command": "journalctl",
  "operation": "follow",
  "args": {
    "unit": "nginx"
  }
}
```

### View Kernel Messages

```json
{
  "action": "execute",
  "command": "dmesg",
  "operation": "read",
  "args": {
    "level": "err",
    "human": true
  }
}
```

## System Configuration

### Get Kernel Parameter

```json
{
  "action": "execute",
  "command": "sysctl",
  "operation": "get",
  "args": {
    "parameter": "net.ipv4.ip_forward"
  }
}
```

### Set Kernel Parameter

```json
{
  "action": "execute",
  "command": "sysctl",
  "operation": "set",
  "args": {
    "parameter": "net.ipv4.ip_forward",
    "value": "1"
  },
  "sudo": true
}
```

### List All Kernel Parameters

```json
{
  "action": "execute",
  "command": "sysctl",
  "operation": "list-all"
}
```

### Set Hostname

```json
{
  "action": "execute",
  "command": "hostnamectl",
  "operation": "set-hostname",
  "args": {
    "hostname": "myserver"
  },
  "sudo": true
}
```

### Set Timezone

```json
{
  "action": "execute",
  "command": "timedatectl",
  "operation": "set-timezone",
  "args": {
    "timezone": "America/New_York"
  },
  "sudo": true
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "command": "systemctl",
    "operation": "status",
    "exitCode": 0,
    "duration": "0.1s",
    "status": "success",
    "stdout": "● nginx.service - A high performance web server\n   Loaded: loaded...",
    "metadata": {
      "service": "nginx",
      "active": true,
      "enabled": true,
      "state": "running",
      "pid": 1234,
      "uptime": "2 days"
    }
  }
}
```

### Service Status Result

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "command": "systemctl",
    "operation": "status",
    "args": {
      "service": "nginx"
    },
    "exitCode": 0,
    "duration": "0.08s",
    "status": "success",
    "stdout": "● nginx.service - A high performance web server...",
    "metadata": {
      "service": "nginx.service",
      "loaded": true,
      "active": "active",
      "state": "running",
      "enabled": true,
      "pid": 1234,
      "memory": "12.3M",
      "uptime": "2 days 5 hours"
    }
  }
}
```

### System Information Result

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:31:00Z",
    "command": "uname",
    "operation": "all",
    "exitCode": 0,
    "duration": "0.02s",
    "status": "success",
    "metadata": {
      "kernel": "Linux",
      "hostname": "myserver",
      "kernelRelease": "6.5.0-14-generic",
      "kernelVersion": "#14-Ubuntu SMP PREEMPT_DYNAMIC Mon Nov 20 18:15:30 UTC 2023",
      "machine": "x86_64",
      "processor": "x86_64",
      "platform": "GNU/Linux",
      "os": "Linux"
    }
  }
}
```

### Memory Usage Result

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:32:00Z",
    "command": "free",
    "operation": "info",
    "exitCode": 0,
    "duration": "0.01s",
    "status": "success",
    "metadata": {
      "total": "16Gi",
      "used": "8.2Gi",
      "free": "2.1Gi",
      "shared": "524Mi",
      "buffCache": "5.7Gi",
      "available": "7.8Gi",
      "usedPercent": 51.2,
      "swap": {
        "total": "8Gi",
        "used": "0B",
        "free": "8Gi"
      }
    }
  }
}
```

### Package Installation Result

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:33:00Z",
    "command": "apt",
    "operation": "install",
    "args": {
      "packages": ["nginx"]
    },
    "exitCode": 0,
    "duration": "23.5s",
    "status": "success",
    "stdout": "Reading package lists...\nBuilding dependency tree...",
    "metadata": {
      "packagesInstalled": ["nginx", "nginx-common", "nginx-core"],
      "newPackages": 3,
      "upgradedPackages": 0,
      "diskSpaceUsed": "1,234 kB"
    }
  }
}
```

## Error Handling

Returns structured error information for:

- **Permission denied**: Insufficient privileges
- **Service not found**: Unknown service name
- **Package not found**: Unknown package name
- **Command not found**: Tool not installed
- **Network error**: Cannot reach package repositories
- **Dependency error**: Missing or conflicting dependencies
- **Configuration error**: Invalid sysctl parameter or value

Example error response:

```json
{
  "error": {
    "type": "permission-denied",
    "command": "systemctl",
    "operation": "start",
    "service": "nginx",
    "message": "Failed to start nginx.service: Access denied",
    "exitCode": 1,
    "solution": "Run with sudo: Set sudo=true in request"
  }
}
```

### Service Not Found

```json
{
  "error": {
    "type": "service-not-found",
    "command": "systemctl",
    "operation": "status",
    "service": "nonexistent",
    "message": "Unit nonexistent.service could not be found",
    "exitCode": 4,
    "solution": "List available services: systemctl list-units --type=service"
  }
}
```

### Package Not Found

```json
{
  "error": {
    "type": "package-not-found",
    "command": "apt",
    "operation": "install",
    "package": "nonexistent-package",
    "message": "Unable to locate package nonexistent-package",
    "exitCode": 100,
    "solution": "Search for package: apt search <package-name>"
  }
}
```

### Network Error

```json
{
  "error": {
    "type": "network-error",
    "command": "apt",
    "operation": "update",
    "message": "Failed to fetch http://archive.ubuntu.com/ubuntu/dists/jammy/InRelease",
    "exitCode": 100,
    "solution": "Check network connectivity and repository URLs in /etc/apt/sources.list"
  }
}
```

## Distribution Detection

### Automatic Detection

The skill auto-detects the Linux distribution and uses appropriate commands:

- **Debian/Ubuntu**: apt, systemctl
- **RHEL/CentOS/Fedora**: dnf/yum, systemctl
- **Arch Linux**: pacman, systemctl
- **openSUSE**: zypper, systemctl

Detection based on:
- `/etc/os-release`
- `/etc/lsb-release`
- `/etc/redhat-release`

## Tool Requirements

### Pre-installed (Most Distributions)
- systemctl, journalctl (systemd-based)
- uname, free, df, top, vmstat
- /proc, /sys filesystems

### Distribution Package Managers
- **apt**: Debian, Ubuntu, Linux Mint
- **dnf**: Fedora 22+, RHEL 8+
- **yum**: RHEL 7, CentOS 7
- **pacman**: Arch Linux, Manjaro
- **zypper**: openSUSE, SUSE Linux

### Optional Tools
- htop: `apt install htop` / `dnf install htop`
- iostat: `apt install sysstat` / `dnf install sysstat`
- sar: Included in sysstat package

## Constraints

This skill does NOT:
- Diagnose system issues or provide troubleshooting guidance
- Write or port code using Linux APIs
- Make architectural decisions
- Recommend configuration changes
- Explain kernel internals or system concepts
- Analyze performance bottlenecks (returns data only)
- Design security policies (SELinux, AppArmor)
- Interpret log entries
- Choose between distributions or packages

## Common Linux Workflows

### Check Service Status and Restart

```json
{
  "action": "execute",
  "command": "systemctl",
  "operation": "status",
  "args": {
    "service": "nginx"
  }
}
```

Then:
```json
{
  "action": "execute",
  "command": "systemctl",
  "operation": "restart",
  "args": {
    "service": "nginx"
  },
  "sudo": true
}
```

### Install Package and Enable Service

```json
{
  "action": "execute",
  "command": "apt",
  "operation": "install",
  "args": {
    "packages": ["postgresql"],
    "assumeYes": true
  },
  "sudo": true
}
```

Then:
```json
{
  "action": "execute",
  "command": "systemctl",
  "operation": "enable",
  "args": {
    "service": "postgresql"
  },
  "sudo": true
}
```

### Check Memory and Disk Usage

```json
{
  "action": "execute",
  "command": "free",
  "operation": "info",
  "args": {
    "human": true
  }
}
```

```json
{
  "action": "execute",
  "command": "df",
  "operation": "info",
  "args": {
    "human": true
  }
}
```

### View Recent System Logs

```json
{
  "action": "execute",
  "command": "journalctl",
  "operation": "query",
  "args": {
    "since": "1 hour ago",
    "priority": "err",
    "lines": 50
  }
}
```

### Set Kernel Parameter

```json
{
  "action": "execute",
  "command": "sysctl",
  "operation": "set",
  "args": {
    "parameter": "vm.swappiness",
    "value": "10"
  },
  "sudo": true
}
```
