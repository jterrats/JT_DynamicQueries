#!/bin/bash
# Smart Deploy: Auto-detecta cambios en target-org y actualiza Named Credential

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Smart Deploy - Named Credentials"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get current target org
CURRENT_ORG="${1:-$(sf config get target-org --json | jq -r '.result[0].value')}"

if [ -z "$CURRENT_ORG" ] || [ "$CURRENT_ORG" == "null" ]; then
    echo "❌ No target org found"
    exit 1
fi

echo "📍 Current Target Org: $CURRENT_ORG"

# Get current org URL
CURRENT_URL=$(sf org display --target-org "$CURRENT_ORG" --json | jq -r '.result.instanceUrl')

if [ -z "$CURRENT_URL" ] || [ "$CURRENT_URL" == "null" ]; then
    echo "❌ Failed to get org URL"
    exit 1
fi

echo "🌐 Current Org URL: $CURRENT_URL"

# Check if .env exists and load it
if [ -f .env ]; then
    source .env
    CACHED_URL="$SF_ORG_SQF"
    echo "💾 Cached URL: ${CACHED_URL:-<not set>}"
else
    CACHED_URL=""
    echo "💾 No .env file found"
fi

echo ""

# Compare URLs
if [ "$CURRENT_URL" != "$CACHED_URL" ]; then
    echo "⚠️  Org URL mismatch detected!"
    echo ""
    echo "   Cached: ${CACHED_URL:-<none>}"
    echo "   Current: $CURRENT_URL"
    echo ""
    echo "🔄 Updating environment..."
    
    # Run setup to update .env
    ./scripts/setup-org-url.sh "$CURRENT_ORG"
    
    # Reload .env
    source .env
    
    echo ""
    echo "✅ Environment updated!"
else
    echo "✅ Org URL matches cached value"
    echo "   No update needed"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Deploying Named Credential..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Deploy with replacement
./scripts/deploy-with-replacement.sh "$CURRENT_ORG"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Smart Deploy Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Named Credential configured for: $CURRENT_ORG"
echo "   URL: $CURRENT_URL"

