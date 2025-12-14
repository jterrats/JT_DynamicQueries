# Error Logging Implementation

## Overview

A centralized error logging system has been created using the `JT_ErrorLog__c` object to capture exceptions encountered by users, with detailed information for technical support.

## Object: JT_ErrorLog\_\_c

### Fields

- **JT_ErrorType\_\_c** (Text, Required): Error type/category
- **JT_ErrorMessage\_\_c** (Text, Required): User-friendly message displayed to the user
- **JT_ExceptionType\_\_c** (Text): Apex exception type (AuraHandledException, QueryException, etc.)
- **JT_StackTrace\_\_c** (LongTextArea): Full stack trace for debugging
- **JT_Context\_\_c** (Text): Context where the error occurred (component, method, action)
- **JT_Severity\_\_c** (Picklist): Severity (Low, Medium, High, Critical)
- **OwnerId** (Standard Owner field): User who encountered the error (standard Salesforce field)
- **JT_Timestamp\_\_c** (DateTime, Required): When the error occurred
- **JT_AdditionalDetails\_\_c** (LongTextArea): Additional information in JSON (optional)
- **JT_OrgType\_\_c** (Text): Organization type where it occurred
- **JT_Resolved\_\_c** (Checkbox): Whether the error has been resolved

## Classes

### JT_ErrorLogDomain.cls

Domain layer for DML operations on `JT_ErrorLog__c`. Executes `without sharing` to ensure logs are always created.

### JT_ErrorLogger.cls

Utility class to facilitate error logging. Provides overloaded methods for different scenarios.

## Usage Examples

### Example 1: Basic logging from Apex

```apex
try {
    // Code that may fail
    executeQuery();
} catch (Exception e) {
    // Log the error
    JT_ErrorLogger.logError(
        'Query Execution Failed',
        e,
        'JT_QueryViewerController.executeQuery'
    );

    // Show user-friendly message
    throw new AuraHandledException('Unable to execute query. Please try again.');
}
```

### Example 2: Logging with specific ErrorType

```apex
try {
    // Code that may fail
    executeRunAsTest();
} catch (AuraHandledException ahe) {
    JT_ErrorMessageUtil.ErrorAnalysisResult analysis =
        JT_ErrorMessageUtil.analyzeError(ahe.getMessage(), null);

    // Log with specific type
    JT_ErrorLogger.logError(
        analysis.errorType,
        ahe.getMessage(),
        ahe,
        'JT_RunAsTestEnqueuer.execute'
    );

    throw ahe;
}
```

### Example 3: Logging with additional details

```apex
try {
    // Code that may fail
    createConfiguration(configJson);
} catch (Exception e) {
    // Build additional details in JSON
    Map<String, Object> details = new Map<String, Object>{
        'configName' => configName,
        'userId' => UserInfo.getUserId(),
        'orgId' => UserInfo.getOrganizationId()
    };

    // Log with additional details
    JT_ErrorLogger.logError(
        'Configuration Creation Failed',
        e.getMessage(),
        e,
        'JT_MetadataCreator.createConfiguration',
        JSON.serialize(details),
        'High'
    );

    throw new AuraHandledException('Failed to create configuration.');
}
```

### Example 4: Integration in JT_RunAsTestEnqueuer

```apex
private void updateExecutionWithError(String errorMessage) {
    try {
        // ... existing code to update execution ...

        // Log error for support
        JT_ErrorLogger.logError(
            'Test Execution Failed',
            new AuraHandledException(errorMessage),
            'JT_RunAsTestEnqueuer.updateExecutionWithError'
        );
    } catch (Exception e) {
        // Log even if update fails
        JT_ErrorLogger.logError(
            'Failed to Update Execution Record',
            e,
            'JT_RunAsTestEnqueuer.updateExecutionWithError'
        );
        throw e;
    }
}
```

### Example 5: Logging from LWC (via Apex)

In the LWC component, when an error is caught:

```javascript
.catch((error) => {
    // Extract error message
    const errorMsg = extractErrorMessage(error, this.labels.unknownError);

    // Show to user
    this.showError = true;
    this.errorMessage = errorMsg;

    // Log to Apex for support (optional, if you need more context)
    logErrorToApex({
        errorType: 'LWC Error',
        errorMessage: errorMsg,
        context: 'jtQueryViewer.handleExecuteQuery',
        additionalDetails: JSON.stringify({
            selectedConfig: this.selectedConfig,
            bindings: this.bindings
        })
    })
    .catch(() => {
        // Ignore logging errors, should not affect UX
    });
})
```

And the corresponding Apex method:

```apex
@AuraEnabled
public static String logErrorToApex(
    String errorType,
    String errorMessage,
    String context,
    String additionalDetails
) {
    return JT_ErrorLogger.logError(
        errorType,
        errorMessage,
        null, // No exception from LWC
        context,
        additionalDetails,
        'Medium'
    );
}
```

## Advantages

1. **Separation of concerns**: `JT_SettingsAuditLog__c` for audit trail, `JT_ErrorLog__c` for errors
2. **Complete information**: Stack trace, context, additional details
3. **Non-blocking**: Logging fails silently if there are issues
4. **Facilitates support**: Detailed information for debugging
5. **Reporting**: Allows creating reports of common errors, affected users, etc.

## Retention Policies

It is recommended to implement a cleanup policy similar to `JT_SettingsAuditLog__c`:

```apex
// Example: Clean logs older than 90 days
JT_ErrorLogDomain.deleteOldLogs(90);
```

## Next Steps

1. Integrate `JT_ErrorLogger.logError()` at key points where exceptions are caught
2. Create reports of common errors
3. Implement automatic cleanup policy
4. Consider creating an LWC component to visualize errors (optional)
