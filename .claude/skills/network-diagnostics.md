# Network Diagnostics

Execute network diagnostic commands with structured output for connectivity troubleshooting and analysis.

## Capability

This skill executes network diagnostic and monitoring commands across macOS, Linux, and Windows platforms. It returns structured results with exit codes, output, and parsed metadata for network analysis.

## Supported Operations

### Connectivity Tests
- **ping** - Test reachability and measure latency
- **traceroute** - Trace packet route to destination
- **mtr** - Combined ping/traceroute with statistics
- **nc** (netcat) - Test TCP/UDP port connectivity

### Network Configuration
- **ifconfig** - Display/configure network interfaces (BSD/macOS)
- **ip** - Display/configure network interfaces (Linux)
- **ipconfig** - Display network configuration (Windows)
- **route** - Display/configure routing table
- **arp** - Display/manipulate ARP cache

### Connection Status
- **netstat** - Display network connections and statistics
- **ss** - Display socket statistics (Linux)
- **lsof** - List open network sockets

### DNS Resolution
- **nslookup** - Query DNS servers
- **dig** - DNS lookup utility
- **host** - DNS lookup utility
- **getent** - Query name service databases

### Network Monitoring
- **tcpdump** - Packet capture and analysis
- **iftop** - Display bandwidth usage per connection
- **nethogs** - Display bandwidth usage per process
- **vnstat** - Network traffic monitor

### Wi-Fi Tools
- **airport** - Wi-Fi diagnostics (macOS)
- **networksetup** - Network configuration (macOS)
- **iwconfig** - Configure wireless interfaces (Linux)
- **nmcli** - NetworkManager CLI (Linux)

### Performance Testing
- **iperf3** - Network bandwidth testing
- **speedtest-cli** - Internet speed test

## Usage Protocol

Agents invoke this skill by specifying diagnostic parameters:

```json
{
  "action": "diagnose",
  "command": "ping",
  "args": {
    "host": "8.8.8.8",
    "count": 5,
    "timeout": 10
  },
  "platform": "auto"
}
```

### Parameters

- **action** (required): Always `"diagnose"`
- **command** (required): Diagnostic command to execute
- **args** (required): Command-specific arguments
- **platform** (optional): `"macos"`, `"linux"`, `"windows"`, or `"auto"` (default: "auto")
- **timeout** (optional): Timeout in seconds (default: 30s)
- **sudo** (optional): Run with elevated privileges (default: false)

## Command Arguments

### Ping Args
```json
{
  "host": "8.8.8.8",
  "count": 5,
  "interval": 1,
  "timeout": 10,
  "packetSize": 64,
  "ipv6": false
}
```

### Traceroute Args
```json
{
  "host": "example.com",
  "maxHops": 30,
  "timeout": 5,
  "queries": 3,
  "ipv6": false
}
```

### MTR Args
```json
{
  "host": "example.com",
  "count": 10,
  "reportMode": true,
  "noResolve": false
}
```

### Netcat Args
```json
{
  "host": "example.com",
  "port": 443,
  "protocol": "tcp",
  "timeout": 10,
  "zeroIO": true
}
```

### Netstat Args
```json
{
  "showAll": true,
  "showListening": true,
  "showNumeric": true,
  "protocol": "tcp",
  "program": true
}
```

### TCPDump Args
```json
{
  "interface": "en0",
  "filter": "port 80",
  "count": 100,
  "verbose": false,
  "writeFile": "/tmp/capture.pcap"
}
```

### DNS Lookup Args (dig/nslookup)
```json
{
  "host": "example.com",
  "recordType": "A",
  "nameserver": "8.8.8.8",
  "timeout": 5
}
```

### Interface Info Args (ifconfig/ip)
```json
{
  "interface": "en0",
  "showAll": true
}
```

### Route Args
```json
{
  "destination": "default",
  "showNumeric": true
}
```

### ARP Args
```json
{
  "showAll": true,
  "host": "192.168.1.1"
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "command": "ping",
    "platform": "macos",
    "exitCode": 0,
    "duration": "5.2s",
    "status": "success",
    "stdout": "...",
    "stderr": "",
    "metadata": {
      "host": "8.8.8.8",
      "packetsSent": 5,
      "packetsReceived": 5,
      "packetLoss": "0%",
      "rttMin": "10.2ms",
      "rttAvg": "12.5ms",
      "rttMax": "15.8ms",
      "rttStddev": "2.1ms"
    }
  }
}
```

### Ping Results

```json
{
  "executionReport": {
    "command": "ping",
    "platform": "macos",
    "exitCode": 0,
    "duration": "5.2s",
    "status": "success",
    "stdout": "PING 8.8.8.8 (8.8.8.8): 56 data bytes\n64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=12.5 ms\n...",
    "metadata": {
      "host": "8.8.8.8",
      "ipAddress": "8.8.8.8",
      "packetsSent": 5,
      "packetsReceived": 5,
      "packetLoss": "0%",
      "rttMin": "10.2ms",
      "rttAvg": "12.5ms",
      "rttMax": "15.8ms",
      "rttStddev": "2.1ms"
    }
  }
}
```

