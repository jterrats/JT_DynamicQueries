# Tooling API Setup Guide

This guide explains how the Tooling API is used in JT Dynamic Queries for the "Where is this used?" feature and metadata operations.

## Overview

The application uses **Visualforce Page-based session ID retrieval** for Tooling API calls instead of Named Credentials. This approach:

- ✅ **Simpler**: No OAuth setup required
- ✅ **More Reliable**: Works consistently in same-org scenarios
- ✅ **Production-Ready**: Optimized with multi-level caching to minimize callouts
- ✅ **No Configuration**: Works out-of-the-box after installation

## How It Works

### Architecture

The application uses a **3-level caching strategy** to optimize Tooling API callouts:

1. **Static Variable Cache** (Transaction-level)
   - Session ID cached in memory for the duration of a single transaction
   - Eliminates redundant VFP calls within the same request
   - **Benefit**: Multiple Tooling API calls in one transaction = 1 VFP callout

2. **Platform Cache** (Cross-request, 5-minute TTL)
   - Session ID cached in Platform Cache with user-specific key
   - Shared across requests for the same user
   - **Benefit**: Subsequent requests within 5 minutes = 0 VFP callouts

3. **Visualforce Page** (Fallback)
   - `JT_SessionIdPage` exposes API-enabled session ID via `{!$Api.Session_ID}`
   - Only called when cache is empty or expired
   - **Benefit**: Provides API-enabled session ID that works from LWC context

### Why Not Named Credentials?

We initially attempted to use Named Credentials with OAuth 2.0, but encountered a **known Salesforce limitation**:

- **Issue**: Same-org Tooling API callouts via OAuth Named Credentials fail with 500 proxy errors
- **Root Cause**: Salesforce's internal proxy (Squid) cannot handle same-org OAuth callouts
- **Solution**: Use Visualforce Page to obtain API-enabled session ID directly

This approach is:

- ✅ More reliable for same-org scenarios
- ✅ Simpler (no OAuth configuration needed)
- ✅ Production-ready with caching optimizations

## Setup Requirements

### ✅ Automatic Setup

**No manual configuration required!** The application works out-of-the-box:

1. **Visualforce Page**: `JT_SessionIdPage` is deployed automatically
2. **Permission Set**: `JT_Dynamic_Queries` includes necessary permissions
3. **Platform Cache**: Optional but recommended (gracefully degrades if unavailable)

### Optional: Platform Cache Configuration

For optimal performance, configure Platform Cache (optional):

