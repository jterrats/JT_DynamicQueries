# CI/CD Setup Guide

This guide explains how to set up Continuous Integration for E2E tests on every merge to `main`.

## Prerequisites

- Salesforce DevHub org
- GitHub repository with Actions enabled
- OpenSSL installed locally

---

## 1. Generate Certificate for JWT-Based Auth

Run the following commands locally (certificates will NOT be tracked in git):

```bash
# Navigate to project root
cd /path/to/JT_DynamicQueries

# Create certs directory (ignored by git)
mkdir -p certs
cd certs

# Generate private key (2048-bit RSA)
openssl genrsa -out server.key 2048

# Generate certificate signing request (CSR)
openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=JT Dynamic Queries/OU=CI/CN=ci.jtdynamicqueries.dev"

# Generate self-signed certificate (valid for 730 days = 2 years)
openssl x509 -req -sha256 -days 730 -in server.csr -signkey server.key -out server.crt

# Verify certificate
openssl x509 -in server.crt -text -noout

# Display certificate for Connected App (copy this)
cat server.crt
```

**⚠️ IMPORTANT**: Store `server.key` securely (never commit to git). You'll need it for GitHub Secrets.

---

## 2. Create Connected App in Salesforce

### Step 1: Navigate to Setup

1. Go to **Setup** → **App Manager**
2. Click **New Connected App**

### Step 2: Basic Information

- **Connected App Name**: `JT_CI_Runner`
- **API Name**: `JT_CI_Runner`
- **Contact Email**: Your email
- **Description**: `JWT-based authentication for CI/CD E2E tests`

### Step 3: API (Enable OAuth Settings)

- ✅ **Enable OAuth Settings**
- **Callback URL**: `http://localhost:1717/OauthRedirect`
- **Use digital signatures**: ✅ YES
  - **Upload Certificate**: Upload `server.crt` (generated above)
- **Selected OAuth Scopes**:
  - `Full access (full)`
  - `Perform requests at any time (refresh_token, offline_access)`
  - `Manage user data via APIs (api)`

### Step 4: Save and Note Consumer Key

