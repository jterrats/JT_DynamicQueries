#!/bin/bash

# JT Dynamic Queries - Quick Setup Script
# This script deploys the package and assigns permissions

set -e  # Exit on error

echo "========================================="
echo "JT Dynamic Queries - Setup"
echo "========================================="
echo ""

# Check if SF CLI is installed
if ! command -v sf &> /dev/null; then
    echo "❌ Error: Salesforce CLI (sf) is not installed"
    echo "Please install it from: https://developer.salesforce.com/tools/sfdxcli"
    exit 1
fi

echo "✓ Salesforce CLI found"
echo ""

# Check if user is authenticated
if ! sf org display --json &> /dev/null; then
    echo "❌ Error: No default org found"
    echo "Please authenticate with: sf org login web --set-default"
    exit 1
fi

ORG_USERNAME=$(sf org display --json | grep -o '"username":"[^"]*' | cut -d'"' -f4)
echo "✓ Authenticated as: $ORG_USERNAME"
echo ""

# Deploy the project
echo "📦 Deploying project..."
sf project deploy start --wait 10

if [ $? -eq 0 ]; then
    echo "✓ Deployment successful"
else
    echo "❌ Deployment failed"
    exit 1
fi

echo ""

# Assign permission set
echo "🔐 Assigning permission set..."
sf org assign permset --name JT_Dynamic_Queries

if [ $? -eq 0 ]; then
    echo "✓ Permission set assigned"
else
    echo "⚠️  Warning: Could not assign permission set"
fi

echo ""
echo "========================================="
echo "Setup Complete! 🎉"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Open your org: sf org open"
echo "2. Go to App Launcher → Dynamic Queries"
echo "3. Create query configurations in Setup → Custom Metadata Types"
echo ""
echo "For E2E testing:"
echo "  npm install"
echo "  npx playwright install chromium"
echo "  npm run test:e2e"
echo ""
echo "Documentation:"
echo "  README.md - Main documentation"
echo "  RUN_AS_USER_FEATURE.md - Run As User feature details"
echo "  tests/e2e/README.md - E2E testing guide"
echo ""