1. Go to **Setup → Platform Cache**
2. Create a **Cache Partition** (if not exists):
   - **Name**: `JTDynamicQueries`
   - **Namespace**: `local` (or your org's namespace)
   - **Type**: Org Cache
   - **Size**: 1 MB (minimum)
3. Assign to users via Permission Set or Profile

**Note**: If Platform Cache is not configured, the application still works using static variable caching (transaction-level only).

## Usage in Code

### Session ID Retrieval

The application uses a centralized `getApiSessionId()` method in multiple classes:

- `JT_UsageFinder.cls` - For "Where is this used?" searches
- `JT_MetadataCreator.cls` - For creating/updating Custom Metadata
- `JT_SetupWizardController.cls` - For Tooling API verification

**Implementation Pattern**:

```apex
// Cache session ID in static variable for transaction reuse
private static String cachedSessionId = null;
private static final String CACHE_KEY_SESSION_ID = 'JT_ApiSessionId_' + UserInfo.getUserId();
private static final Integer SESSION_CACHE_TTL = 300; // 5 minutes

private static String getApiSessionId() {
    // Level 1: Check static cache (same transaction)
    if (cachedSessionId != null) {
        return cachedSessionId;
    }

    // Level 2: Check Platform Cache (cross-request)
    try {
        Object cached = Cache.Org.get(CACHE_KEY_SESSION_ID);
        if (cached != null) {
            cachedSessionId = (String) cached;
            return cachedSessionId;
        }
    } catch (Exception e) {
        // Platform Cache not available - continue to VFP
    }

    // Level 3: Fetch from Visualforce Page
    PageReference sessionPage = Page.JT_SessionIdPage;
    String sessionId = sessionPage.getContent().toString().trim();

    // Cache for future use
    cachedSessionId = sessionId;
    try {
        Cache.Org.put(CACHE_KEY_SESSION_ID, sessionId, SESSION_CACHE_TTL);
    } catch (Exception e) {
        // Platform Cache not available - that's okay
    }

    return sessionId;
}
```

### Tooling API Callouts

Once the session ID is obtained, Tooling API calls are made directly:

```apex
String orgUrl = URL.getOrgDomainUrl().toExternalForm();
String sessionId = getApiSessionId();
String endpoint = orgUrl + '/services/data/v65.0/tooling/query?q=' +
                  EncodingUtil.urlEncode(query, 'UTF-8');

HttpRequest request = new HttpRequest();
request.setEndpoint(endpoint);
request.setMethod('GET');
request.setHeader('Authorization', 'Bearer ' + sessionId);
request.setHeader('Accept', 'application/json');
request.setTimeout(30000);

HttpResponse response = new Http().send(request);
```

## Performance Optimizations

### Callout Reduction

**Before Optimization**:

- Each `getApiSessionId()` call = 1 VFP callout
- Example: "Where is this used?" with 20 Flows = 20+ VFP callouts

**After Optimization**:

- First call = 1 VFP callout + cache
- Subsequent calls in same transaction = 0 callouts (static cache)
- Requests within 5 minutes = 0 callouts (Platform Cache)

**Result**: From 20+ callouts → 1 callout per transaction

### Flow Search Optimization

The Flow search feature includes additional optimizations:

1. **Name-based Pre-filtering**: Filters Flows by name before checking metadata
2. **Limited Batch Size**: Checks maximum 20 Flows to avoid timeout
3. **Individual Metadata Queries**: Fetches metadata one Flow at a time (Tooling API limitation)

## Setup Wizard

The **Setup Wizard** (`jtSetupWizard` component) verifies Tooling API accessibility:

1. **Purpose**: Confirms Tooling API is accessible and working
2. **Method**: Performs a lightweight test query (`SELECT Id FROM ApexClass LIMIT 1`)
3. **Status**: Shows green checkmark if Tooling API is accessible

**No configuration needed** - the wizard uses the same session ID retrieval method as the rest of the application.

## Troubleshooting

### Error: "Failed to get API session ID"

**Symptoms**:

- Error message: "Failed to get API session ID: [error message]"
- "Where is this used?" feature doesn't work

**Causes & Solutions**:

1. **Visualforce Page Missing**:
   - Verify `JT_SessionIdPage` exists: **Setup → Visualforce Pages**
   - If missing, redeploy the package

2. **Permission Issues**:
   - User needs access to Visualforce Page
   - Ensure Permission Set `JT_Dynamic_Queries` is assigned
   - Verify Profile has access to Visualforce Page

3. **Platform Cache Issues** (Non-blocking):
   - If Platform Cache fails, the app falls back to VFP
   - Check debug logs for cache warnings (they're informational only)

### Error: "Tooling API connection failed"

**Symptoms**:

- Setup Wizard shows red X
- Tooling API calls return 401 or 403 errors

**Causes & Solutions**:

1. **Session ID Not API-Enabled**:
   - Verify Visualforce Page is accessible
   - Check that `{!$Api.Session_ID}` is working
   - Test by navigating to `/apex/JT_SessionIdPage` (should show session ID)

2. **User Permissions**:
   - User needs API access enabled
   - Check Profile → **API Enabled** checkbox
   - Or assign Permission Set with API access

3. **Org Limitations**:
   - Some Developer Orgs have Tooling API restrictions
   - Verify Tooling API is available: **Setup → Company Information → Instance**

### Performance Issues

**Symptoms**:

- Slow "Where is this used?" searches
- Multiple VFP callouts in debug logs

**Solutions**:

1. **Enable Platform Cache**:
   - Configure Platform Cache partition (see Setup Requirements above)
   - Reduces cross-request callouts significantly

2. **Check Cache Hit Rate**:
   - Review debug logs for cache hits/misses
   - High cache hit rate = better performance

3. **Reduce Flow Count**:
   - The app limits to 20 Flows by default
   - If you have many Flows, consider archiving obsolete ones

## Security Considerations

### Session ID Security

- ✅ Session IDs are **user-specific** (cannot be shared across users)
- ✅ Session IDs expire automatically (Salesforce security)
- ✅ Platform Cache is **org-scoped** (not accessible cross-org)
- ✅ Visualforce Page access is controlled by Profile/Permission Set

### Best Practices

1. **Permission Sets**: Use Permission Sets instead of Profiles for access control
2. **Platform Cache**: Configure Platform Cache for production orgs (better performance)
3. **Monitoring**: Monitor debug logs for cache hit rates and performance metrics

## Comparison: VFP vs Named Credentials

| Aspect                   | Visualforce Page (Current) | Named Credentials (Previous)        |
| ------------------------ | -------------------------- | ----------------------------------- |
| **Setup Complexity**     | ✅ None (automatic)        | ❌ OAuth 2.0 configuration required |
| **Same-Org Reliability** | ✅ Works reliably          | ❌ 500 proxy errors                 |
| **Cross-Org Support**    | ❌ Same-org only           | ✅ Supports cross-org               |
| **Performance**          | ✅ Optimized with caching  | ⚠️ No caching (each call = OAuth)   |
| **Configuration**        | ✅ Zero configuration      | ❌ Multiple setup steps             |
| **Production Ready**     | ✅ Yes                     | ⚠️ Limited by proxy issues          |

## References

- [Salesforce Tooling API Documentation](https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/)
- [Visualforce Page Reference](https://developer.salesforce.com/docs/atlas.en-us.pages.meta/pages/)
- [Platform Cache Documentation](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_cache_namespace_overview.htm)
