# Experimental E2E Tests

## 🧪 Overview

This directory contains **experimental** E2E tests that are not part of the main test suite. These tests are used for research, prototyping, and advanced validation scenarios.

---

## 📁 Contents

### `accessibility.spec.js`

**Automated accessibility testing using Axe-core**

- **Status**: ⚠️ Experimental (may have timeout issues in Salesforce environments)
- **Purpose**: Validate WCAG 2.1 AA compliance automatically
- **Coverage**: 25 tests (positive + negative scenarios)

**Why Experimental?**

- Salesforce Lightning pages have unpredictable network activity
- `networkidle` state is rarely achieved due to background processes
- Shadow DOM can interfere with some Axe-core rules
- Timeouts vary significantly between orgs and network conditions

**Running These Tests:**

```bash
# Run accessibility tests only
npx playwright test tests/e2e/experimental/accessibility.spec.js

# Run with increased timeout
npx playwright test tests/e2e/experimental/accessibility.spec.js --timeout=180000
```

**Note:** Even if these tests fail due to timeouts, the **manual accessibility implementation** in components is complete and functional. See `docs/ACCESSIBILITY.md` for details.

---

## ✅ Main Test Suite

The main E2E test suite is located in `tests/e2e/queryViewer.spec.js` and includes:

- ✅ **28 tests** - All passing
- ✅ Core functionality validation
- ✅ Responsive design testing
- ✅ i18n validation
- ✅ Basic accessibility checks (ARIA attributes, keyboard nav)

---

## 🎯 Future Work

Once Salesforce Lightning stability improves or we implement better wait strategies, these experimental tests can be promoted to the main suite.

**Potential Solutions:**

- Use custom wait conditions instead of `networkidle`
- Implement retry logic with exponential backoff
- Mock Salesforce background requests
- Run tests in isolated scratch orgs


