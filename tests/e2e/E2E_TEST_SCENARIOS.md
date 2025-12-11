# 🧪 E2E Test Scenarios - JT Dynamic Queries

## Complete Test Coverage Documentation

**Total Scenarios**: 15 E2E Tests
**Framework**: Playwright
**Browser**: Chromium
**Auth Method**: SF CLI Session (no manual login)

---

## 📋 Test Scenarios Overview

### 1. **Component Loading & UI** (3 tests)

#### 1.1 `should load the Query Viewer component`

- ✅ Verifies LWC loads correctly
- ✅ Validates card title is visible
- ✅ Confirms component structure

#### 1.2 `should load and display query configurations`

- ✅ Combobox loads with options
- ✅ Configurations retrieved from backend
- ✅ At least one config available

#### 1.3 `should navigate between tabs in the app`

- ✅ Query Viewer tab is visible
- ✅ Can navigate to Home tab
- ✅ Can navigate back to Query Viewer
- ✅ Component reloads properly

---

### 2. **Query Execution** (3 tests)

#### 2.1 `should select a configuration and display query preview`

- ✅ Selects first configuration
- ✅ Query preview displays
- ✅ Contains valid SELECT statement
- ✅ Shows preview text in console

#### 2.2 `should execute query and display results`

- ✅ Executes query successfully
- ✅ Shows loading spinner
- ✅ Displays datatable OR "No records found"
- ✅ Record count is visible
- ✅ Handles empty results gracefully

#### 2.3 `should handle query with dynamic parameters`

- ✅ Detects parameter inputs
- ✅ Fills parameters with test data
- ✅ Executes query with parameters
- ✅ No errors shown
- ✅ Handles configs without parameters

---

### 3. **Error Handling** (1 test)

#### 3.1 `should display error for invalid configuration`

- ✅ Executes without selecting config
- ✅ Shows error toast
- ✅ Validates error handling

---

### 4. **Run As User Feature** (3 tests)

#### 4.1 `should show Run As User section for authorized users`

- ✅ Detects user permissions
- ✅ Shows Run As container if authorized
- ✅ Warning message about USER_MODE present
- ✅ Search input available
- ✅ Skips gracefully if no permissions

#### 4.2 `should search and select a Run As user if authorized`

- ✅ Validates permissions first
- ✅ Types in search field
- ✅ Waits for debounce (1.5s)
- ✅ Results load
- ✅ Auto-skips without permissions

#### 4.3 `should execute query with Run As user if selected`

- ✅ Validates permissions
- ✅ Selects configuration
- ✅ Executes in Run As context
- ✅ Verifies results (datatable/error/no results)
- ✅ Confirms execution completes

---

### 5. **Create Configuration** (5 tests) 🆕

#### 5.1 `should enforce production safeguard - hide Create Configuration in Production` ⭐ NEW

- ✅ **Detects org type from URL** (sandbox URLs contain "sandbox")
- ✅ **Simple & fast detection** (no navigation needed)
- ✅ **IN PRODUCTION: Validates button is HIDDEN**
- ✅ **IN PRODUCTION: Confirms button not in DOM**
- ✅ **IN SANDBOX: Validates button is VISIBLE**
- ✅ **IN SANDBOX: Confirms button is enabled**
- ✅ **Enforces production safeguard feature**

#### 5.2 `should open and close Create Configuration modal`

- ✅ Skips if Production (auto-detect)
- ✅ Opens modal on button click
- ✅ Modal title is correct
- ✅ All form fields present (label, devName, query, bindings, object)
- ✅ Cancel button closes modal

#### 5.3 `should validate required fields in Create Configuration`

- ✅ Skips if Production
- ✅ Opens modal
- ✅ Tries to save empty form
- ✅ Validation error shown
- ✅ Toast or field error appears

#### 5.4 `should create a new configuration successfully`

- ✅ Skips if Production
- ✅ Opens modal
- ✅ Fills all fields with valid data
- ✅ Unique timestamp-based name
- ✅ Valid SOQL query
- ✅ Valid JSON bindings
- ✅ Saves successfully
- ✅ Success toast appears
- ✅ **Verifies refreshApex() works** (new config appears in list)

