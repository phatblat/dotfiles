# Harness CI Runner Setup for Mac mini

This document describes how to set up a self-hosted Harness CI runner on your Mac mini.

## Prerequisites

- Docker Desktop for Mac installed and running
- Harness account with CI module enabled
- Mac mini running macOS with ARM64 (Apple Silicon)

## Step 1: Get Harness Account Details

1. Log into [app.harness.io](https://app.harness.io)
2. Navigate to **Account Settings** → **Account Resources** → **Delegates**
3. Note your **Account ID** (visible in the URL or account settings)
4. Click **New Delegate** to get a delegate token

## Step 2: Install Harness Delegate

The delegate handles communication between Harness and your Mac mini.

```bash
# Create a directory for harness
mkdir -p ~/.harness/runner
cd ~/.harness/runner

# Run the delegate container
docker run -d \
  --name harness-delegate \
  --restart unless-stopped \
  --net=host \
  -e DELEGATE_NAME=mac-mini-delegate \
  -e DELEGATE_TAGS="macos-arm64,dotfiles" \
  -e NEXT_GEN=true \
  -e ACCOUNT_ID=<YOUR_ACCOUNT_ID> \
  -e DELEGATE_TOKEN=<YOUR_DELEGATE_TOKEN> \
  -e MANAGER_HOST_AND_PORT=https://app.harness.io \
  -e LOG_STREAMING_SERVICE_URL=https://app.harness.io/log-service/ \
  harness/delegate:latest
```

Replace:
- `<YOUR_ACCOUNT_ID>` with your Harness account ID
- `<YOUR_DELEGATE_TOKEN>` with the token from the Harness UI

## Step 3: Install Harness Docker Runner

The runner executes the actual CI build steps.

```bash
cd ~/.harness/runner

# Download the runner for macOS ARM64
curl -L -o harness-docker-runner \
  https://github.com/harness/harness-docker-runner/releases/latest/download/harness-docker-runner-darwin-arm64

# Make it executable
chmod +x harness-docker-runner

# Start the runner (runs on port 3000)
./harness-docker-runner server &
```

## Step 4: Configure Runner as Launch Agent (Optional)

To auto-start the runner on boot:

```bash
# Create launchd plist
cat > ~/Library/LaunchAgents/io.harness.docker-runner.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>io.harness.docker-runner</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/phatblat/.harness/runner/harness-docker-runner</string>
        <string>server</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/phatblat/.harness/runner/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/phatblat/.harness/runner/stderr.log</string>
    <key>WorkingDirectory</key>
    <string>/Users/phatblat/.harness/runner</string>
</dict>
</plist>
EOF

# Load the launch agent
launchctl load ~/Library/LaunchAgents/io.harness.docker-runner.plist
```

## Step 5: Verify Setup

1. Check delegate status in Harness UI:
   - Go to **Account Settings** → **Delegates**
   - Your `mac-mini-delegate` should show as **Connected**

2. Check runner is running:
   ```bash
   curl http://localhost:3000/healthz
   ```

3. Check delegate container:
   ```bash
   docker logs harness-delegate
   ```

## Step 6: Configure Harness Secrets

Add these secrets in Harness UI (**Project Settings** → **Secrets**):

| Secret Name | Description |
|-------------|-------------|
| `CACHIX_AUTH_TOKEN` | Auth token for pushing to Cachix |

Get your Cachix token from [cachix.org](https://cachix.org) → Settings → Auth Tokens.

## Step 7: Set Up GitHub Connector

1. In Harness, go to **Project Settings** → **Connectors**
2. Create a new GitHub connector named `github_phatblat`
3. Configure with your GitHub credentials or personal access token
4. Test the connection

## Step 8: Import Pipeline

1. Go to **CI** → **Pipelines** → **Create Pipeline**
2. Choose **Import from Git**
3. Select the `~/.harness/ci.yaml` file
4. Or manually create and paste the YAML content

## Troubleshooting

### Delegate not connecting

```bash
# Check delegate logs
docker logs harness-delegate

# Restart delegate
docker restart harness-delegate
```

### Runner not responding

```bash
# Check if runner is running
pgrep -f harness-docker-runner

# Restart runner
pkill -f harness-docker-runner
~/.harness/runner/harness-docker-runner server &
```

### Docker not available in CI

Ensure Docker Desktop is running and the delegate has access:

```bash
docker info
```

## File Locations

| File | Purpose |
|------|---------|
| `~/.harness/ci.yaml` | Main CI pipeline definition |
| `~/.harness/pipelines/*.yaml` | Individual pipeline components |
| `~/.harness/runner/` | Runner binary and logs |
| `~/Library/LaunchAgents/io.harness.docker-runner.plist` | Launch agent config |
