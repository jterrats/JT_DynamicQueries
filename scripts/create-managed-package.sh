#!/bin/bash

# Script to create a Managed Package for AppExchange
# This requires a registered namespace

set -e

NAMESPACE="${1:-}"

if [ -z "$NAMESPACE" ]; then
    echo "❌ Error: Namespace is required for Managed Package"
    echo ""
    echo "Usage: $0 <namespace>"
    echo "Example: $0 JTDynamicQueries"
    echo ""
    echo "⚠️  IMPORTANT: Namespace must be registered first!"
    echo "   1. Setup → Package Manager → Namespace Registry"
    echo "   2. Register your namespace (e.g., JTDynamicQueries)"
    echo "   3. Wait for approval (1-3 business days)"
    echo ""
    exit 1
fi

echo "========================================="
echo "JT Dynamic Queries - Managed Package Creator"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo ""

# Check if SF CLI is installed
if ! command -v sf &> /dev/null; then
    echo "❌ Error: Salesforce CLI (sf) is not installed"
    exit 1
fi

echo "✓ Salesforce CLI found"
echo ""

# Check if user is authenticated to a DevHub
if ! sf org display --json &> /dev/null; then
    echo "❌ Error: No default org found"
    echo "Please authenticate to a DevHub org:"
    echo "  sf org login web --alias devhub --set-default"
    exit 1
fi

ORG_INFO=$(sf org display --json)
ORG_TYPE=$(echo $ORG_INFO | grep -o '"instanceType":"[^"]*' | cut -d'"' -f4)

if [ "$ORG_TYPE" != "Developer Edition" ] && [ "$ORG_TYPE" != "Production" ]; then
    echo "⚠️  Warning: Managed Packages require a DevHub org"
    echo "   Current org type: $ORG_TYPE"
    exit 1
fi

ORG_USERNAME=$(echo $ORG_INFO | grep -o '"username":"[^"]*' | cut -d'"' -f4)
echo "✓ Authenticated as: $ORG_USERNAME"
echo ""

# Verify namespace is set in sfdx-project.json
CURRENT_NS=$(grep '"namespace"' sfdx-project.json | cut -d'"' -f4)
if [ "$CURRENT_NS" != "$NAMESPACE" ]; then
    echo "⚠️  Warning: Namespace in sfdx-project.json is '$CURRENT_NS'"
    echo "   Expected: '$NAMESPACE'"
    echo ""
    echo "Run migration script first:"
    echo "  ./scripts/migrate-to-namespace.sh $NAMESPACE"
    exit 1
fi

echo "✓ Namespace verified in sfdx-project.json"
echo ""

# Get package alias or create new package
PACKAGE_NAME="JT_DynamicQueries"
PACKAGE_ALIAS=$(grep -A 2 "packageAliases" sfdx-project.json | grep "$PACKAGE_NAME" | cut -d'"' -f4 || echo "")

if [ -z "$PACKAGE_ALIAS" ] || [ "$PACKAGE_ALIAS" == "0Ho..." ]; then
    echo "📦 Creating new Managed Package: $PACKAGE_NAME"
    echo ""

    PACKAGE_RESULT=$(sf package create \
        --name "$PACKAGE_NAME" \
        --description "Dynamic Query Framework - Metadata-driven SOQL execution framework with built-in security, batch processing, and risk assessment" \
        --type Managed \
        --namespace "$NAMESPACE" \
        --json 2>&1)

    if [ $? -eq 0 ]; then
        PACKAGE_ID=$(echo $PACKAGE_RESULT | grep -o '"Id":"[^"]*' | cut -d'"' -f4)
        echo "✓ Managed Package created successfully"
        echo "  Package ID: $PACKAGE_ID"
        echo ""
        echo "⚠️  IMPORTANT: Update sfdx-project.json with this Package ID:"
        echo "  \"packageAliases\": {"
        echo "    \"JT_DynamicQueries\": \"$PACKAGE_ID\""
        echo "  }"
        echo ""
    else
        echo "❌ Failed to create Managed Package"
        echo "$PACKAGE_RESULT"
        exit 1
    fi
else
    echo "✓ Using existing package: $PACKAGE_NAME ($PACKAGE_ALIAS)"
    echo ""
fi

# Get version number
VERSION_NUMBER=$(grep "versionNumber" sfdx-project.json | cut -d'"' -f4 | cut -d'.' -f1-3)
VERSION_NAME=$(grep "versionName" sfdx-project.json | cut -d'"' -f4)

if [ -z "$VERSION_NUMBER" ]; then
    VERSION_NUMBER="2.5.0"
fi

if [ -z "$VERSION_NAME" ]; then
    VERSION_NAME="ver $VERSION_NUMBER"
fi

echo "📦 Creating Managed Package version..."
echo "   Version: $VERSION_NUMBER"
echo "   Name: $VERSION_NAME"
echo "   Type: Managed (for AppExchange)"
echo ""

# Create package version
VERSION_RESULT=$(sf package version create \
    --package "$PACKAGE_NAME" \
    --installation-key-bypass \
    --wait 10 \
    --code-coverage \
    --json 2>&1)

if [ $? -eq 0 ]; then
    VERSION_ID=$(echo $VERSION_RESULT | grep -o '"SubscriberPackageVersionId":"[^"]*' | cut -d'"' -f4)
    STATUS=$(echo $VERSION_RESULT | grep -o '"Status":"[^"]*' | cut -d'"' -f4)

    echo "✓ Managed Package version created successfully"
    echo "  Version ID: $VERSION_ID"
    echo "  Status: $STATUS"
    echo ""

    if [ "$STATUS" == "Success" ]; then
        echo "========================================="
        echo "✅ Managed Package Ready for AppExchange!"
        echo "========================================="
        echo ""
        echo "📋 Next Steps:"
        echo ""
        echo "1. Security Review:"
        echo "   - Submit to AppExchange Partner Portal"
        echo "   - Complete Security Questionnaire"
        echo "   - Upload documentation"
        echo ""
        echo "2. AppExchange Listing:"
        echo "   - Create listing in Partner Portal"
        echo "   - Add screenshots/videos"
        echo "   - Write description"
        echo ""
        echo "3. Installation URL:"
        echo "   https://login.salesforce.com/packaging/installPackage.apexp?p0=$VERSION_ID"
        echo ""
        echo "📚 Documentation:"
        echo "   - See docs/APPEXCHANGE_PREPARATION.md"
        echo "   - See docs/deprecated/APPEXCHANGE_READINESS.md"
        echo ""
    else
        echo "⚠️  Package version status: $STATUS"
        echo "   Check the output above for details"
    fi
else
    echo "❌ Failed to create Managed Package version"
    echo "$VERSION_RESULT"
    exit 1
fi

