# Error Handling Analysis: "Uncommitted Work Pending"

## Identified Problem

The error "You have uncommitted work pending. Please commit or rollback before calling out" occurs when:

1. **In Run As User:**
   - `JT_RunAsTest_Execution__c` is created/updated (DML)
   - Then a callout to Tooling API is attempted
   - Salesforce does not allow DML + callout in the same transaction
   - This occurs especially during deployments/setup operations

2. **Current Flow:**

   ```
   JT_RunAsTestExecutor.executeAsUser()
   → Creates JT_RunAsTest_Execution__c (DML)
   → Enqueues JT_RunAsTestEnqueuer (Queueable)
   → JT_RunAsTestEnqueuer.execute()
   → Attempts synchronous callout (403 ORG_ADMIN_LOCKED)
   → Attempts async fallback
   → ❌ CalloutException: "uncommitted work pending"
   ```

3. **In "Where is this used?":**
   - Uses Continuation (no DML + callout problem)
   - But could have other deployment-related errors

## UX Impact

### Scenarios where it occurs:

1. **During Deployments:**
   - Org is locked for admin operations
   - User sees confusing technical error
   - Doesn't know to wait or retry

2. **During Setup Operations:**
   - Initial app configuration
   - Data migrations
   - Bulk operations in progress

3. **During Concurrent Operations:**
   - Multiple users executing Run As simultaneously
   - Org limits reached

### Current Messages (Technical):

- ❌ "Failed to execute test: You have uncommitted work pending. Please commit or rollback before calling out"
- ❌ "Synchronous execution failed with HTTP status: 403"
- ❌ Stack traces visible to user

### Proposed Messages (User-Friendly):

1. **For "uncommitted work pending":**

   ```
   "The system is currently processing another operation.
   Please wait a moment and try again.
   This may occur during deployments or system maintenance."
   ```

2. **For "ORG_ADMIN_LOCKED" (403):**

   ```
   "The system is temporarily unavailable due to an ongoing deployment or maintenance operation.
   Please wait a few minutes and try again."
   ```

3. **For deployment/setup errors:**
   ```
   "This feature is temporarily unavailable.
   The system may be processing a deployment or configuration change.
   Please try again in a few minutes."
   ```

## Proposed Changes

### 1. Custom Labels to Create:

```xml
<labels>
    <fullName>JT_RunAsTestEnqueuer_uncommittedWorkPending</fullName>
    <value>The system is currently processing another operation. Please wait a moment and try again. This may occur during deployments or system maintenance.</value>
</labels>
<labels>
    <fullName>JT_RunAsTestEnqueuer_orgAdminLocked</fullName>
    <value>The system is temporarily unavailable due to an ongoing deployment or maintenance operation. Please wait a few minutes and try again.</value>
</labels>
<labels>
    <fullName>JT_RunAsTestEnqueuer_deploymentInProgress</fullName>
    <value>This feature is temporarily unavailable. The system may be processing a deployment or configuration change. Please try again in a few minutes.</value>
</labels>
```

### 2. Changes in `JT_RunAsTestEnqueuer.cls`:

```apex
// In execute() - Detect specific error
catch (Exception e) {
    String errorMessage = e.getMessage();
    String userFriendlyMessage;

    // Detect "uncommitted work pending"
    if (errorMessage.contains('uncommitted work') ||
        errorMessage.contains('CalloutException')) {
        userFriendlyMessage = Label.JT_RunAsTestEnqueuer_uncommittedWorkPending;
    }
    // Detect ORG_ADMIN_LOCKED (403)
    else if (errorMessage.contains('ORG_ADMIN_LOCKED') ||
             errorMessage.contains('admin operation already in progress')) {
        userFriendlyMessage = Label.JT_RunAsTestEnqueuer_orgAdminLocked;
    }
    // Other deployment errors
    else if (errorMessage.contains('deployment') ||
             errorMessage.contains('maintenance')) {
        userFriendlyMessage = Label.JT_RunAsTestEnqueuer_deploymentInProgress;
    }
    // Generic error
    else {
        userFriendlyMessage = 'Failed to execute test: ' + errorMessage;
    }

    updateExecutionWithError(userFriendlyMessage);
}
```

### 3. Changes in `JT_UsageFinder.cls`:

```apex
// In processFlowSearchCallback() - Handle deployment errors
catch (Exception e) {
    String errorMessage = e.getMessage();
    String userFriendlyError;

    if (errorMessage.contains('ORG_ADMIN_LOCKED') ||
        errorMessage.contains('admin operation')) {
        userFriendlyError = Label.JT_RunAsTestEnqueuer_orgAdminLocked;
    } else {
        userFriendlyError = 'Flow search failed: ' + errorMessage;
    }

    response.success = false;
    response.error = userFriendlyError;
}
```

### 4. Changes in LWC (`jtQueryViewer.js`):

```javascript
// In handleTestResults() - Show user-friendly messages
if (!result.success) {
  // Message already comes user-friendly from Apex
  this.showError = true;
  this.errorMessage = result.errorMessage;
  // Don't show additional toast if error banner already displayed
}
```

## Considerations

### ✅ Advantages:

1. **Better UX:** Users understand what happened and what to do
2. **Less confusion:** No technical stack traces visible
3. **Clear action:** They know to wait and retry
4. **Consistency:** Same pattern for all deployment errors

### ⚠️ Disadvantages:

1. **Less information for debugging:** We lose technical details
   - **Solution:** Keep technical details in Debug Logs

2. **Error detection:** We need to correctly detect error types
   - **Solution:** Use multiple detection patterns

3. **Generic messages:** Might not cover all cases
   - **Solution:** Have fallback to generic message with instructions

## Next Steps

1. ✅ Create Custom Labels
2. ✅ Update `JT_RunAsTestEnqueuer.cls` with specific detection
3. ✅ Update `JT_UsageFinder.cls` to handle similar errors
4. ✅ Verify LWC displays messages correctly
5. ✅ Test during real deployment
6. ✅ Update documentation

## Testing

### Scenarios to test:

1. **During active deployment:**
   - Execute Run As User → Should show user-friendly message
   - Execute "Where is this used?" → Should handle error gracefully

2. **With concurrent operations:**
   - Multiple users executing simultaneously
   - Verify messages are appropriate

3. **With setup operations:**
   - During initial configuration
   - During migrations
