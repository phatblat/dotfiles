# Docker Executor

Execute Docker and container operations with structured output and safety checks.

## Capability

This skill executes Docker commands, Docker Compose operations, and container lifecycle management. It returns structured results with exit codes, output, and parsed metadata for container operations.

## Supported Operations

### Docker Commands
- **build** - Build container images from Dockerfile
- **run** - Create and start containers
- **ps** - List containers (running, stopped, all)
- **logs** - Fetch container logs
- **exec** - Execute commands in running containers
- **stop** - Stop running containers
- **start** - Start stopped containers
- **restart** - Restart containers
- **rm** - Remove containers
- **images** - List Docker images
- **rmi** - Remove images
- **pull** - Pull images from registry
- **push** - Push images to registry
- **network** - Manage Docker networks
- **volume** - Manage Docker volumes
- **inspect** - Inspect containers, images, networks, volumes
- **stats** - Display resource usage statistics

### Docker Compose Commands
- **up** - Create and start services
- **down** - Stop and remove services
- **ps** - List services
- **logs** - View service logs
- **exec** - Execute command in service container
- **build** - Build service images
- **restart** - Restart services

## Usage Protocol

Agents invoke this skill by specifying operation parameters:

```json
{
  "action": "docker",
  "command": "build",
  "args": {
    "dockerfile": "Dockerfile",
    "context": ".",
    "tag": "myapp:latest",
    "buildArgs": {"VERSION": "1.0"}
  }
}
```

### Parameters

- **action** (required): Either `"docker"` or `"compose"`
- **command** (required): Docker/compose command to execute
- **args** (required): Command-specific arguments (see below)
- **workdir** (optional): Working directory for command execution
- **timeout** (optional): Timeout in seconds (default: 300s)

### Docker Build Args
```json
{
  "dockerfile": "Dockerfile",
  "context": ".",
  "tag": "myapp:latest",
  "target": "production",
  "buildArgs": {"VERSION": "1.0", "ENV": "prod"},
  "noCache": false,
  "platform": "linux/amd64"
}
```

### Docker Run Args
```json
{
  "image": "myapp:latest",
  "name": "myapp-container",
  "detach": true,
  "ports": {"8080": "80", "8443": "443"},
  "volumes": {"/host/data": "/container/data"},
  "env": {"DATABASE_URL": "postgres://..."},
  "network": "mynetwork",
  "restart": "unless-stopped"
}
```

### Docker Exec Args
```json
{
  "container": "myapp-container",
  "command": ["sh", "-c", "ls -la /app"],
  "interactive": false,
  "tty": false,
  "user": "www-data",
  "workdir": "/app"
}
```

### Compose Up Args
```json
{
  "file": "docker-compose.yml",
  "services": ["web", "db"],
  "detach": true,
  "build": false,
  "forceRecreate": false,
  "removeOrphans": true
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "action": "docker",
    "command": "build",
    "workdir": "/path/to/project",
    "exitCode": 0,
    "duration": "45.3s",
    "status": "success",
    "stdout": "...",
    "stderr": "...",
    "metadata": {
      "imageId": "sha256:abc123...",
      "imageTags": ["myapp:latest"],
      "imageSize": "1.2GB"
    }
  }
}
```

### Docker Build Results

```json
{
  "executionReport": {
    "command": "build",
    "exitCode": 0,
    "duration": "45.3s",
    "status": "success",
    "stdout": "Step 1/8 : FROM node:18-alpine\n...",
    "metadata": {
      "imageId": "sha256:abc123def456",
      "imageTags": ["myapp:latest", "myapp:v1.0"],
      "imageSize": "1.2GB",
      "totalLayers": 8,
      "cachedLayers": 5
    }
  }
}
```

### Docker Run Results

```json
{
  "executionReport": {
    "command": "run",
    "exitCode": 0,
    "duration": "2.1s",
    "status": "success",
    "metadata": {
      "containerId": "f3a8bc29e1a2",
      "containerName": "myapp-container",
      "image": "myapp:latest",
      "ports": {
        "80/tcp": [{"HostIp": "0.0.0.0", "HostPort": "8080"}]
      },
      "status": "running"
    }
  }
}
```

### Docker PS Results

```json
{
  "executionReport": {
    "command": "ps",
    "exitCode": 0,
    "duration": "0.3s",
    "status": "success",
    "metadata": {
      "containers": [
        {
          "containerId": "f3a8bc29e1a2",
          "name": "myapp-container",
          "image": "myapp:latest",
          "status": "Up 2 hours",
          "ports": "0.0.0.0:8080->80/tcp",
          "created": "2025-12-14T12:00:00Z"
        },
        {
          "containerId": "a1b2c3d4e5f6",
          "name": "postgres-db",
          "image": "postgres:15",
          "status": "Up 3 hours",
          "ports": "0.0.0.0:5432->5432/tcp",
          "created": "2025-12-14T11:00:00Z"
        }
      ],
      "totalContainers": 2
    }
  }
}
```

### Docker Logs Results

```json
{
  "executionReport": {
    "command": "logs",
    "exitCode": 0,
    "duration": "0.5s",
    "status": "success",
    "stdout": "2025-12-14 14:30:00 INFO Server started on port 80\n...",
    "metadata": {
      "containerId": "f3a8bc29e1a2",
      "containerName": "myapp-container",
      "lineCount": 1247,
      "truncated": false
    }
  }
}
```

### Docker Exec Results

