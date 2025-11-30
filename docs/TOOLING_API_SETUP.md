# Tooling API Setup Guide

## 📋 Overview

This guide will help you configure the **Named Credential** required for Tooling API features:

- **"Where is this used?"** - Searches Flows for configuration references (1-5 API calls)
- **Create/Edit Configurations** - Deploys custom metadata via Tooling API (2-3 API calls)

> **Note:** The application works **without** Tooling API, but these features will be disabled.

---

## 🎯 Prerequisites

- ✅ Salesforce Administrator access
- ✅ API Enabled org (not available in Trial orgs)
- ✅ Permission to create Connected Apps

---

## 🔧 Step 1: Create a Connected App

### 1.1 Navigate to Setup

1. Click the **⚙️ Setup** icon (top right)
2. In Quick Find, search for: **App Manager**
3. Click **New Connected App**

### 1.2 Configure Basic Information

| Field                  | Value                            |
| ---------------------- | -------------------------------- |
| **Connected App Name** | `JT Dynamic Queries Tooling API` |
| **API Name**           | `JT_Dynamic_Queries_Tooling_API` |
| **Contact Email**      | Your email address               |

### 1.3 Enable OAuth Settings

✅ Check **Enable OAuth Settings**

**Callback URL:**

```
https://login.salesforce.com/services/oauth2/callback
```

**Selected OAuth Scopes:**

- ✅ `Access the identity URL service (id, profile, email, address, phone)`
- ✅ `Manage user data via APIs (api)`
- ✅ `Perform requests at any time (refresh_token, offline_access)`

### 1.4 Save and Note Credentials

1. Click **Save**
2. Click **Continue**
3. **Copy and save securely:**
   - 🔑 **Consumer Key** (Client ID)
   - 🔐 **Consumer Secret** (Click to reveal)

> ⚠️ **Security Warning:** Store these credentials securely. You'll need them in Step 2.

---

## 🔐 Step 2: Configure External Credential

### 2.1 Navigate to Named Credentials

1. In Setup, search for: **Named Credentials**
2. Click on **External Credentials** tab
3. Find: `JT_Tooling_API_External`
4. Click **Edit**

### 2.2 Add Authentication Protocol

1. Under **Principals**, click **New**
2. Configure:

| Field                        | Value                                        |
| ---------------------------- | -------------------------------------------- |
| **Label**                    | `Tooling API OAuth`                          |
| **Name**                     | `Tooling_API_OAuth`                          |
| **Authentication Protocol**  | `OAuth 2.0`                                  |
| **Authentication Flow Type** | `Client Credentials with Client Secret Flow` |
| **Scope**                    | `api refresh_token`                          |

### 2.3 Add Client Credentials

In the **Authentication Parameters** section:

| Parameter         | Value                                 |
| ----------------- | ------------------------------------- |
| **Client ID**     | _Paste Consumer Key from Step 1.4_    |
| **Client Secret** | _Paste Consumer Secret from Step 1.4_ |

3. Click **Save**

---

## 🌐 Step 3: Configure Named Credential

### 3.1 Navigate to Named Credentials

1. In Setup, click **Named Credentials** tab
2. Find: `JT_Tooling_API`
3. Click **Edit**

### 3.2 Configure Settings

| Field                    | Value                                    |
| ------------------------ | ---------------------------------------- |
| **Label**                | `JT Tooling API`                         |
| **Name**                 | `JT_Tooling_API`                         |
| **URL**                  | `https://[YOUR_INSTANCE].salesforce.com` |
| **External Credential**  | `JT_Tooling_API_External`                |
| **Enabled for Callouts** | ✅ Checked                               |

**Replace `[YOUR_INSTANCE]`** with your org's My Domain:

- Example: `https://mycompany.my.salesforce.com`

3. Click **Save**

---

## ✅ Step 4: Test the Configuration

### 4.1 Open Dynamic Query Viewer

1. Navigate to **Dynamic Queries** app
2. Go to **Query Viewer** tab
3. Look for the **API Features & Tooling API** section

### 4.2 Enable "Where is this used?" Search

1. Check the box: ✅ **Enable "Where is this used?" search**
2. Select a query configuration
3. Click **Where is this used?**

