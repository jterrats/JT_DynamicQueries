# Refactoring Plan: jtQueryViewer.js

## Current State

- **Lines of code**: 2,289
- **Methods**: 55
- **Console.log/error/warn**: 60
- **Custom Label imports**: 89 individual

## Identified Redundancies

### 1. Console.log Statements (60 found)

- Many are temporary debug that should be removed
- Some are useful but should be behind a debug flag
- **Action**: Remove temporary debug, keep only critical logs

### 2. Duplicated Error Handling

- Repeated pattern of error message extraction:
  ```javascript
  error.body?.message ||
    error.body?.pageErrors?.[0]?.message ||
    error.body?.output?.errors?.[0]?.message ||
    error.message ||
    fallback;
  ```
- **Action**: Extract to helper function `extractErrorMessage(error, fallback)` in jtUtils

### 3. Repeated Validations

- Validation of `configToUse` null/undefined
- Validation of required fields (label, developerName, baseQuery)
- Validation of query syntax
- **Action**: Extract validation functions to helpers

### 4. Polling Logic

- `startPollingTestResults()` has complex logic that could be reused
- **Action**: Create generic helper function `pollUntilComplete()` in jtUtils

### 5. Custom Labels

- 89 individual imports
- `getLabels()` already exists in jtUtils but not being used
- **Action**: Use `getLabels()` to simplify imports

## Refactoring Plan

### Phase 1: Immediate Cleanup

1. ✅ Remove temporary debug console.log
2. ✅ Extract `extractErrorMessage()` to jtUtils
3. ✅ Extract validation functions to helpers

### Phase 2: Simplification

4. ✅ Use `getLabels()` for Custom Labels
5. ✅ Extract polling logic to generic helper
6. ✅ Consolidate error handling

### Phase 3: Optimization

7. ✅ Review long methods and split them
8. ✅ Identify and extract common logic

## Target Metrics

- Reduce to ~1,800 lines (21% reduction)
- Reduce console.log to <10 (only critical)
- Simplify label imports
