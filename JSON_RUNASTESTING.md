# JSON-Based Run As Testing

## Overview

Sistema funcional para ejecutar queries con `System.runAs()` real que serializa resultados como JSON para consumo en LWC.

## Arquitectura del Flujo de Datos

```
┌─────────────────────────────────────────────────────────────────┐
│   LWC Component (jtQueryViewer)                                 │
│   1. User clicks "Execute with System.runAs (Test)"            │
│   2. Calls executeAsUser()                                      │
│   3. Receives jobId                                             │
│   4. Polls getTestResults() every 2 seconds                     │
│   5. Parses JSON results                                         │
│   6. Displays in datatable                                      │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────────────────┐
│   JT_RunAsTestExecutor (Orchestrator)                           │
│   - Validates permissions                                       │
│   - Stores parameters in Platform Cache                         │
│   - Enqueues test execution (Queueable)                         │
│   - Provides getTestResults() for polling                       │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ↓ Platform Cache (params)
┌─────────────────────────────────────────────────────────────────┐
│   RunAsTestQueueable (Async Executor)                           │
│   - Reads params from cache                                     │
│   - Executes query with JT_DataSelector                         │
│   - Serializes results as JSON                                  │
│   - Stores in Platform Cache                                    │
└──────────────────┬──────────────────────────────────────────────┘
                   │
                   ↓ Platform Cache (results)
┌─────────────────────────────────────────────────────────────────┐
│   JT_GenericRunAsTest (@isTest class)                           │
│   - System.runAs(user) ✅ Real impersonation                   │
│   - Executes query in user context                             │
│   - Serializes as JSON for LWC                                  │
│   - Stores assertion message                                    │
└─────────────────────────────────────────────────────────────────┘
```

## JSON Structure

### Test Parameters (Input)

```json
{
    "userId": "005...",
    "configName": "Get_Accounts",
    "bindingsJson": "{\"name\":\"Acme Corp\"}",
    "timestamp": 1234567890
}
```

**Storage**: `Cache.Org.put('RunAsTest_' + userId, ...)`

### Test Results (Output)

```json
{
    "success": true,
    "recordCount": 3,
    "errorMessage": null,
    "executionTime": 245,
    "runAsUser": "John Doe",
    "timestamp": 1234567890,
    "fields": ["Id", "Name", "CreatedDate", "Owner.Name"],
    "records": [
        {
            "Id": "001...",
            "Name": "Acme Corp",
            "CreatedDate": "2025-11-29T10:00:00.000Z",
            "Owner": {
                "Name": "John Doe"
            }
        },
        {
            "Id": "001...",
            "Name": "Global Industries",
            "CreatedDate": "2025-11-28T15:30:00.000Z",
            "Owner": {
                "Name": "Jane Smith"
            }
        }
    ]
}
```

**Storage**: `Cache.Org.put('RunAsTestResult_' + userId, JSON.serialize(...))`

### Assert Message

```
SUCCESS: Found 3 record(s) as John Doe
```

**Storage**: `Cache.Org.put('RunAsTestAssert_' + userId, ...)`

## Functional Code Flow

### 1. Execute Test (LWC → Apex)

```javascript
// LWC Component
handleExecuteAsUserTest() {
    const bindingsJson = this.buildBindingsJson();

    executeAsUser({
        userId: this.runAsUserId,
        configName: this.selectedConfig,
        bindingsJson: bindingsJson
    })
    .then(result => {
        if (result.success) {
            this.testJobId = result.jobId;
            this.startPollingTestResults();
        }
    });
}
```

```apex
// Apex Controller
@AuraEnabled
public static TestExecutionResult executeAsUser(
    String userId,
    String configName,
    String bindingsJson
) {
    // Functional validation
    User targetUser = validateUser(userId);

    // Store params (immutable)
    storeTestParameters(userId, configName, bindingsJson);

    // Enqueue async execution
    String jobId = enqueueTestExecution(userId, configName, bindingsJson);

    return result;
}
```

### 2. Execute in Test Context

```apex
// Queueable Executor
public void execute(QueueableContext context) {
    // Functional query execution
    Map<String, Object> bindings = deserializeBindings(bindingsJson);
    List<SObject> records = JT_DataSelector.getRecords(configName, true, bindings);

    // Serialize for LWC
    String resultJson = JSON.serialize(buildResultMap(records));

    // Store functionally
    Cache.Org.put('RunAsTestResult_' + userId, resultJson, 300);
}
```

