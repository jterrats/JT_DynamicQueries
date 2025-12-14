# Refactoring Plan: jtQueryViewer.js

## Current Analysis

- **Size**: 2243 lines
- **Methods**: 99 methods/properties
- **Identified problems**:
  1. Duplicated toast methods (already exist in `jtUtils.js`)
  2. Modal logic mixed with business logic
  3. Duplicated pagination logic (preview and main results)
  4. Duplicated `getFieldType` method (already exists in `jtUtils.js`)
  5. Many getters that could be simplified
  6. Very long query execution logic

## Refactoring Plan (Prioritized)

### Phase 1: Remove Duplicated Code (High Impact, Low Risk)

1. **Replace local toast methods with `jtUtils`**
   - Remove: `showSuccessToast`, `showErrorToast`, `showInfoToast`, `showWarningToast`
   - Replace all calls (57 occurrences) with `jtUtils` functions
   - **Estimated savings**: ~100 lines

2. **Remove duplicated `getFieldType`**
   - Already exists in `jtUtils.js`
   - Replace local calls
   - **Estimated savings**: ~15 lines

### Phase 2: Extract Pagination Logic (Medium Impact, Medium Risk)

3. **Create `jtPagination` component or utility**
   - Extract pagination logic (preview and results)
   - Methods: `handlePreviousPage`, `handleNextPage`, `resetPagination`, related getters
   - **Estimated savings**: ~150 lines

### Phase 3: Extract Modal Logic (Medium Impact, Medium Risk)

4. **Create modal management service**
   - Extract: `handleOpenCacheModal`, `handleCloseCacheModal`, `handleShowCreateModal`, `handleShowEditModal`, `handleCloseUsageModal`
   - Centralize modal state
   - **Estimated savings**: ~100 lines

### Phase 4: Simplify Getters (Low Impact, Low Risk)

5. **Consolidate related getters**
   - Group pagination, view, state getters
   - Use computed properties where possible
   - **Estimated savings**: ~50 lines

### Phase 5: Extract Query Execution Logic (High Impact, High Risk)

6. **Create `jtQueryExecutor` component**
   - Extract: `executeQueryNormal`, `executeQueryWithBatches`, `assessQueryRiskAndExecute`
   - Handle all execution and results logic
   - **Estimated savings**: ~300 lines

## Expected Metrics Post-Refactoring

- **Reduced lines**: ~715 lines (32% reduction)
- **Reduced methods**: ~30 methods (30% reduction)
- **Maintainability**: Significantly improved
- **Testability**: Improved (smaller, focused components)

## Recommended Execution Order

1. ✅ Phase 1 (already started)
2. Phase 2
3. Phase 3
4. Phase 4
5. Phase 5 (requires more analysis)

## Notes

- Each phase must include tests
- Make incremental commits after each phase
- Validate functionality after each change