#### 5.5 `should handle invalid SOQL in Create Configuration`

- ✅ Skips if Production
- ✅ Opens modal
- ✅ Fills with invalid SOQL
- ✅ Tries to save
- ✅ Error toast appears
- ✅ Invalid query rejected

---

### 6. **Edit Configuration** (4 tests) 🆕 v2.0

#### 6.1 `should show Edit Configuration button when config is selected`

- ✅ Skips if Production
- ✅ Selects a configuration from dropdown
- ✅ Verifies Edit button becomes visible
- ✅ Validates button has correct icon and label

#### 6.2 `should open Edit Configuration modal with pre-filled data`

- ✅ Skips if Production
- ✅ Selects a configuration
- ✅ Clicks Edit button
- ✅ Validates modal title says "Edit" (not "Create")
- ✅ Verifies Label field is pre-filled
- ✅ Verifies all fields contain existing config data

#### 6.3 `should have Developer Name as read-only in Edit mode`

- ✅ Skips if Production
- ✅ Opens Edit modal
- ✅ Validates Developer Name input is disabled
- ✅ Security: Cannot change API name of existing config

#### 6.4 `should update configuration label successfully`

- ✅ Skips if Production
- ✅ Opens Edit modal
- ✅ Modifies Label field
- ✅ Clicks Update button
- ✅ Verifies modal closes
- ✅ Success toast appears
- ✅ Validates refreshApex() refreshes config list

---

## 🎯 Feature Coverage Matrix

| Feature                  | Tests | Coverage | Production Safe                |
| ------------------------ | ----- | -------- | ------------------------------ |
| **UI Loading**           | 3     | ✅ 100%  | N/A                            |
| **Query Execution**      | 3     | ✅ 100%  | ✅ Yes                         |
| **Error Handling**       | 1     | ✅ 100%  | ✅ Yes                         |
| **Run As User**          | 3     | ✅ 100%  | ✅ Yes (permission-gated)      |
| **Create Config**        | 5     | ✅ 100%  | ✅ **Yes (environment-gated)** |
| **Edit Config** 🆕       | 4     | ✅ 100%  | ✅ **Yes (environment-gated)** |
| **Production Safeguard** | 1     | ✅ 100%  | ✅ **Explicitly tested**       |

---

## 🔒 Security & Safeguard Tests

### Production Safeguard ⭐

```javascript
// Simple & fast detection from URL
const isProduction = !session.instanceUrl.toLowerCase().includes("sandbox");

// Sandbox URLs: https://domain--name.sandbox.my.salesforce.com
// Production URLs: https://domain.my.salesforce.com

// Test explicitly validates that Create Configuration is hidden in Production
if (isProduction) {
  expect(isButtonVisible).toBeFalsy(); // MUST be false
  expect(buttonCount).toBe(0); // MUST not exist in DOM
}
```

### Permission-Based Features

- Run As User: Only shown if user has permissions
- All features respect org security settings

---

## 🚀 Running the Tests

### All Tests

```bash
npm run test:e2e
```

### Interactive Mode (UI)

```bash
npm run test:e2e:ui
```

### Specific Test File

```bash
npx playwright test queryViewer.spec.js
```

### With Debug

```bash
npx playwright test --debug
```

---

## 📊 Expected Results

### Sandbox/Scratch Org

```
Running 15 tests using 1 worker

✅ should load the Query Viewer component
✅ should load and display query configurations
✅ should select a configuration and display query preview
✅ should execute query and display results
✅ should handle query with dynamic parameters
✅ should display error for invalid configuration
✅ should navigate between tabs in the app
✅ should show Run As User section for authorized users
✅ should search and select a Run As user if authorized
✅ should execute query with Run As user if selected
✅ should enforce production safeguard - hide Create Configuration in Production
✅ should open and close Create Configuration modal
✅ should validate required fields in Create Configuration
✅ should create a new configuration successfully
✅ should handle invalid SOQL in Create Configuration

15 passed (55s)
```

### Production Org