1. Click **Save**
2. Click **Continue**
3. **Copy the Consumer Key** (you'll need this for GitHub Secrets)
4. Click **Manage Consumer Details** to view it again if needed

### Step 5: Edit Policies

1. Go back to **App Manager** → Find `JT_CI_Runner` → Click dropdown → **Edit Policies**
2. **Permitted Users**: `Admin approved users are pre-authorized`
3. **IP Relaxation**: `Relax IP restrictions`
4. **Refresh Token Policy**: `Refresh token is valid until revoked`
5. Click **Save**

### Step 6: Assign Permission Set

1. In **App Manager** → Find `JT_CI_Runner` → Click dropdown → **Manage**
2. Scroll to **Permission Sets** → Click **Manage Permission Sets**
3. Select the permission set used for your CI user (or create a new one)
4. Click **Save**

---

## 3. Create CI User (Recommended)

For best practices, create a dedicated user for CI:

```bash
# Create user via CLI (adjust values as needed)
sf org create user \
  --set-alias ci-user \
  --definition-file config/ci-user-def.json
```

**`config/ci-user-def.json`**:

```json
{
  "Username": "ci-runner@jtdynamicqueries.dev",
  "LastName": "CI Runner",
  "Email": "your-email@example.com",
  "Alias": "cirun",
  "TimeZoneSidKey": "America/Los_Angeles",
  "LocaleSidKey": "en_US",
  "EmailEncodingKey": "UTF-8",
  "ProfileId": "00e...",
  "LanguageLocaleKey": "en_US"
}
```

**Assign Permission Set**:

```bash
sf org assign permset --name JT_Dynamic_Queries_User --target-org ci-user
```

---

## 4. Test JWT Authentication Locally

Before setting up GitHub Actions, test JWT auth locally:

```bash
# Authenticate using JWT
sf org login jwt \
  --client-id YOUR_CONSUMER_KEY \
  --jwt-key-file certs/server.key \
  --username ci-runner@jtdynamicqueries.dev \
  --set-default-dev-hub \
  --alias ci-devhub

# Verify authentication
sf org display --target-org ci-devhub

# Test E2E
npm run test:e2e
```

If this works, you're ready for GitHub Actions!

---

## 5. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

**Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret Name       | Value                           | How to Get                           |
| ----------------- | ------------------------------- | ------------------------------------ |
| `SF_CONSUMER_KEY` | Consumer Key from Connected App | Step 2.4 above                       |
| `SF_JWT_KEY`      | Contents of `server.key`        | `cat certs/server.key`               |
| `SF_USERNAME`     | CI user username                | `ci-runner@jtdynamicqueries.dev`     |
| `SF_INSTANCE_URL` | Org URL                         | `https://your-org.my.salesforce.com` |

**⚠️ For `SF_JWT_KEY`**: Copy the ENTIRE contents including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`

---

## 6. Create GitHub Actions Workflow

Create `.github/workflows/e2e-tests.yml`:

```yaml
name: E2E Tests on Main Merge

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  e2e-tests:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Install Salesforce CLI
        run: |
          npm install -g @salesforce/cli
          sf version

      - name: Write JWT key to file
        run: |
          echo "${{ secrets.SF_JWT_KEY }}" > server.key
          chmod 600 server.key

      - name: Authenticate to Salesforce
        run: |
          sf org login jwt \
            --client-id ${{ secrets.SF_CONSUMER_KEY }} \
            --jwt-key-file server.key \
            --username ${{ secrets.SF_USERNAME }} \
            --instance-url ${{ secrets.SF_INSTANCE_URL }} \
            --set-default \
            --alias ci-org

          sf org display --target-org ci-org

      - name: Deploy to org
        run: |
          sf project deploy start \
            --source-dir force-app \
            --target-org ci-org \
            --wait 10

      - name: Run Apex tests
        run: |
          sf apex run test \
            --target-org ci-org \
            --test-level RunSpecifiedTests \
            --tests JT_QueryViewerController_Test,JT_DataSelector_Test,JT_AuditLogDomain_Test \
            --result-format human \
            --code-coverage \
            --wait 10

      - name: Install Playwright browsers
        run: npx playwright install --with-deps chromium

      - name: Run E2E tests
        run: npm run test:e2e
        env:
          SF_INSTANCE_URL: ${{ secrets.SF_INSTANCE_URL }}

      - name: Upload E2E test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30

      - name: Upload E2E videos
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: e2e-videos
          path: test-results/
          retention-days: 30

      - name: Clean up JWT key
        if: always()
        run: rm -f server.key
```

---

## 7. Verify CI Pipeline

1. Commit and push your changes (workflow file only)
2. Go to **Actions** tab in GitHub
3. Watch the workflow run
4. Check E2E test results and artifacts

---

## Security Best Practices

✅ **DO**:

- Store certificates and keys in GitHub Secrets
- Use dedicated CI user with minimal permissions
- Rotate certificates before expiration (set calendar reminder for 2 years)
- Use IP restrictions if possible
- Review audit logs regularly

❌ **DON'T**:

- Commit certificates or keys to git
- Use production org for CI (use dedicated DevHub)
- Share CI user credentials
- Use personal user accounts for CI

---

## Troubleshooting

### "JWT validation failed"

- Verify certificate matches the one uploaded to Connected App
- Check Consumer Key is correct
- Ensure user has permission to Connected App

### "Invalid username or password"

- Verify username is correct (check for typos)
- Ensure user is active in org
- Check IP restrictions

### "Tests failing in CI but pass locally"

- Check org state (test data, configurations)
- Review E2E videos in artifacts
- Verify deployment succeeded before tests run

---

## Certificate Rotation (Before Expiration)

When certificate is about to expire (730 days):

1. Generate new certificate (same process as above)
2. Update Connected App with new certificate
3. Update `SF_JWT_KEY` in GitHub Secrets
4. Test authentication locally first
5. Monitor first CI run with new certificate

---

## Cost Considerations

- **GitHub Actions**: Free for public repos, limited minutes for private
- **Salesforce DevHub**: Free with Developer Edition
- **Playwright**: Runs in CI, no additional cost

---

## Next Steps

1. ✅ Generate certificate
2. ✅ Create Connected App
3. ✅ Test JWT auth locally
4. ✅ Configure GitHub Secrets
5. ✅ Create workflow file
6. ✅ Monitor first CI run
7. ✅ Set calendar reminder for certificate rotation (2 years)
