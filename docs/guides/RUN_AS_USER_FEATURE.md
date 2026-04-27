---
layout: default
title: Run As User Feature
permalink: /guides/RUN_AS_USER_FEATURE/
---

# Run As User Feature

## Overview

The Query Viewer component includes an advanced "Run As" feature that allows administrators and privileged users to validate query results in the context of another user's permissions. It supports two modes:

- **Specific User mode** — runs the query as an existing named user in the org (e.g., Alice, Bob)
- **Persona mode** — runs the query as a synthetic user built from a Profile + Permission Sets definition, with no real named user required

## How It Really Works (Tooling API + System.runAs)

Both modes use `System.runAs()` in an `@IsTest` context, invoked via the Salesforce Tooling API. This is not a simple USER_MODE query — it is actual permission impersonation through a pre-compiled test class.

**Named User flow:**

1. `JT_RunAsTestExecutor.executeAsUser()` creates a `JT_RunAsTest_Execution__c` record
2. `JT_RunAsTestEnqueuer` calls Tooling API `runTestsSynchronous` → `JT_GenericRunAsTest`
3. `JT_GenericRunAsTest` fetches the real User from the DB, calls `System.runAs(realUser)`, and executes the query
4. Results are written to the Debug Log with unique markers and extracted by the Queueable

**Persona flow:**

1. `JT_RunAsTestExecutor.executeAsPersona()` creates the execution record with `Persona_Developer_Name__c`
2. `JT_RunAsTestEnqueuer` reads `JT_PersonaConfig__mdt` to decide which test class to invoke
3. The test class builds a synthetic `User` (inserted in `@IsTest` context, rolled back after), assigns Permission Sets, and calls `System.runAs(syntheticUser)`

## Important Notes

### What It DOES:

- ✅ True `System.runAs()` impersonation — respects FLS, CRUD, object access, and sharing rules
- ✅ Named User mode: validates that a specific real user can see the expected records
- ✅ Persona mode: validates that a Profile + Permission Sets combination has the correct access
- ✅ `seeAllData=false` option (Persona mode): validates access without requiring real data in org

### What It DOESN'T DO:

- ❌ Cannot be used without Modify All Data / View All Data permission
- ❌ `SeeAllData=true` is required when validating that a user sees real records (not just access errors)
- ❌ Persona mode does not validate record volume when `See_All_Data__c = false`

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

---

## Persona Mode (US-025)

Persona mode allows testing without a real named user. Instead, define an archetype in `JT_PersonaConfig__mdt` and the framework creates a synthetic user in the `@IsTest` context.

### When to use Persona mode

| Scenario                                              | Recommendation                             |
| ----------------------------------------------------- | ------------------------------------------ |
| ISV org with no real QA users                         | ✅ Persona mode                            |
| Scarce user licenses                                  | ✅ Persona mode                            |
| Validate FLS/CRUD only (no data needed)               | ✅ Persona mode, `See_All_Data__c = false` |
| Validate real record visibility for a specific person | Named User mode                            |
| CI/CD permission regression tests                     | ✅ Persona mode                            |

### Configure a Persona

Go to **Setup → Custom Metadata Types → JT Persona Config → Manage Records** and create a record:

| Field            | Example                             | Description                              |
| ---------------- | ----------------------------------- | ---------------------------------------- |
| Label            | `Sales Rep - Territory`             | Display name in UI selector              |
| DeveloperName    | `Sales_Rep_Territory`               | API name                                 |
| Profile API Name | `Standard User`                     | Exact Profile Name from Setup            |
| Permission Sets  | `Territory_Manager,Pipeline_Access` | Comma-separated PS API names             |
| See All Data     | `false`                             | FLS/CRUD only; `true` = real data volume |
| Description      | `Sales rep with territory access`   | Shown in combobox                        |

> **Governor Limit Note:** Maximum 10 Permission Sets per persona recommended to stay within DML row limits in `@IsTest` context.

### UI: Mode Toggle

The `jtRunAsSection` component now shows a mode toggle:

```
[ Specific User ] [ Persona ]
```

- **Specific User** (default): existing behavior, searches real users
- **Persona**: loads `JT_PersonaConfig__mdt` records in the combobox

### Apex API

```apex
// Get persona options for LWC combobox
List<JT_RunAsTestExecutor.PersonaOption> options = JT_RunAsTestExecutor.getPersonaOptions();

// Execute as persona
JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsPersona(
    'Sales_Rep_Territory',  // DeveloperName of JT_PersonaConfig__mdt
    'Account_By_Name',      // Config name
    '{"name": "Acme"}'      // Bindings JSON
);
```

### seeAllData behavior

| `See_All_Data__c` | Test class used                                       | What is validated                     |
| ----------------- | ----------------------------------------------------- | ------------------------------------- |
| `false`           | `JT_GenericPersonaTest` (`@IsTest(SeeAllData=false)`) | FLS, CRUD, object access only         |
| `true`            | `JT_GenericRunAsTest` (`@IsTest(SeeAllData=true)`)    | FLS, CRUD, access + real record count |

When `seeAllData=false`, a result of 0 records is considered a successful test (the query ran without access errors). This is ideal for ISV orgs where no data exists in the installation org.

---

## Conclusion

The Run As feature gives administrators and ISV developers two complementary tools:

- **Named User mode** for investigating specific individuals ("Why can't Alice see this record?")
- **Persona mode** for regression testing permission archetypes without depending on real users

For questions or issues, please refer to the main project documentation or create an issue in the repository.
