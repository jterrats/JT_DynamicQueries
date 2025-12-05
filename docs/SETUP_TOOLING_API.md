# 🔧 Tooling API Setup Guide

## Overview

The "Where is this used?" feature searches for configuration references in Apex classes and Flows. Flow search requires Tooling API access, which consumes API limits.

## ⚠️ Important Notes

- **Apex Search**: FREE (no API limits consumed)
- **Flow Search**: Consumes Tooling API calls (1-5 calls per search depending on org size)
- **Audit Logging**: All searches are logged in the Audit History tab
- **Named Credential**: Required for secure Tooling API authentication

---

## Setup Instructions

### 1. Create Connected App

1. Go to **Setup** → **App Manager** → **New Connected App**
2. Configure:
   - **Connected App Name**: `JT Dynamic Queries Tooling API`
   - **API Name**: `JT_Dynamic_Queries_Tooling_API`
   - **Contact Email**: Your email
   - **Enable OAuth Settings**: ✅ Checked
   - **Callback URL**: `https://login.salesforce.com/services/oauth2/callback`
   - **Selected OAuth Scopes**:
     - `api` - Access unique identifier
     - `refresh_token` - Perform requests at any time
   - **Require Proof Key for Code Exchange (PKCE)**: ✅ Checked (recommended)
3. **Save** and note the **Consumer Key** (Client ID)

### 2. Configure External Credential

1. Go to **Setup** → **Named Credentials** → **External Credentials**
2. Find or create **JT Tooling API External**
3. Click **New** under **Principals**
4. Configure:
   - **Parameter Name**: `Client ID`
   - **Parameter Value**: Paste your Connected App Consumer Key
   - **Authentication Protocol**: OAuth 2.0
   - **Authentication Flow Type**: Authorization Code with PKCE
   - **Scope**: `api refresh_token`

### 3. Configure Named Credential

1. Go to **Setup** → **Named Credentials**
2. Find or create **JT Tooling API**
3. Configure:
   - **Label**: `JT Tooling API`
   - **Name**: `JT_Tooling_API`
   - **URL**: `callout:JT_Tooling_API_External`
   - **External Credential**: `JT Tooling API External`
   - **Enabled for Callouts**: ✅ Checked

### 4. Authenticate Users

Each user who wants to use "Where is this used?" must authenticate:

1. Go to **Setup** → **Named Credentials** → **External Credentials**
2. Click **JT Tooling API External**
3. Click **Authenticate** next to the user's name
4. Complete the OAuth flow

### 5. Enable in the Application

1. Open **JT Dynamic Queries** app
2. Go to **Query Viewer** tab
3. Under **API Features** section
4. Enable **"Where is this used?" search** checkbox
5. Read the API consumption disclaimer

---

## API Consumption Estimates

| Org Size           | Apex Classes | Flows | Est. API Calls per Search |
| ------------------ | ------------ | ----- | ------------------------- |
| Small (<100 Flows) | FREE         | ~1-2  | 1-2                       |
| Medium (100-500)   | FREE         | ~2-3  | 2-3                       |
| Large (500+)       | FREE         | ~3-5  | 3-5                       |

### Daily Limits

- **API Calls**: Varies by Salesforce Edition
  - Developer Edition: 5,000 calls/day
  - Enterprise Edition: 15,000 calls/day
  - Unlimited Edition: 20,000 calls/day

### Best Practices

1. **Enable only when needed**: Toggle off when not actively using the feature
2. **Monitor usage**: Check Audit History tab for search frequency
3. **Educate users**: Ensure team understands API consumption
4. **Consider alternatives**: For frequent searches, use IDE tools (VS Code Extension)

---

## Troubleshooting

### "Authentication Required" Error

**Cause**: User hasn't authenticated with the Named Credential.

**Solution**: Follow Step 4 above to authenticate the user.

### "API Limit Exceeded" Error

**Cause**: Daily API limit reached.

**Solution**:

- Wait until limits reset (midnight Pacific Time)
- Disable the feature temporarily
- Contact Salesforce to increase limits

### "Where is this used?" Link Not Visible

**Cause**: Feature is disabled in settings.

**Solution**: Enable the checkbox in **API Features** section.

---

## Alternative: IDE Search

For frequent usage, consider using Salesforce Extensions for VS Code:

1. Install **Salesforce Extension Pack**
2. Use **Command Palette** → **SFDX: Find References**
3. No API limits consumed!

---

## Security Notes

- ✅ **OAuth 2.0** with PKCE for secure authentication
- ✅ **Per-User** authentication (respects user permissions)
- ✅ **Audit Logging** tracks all searches
- ✅ **Toggleable** feature (can be disabled org-wide)
- ⚠️ **Named Credential** stores credentials securely in Salesforce

---

## Support

For issues or questions:

- 📖 [Full Documentation](https://jterrats.github.io/JT_DynamicQueries)
- 🐛 [Report Issues](https://github.com/jterrats/JT_DynamicQueries/issues)
- 💬 [Discussions](https://github.com/jterrats/JT_DynamicQueries/discussions)


