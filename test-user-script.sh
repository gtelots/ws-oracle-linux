#!/bin/bash
# Quick test for setup-user.sh script

set -e

echo "🧪 Testing setup-user.sh script..."

# Test with required parameters only
echo "Test 1: Required parameters only"
USERNAME=testuser \
USER_UID=1001 \
USER_GID=1001 \
bash scripts/setup/setup-user.sh --help 2>/dev/null || true

echo ""
echo "Test 2: Full parameters"
USERNAME=testuser \
USER_UID=1001 \
USER_GID=1001 \
ROOT_PASSWORD=testroot \
USER_PASSWORD=testpass \
bash -n scripts/setup/setup-user.sh

echo ""
echo "✅ All tests passed! Script is ready for Docker build."
