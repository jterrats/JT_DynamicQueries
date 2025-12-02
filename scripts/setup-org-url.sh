#!/bin/bash
# Setup script to detect org URL and set SF_ORG_SQF env var

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Setup Named Credential URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get target org from parameter or use default
TARGET_ORG="${1:-$(sf config get target-org --json | jq -r '.result[0].value')}"

if [ -z "$TARGET_ORG" ] || [ "$TARGET_ORG" == "null" ]; then
    echo "❌ No target org found"
    echo ""
    echo "Usage:"
    echo "  ./scripts/setup-org-url.sh [org-alias]"
    echo ""
    echo "Or set default org:"
    echo "  sf config set target-org <username-or-alias>"
    exit 1
fi

echo "📍 Target Org: $TARGET_ORG"

# Get org URL using SF CLI
ORG_URL=$(sf org display --target-org "$TARGET_ORG" --json | jq -r '.result.instanceUrl')

if [ -z "$ORG_URL" ] || [ "$ORG_URL" == "null" ]; then
    echo "❌ Failed to get org URL"
    echo "   Make sure you're authenticated to: $TARGET_ORG"
    exit 1
fi

echo "🌐 Org URL: $ORG_URL"
echo ""

# Export to environment
export SF_ORG_SQF="$ORG_URL"

echo "✅ Environment variable set:"
echo "   SF_ORG_SQF=$SF_ORG_SQF"
echo ""

# Optionally add to .env file for persistence
if [ ! -f .env ]; then
    echo "SF_ORG_SQF=$ORG_URL" > .env
    echo "📝 Created .env file with SF_ORG_SQF"
else
    # Update or append SF_ORG_SQF in .env
    if grep -q "^SF_ORG_SQF=" .env; then
        # Update existing
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|^SF_ORG_SQF=.*|SF_ORG_SQF=$ORG_URL|" .env
        else
            # Linux
            sed -i "s|^SF_ORG_SQF=.*|SF_ORG_SQF=$ORG_URL|" .env
        fi
        echo "📝 Updated SF_ORG_SQF in .env file"
    else
        # Append
        echo "SF_ORG_SQF=$ORG_URL" >> .env
        echo "📝 Added SF_ORG_SQF to .env file"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Next steps:"
echo "   1. Source the environment: source .env"
echo "   2. Deploy with replacement: ./scripts/deploy-with-replacement.sh"
echo ""