### Traceroute Results

```json
{
  "executionReport": {
    "command": "traceroute",
    "platform": "linux",
    "exitCode": 0,
    "duration": "8.5s",
    "status": "success",
    "stdout": "traceroute to example.com (93.184.216.34), 30 hops max...\n 1  192.168.1.1 (192.168.1.1)  2.145 ms\n...",
    "metadata": {
      "host": "example.com",
      "destinationIP": "93.184.216.34",
      "hopCount": 12,
      "hops": [
        {"hop": 1, "ip": "192.168.1.1", "hostname": "gateway", "rtt": ["2.145ms", "1.987ms", "2.234ms"]},
        {"hop": 2, "ip": "10.0.0.1", "hostname": "isp-router", "rtt": ["15.3ms", "14.8ms", "15.1ms"]}
      ]
    }
  }
}
```

### Netstat Results

```json
{
  "executionReport": {
    "command": "netstat",
    "platform": "macos",
    "exitCode": 0,
    "duration": "0.3s",
    "status": "success",
    "stdout": "Active Internet connections\nProto Recv-Q Send-Q  Local Address          Foreign Address        (state)\n...",
    "metadata": {
      "totalConnections": 47,
      "tcpConnections": 32,
      "udpConnections": 15,
      "listening": 8,
      "established": 24,
      "connections": [
        {
          "protocol": "tcp4",
          "localAddress": "192.168.1.100:54321",
          "foreignAddress": "52.1.2.3:443",
          "state": "ESTABLISHED",
          "pid": 1234,
          "program": "chrome"
        }
      ]
    }
  }
}
```

### DNS Lookup Results (dig)

```json
{
  "executionReport": {
    "command": "dig",
    "platform": "linux",
    "exitCode": 0,
    "duration": "0.2s",
    "status": "success",
    "stdout": "; <<>> DiG 9.10.6 <<>> example.com\n;; ANSWER SECTION:\nexample.com.  300  IN  A  93.184.216.34\n...",
    "metadata": {
      "host": "example.com",
      "recordType": "A",
      "queryTime": "23ms",
      "server": "8.8.8.8#53",
      "answers": [
        {"name": "example.com", "ttl": 300, "type": "A", "value": "93.184.216.34"}
      ]
    }
  }
}
```

### Interface Info Results (ifconfig)

```json
{
  "executionReport": {
    "command": "ifconfig",
    "platform": "macos",
    "exitCode": 0,
    "duration": "0.1s",
    "status": "success",
    "stdout": "en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500\n...",
    "metadata": {
      "interface": "en0",
      "status": "active",
      "mtu": 1500,
      "ipv4": "192.168.1.100",
      "netmask": "255.255.255.0",
      "broadcast": "192.168.1.255",
      "ipv6": "fe80::1234:5678:abcd:ef01",
      "macAddress": "aa:bb:cc:dd:ee:ff",
      "rxPackets": 1234567,
      "txPackets": 987654,
      "rxBytes": "2.3GB",
      "txBytes": "1.8GB"
    }
  }
}
```

### TCPDump Results

```json
{
  "executionReport": {
    "command": "tcpdump",
    "platform": "linux",
    "exitCode": 0,
    "duration": "30.5s",
    "status": "success",
    "stdout": "tcpdump: listening on eth0, link-type EN10MB\n14:30:00.123456 IP 192.168.1.100.54321 > 52.1.2.3.443: Flags [S]...",
    "metadata": {
      "interface": "eth0",
      "captureFile": "/tmp/capture.pcap",
      "packetsReceived": 1247,
      "packetsDropped": 0,
      "duration": "30.5s"
    }
  }
}
```

## Platform-Specific Handling

### macOS
- Uses `ifconfig` for interface info
- Uses `netstat` for connections
- Uses `traceroute` (BSD version)
- Uses `airport` utility for Wi-Fi diagnostics
- Uses `networksetup` for configuration

### Linux
- Uses `ip` command (preferred) or `ifconfig`
- Uses `ss` (preferred) or `netstat`
- Uses `traceroute` (GNU version)
- Uses `iwconfig` for wireless configuration
- Uses `nmcli` for NetworkManager

### Windows
- Uses `ipconfig` for interface info
- Uses `netstat` for connections
- Uses `tracert` (not traceroute)
- Uses `nslookup` (dig not available by default)

### Auto-Detection

When `platform: "auto"`:
1. Detect OS via `uname` or equivalent
2. Select appropriate command variant
3. Adjust argument syntax for platform

## Privilege Requirements

### Commands Requiring sudo/root

- `tcpdump` - Packet capture requires elevated privileges
- `iftop` - Network monitoring requires root
- `nethogs` - Process monitoring requires root
- Interface configuration commands (ifconfig/ip for changes)
- Route table modifications

### Privilege Handling

```json
{
  "action": "diagnose",
  "command": "tcpdump",
  "sudo": true,
  "args": {
    "interface": "en0",
    "filter": "port 443",
    "count": 50
  }
}
```