### 4.3 Expected Results

✅ **Success:** You'll see:

```
✓ Apex Search: Complete
✓ Flow Search: Complete
Found X references in Apex classes
Found Y references in Flows
```

❌ **Failure:** You'll see:

```
⚠️ Flow Search: Failed
Error: Named Credential not configured
```

---

## 🐛 Troubleshooting

### Issue 1: "Named Credential not found"

**Cause:** Named Credential `JT_Tooling_API` doesn't exist or is disabled.

**Solution:**

1. Verify the Named Credential exists in Setup
2. Ensure **Enabled for Callouts** is checked
3. Redeploy the metadata:
   ```bash
   sf project deploy start --source-dir force-app/main/default/namedCredentials
   ```

### Issue 2: "Invalid Client Credentials"

**Cause:** Connected App credentials are incorrect or expired.

**Solution:**

1. Go to **App Manager** → Find your Connected App
2. Click **View** → Verify **Consumer Key**
3. If needed, reset **Consumer Secret**
4. Update the External Credential with new credentials

### Issue 3: "API limit exceeded"

**Cause:** Tooling API calls consume daily API limits.

**Solution:**

1. Check API usage in Setup → **System Overview**
2. Consider disabling "Where is this used?" temporarily
3. Schedule searches during off-peak hours

### Issue 4: "Insufficient privileges"

**Cause:** User doesn't have API access or required permissions.

**Solution:**

1. Verify user has **API Enabled** permission
2. Ensure user has the `JT_Dynamic_Queries` permission set
3. Check user profile allows API access

---

## 📊 API Consumption Reference

| Feature                         | API Calls per Operation               |
| ------------------------------- | ------------------------------------- |
| **Where is this used? (Apex)**  | 0 (no API, uses SOQL on `ApexClass`)  |
| **Where is this used? (Flows)** | 1-5 (Tooling API query)               |
| **Create New Configuration**    | 2-3 (Tooling API metadata deployment) |
| **Edit Configuration**          | 2-3 (Tooling API metadata deployment) |

**Daily Limit:** Varies by org edition (typically 15,000-100,000 calls/day)

---

## 🔒 Security Best Practices

### ✅ DO:

- ✅ Use a dedicated Connected App for this integration
- ✅ Rotate Consumer Secret periodically (every 90 days)
- ✅ Use a service account (not personal user) for OAuth
- ✅ Enable IP restrictions on Connected App (if possible)
- ✅ Audit API usage via Setup → API Usage

### ❌ DON'T:

- ❌ Share Consumer Key/Secret in plain text (Slack, email)
- ❌ Commit credentials to version control
- ❌ Use the same Connected App for multiple integrations
- ❌ Grant more OAuth scopes than necessary

---

## 📚 Additional Resources

- [Salesforce Named Credentials Documentation](https://help.salesforce.com/s/articleView?id=sf.named_credentials_about.htm)
- [Tooling API Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/)
- [OAuth 2.0 JWT Bearer Flow](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_jwt_flow.htm)

---

## 🆘 Need Help?

If you encounter issues not covered in this guide:

1. **Check Logs:** Setup → Debug Logs (enable for API user)
2. **Review Audit Trail:** Setup → View Setup Audit Trail
3. **Open an Issue:** [GitHub Issues](https://github.com/YOUR_REPO/issues)
4. **Community Support:** [Salesforce Trailblazer Community](https://trailhead.salesforce.com/trailblazer-community)

---

## 📝 Quick Reference Checklist

- [ ] Step 1: Create Connected App
  - [ ] Note Consumer Key
  - [ ] Note Consumer Secret
- [ ] Step 2: Configure External Credential
  - [ ] Add Authentication Protocol (OAuth 2.0)
  - [ ] Add Client Credentials
- [ ] Step 3: Configure Named Credential
  - [ ] Set correct URL (My Domain)
  - [ ] Link to External Credential
- [ ] Step 4: Test Configuration
  - [ ] Enable "Where is this used?" toggle
  - [ ] Verify search results

---

**Setup Complete!** 🎉 Your Tooling API integration is now configured and ready to use.
