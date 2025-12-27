---
layout: default
title: Run As User Feature
permalink: /guides/RUN_AS_USER_FEATURE/
---

# Run As User Feature

## Overview

The Query Viewer component includes an advanced "Run As User" feature that allows administrators and privileged users to validate query results in the context of another user's permissions.

## Important Limitations

⚠️ **Security Notice**: This feature has inherent limitations due to Salesforce's security model:

### What It DOES:

- ✅ Validates that the selected user exists and is active
- ✅ Executes queries with `USER_MODE` security (respects FLS and CRUD)
- ✅ Applies sharing rules and record-level security
- ✅ Provides insight into what data different users can access
- ✅ Useful for testing permissions and troubleshooting access issues

### What It DOESN'T DO:

- ❌ **Cannot use `System.runAs()`** - This is only available in test context
- ❌ **Cannot truly impersonate** - The query still runs in the current user's context
- ❌ **Cannot bypass security** - All queries respect USER_MODE security
- ❌ **Cannot override permissions** - FLS, CRUD, and sharing rules are always enforced

## How It Works

```apex
// Simplified logic
public static QueryResult executeQuery(String devName, String bindingsJson, String runAsUserId) {
    // 1. Validate current user has permission to use Run As feature
    if (String.isNotBlank(runAsUserId)) {
        validateRunAsPermission(runAsUserId);
    }

    // 2. Execute query with USER_MODE (respects all security)
    List<SObject> records = JT_DataSelector.getRecords(devName, true, bindings);

    // 3. Return results with Run As user info
    result.runAsUserName = getUserName(runAsUserId);
    return result;
}
```

## Who Can Use It?

The Run As feature is available to users with:

- System Administrator profile
- Modify All Data permission
- View All Data permission

Check permissions:

```apex
Boolean canUse = JT_QueryViewerController.canUseRunAs();
```

## Use Cases

### 1. Permission Testing

Test if a specific user can see certain records:

```
1. Select user: "Sales Rep - John Doe"
2. Execute query: SELECT Id, Name FROM Account
3. Result shows only accounts John has access to
```

### 2. Troubleshooting Access Issues

Investigate why a user can't see expected records:

```
1. User reports: "I can't see Account X"
2. Admin selects that user in Run As
3. Executes query to verify sharing rules
4. Identifies permission gap
```

### 3. Training & Demos

Show different user perspectives:

```
1. Demo to stakeholders
2. Switch between user contexts
3. Demonstrate how permissions work
```

## UI Components

### Run As Section

```html
<div class="run-as-container">
  <lightning-icon icon-name="utility:user"></lightning-icon>
  Run As User (Advanced)

  <lightning-combobox
    label="Search User"
    placeholder="Type to search users..."
    oninput="{handleUserSearch}"
  >
  </lightning-combobox>
</div>
```

### Search Functionality

- Type-ahead search with 300ms debounce
- Searches by Name or Username
- Shows Profile name in results
- Limited to 20 results
- Only shows active users

### Clear Button

Removes the selected Run As user to return to normal execution.

## API Methods

### `canUseRunAs()`

```apex
@AuraEnabled(cacheable=true)
public static Boolean canUseRunAs()
```

Returns `true` if current user can use the Run As feature.

### `searchUsers(String searchTerm)`

```apex
@AuraEnabled(cacheable=true)
public static List<UserOption> searchUsers(String searchTerm)
```

Searches for users matching the search term.

### `executeQuery(String devName, String bindingsJson, String runAsUserId)`

```apex
@AuraEnabled
public static QueryResult executeQuery(String devName, String bindingsJson, String runAsUserId)
```

Executes query with optional Run As user validation.

## Technical Details

### Validation Process

1. Check if current user has Run As permission
2. Verify selected user exists
3. Verify selected user is active
4. Execute query with USER_MODE
5. Return results with Run As context info

### Security Model

```apex
// Query always uses USER_MODE
AccessLevel accessMode = enforceSecurity ? AccessLevel.USER_MODE : AccessLevel.SYSTEM_MODE;

return Database.queryWithBinds(
    config.JT_BaseQuery__c,
    bindings,
    accessMode  // <- Always respects security
);
```

## Best Practices

### DO:

- ✅ Use for permission testing and troubleshooting
- ✅ Validate sharing rules and FLS
- ✅ Document permission gaps found
- ✅ Test with real user scenarios
- ✅ Combine with Salesforce Inspector for deeper analysis

### DON'T:

- ❌ Assume it provides true impersonation
- ❌ Use as a security bypass mechanism
- ❌ Rely on it for compliance auditing
- ❌ Use in production for critical operations
- ❌ Expect it to work exactly like `System.runAs()`

## Alternatives & Complements

For more comprehensive testing:

1. **Login As** (Salesforce Native)
   - Setup → Users → Login
   - True user impersonation
   - Works for full user session

2. **Permission Set Testing**
   - Assign/unassign permission sets
   - Test in isolation
   - More controlled environment

3. **System.runAs() in Tests**
   - Use in Apex tests
   - True impersonation
   - Safe testing environment

## Error Handling

### Common Errors:

**"You do not have permission to use the Run As feature"**

- User lacks required permissions
- Assign System Administrator profile or View/Modify All Data

**"Selected user not found"**

- User was deleted or doesn't exist
- Refresh search and select valid user

**"Cannot run as inactive user"**

- Selected user is deactivated
- Select an active user only

## Testing

E2E tests included:

```bash
npm run test:e2e
```

Tests cover:

- Feature visibility based on permissions
- User search functionality
- Query execution with Run As context
- Error handling scenarios

## Conclusion

The Run As User feature is a valuable tool for administrators to understand and validate permissions in their org. While it has limitations compared to true user impersonation, it provides practical value for everyday permission testing and troubleshooting within Salesforce's security constraints.

For questions or issues, please refer to the main project documentation or create an issue in the repository.
