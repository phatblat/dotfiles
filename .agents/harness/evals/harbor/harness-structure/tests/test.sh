#!/bin/bash
set -euo pipefail

cd /app/.agents/harness

# Check required files exist
if [ ! -f README.md ]; then
  echo "✗ Missing README.md"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

if [ ! -f instructions.md ]; then
  echo "✗ Missing instructions.md"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Check required directories exist
for dir in adapters commands agents hooks; do
  if [ ! -d "$dir" ]; then
    echo "✗ Missing $dir/ directory"
    echo 0 > /logs/verifier/reward.txt
    exit 1
  fi
done

# Verify README has inventory information
if ! grep -q "Inventory" README.md; then
  echo "✗ README missing inventory"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

if ! grep -q "Commands:" README.md; then
  echo "✗ README missing commands count"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Verify instructions.md is not empty
if [ ! -s instructions.md ]; then
  echo "✗ instructions.md is empty"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Check that at least one adapter exists
adapter_count=$(find adapters -mindepth 1 -maxdepth 1 -type d | wc -l)
if [ "$adapter_count" -lt 1 ]; then
  echo "✗ No adapters found in adapters/ directory"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

echo "✓ Harness structure is valid"
echo "✓ Found $adapter_count adapter(s)"
echo 1 > /logs/verifier/reward.txt
exit 0