### 3. Serialize Records for LWC

```apex
private static List<Map<String, Object>> serializeRecordsForLWC(List<SObject> records) {
    List<Map<String, Object>> serializedRecords = new List<Map<String, Object>>();

    for (SObject record : records) {
        Map<String, Object> recordMap = new Map<String, Object>();
        Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();

        for (String fieldName : populatedFields.keySet()) {
            Object fieldValue = populatedFields.get(fieldName);

            // Handle relationships
            if (fieldValue instanceof SObject) {
                recordMap.put(fieldName, flattenSObject((SObject) fieldValue));
            } else {
                recordMap.put(fieldName, fieldValue);
            }
        }

        serializedRecords.add(recordMap);
    }

    return serializedRecords;
}
```

### 4. Poll for Results (LWC)

```javascript
startPollingTestResults() {
    let pollCount = 0;
    const maxPolls = 30; // 60 seconds max

    this.pollInterval = setInterval(() => {
        pollCount++;

        getTestResults({ userId: this.runAsUserId })
            .then(result => {
                if (result.success !== undefined) {
                    // Results ready - parse JSON
                    clearInterval(this.pollInterval);
                    this.handleTestResults(result);
                } else if (pollCount >= maxPolls) {
                    // Timeout
                    clearInterval(this.pollInterval);
                    this.showErrorToast('Timeout', 'Test execution timed out.');
                }
            });
    }, 2000); // Poll every 2 seconds
}
```

### 5. Parse and Display Results (LWC)

```javascript
processTestQueryResults(result) {
    this.recordCount = result.recordCount || 0;

    if (this.recordCount > 0 && result.records) {
        // Build columns from fields
        const fields = result.fields || Object.keys(result.records[0]);
        this.columns = fields.map(field => ({
            label: this.formatLabel(field),
            fieldName: field,
            type: this.getFieldType(field)
        }));

        // Transform records for datatable
        this.queryResults = result.records.map((record, index) => {
            const row = { Id: record.Id || `temp_${index}` };
            fields.forEach(field => {
                row[field] = record[field];
            });
            return row;
        });

        this.hasResults = true;

        // Display assertion message
        this.testAssertMessage = result.assertMessage;
    }
}
```

## Functional Patterns Used

### 1. Immutable Data Structures

```apex
// All parameters passed as immutable
public class TestParameters {
    public final String userId;
    public final String configName;
    public final String bindingsJson;
}
```

### 2. Pure Functions

```apex
// No side effects - same input = same output
private static List<String> extractFieldNames(SObject record) {
    Map<String, Object> fieldMap = record.getPopulatedFieldsAsMap();
    List<String> fields = new List<String>(fieldMap.keySet());
    fields.sort();
    return fields;
}
```

### 3. Functional Composition

```apex
// Pipeline of transformations
User user = validateUser(params);
QueryResult queryResult = executeInUserContext(user, params);
TestResult result = storeResults(params.userId, queryResult);
```

### 4. Declarative Data Flow

```apex
// Declarative: what to do, not how
Map<String, Object> resultData = new Map<String, Object>{
    'success' => queryResult.success,
    'recordCount' => queryResult.recordCount,
    'records' => serializeRecordsForLWC(queryResult.records),
    'fields' => extractFieldNames(queryResult.records[0])
};
```

## Handling Relationships

```apex
// Flatten nested SObjects for JSON
private static Map<String, Object> flattenSObject(SObject obj) {
    Map<String, Object> flatMap = new Map<String, Object>();
    Map<String, Object> fields = obj.getPopulatedFieldsAsMap();

    for (String fieldName : fields.keySet()) {
        flatMap.put(fieldName, fields.get(fieldName));
    }

    return flatMap;
}
```

**Input:**
```apex
Account acc = [SELECT Id, Name, Owner.Name, Owner.Email FROM Account LIMIT 1];
```

**Output JSON:**
```json
{
    "Id": "001...",
    "Name": "Acme Corp",
    "Owner": {
        "Name": "John Doe",
        "Email": "john@example.com"
    }
}
```

## LWC Datatable Consumption

