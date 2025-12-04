# 🔧 E2E Fixes - Error-Driven Development

## 📊 Test Results Summary (Run: Dec 3, 2025)
- **Total**: 135 tests
- **✅ Passed**: 106 (78.5%)
- **❌ Failed**: 28 (20.7%)
- **⏭️ Skipped**: 1 (0.8%)
- **⏱️ Duration**: 40.3 minutes

---

## 🔴 Failed Tests by Category

### 1. 🗑️ Cache Management Tests (5 failures) - **PRIORITY 1**

**Root Cause**: Tests not using updated `testHelpers.js` for navigation

#### Failures:
1. `should open cache management modal` - Modal not visible
2. `should have all cache options in modal` - Cache checkboxes not found
3. `should enable Clear button only when options selected` - Button state check failed
4. `should clear cache and show success toast` - Checkbox not found
5. `should use Select All to select all options` - Select All checkbox not found

#### Fix Strategy:
- [ ] Update `beforeEach` in queryViewer.spec.js (cache tests section) to use `setupTestContext`
- [ ] Verify all `data-testid` attributes in `jtCacheModal.html`
- [ ] Test modal opening/closing flow manually

---

### 2. 📄 Query Execution Tests (4 failures) - **PRIORITY 2**

**Root Cause**: Selectors changed (lightning-datatable → table.slds-table) but some tests not updated

#### Failures:
1. `should execute query and display results or empty table`
2. `should display pagination when results exceed 10 records`
3. `should handle pagination in results without errors`
4. `should display record count in success message`

#### Fix Strategy:
- [ ] Update remaining selectors from `lightning-datatable` to `table.slds-table`
- [ ] Verify pagination selectors in `jtQueryResults.html`
- [ ] Add helper for checking pagination presence

---

### 3. 🌐 GitHub Pages Tests (3 failures) - **PRIORITY 3**

**Root Cause**: Network or site configuration issues

#### Failures:
1. `Homepage loads successfully`
2. `Navigation links are visible and functional`
3. `No broken images on homepage`

#### Fix Strategy:
- [ ] Check if GitHub Pages is deployed correctly
- [ ] Verify URL in test configuration
- [ ] Add retry logic for network-dependent tests

---

### 4. 🎨 Accessibility Tests (16 failures) - **PRIORITY 4**

**Note**: Many are duplicated between `/e2e/` and `/experimental/`

#### Failures (per suite):
1. `Color contrast should meet WCAG AA standards` - Known issue (some SLDS components)
2. `Execute button should have proper focus indicators` - Selector/assertion issue
3. `Skip navigation should work with Tab key` - Keyboard nav not found
4. `Execute button should announce loading state` - ARIA live region not found
5. `Mobile navigation should have touch-friendly targets` - Touch target size check failed
6. `NEGATIVE: Should detect missing ARIA labels if removed` - Test logic issue
7. `NEGATIVE: Should detect poor color contrast if present` - Test logic issue
8. `NEGATIVE: Should detect links that open in new window without warning` - Test logic issue

#### Fix Strategy:
- [ ] Consolidate duplicate tests (remove `/experimental/` if not needed)
- [ ] Update ARIA selectors for Execute Button
- [ ] Add skip-link to main content
- [ ] Verify ARIA live region for loading states
- [ ] Fix NEGATIVE test assertions (they should PASS when violations are detected)

---

## 🎯 Execution Plan (EDD)

### Phase 1: Cache Management (Est: 30 min)
1. Update `queryViewer.spec.js` cache tests to use `setupTestContext`
2. Verify `data-testid` attributes in `jtCacheModal`
3. Run cache tests in isolation: `npm run test:e2e -- --grep "cache"`
4. Fix any remaining selector issues

### Phase 2: Query Execution (Est: 20 min)
1. Update all selectors to use `table.slds-table`
2. Add pagination helper in `testHelpers.js`
3. Run query execution tests: `npm run test:e2e -- --grep "pagination|record count"`
4. Verify results

### Phase 3: GitHub Pages (Est: 15 min)
1. Verify GitHub Pages deployment
2. Add retry logic for network tests
3. Run GH Pages tests: `npm run test:e2e -- --grep "GitHub Pages"`

### Phase 4: Accessibility (Est: 45 min)
1. Consolidate duplicate tests
2. Fix NEGATIVE test logic
3. Add missing ARIA attributes to components
4. Run accessibility tests: `npm run test:e2e -- --grep "Accessibility"`

---

## 📝 Next Steps

**Immediate Actions**:
1. ✅ Create this EDD document
2. ⏳ Fix Cache Management tests (Phase 1)
3. ⏳ Fix Query Execution tests (Phase 2)
4. ⏳ Fix GitHub Pages tests (Phase 3)
5. ⏳ Fix Accessibility tests (Phase 4)
6. ⏳ Run full E2E suite to verify all fixes
7. ⏳ Commit all fixes with detailed messages

**Time Estimate**: ~2 hours total

---

## 🏁 Success Criteria

- [ ] Cache Management: 5/5 passing
- [ ] Query Execution: 4/4 passing
- [ ] GitHub Pages: 3/3 passing (or marked as flaky with retry logic)
- [ ] Accessibility: 16/16 passing (or reduced to 8/8 after consolidation)
- [ ] **Total E2E Pass Rate**: ≥95% (≥128/135 passing)

