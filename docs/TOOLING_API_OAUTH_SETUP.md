# Tooling API Named Credential Setup (OAuth 2.0 - Next-Gen)

This guide walks you through setting up a Named Credential for the Salesforce Tooling API using the modern Next-Gen approach with External Credentials and OAuth 2.0 authentication. This is required for the "Where is this used?" feature to search Flows and other metadata.

## Prerequisites

- Admin access to your Salesforce org
- Salesforce org with External Credentials enabled (available in most orgs)

## Step-by-Step Setup

### Step 1: Create an Authentication Provider

1. From **Setup**, in the Quick Find box, enter **Auth. Providers** and select **Auth. Providers**.
2. Click **New**.
3. Select **Salesforce** as the provider type.
4. Configure the provider:
   - **Name**: `JT_Tooling_API_Auth_Provider`
   - **URL Suffix**: `jt_tooling_api` (auto-generated, can be customized)
   - **Consumer Key**: Leave blank for now (will be filled in Step 2)
   - **Consumer Secret**: Leave blank for now (will be filled in Step 2)
   - **Default Scopes**: `full refresh_token`
5. Click **Save**.
6. **Important**: Copy the **Callback URL** that is generated. You will need this in Step 2.

### Step 2: Create a Connected App (for Auth Provider)

1. From **Setup**, in the Quick Find box, enter **App Manager** and select **App Manager**.
2. Click **New Connected App**.
3. Fill in the basic information:
   - **Connected App Name**: `JT Tooling API`
   - **API Name**: `JT_Tooling_API` (auto-generated)
   - **Contact Email**: Your email address
4. Under **API (Enable OAuth Settings)**, check **Enable OAuth Settings**.
5. Configure OAuth settings:
   - **Callback URL**: Paste the Callback URL from Step 1
   - **Selected OAuth Scopes**:
     - Add `Full access (full)`
     - Add `Perform requests on your behalf at any time (refresh_token, offline_access)`
6. Click **Save**.
7. **Important**: After saving, copy:
   - **Consumer Key** (also called Client ID)
   - **Consumer Secret** (also called Client Secret)

### Step 3: Update the Authentication Provider

1. Go back to **Setup → Auth. Providers**.
2. Click on the Authentication Provider you created in Step 1 (`JT_Tooling_API_Auth_Provider`).
3. Click **Edit**.
4. Fill in:
   - **Consumer Key**: Paste the Consumer Key from Step 2
   - **Consumer Secret**: Paste the Consumer Secret from Step 2
5. Click **Save**.

### Step 4: Create External Credential (Next-Gen)

1. From **Setup**, in the Quick Find box, enter **External Credentials** and select **External Credentials**.
2. Click **New**.
3. Configure the External Credential:
   - **Label**: `JT Tooling API External`
   - **Name**: `JT_Tooling_API_External` (auto-generated)
   - **Authentication Protocol**: `OAuth 2.0`
   - **Authentication Provider**: Select `JT_Tooling_API_Auth_Provider` (created in Step 1)
   - **Principal Type**: `Per User` (recommended) or `Named Principal`
   - **Scope**: `refresh_token full`
4. Click **Save**.
5. **Important**: After saving, you will be prompted to authenticate:
   - Click **Start Authentication Flow** or **Authenticate**.
   - Log in with your Salesforce credentials if prompted.
   - Grant access to the Connected App.
   - The credential status should change to **Authenticated as [Your Name]**.

### Step 5: Link Named Credential to External Credential

**Note**: The Named Credential (`JT_Tooling_API`) is deployed with the package, but it needs to be linked to the External Credential.

1. From **Setup**, in the Quick Find box, enter **Named Credentials** and select **Named Credentials**.
2. Find `JT_Tooling_API` (deployed with the package).
3. Click **Edit**.
4. Configure the Named Credential:
   - **URL**: Update to your org's instance URL (e.g., `https://yourdomain.my.salesforce.com`)
     - You can find this in **Setup → Company Information → Instance URL**
     - Or use: `https://` + your org domain (e.g., `https://therionpolux-dev-ed.my.salesforce.com`)
   - **External Credential**: Select `JT_Tooling_API_External` (created in Step 4)
5. Click **Save**.

### Step 6: Verify the Setup

1. Go to **Setup → Named Credentials**.
2. Find `JT_Tooling_API`.
3. Verify:
   - Status shows **Authenticated** (via External Credential)
   - URL is correct (your org's instance URL)
   - External Credential is linked (`JT_Tooling_API_External`)

## Usage in Apex Code

Once configured, the Named Credential handles authentication automatically via OAuth 2.0. The code uses it like this:

```apex
HttpRequest request = new HttpRequest();
request.setEndpoint('callout:JT_Tooling_API/services/data/v65.0/tooling/query/?q=SELECT+Id+FROM+Flow');
request.setMethod('GET');
// No need to set Authorization header - Named Credential handles it automatically via OAuth 2.0
HttpResponse response = new Http().send(request);
```

## Troubleshooting

### Error: 401 Unauthorized

- **Cause**: External Credential not authenticated or OAuth token expired
- **Solution**:
  1. Go to **Setup → External Credentials → JT_Tooling_API_External**
  2. Click **Authenticate** or **Start Authentication Flow** to re-authenticate
  3. Ensure the Authentication Provider is correctly linked to the Connected App

### Error: External Credential Not Found

- **Cause**: Named Credential not linked to External Credential
- **Solution**:
  1. Go to **Setup → Named Credentials → JT_Tooling_API**
  2. Edit and ensure **External Credential** field is set to `JT_Tooling_API_External`

### Error: Invalid Consumer Key/Secret

- **Cause**: Authentication Provider not linked to Connected App correctly
- **Solution**:
  1. Verify Consumer Key and Consumer Secret match between Auth Provider and Connected App
  2. Ensure Callback URL in Connected App matches the one from Auth Provider

## Security Notes

- The External Credential uses OAuth 2.0 refresh tokens for long-term access
- Tokens are stored securely by Salesforce
- Each user authenticates separately (if using Per User principal type)
- The Connected App has `full` scope - ensure this is appropriate for your security requirements

## Alternative: Named Principal (System-Level)

If you prefer system-level authentication instead of per-user:

1. In Step 4, select **Principal Type**: `Named Principal`
2. After saving, authenticate once as an admin user
3. The credential will work for all users (system-level access)
4. **Note**: This requires careful security consideration

## Benefits of Next-Gen Approach

✅ **Modern**: Uses External Credentials (recommended by Salesforce)
✅ **Secure**: OAuth 2.0 with refresh tokens
✅ **Maintainable**: Centralized credential management
✅ **Flexible**: Can be reused across multiple Named Credentials
✅ **Future-proof**: Aligned with Salesforce's direction

## References

- [Salesforce Named Credentials Documentation](https://help.salesforce.com/s/articleView?id=sf.named_credentials_about.htm)
- [External Credentials Documentation](https://help.salesforce.com/s/articleView?id=sf.external_credentials.htm)
- [OAuth 2.0 Authentication Flow](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_flows.htm)