```javascript
// Transform JSON records to datatable format
this.queryResults = result.records.map((record, index) => {
    const row = {
        Id: record.Id || `temp_${index}`,  // Ensure unique key
        Name: record.Name,
        CreatedDate: record.CreatedDate,
        OwnerName: record.Owner?.Name       // Handle relationships
    };
    return row;
});

// Define columns
this.columns = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' },
    { label: 'Owner', fieldName: 'OwnerName', type: 'text' }
];
```

## Error Handling

### Success Case

```json
{
    "success": true,
    "recordCount": 5,
    "records": [...],
    "fields": [...],
    "assertMessage": "SUCCESS: Found 5 record(s) as John Doe"
}
```

### Failure Case

```json
{
    "success": false,
    "recordCount": 0,
    "records": [],
    "fields": [],
    "errorMessage": "System.QueryException: List has no rows for assignment",
    "assertMessage": "FAILURE: System.QueryException: List has no rows for assignment"
}
```

## Platform Cache Configuration

```apex
// TTL: 5 minutes (300 seconds)
Cache.Org.put('RunAsTestResult_' + userId, resultJson, 300);

// Manual cleanup if needed
Cache.Org.remove('RunAsTestResult_' + userId);
```

## Testing the Implementation

### 1. From Developer Console

```apex
// Store test params
Cache.Org.put('RunAsTest_005xxx', new Map<String, Object>{
    'userId' => '005xxx',
    'configName' => 'Test_Record',
    'bindingsJson' => '{"name":"Test Account"}'
}, 300);

// Execute test
JT_GenericRunAsTest.executeRunAsTest();

// Retrieve results
String resultJson = (String) Cache.Org.get('RunAsTestResult_005xxx');
System.debug(resultJson);
```

### 2. From LWC

```javascript
// Click "Execute with System.runAs (Test)"
// Watch browser console for JSON results
console.log('Test Results:', result);
```

## Advantages of JSON Serialization

1. **✅ Type Safety**: All data properly typed in JSON
2. **✅ Relationship Handling**: Nested objects preserved
3. **✅ LWC Compatible**: Direct consumption in JavaScript
4. **✅ Debuggable**: JSON string easy to inspect
5. **✅ Extensible**: Easy to add new fields
6. **✅ Platform Cache**: Efficient temporary storage
7. **✅ Functional**: Immutable data flow

## Performance Considerations

- **Cache TTL**: 5 minutes (adjustable)
- **Polling Interval**: 2 seconds
- **Max Polls**: 30 (60 seconds timeout)
- **JSON Size**: Platform Cache limits apply (~100KB typical)
- **Record Limit**: Consider pagination for large result sets

## Complete Example

### Setup

```apex
// User: John Doe (ID: 005xxx)
// Config: Get_Accounts
// Binding: {"name": "Acme%"}
```

### Execution

```javascript
// LWC calls
executeAsUser({
    userId: '005xxx',
    configName: 'Get_Accounts',
    bindingsJson: '{"name":"Acme%"}'
})
```

### Result

```json
{
    "success": true,
    "recordCount": 2,
    "executionTime": 156,
    "runAsUser": "John Doe",
    "assertMessage": "SUCCESS: Found 2 record(s) as John Doe",
    "fields": ["Id", "Name", "Industry"],
    "records": [
        {
            "Id": "001xxx",
            "Name": "Acme Corp",
            "Industry": "Technology"
        },
        {
            "Id": "001yyy",
            "Name": "Acme Industries",
            "Industry": "Manufacturing"
        }
    ]
}
```

### Display

```html
<lightning-datatable
    key-field="Id"
    data={queryResults}
    columns={columns}
    hide-checkbox-column>
</lightning-datatable>
```

## Conclusion

Este enfoque funcional con serialización JSON proporciona:

- ✅ **System.runAs() real** en contexto de test
- ✅ **JSON parseable** para consumo directo en LWC
- ✅ **Mensajes de assertion** para validación visual
- ✅ **Programación funcional** con datos inmutables
- ✅ **Polling eficiente** con timeouts configurables
- ✅ **Manejo de relaciones** automático
- ✅ **Error handling** robusto

---

**Autor**: Jaime Terrats
**Fecha**: 29 de Noviembre, 2025
**Versión**: 1.0