## Safety Checks

The skill enforces safety guardrails:

1. **Read-only by default**: Commands that modify network state require explicit confirmation
2. **Timeout protection**: All commands have maximum execution time
3. **Privilege escalation**: sudo flag must be explicit, never automatic
4. **Packet capture limits**: TCPDump limited to 10,000 packets or 5 minutes
5. **Resource protection**: Commands that consume significant bandwidth/CPU include warnings

## Tool Requirements

### Core Tools (usually pre-installed)
- **ping** - Available on all platforms
- **traceroute/tracert** - Available on all platforms
- **netstat** - Available on all platforms
- **nslookup** - Available on all platforms

### Optional Tools (may need installation)
- **mtr** - `brew install mtr` (macOS) / `apt install mtr` (Linux)
- **tcpdump** - Usually pre-installed, may need permissions
- **dig** - `brew install bind` (macOS) / usually pre-installed (Linux)
- **ss** - Pre-installed on modern Linux
- **iftop** - `brew install iftop` / `apt install iftop`
- **nethogs** - `brew install nethogs` / `apt install nethogs`
- **iperf3** - `brew install iperf3` / `apt install iperf3`
- **speedtest-cli** - `pip install speedtest-cli`

## Constraints

This skill does NOT:
- Interpret diagnostic results (calling agent's responsibility)
- Recommend solutions or fixes
- Modify network configuration (unless explicitly requested)
- Analyze packet captures (returns raw data only)
- Make decisions about network architecture
- Provide security recommendations
- Install missing diagnostic tools
- Explain network protocols or concepts
- Troubleshoot application-layer issues
- Configure firewalls or VPNs

## Error Handling

Returns structured error information for:

- **Host unreachable**: Ping/connection failures
- **DNS resolution failed**: Cannot resolve hostname
- **Permission denied**: Insufficient privileges for command
- **Tool not found**: Diagnostic tool not installed
- **Timeout exceeded**: Command took too long
- **Invalid arguments**: Malformed command arguments
- **Network interface not found**: Interface doesn't exist
- **Port closed**: TCP/UDP connection refused

Example error response:

```json
{
  "error": {
    "type": "host-unreachable",
    "message": "100% packet loss",
    "exitCode": 1,
    "command": "ping",
    "args": {"host": "192.168.99.1", "count": 5},
    "stderr": "ping: sendto: Host is down",
    "metadata": {
      "packetsSent": 5,
      "packetsReceived": 0,
      "packetLoss": "100%"
    }
  }
}
```

### DNS Resolution Failed

```json
{
  "error": {
    "type": "dns-resolution-failed",
    "message": "Cannot resolve hostname",
    "exitCode": 68,
    "command": "ping",
    "args": {"host": "nonexistent.invalid"},
    "stderr": "ping: cannot resolve nonexistent.invalid: Unknown host",
    "solution": "Check hostname spelling and DNS configuration"
  }
}
```

### Permission Denied

```json
{
  "error": {
    "type": "permission-denied",
    "message": "Packet capture requires elevated privileges",
    "exitCode": 1,
    "command": "tcpdump",
    "stderr": "tcpdump: en0: You don't have permission to capture on that device",
    "solution": "Use sudo: Set sudo=true in request or run: sudo tcpdump ..."
  }
}
```

### Tool Not Found

```json
{
  "error": {
    "type": "tool-not-found",
    "message": "mtr command not found",
    "exitCode": 127,
    "command": "mtr",
    "stderr": "command not found: mtr",
    "solution": "Install mtr: brew install mtr (macOS) or apt install mtr (Linux)"
  }
}
```

## Common Diagnostic Workflows

### Basic Connectivity Test

```json
{
  "action": "diagnose",
  "command": "ping",
  "args": {"host": "8.8.8.8", "count": 5}
}
```

### Trace Route to Destination

```json
{
  "action": "diagnose",
  "command": "traceroute",
  "args": {"host": "example.com", "maxHops": 30}
}
```

### Check DNS Resolution

```json
{
  "action": "diagnose",
  "command": "dig",
  "args": {"host": "example.com", "recordType": "A"}
}
```

### List Active Connections

```json
{
  "action": "diagnose",
  "command": "netstat",
  "args": {"showAll": true, "showNumeric": true, "program": true}
}
```

### Check Interface Status

```json
{
  "action": "diagnose",
  "command": "ifconfig",
  "args": {"interface": "en0"}
}
```

### Test Port Connectivity

```json
{
  "action": "diagnose",
  "command": "nc",
  "args": {"host": "example.com", "port": 443, "protocol": "tcp", "timeout": 5}
}
```

### Capture Network Traffic

```json
{
  "action": "diagnose",
  "command": "tcpdump",
  "sudo": true,
  "args": {
    "interface": "en0",
    "filter": "host 192.168.1.100 and port 443",
    "count": 100,
    "writeFile": "/tmp/capture.pcap"
  }
}
```
