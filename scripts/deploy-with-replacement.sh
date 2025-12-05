#!/bin/bash
# Deploy with string replacement for Named Credential URL

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Deploy with Named Credential Replacement"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if SF_ORG_SQF is set
if [ -z "$SF_ORG_SQF" ]; then
    echo "⚠️  SF_ORG_SQF not set in environment"
    echo ""
    echo "Running setup script first..."
    echo ""
    source ./scripts/setup-org-url.sh
    source .env
fi

if [ -z "$SF_ORG_SQF" ]; then
    echo "❌ Failed to set SF_ORG_SQF"
    exit 1
fi

echo "🌐 Using Org URL: $SF_ORG_SQF"
echo ""

# Create temporary file with replacement
NC_FILE="force-app/main/default/namedCredentials/JT_Tooling_API.namedCredential-meta.xml"
NC_FILE_TEMP="${NC_FILE}.temp"

echo "🔄 Applying string replacement..."
sed "s|{!\$Credential.JT_Tooling_API}|$SF_ORG_SQF|g" "$NC_FILE" > "$NC_FILE_TEMP"

# Backup original
cp "$NC_FILE" "${NC_FILE}.backup"

# Replace with temp
mv "$NC_FILE_TEMP" "$NC_FILE"

echo "✅ Replacement applied"
echo ""

# Deploy
echo "📦 Deploying to org..."
TARGET_ORG="${1:-$(sf config get target-org --json | jq -r '.result[0].value')}"

sf project deploy start --source-dir force-app/main/default/namedCredentials --target-org "$TARGET_ORG"

DEPLOY_STATUS=$?

# Restore original file
echo ""
echo "🔄 Restoring original file..."
mv "${NC_FILE}.backup" "$NC_FILE"

if [ $DEPLOY_STATUS -eq 0 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Deployment Successful!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 Named Credential configured with:"
    echo "   URL: $SF_ORG_SQF"
else
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ Deployment Failed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi



