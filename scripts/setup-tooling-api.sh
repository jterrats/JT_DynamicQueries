#!/bin/bash

# =============================================================================
# JT Dynamic Queries - Tooling API Setup Script
# =============================================================================
# This script automates the creation of Named Credentials for Tooling API
# Prerequisites: Salesforce CLI installed and authenticated to target org
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONNECTED_APP_NAME="JT_Dynamic_Queries_Tooling_API"
EXTERNAL_CRED_NAME="JT_Tooling_API_External"
NAMED_CRED_NAME="JT_Tooling_API"
PRINCIPAL_NAME="Tooling_API_Principal"

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  JT Dynamic Queries - Tooling API Setup${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if SF CLI is installed
if ! command -v sf &> /dev/null; then
    echo -e "${RED}❌ Error: Salesforce CLI not found${NC}"
    echo "Please install it from: https://developer.salesforce.com/tools/salesforcecli"
    exit 1
fi

echo -e "${GREEN}✅ Salesforce CLI found${NC}"

# Check if user is authenticated
if ! sf org display --json &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not authenticated to any org${NC}"
    echo "Please run: sf org login web --alias myorg --set-default"
    exit 1
fi

# Get current org info
ORG_INFO=$(sf org display --json)
ORG_ID=$(echo $ORG_INFO | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
ORG_USERNAME=$(echo $ORG_INFO | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
INSTANCE_URL=$(echo $ORG_INFO | grep -o '"instanceUrl":"[^"]*"' | cut -d'"' -f4)

echo -e "${GREEN}✅ Authenticated as: ${YELLOW}${ORG_USERNAME}${NC}"
echo -e "${GREEN}✅ Org ID: ${YELLOW}${ORG_ID}${NC}"
echo -e "${GREEN}✅ Instance URL: ${YELLOW}${INSTANCE_URL}${NC}"
echo ""

# Warning
echo -e "${YELLOW}⚠️  This script will create:${NC}"
echo "   1. Connected App: ${CONNECTED_APP_NAME}"
echo "   2. External Credential: ${EXTERNAL_CRED_NAME}"
echo "   3. Named Credential: ${NAMED_CRED_NAME}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Setup cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
echo -e "${BLUE}Step 1: Creating Connected App${NC}"
echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"

# Create Connected App metadata
mkdir -p force-app/main/default/connectedApps

cat > force-app/main/default/connectedApps/${CONNECTED_APP_NAME}.connectedApp-meta.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<ConnectedApp xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>${CONNECTED_APP_NAME}</label>
    <contactEmail>${ORG_USERNAME}</contactEmail>
    <oauthConfig>
        <callbackUrl>https://login.salesforce.com/services/oauth2/callback</callbackUrl>
        <consumerKey><!-- Will be auto-generated --></consumerKey>
        <isAdminApproved>false</isAdminApproved>
        <isConsumerSecretOptional>true</isConsumerSecretOptional>
        <scopes>Api</scopes>
        <scopes>RefreshToken</scopes>
        <scopes>Full</scopes>
    </oauthConfig>
</ConnectedApp>
EOF

echo -e "${YELLOW}⏳ Deploying Connected App...${NC}"
sf project deploy start --source-dir force-app/main/default/connectedApps --wait 10 > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Connected App created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create Connected App${NC}"
    echo -e "${YELLOW}Please create it manually following the guide in docs/TOOLING_API_SETUP.md${NC}"
    exit 1
fi

# Get Consumer Key (requires querying ConnectedApplication)
echo -e "${YELLOW}⏳ Retrieving Consumer Key...${NC}"
sleep 5  # Wait for metadata to propagate

CONSUMER_KEY=$(sf data query --query "SELECT ConsumerKey FROM ConnectedApplication WHERE Name='${CONNECTED_APP_NAME}' LIMIT 1" --json | grep -o '"ConsumerKey":"[^"]*"' | cut -d'"' -f4)

if [ -z "$CONSUMER_KEY" ]; then
    echo -e "${YELLOW}⚠️  Could not retrieve Consumer Key automatically${NC}"
    echo -e "${YELLOW}Please retrieve it manually from Setup → App Manager → ${CONNECTED_APP_NAME}${NC}"
    echo ""
    read -p "Enter Consumer Key: " CONSUMER_KEY
fi

echo -e "${GREEN}✅ Consumer Key: ${CONSUMER_KEY:0:20}...${NC}"

echo ""
echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
echo -e "${BLUE}Step 2: Creating External Credential${NC}"
echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"

# Note: External Credentials cannot be fully automated via metadata API
# They require manual authentication step

echo -e "${YELLOW}⚠️  External Credentials require manual setup${NC}"
echo ""
echo "Please follow these steps:"
echo ""
echo "1. Go to Setup → Named Credentials → External Credentials"
echo "2. Click 'New' and enter:"
echo "   - Label: JT Tooling API External"
echo "   - Name: ${EXTERNAL_CRED_NAME}"
echo "   - Authentication Protocol: OAuth 2.0"
echo "   - Authentication Flow Type: User Agent OAuth Flow"
echo "   - Scope: api refresh_token"
echo "3. Save and add these Authentication Parameters:"
echo "   - ClientId: ${CONSUMER_KEY}"
echo "   - AuthorizationEndpoint: https://login.salesforce.com/services/oauth2/authorize"
echo "   - TokenEndpoint: https://login.salesforce.com/services/oauth2/token"
echo "   - RedirectUri: https://login.salesforce.com/services/oauth2/callback"
echo "4. Create a Principal (Named Principal) and Authenticate"
echo ""
read -p "Press Enter when done..."

echo ""
echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
echo -e "${BLUE}Step 3: Creating Named Credential${NC}"
echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"

echo -e "${YELLOW}⚠️  Named Credentials also require manual setup${NC}"
echo ""
echo "Please follow these steps:"
echo ""
echo "1. Go to Setup → Named Credentials (top tab)"
echo "2. Click 'New Named Credential' and enter:"
echo "   - Label: JT Tooling API"
echo "   - Name: ${NAMED_CRED_NAME}"
echo "   - URL: callout:${EXTERNAL_CRED_NAME}/services/data/v65.0/tooling"
echo "   - External Credential: ${EXTERNAL_CRED_NAME}"
echo "   - Enabled for Callouts: ✅"
echo "   - Generate Authorization Header: ✅"
echo "3. Save"
echo ""
read -p "Press Enter when done..."

echo ""
echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
echo -e "${BLUE}Step 4: Testing Setup${NC}"
echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"

echo -e "${YELLOW}⏳ Running test query via Tooling API...${NC}"

# Create anonymous Apex test
cat > /tmp/tooling-api-test.apex <<EOF
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:${NAMED_CRED_NAME}/query?q=SELECT+Id+FROM+ApexClass+LIMIT+1');
req.setMethod('GET');
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Status: ' + res.getStatusCode());
System.debug('Response: ' + res.getBody());
EOF

TEST_RESULT=$(sf apex run --file /tmp/tooling-api-test.apex 2>&1)

if echo "$TEST_RESULT" | grep -q "Status: 200"; then
    echo -e "${GREEN}✅ Tooling API test successful!${NC}"
    echo -e "${GREEN}✅ Named Credential is working correctly${NC}"
else
    echo -e "${YELLOW}⚠️  Test result unclear. Check logs:${NC}"
    echo "$TEST_RESULT"
fi

# Cleanup
rm -f /tmp/tooling-api-test.apex
rm -rf force-app/main/default/connectedApps

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "1. Open JT Dynamic Queries app"
echo "2. Go to Query Viewer tab"
echo "3. Enable 'Where is this used?' checkbox"
echo "4. Test the feature"
echo ""
echo "For troubleshooting, see: docs/TOOLING_API_SETUP.md"
echo ""

