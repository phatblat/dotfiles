#!/bin/bash
set -e

# Check required files exist
test -f README.md || { echo "✗ Missing README.md"; exit 1; }
test -f instructions.md || { echo "✗ Missing instructions.md"; exit 1; }

# Check required directories exist
test -d adapters || { echo "✗ Missing adapters/ directory"; exit 1; }
test -d commands || { echo "✗ Missing commands/ directory"; exit 1; }
test -d agents || { echo "✗ Missing agents/ directory"; exit 1; }
test -d hooks || { echo "✗ Missing hooks/ directory"; exit 1; }

# Verify README has inventory information
grep -q "Inventory" README.md || { echo "✗ README missing inventory"; exit 1; }
grep -q "Commands:" README.md || { echo "✗ README missing commands count"; exit 1; }

# Verify instructions.md is not empty
test -s instructions.md || { echo "✗ instructions.md is empty"; exit 1; }

# Check that at least one adapter exists
adapter_count=$(find adapters -mindepth 1 -maxdepth 1 -type d | wc -l)
if [ "$adapter_count" -lt 1 ]; then
  echo "✗ No adapters found in adapters/ directory"
  exit 1
fi

echo "✓ Harness structure is valid"
echo "✓ Found $adapter_count adapter(s)"
exit 0