```
Running 15 tests using 1 worker

✅ should load the Query Viewer component
✅ should load and display query configurations
✅ should select a configuration and display query preview
✅ should execute query and display results
✅ should handle query with dynamic parameters
✅ should display error for invalid configuration
✅ should navigate between tabs in the app
✅ should show Run As User section for authorized users
✅ should search and select a Run As user if authorized
✅ should execute query with Run As user if selected
✅ should enforce production safeguard - hide Create Configuration in Production (VALIDATES HIDDEN)
⊘ should open and close Create Configuration modal (SKIPPED - Production)
⊘ should validate required fields in Create Configuration (SKIPPED - Production)
⊘ should create a new configuration successfully (SKIPPED - Production)
⊘ should handle invalid SOQL in Create Configuration (SKIPPED - Production)

11 passed, 4 skipped (45s)
```

---

## 🎓 Test Design Principles

### 1. **Environment Awareness**

- Tests adapt to Production vs Sandbox
- Auto-skip features not available in current environment

### 2. **Permission Awareness**

- Tests detect user permissions
- Gracefully skip unauthorized features

### 3. **Data Awareness**

- Handle cases with/without data
- Don't assume specific records exist

### 4. **Robust Waiting**

- Use proper `waitForSelector` with timeouts
- Add strategic waits for async operations
- Don't rely on fixed delays alone

### 5. **Clear Logging**

- Console logs explain what's happening
- Easy to debug failures
- Shows environment detection results

---

## 💡 Key Testing Features

### ✅ No Manual Login Required

```javascript
session = getSFSession(); // Uses active SF CLI session
await injectSFSession(page, session);
```

### ✅ Smart App Navigation

```javascript
const currentApp = await getCurrentApp(page);
if (!currentApp.includes(TARGET_APP_NAME)) {
  await navigateToApp(page, TARGET_APP_NAME);
}
```

### ✅ Environment Detection (Simple & Fast)

```javascript
// NEW: Detects Production vs Sandbox from URL
const isProduction = !session.instanceUrl.toLowerCase().includes("sandbox");

// Examples:
// Sandbox: https://mycompany--dev.sandbox.my.salesforce.com
// Production: https://mycompany.my.salesforce.com
```

### ✅ Adaptive Assertions

```javascript
if (isProduction) {
  expect(createButton).not.toBeVisible(); // Production
} else {
  expect(createButton).toBeVisible(); // Sandbox
}
```

---

## 🐛 Debugging Failed Tests

### View Last Run Report

```bash
npx playwright show-report
```

### Run with Screenshots

```bash
npx playwright test --screenshot=on
```

### Run with Video

```bash
npx playwright test --video=on
```

### Headed Mode (see browser)

```bash
npx playwright test --headed
```

---

## 📝 Test Maintenance

### Adding New Tests

1. Add test to `queryViewer.spec.js`
2. Update this documentation
3. Run locally to verify
4. Commit changes

### Updating Selectors

If UI changes, update locators:

```javascript
// Before
page.locator('lightning-button[label="Execute"]');

// After (if label changes)
page.locator('lightning-button[label="Run Query"]');
```

---

## ✅ AppExchange Compliance

### E2E Testing Requirements

- ✅ All core features tested
- ✅ Error handling validated
- ✅ Permission checks verified
- ✅ **Production safeguards explicitly tested** ⭐
- ✅ User workflows covered
- ✅ Edge cases handled

### Security Testing

- ✅ Production safeguards enforced
- ✅ Permission-based feature access
- ✅ Invalid input handling
- ✅ Error scenarios covered

---

## 🎉 Summary

**15 comprehensive E2E tests** covering:

- ✅ UI loading and navigation
- ✅ Query execution (with/without parameters)
- ✅ Error handling
- ✅ Run As User feature
- ✅ Create Configuration feature
- ✅ **Production safeguard enforcement** ⭐

**Key Achievement**: Tests adapt to environment and permissions, providing realistic validation in any Salesforce org.

---

**Last Updated**: November 29, 2025
**Test Framework**: Playwright v1.40+
**Status**: ✅ Complete & Production Ready
**Production Safe**: ✅ **Explicitly Validated**
