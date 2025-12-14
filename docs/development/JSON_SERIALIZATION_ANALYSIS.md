# Impact Analysis: JSON Serialization Refactoring

## Current State

### ✅ Already Using Standard JSON Serialization (Correct)

1. **JT_QueryViewerController.executeQuery** (line 107-108)

   ```apex
   String recordsJson = JSON.serialize(sobjectRecords);
   result.records = (List<Object>) JSON.deserializeUntyped(recordsJson);
   ```

   - ✅ Correct: Preserves nested relationships
   - ✅ Used by: Main query execution

2. **JT_QueryViewerController.executeQueryWithBatchProcessing** (line 736-737)

   ```apex
   String recordsJson = JSON.serialize(sobjectRecords);
   result.records = (List<Object>) JSON.deserializeUntyped(recordsJson);
   ```

   - ✅ Correct: Preserves nested relationships
   - ✅ Used by: Batch processing

3. **JT_GenericRunAsTest.storeResults** (line 481)

   ```apex
   List<Object> serializedRecords = JT_QueryViewerController.serializeRecordsForLWC(queryResult.records);
   ```

   - ✅ Correct: Uses centralized helper method
   - ✅ Used by: Run As User feature

4. **JT_RunAsTestExecutor.getTestResults** (line 443)

   ```apex
   result.records = (List<Object>) resultMap.get('records');
   ```

   - ✅ Correct: Deserializes from stored JSON
   - ✅ Used by: Test results retrieval

### ⚠️ Direct Assignment Without Serialization (Potential Issue)

1. **JT_QueryViewerController.executeQueryPreview** (line 234)

   ```apex
   result.records = records; // List<SObject> assigned directly
   ```

   - ⚠️ **Issue**: Assigns `List<SObject>` directly without serialization
   - **Impact**: If there are nested relationships in preview, they might not work correctly
   - **Risk**: Medium - Only affects preview (LIMIT 5), not production
   - **Usage**: Query preview in creation modal

2. **JT_GenericRunAsTest.executeRunAsTest** (line 303)

   ```apex
   result.records = records; // List<SObject> assigned directly
   ```

   - ⚠️ **Issue**: Direct assignment, but corrected in `storeResults`
   - **Impact**: Low - Serialized before saving to Debug Log
   - **Risk**: Very low - Only affects internal temporary structure
   - **Usage**: Internal test structure, serialized before persisting

## Refactoring Risk Analysis

### Scenario 1: Refactor `executeQueryPreview`

**Required change:**

```apex
// Before:
result.records = records;

// After:
result.records = serializeRecordsForLWC(records);
```

**Risk:**

- **High**: This method is used in the creation modal for real-time preview
- **Impact**: If there's a bug, it would affect critical preview functionality
- **Testing**: Requires testing with queries that have nested relationships
- **Benefit**: Low - Preview normally doesn't have nested relationships (LIMIT 5)

**Recommendation**: ⚠️ **DO NOT REFACTOR** - Risk outweighs benefit

### Scenario 2: Refactor `executeRunAsTest`

**Required change:**

```apex
// Before:
result.records = records;

// After:
result.records = serializeRecordsForLWC(records);
```

**Risk:**

- **Low**: Records are correctly serialized in `storeResults` before persisting
- **Impact**: Minimal - Only affects internal temporary structure
- **Testing**: Already tested and working correctly
- **Benefit**: Minimal - Already serialized where it matters

**Recommendation**: ✅ **OPTIONAL** - Can be done but not critical

## Conclusion

### Current State: ✅ **SUFFICIENTLY GOOD**

1. **Critical methods already use correct serialization:**
   - `executeQuery` ✅
   - `executeQueryWithBatchProcessing` ✅
   - `storeResults` ✅
   - `getTestResults` ✅

2. **Methods with direct assignment:**
   - `executeQueryPreview`: High risk to refactor, low benefit
   - `executeRunAsTest`: Already serialized where it matters

3. **Centralized helper method exists:**
   - `JT_QueryViewerController.serializeRecordsForLWC()` ✅
   - Already being used where critical

### Final Recommendation

**DO NOT REFACTOR** - The risk of breaking critical functionality (preview) outweighs the minimal benefit.

**Reasons:**

1. Critical methods already use correct serialization
2. Preview (`executeQueryPreview`) works correctly for normal cases
3. Change would require exhaustive testing of nested relationships
4. Benefit is minimal (only affects preview with nested relationships, rare case)

**Alternative:** If a specific bug is found in the future with nested relationships in preview, then refactor that specific method.