```json
{
  "executionReport": {
    "command": "exec",
    "exitCode": 0,
    "duration": "0.8s",
    "status": "success",
    "stdout": "total 48\ndrwxr-xr-x 1 node node 4096 Dec 14 14:00 .\n...",
    "metadata": {
      "containerId": "f3a8bc29e1a2",
      "command": ["sh", "-c", "ls -la /app"]
    }
  }
}
```

### Docker Images Results

```json
{
  "executionReport": {
    "command": "images",
    "exitCode": 0,
    "duration": "0.4s",
    "status": "success",
    "metadata": {
      "images": [
        {
          "repository": "myapp",
          "tag": "latest",
          "imageId": "sha256:abc123",
          "created": "2025-12-14T14:00:00Z",
          "size": "1.2GB"
        },
        {
          "repository": "postgres",
          "tag": "15",
          "imageId": "sha256:def456",
          "created": "2025-12-10T10:00:00Z",
          "size": "376MB"
        }
      ],
      "totalImages": 2
    }
  }
}
```

### Docker Network Results

```json
{
  "executionReport": {
    "command": "network ls",
    "exitCode": 0,
    "duration": "0.2s",
    "status": "success",
    "metadata": {
      "networks": [
        {
          "networkId": "a1b2c3d4e5f6",
          "name": "bridge",
          "driver": "bridge",
          "scope": "local"
        },
        {
          "networkId": "f6e5d4c3b2a1",
          "name": "myapp-network",
          "driver": "bridge",
          "scope": "local"
        }
      ],
      "totalNetworks": 2
    }
  }
}
```

### Docker Compose Up Results

```json
{
  "executionReport": {
    "command": "up",
    "exitCode": 0,
    "duration": "12.5s",
    "status": "success",
    "stdout": "Creating network myapp_default...\nCreating myapp_db_1...\nCreating myapp_web_1...",
    "metadata": {
      "composeFile": "docker-compose.yml",
      "services": ["web", "db"],
      "containersCreated": 2,
      "networksCreated": 1
    }
  }
}
```

## Safety Checks

The skill enforces safety guardrails:

1. **Destructive Operations Confirmation**:
   - `rm -f` (force remove) requires explicit confirmation
   - `rmi -f` (force remove image) requires explicit confirmation
   - `system prune` requires explicit confirmation

2. **Production Protection**:
   - Warns when stopping/removing containers with `restart: always`
   - Warns when removing images tagged with production labels

3. **Resource Limits**:
   - Build timeout: 15 minutes
   - Log fetch limit: 10,000 lines
   - Container exec timeout: 5 minutes

4. **Validation**:
   - Validates Dockerfile exists before build
   - Validates compose file syntax before operations
   - Checks image exists before run

## Common Docker Operations

### Build Multi-Platform Image
```json
{
  "action": "docker",
  "command": "buildx",
  "args": {
    "platforms": ["linux/amd64", "linux/arm64"],
    "tag": "myapp:latest",
    "push": true
  }
}
```

### Health Check Container
```json
{
  "action": "docker",
  "command": "inspect",
  "args": {
    "container": "myapp-container",
    "format": "{{.State.Health.Status}}"
  }
}
```

### View Resource Usage
```json
{
  "action": "docker",
  "command": "stats",
  "args": {
    "containers": ["myapp-container"],
    "noStream": true
  }
}
```

### Prune Unused Resources
```json
{
  "action": "docker",
  "command": "system prune",
  "args": {
    "all": false,
    "volumes": false,
    "force": true
  }
}
```

## Tool Requirements

- **Docker Engine**: Docker daemon running (version 20.10+)
- **Docker Compose**: For compose operations (version 2.0+)
- **Buildx** (optional): For multi-platform builds
- **Proper permissions**: User in `docker` group or sudo access

## Constraints

This skill does NOT:
- Install or configure Docker daemon
- Modify Dockerfiles or compose files
- Analyze container security vulnerabilities
- Optimize Dockerfile instructions
- Debug application code inside containers
- Manage container orchestration (Kubernetes)
- Interpret application logs
- Fix container networking issues

## Error Handling

Returns structured error information for:

- **Docker daemon not running**: Connection refused errors
- **Permission denied**: User not in docker group
- **Image not found**: Pull required before run
- **Port conflicts**: Port already allocated
- **Resource exhausted**: Out of disk space, memory
- **Network conflicts**: Network name already exists
- **Build failures**: Dockerfile syntax errors, failed RUN commands
- **Timeout**: Operation exceeded time limit

Example error response:

```json
{
  "error": {
    "type": "docker-daemon-not-running",
    "message": "Cannot connect to Docker daemon. Is docker running?",
    "exitCode": 1,
    "stderr": "Cannot connect to the Docker daemon at unix:///var/run/docker.sock",
    "solution": "Start Docker daemon: sudo systemctl start docker"
  }
}
```

## Common Docker Issues

### Port Already Allocated
```bash
# Error: Bind for 0.0.0.0:8080 failed: port is already allocated
# Solution: Find and stop conflicting container
docker ps --filter "publish=8080"
docker stop <container-id>
```

### Out of Disk Space
```bash
# Error: no space left on device
# Solution: Clean up unused resources
docker system prune -a --volumes
```

### Network Not Found
```bash
# Error: network mynetwork not found
# Solution: Create network before running container
docker network create mynetwork
```

### Image Pull Rate Limit
```bash
# Error: toomanyrequests: You have reached your pull rate limit
# Solution: Authenticate with Docker Hub
docker login
```

### Container Name Conflict
```bash
# Error: Conflict. The container name "/myapp" is already in use
# Solution: Remove existing container first
docker rm myapp
# Or use --rm flag for auto-removal
docker run --rm myapp:latest
```
