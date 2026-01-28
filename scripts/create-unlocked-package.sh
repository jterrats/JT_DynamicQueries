#!/bin/bash

# Script to create an Unlocked Package for JT Dynamic Queries
# This creates a versioned package that can be installed and updated in Salesforce orgs

set -e

echo "========================================="
echo "JT Dynamic Queries - Unlocked Package Creator"
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

# Check if user is authenticated to a DevHub
if ! sf org display --json &> /dev/null; then
    echo "❌ Error: No default org found"
    echo "Please authenticate to a DevHub org with:"
    echo "  sf org login web --alias devhub --set-default"
    exit 1
fi

ORG_INFO=$(sf org display --json)
ORG_TYPE=$(echo $ORG_INFO | grep -o '"instanceType":"[^"]*' | cut -d'"' -f4)

if [ "$ORG_TYPE" != "Developer Edition" ] && [ "$ORG_TYPE" != "Production" ]; then
    echo "⚠️  Warning: Unlocked Packages require a DevHub org"
    echo "   Current org type: $ORG_TYPE"
    echo "   Please authenticate to a Developer Edition org"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

ORG_USERNAME=$(echo $ORG_INFO | grep -o '"username":"[^"]*' | cut -d'"' -f4)
echo "✓ Authenticated as: $ORG_USERNAME"
echo ""

# Get package alias from sfdx-project.json or create new package
PACKAGE_NAME="JT_DynamicQueries"
PACKAGE_ALIAS=$(grep -A 5 "packageAliases" sfdx-project.json | grep "$PACKAGE_NAME" | cut -d'"' -f4 || echo "")

if [ -z "$PACKAGE_ALIAS" ] || [ "$PACKAGE_ALIAS" == "0Ho..." ]; then
    echo "📦 Creating new Unlocked Package: $PACKAGE_NAME"
    echo ""

    PACKAGE_RESULT=$(sf package create \
        --name "$PACKAGE_NAME" \
        --description "Dynamic Query Framework - Metadata-driven SOQL execution framework with built-in security, batch processing, and risk assessment" \
        --type Unlocked \
        --no-namespace \
        --json)

    if [ $? -eq 0 ]; then
        PACKAGE_ID=$(echo $PACKAGE_RESULT | grep -o '"Id":"[^"]*' | cut -d'"' -f4)
        echo "✓ Package created successfully"
        echo "  Package ID: $PACKAGE_ID"
        echo ""
        echo "⚠️  IMPORTANT: Update sfdx-project.json with this Package ID:"
        echo "  \"packageAliases\": {"
        echo "    \"JT_DynamicQueries\": \"$PACKAGE_ID\""
        echo "  }"
        echo ""
    else
        echo "❌ Failed to create package"
        exit 1
    fi
else
    echo "✓ Using existing package: $PACKAGE_NAME ($PACKAGE_ALIAS)"
    echo ""
fi

# Get version number from sfdx-project.json or use default
VERSION_NUMBER=$(grep "versionNumber" sfdx-project.json | cut -d'"' -f4 | cut -d'.' -f1-3)
VERSION_NAME=$(grep "versionName" sfdx-project.json | cut -d'"' -f4)

if [ -z "$VERSION_NUMBER" ]; then
    VERSION_NUMBER="2.5.0"
fi

if [ -z "$VERSION_NAME" ]; then
    VERSION_NAME="ver $VERSION_NUMBER"
fi

echo "📦 Creating package version..."
echo "   Version: $VERSION_NUMBER"
echo "   Name: $VERSION_NAME"
echo ""

# Create package version
VERSION_RESULT=$(sf package version create \
    --package "$PACKAGE_NAME" \
    --installation-key-bypass \
    --wait 10 \
    --code-coverage \
    --json)

if [ $? -eq 0 ]; then
    VERSION_ID=$(echo $VERSION_RESULT | grep -o '"SubscriberPackageVersionId":"[^"]*' | cut -d'"' -f4)
    STATUS=$(echo $VERSION_RESULT | grep -o '"Status":"[^"]*' | cut -d'"' -f4)

    echo "✓ Package version created successfully"
    echo "  Version ID: $VERSION_ID"
    echo "  Status: $STATUS"
    echo ""

    if [ "$STATUS" == "Success" ]; then
        echo "========================================="
        echo "✅ Package Ready for Installation!"
        echo "========================================="
        echo ""
        echo "Installation URL:"
        echo "  https://login.salesforce.com/packaging/installPackage.apexp?p0=$VERSION_ID"
        echo ""
        echo "Or install via CLI:"
        echo "  sf package install --package $VERSION_ID --wait 10 --target-org <alias>"
        echo ""
        echo "To update sfdx-project.json with the new version:"
        echo "  Update versionNumber to: $VERSION_NUMBER"
        echo ""
    else
        echo "⚠️  Package version status: $STATUS"
        echo "   Check the output above for details"
    fi
else
    echo "❌ Failed to create package version"
    echo "$VERSION_RESULT"
    exit 1
fi

