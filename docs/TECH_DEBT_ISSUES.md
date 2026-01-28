# Technical Debt GitHub Issues

This document contains all technical debt issues ready to be created in GitHub. You can either:

1. **Use the automated script:** `scripts/create-tech-debt-issues.sh`
2. **Create manually:** Copy/paste the issue bodies below into GitHub

---

## 🔴 High Priority Issues

### Issue #1: Fix Husky Pre-commit Hook Scanner Permissions

**Title:** `[Tech Debt] Fix Husky Pre-commit Hook Scanner Permissions`

**Labels:** `bug`, `tech-debt`, `high-priority`, `infrastructure`

**Body:**

```markdown
## 🔴 High Priority Tech Debt

## 📝 Description

The Husky pre-commit hook fails due to scanner permission errors (EPERM on `.sf/sf-2025-12-02.log`). Currently requires workaround with `git commit --no-verify` which bypasses code quality checks.

## 🔍 Current Issue

- Scanner cannot write logs to `~/.sf/` directory
- Pre-commit hooks fail with permission errors
- Workaround: Use `git commit --no-verify` (bypasses hooks)
- Risk: Code quality checks are bypassed

## ✅ Acceptance Criteria

- [ ] Fix SF CLI log directory permissions OR configure scanner to use temp directory
- [ ] Pre-commit hooks run successfully without `--no-verify`
- [ ] All code quality checks (prettier, lint, scanner) execute properly
- [ ] Document solution in CONTRIBUTING.md
- [ ] Remove workaround from CHANGELOG.md

## 🔧 Technical Notes

- Already attempted temp directory solution in `tests/e2e/utils/sfAuth.js:30-57`
- May need to configure SF CLI to use workspace-relative log directory
- Consider using `SF_LOG_PATH` environment variable

## 📍 References

- `CHANGELOG.md:310` - Documented TODO for v2.2.0
- `tests/e2e/utils/sfAuth.js:30-57` - Previous attempt at temp directory
- `.husky/pre-commit` - Current hook configuration

## 📅 Estimated Effort

**3-5 story points**

## 🎯 Priority

**High** - Blocks proper code quality checks
```

---

### Issue #2: Remove Deprecated Methods

**Title:** `[Tech Debt] Remove Deprecated Methods and Migrate Callers`

**Labels:** `tech-debt`, `high-priority`, `refactoring`

**Body:**

```markdown
## 🔴 High Priority Tech Debt

## 📝 Description

Two methods are marked `@deprecated` but still referenced in codebase. Need to audit all callers, migrate to new methods, and remove deprecated code.

## 🔍 Deprecated Methods

### 1. `JT_QueryViewerController.addWildcardsForLikeBindings()`

- **Status:** `@deprecated` - Use `JT_QueryBindingUtil.addWildcardsForLikeBindings` instead
- **Location:** `force-app/main/default/classes/JT_QueryViewerController.cls:1552`
- **Action Required:** Migrate all callers to new utility class

### 2. `JT_UsageFinder.findConfigurationUsage()`

- **Status:** `@deprecated` - Use `findAllUsagesResilient` for fault-isolated searches
- **Location:** `force-app/main/default/classes/JT_UsageFinder.cls:126`
- **Action Required:** Update all callers to use resilient version

## ✅ Acceptance Criteria

- [ ] Audit all callers of `JT_QueryViewerController.addWildcardsForLikeBindings()`
- [ ] Migrate callers to `JT_QueryBindingUtil.addWildcardsForLikeBindings`
- [ ] Audit all callers of `JT_UsageFinder.findConfigurationUsage()`
- [ ] Migrate callers to `findAllUsagesResilient`
- [ ] Remove deprecated methods from codebase
- [ ] Update all tests to use new methods
- [ ] Verify no breaking changes

## 🔧 Technical Notes

- Use `grep` or IDE search to find all references
- Create migration script if many callers exist
- Test thoroughly before removing deprecated methods
- Consider deprecation period (e.g., mark in v2.6, remove in v3.0)

## 📍 References

- `force-app/main/default/classes/JT_QueryViewerController.cls:1552`
- `force-app/main/default/classes/JT_UsageFinder.cls:126`
- `force-app/main/default/classes/JT_QueryBindingUtil.cls` (new utility)

## 📅 Estimated Effort

**4-6 story points**

## 🎯 Priority

**High** - Code maintainability and potential breaking changes
```

---

### Issue #3: Remove Legacy Code Paths

**Title:** `[Tech Debt] Remove Legacy String Handling in Type Conversion`

**Labels:** `tech-debt`, `high-priority`, `refactoring`

**Body:**

```markdown
## 🔴 High Priority Tech Debt

## 📝 Description

Legacy code paths handle String values for typed fields (Integer, Decimal, Boolean) for backward compatibility. This compromises type safety and may hide bugs. Need to add validation and remove legacy handling.

## 🔍 Legacy Patterns Found

### 1. `JT_QueryViewerController.convertBindingValueForQuery()`

- **Location:** `JT_QueryViewerController.cls:1190`
- **Issue:** Handles String values for typed fields (legacy support)
- **Comment:** "Legacy: Handle String values (shouldn't happen if JS sends typed values)"
- **Risk:** May hide type conversion bugs

### 2. `JT_DataSelector.convertNumericBindingValue()`

- **Location:** `JT_DataSelector.cls:475`
- **Issue:** Legacy String handling for Decimal/Integer fields
- **Comment:** "Legacy: Handle String values (shouldn't happen if JS sends typed values)"
- **Risk:** Type safety compromised

## ✅ Acceptance Criteria

- [ ] Add validation in LWC to ensure JS always sends typed values
- [ ] Add logging/warning when String values are received (transition period)
- [ ] Update all LWC components to send typed values
- [ ] Remove legacy String handling after validation period (v3.0)
- [ ] Add unit tests for type validation
- [ ] Document breaking change in CHANGELOG

## 🔧 Technical Notes

- First phase: Add validation and warnings (v2.6)
- Second phase: Remove legacy handling (v3.0)
- Ensure LWC components use proper type coercion
- Consider using TypeScript for better type safety

## 📍 References

- `force-app/main/default/classes/JT_QueryViewerController.cls:1190`
- `force-app/main/default/classes/JT_DataSelector.cls:475`
- Related test classes for legacy handling

## 📅 Estimated Effort

**3-5 story points** (split across 2 releases)

## 🎯 Priority

**High** - Type safety and code quality
```

---

## 🟡 Medium Priority Issues

### Issue #4: Complete Setup Wizard Tests

**Title:** `[Tech Debt] Complete Setup Wizard Test Coverage`

**Labels:** `tech-debt`, `medium-priority`, `testing`

**Body:**

````markdown
## 🟡 Medium Priority Tech Debt

## 📝 Description

Setup Wizard component has placeholder test case that was never implemented. Need to add comprehensive test coverage.

## 🔍 Current Issue

**Location:** `force-app/main/default/lwc/jtSetupWizard/__tests__/jtSetupWizard.test.js`

**Placeholder test:**

```javascript
it("TODO: test case generated by CLI command, please fill in test logic", () => {
  // Test logic missing
});
```
````

## ✅ Acceptance Criteria

- [ ] Remove placeholder test
- [ ] Implement tests for component initialization
- [ ] Test step navigation (next/previous)
- [ ] Test step completion validation
- [ ] Test error handling
- [ ] Test accessibility (keyboard navigation, ARIA)
- [ ] Achieve 80%+ test coverage for component

## 🔧 Technical Notes

- Review component functionality in `jtSetupWizard.js`
- Use Jest testing framework (already configured)
- Follow existing test patterns in other LWC components
- Test both happy path and error scenarios

## 📍 References

- `force-app/main/default/lwc/jtSetupWizard/jtSetupWizard.js`
- `force-app/main/default/lwc/jtSetupWizard/__tests__/jtSetupWizard.test.js`
- Other LWC test files for reference patterns

## 📅 Estimated Effort

**2-3 story points**

## 🎯 Priority

**Medium** - Missing test coverage

````

---

### Issue #5: Fix Accessibility Issues

**Title:** `[Tech Debt] Fix Accessibility Test Issues and Implement Missing Features`

**Labels:** `tech-debt`, `medium-priority`, `accessibility`, `testing`

**Body:**
```markdown
## 🟡 Medium Priority Tech Debt

## 📝 Description

Multiple accessibility issues identified in E2E tests: skipped color contrast test, Shadow DOM detection failures, and missing skip-to-main-content link.

## 🔍 Issues Found

### 1. Color Contrast Test Skipped
- **Location:** `tests/e2e/accessibility.spec.js:77`
- **Issue:** Test skipped due to SLDS component contrast violations
- **Comment:** "TODO: Fix SLDS component contrast violations (out of our control)"

### 2. Shadow DOM Detection Failures
- **Location:** `tests/e2e/accessibility.spec.js` (lines 438, 471, 605)
- **Issue:** Shadow DOM detection failing for injected elements
- **Comment:** "TODO: Fix Shadow DOM detection for injected elements"

### 3. Missing Skip-to-Main-Content Link
- **Location:** `tests/e2e/accessibility.spec.js:247`
- **Issue:** Skip-to-main-content link component not implemented
- **Comment:** "TODO: Implement skip-to-main-content link component"

## ✅ Acceptance Criteria

### Color Contrast
- [ ] Investigate if custom CSS can override SLDS contrast issues
- [ ] Document known violations if cannot be fixed
- [ ] Re-enable test if fixable

### Shadow DOM Detection
- [ ] Update Playwright/Axe accessibility scanning configuration
- [ ] Use proper Shadow DOM selectors
- [ ] Fix all three failing test locations
- [ ] Verify accessibility scanning works correctly

### Skip-to-Main-Content Link
- [ ] Add skip link component to main LWC
- [ ] Ensure link is visible on focus (keyboard navigation)
- [ ] Link should jump to main content area
- [ ] Test with screen reader
- [ ] Verify WCAG 2.1 AA compliance

## 🔧 Technical Notes

- Skip link should be first focusable element
- Use `#main-content` anchor or similar
- Shadow DOM: May need to use `page.evaluate()` for injected elements
- SLDS contrast: May require custom CSS overrides

## 📍 References

- `tests/e2e/accessibility.spec.js`
- `force-app/main/default/lwc/jtQueryViewer/jtQueryViewer.html`
- WCAG 2.1 AA guidelines

## 📅 Estimated Effort

**4-6 story points**

## 🎯 Priority

**Medium** - WCAG compliance incomplete
````

---

## 🟢 Low Priority Issues

### Issue #6: Update Outdated Test Comments

**Title:** `[Tech Debt] Update Outdated Test Comments`

**Labels:** `tech-debt`, `low-priority`, `documentation`

**Body:**

````markdown
## 🟢 Low Priority Tech Debt

## 📝 Description

Test comments reference removed UI elements, causing confusion in test documentation.

## 🔍 Current Issue

**Location:** `tests/e2e/queryViewerPreview.spec.js:46`

**Outdated comment:**

```javascript
// TODO: UI changed - "Data Preview" no longer exists, only "Query Preview"
```
````

## ✅ Acceptance Criteria

- [ ] Review all test files for outdated comments
- [ ] Update comments to reflect current UI
- [ ] Remove obsolete TODO comments
- [ ] Ensure comments accurately describe test behavior

## 🔧 Technical Notes

- Use grep to find all TODO comments in test files
- Review each comment against current codebase
- Update or remove as appropriate

## 📍 References

- `tests/e2e/queryViewerPreview.spec.js:46`
- Other test files with TODO comments

## 📅 Estimated Effort

**<1 story point**

## 🎯 Priority

**Low** - Documentation clarity

````

---

### Issue #7: Add Favicon

**Title:** `[Tech Debt] Add Favicon to Documentation Site`

**Labels:** `tech-debt`, `low-priority`, `ui/ux`, `documentation`

**Body:**
```markdown
## 🟢 Low Priority Tech Debt

## 📝 Description

Favicon placeholder is commented out in documentation HTML files. Missing branding in browser tabs.

## 🔍 Current Issue

**Locations:**
- `docs/index-static.html:24`
- `docs/_includes/head.html:27`

**Commented code:**
```html
<!-- Favicon (TODO: Add when ready) -->
<!-- <link rel="icon" type="image/svg+xml" href="/favicon.svg" /> -->
<!-- <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" /> -->
````

## ✅ Acceptance Criteria

- [ ] Create favicon.svg (16x16, 32x32, or scalable SVG)
- [ ] Create apple-touch-icon.png (180x180)
- [ ] Add favicon files to `docs/assets/` directory
- [ ] Uncomment and update favicon links in HTML files
- [ ] Test favicon displays correctly in browsers
- [ ] Verify favicon works on GitHub Pages

## 🔧 Technical Notes

- Use project logo/branding for favicon
- SVG format preferred for scalability
- Apple touch icon needed for iOS devices
- Ensure favicon follows GitHub Pages path structure

## 📍 References

- `docs/index-static.html:24`
- `docs/_includes/head.html:27`
- GitHub Pages favicon documentation

## 📅 Estimated Effort

**1 story point**

## 🎯 Priority

**Low** - Missing branding

````

---

### Issue #8: Clean Up Obsolete Code Comments

**Title:** `[Tech Debt] Remove Obsolete Code Comments`

**Labels:** `tech-debt`, `low-priority`, `documentation`

**Body:**
```markdown
## 🟢 Low Priority Tech Debt

## 📝 Description

Code comments reference removed code or obsolete refactoring phases, causing confusion.

## 🔍 Current Issue

**Location:** `force-app/main/default/lwc/jtQueryViewer/jtQueryViewer.js:829`

**Obsolete comment:**
```javascript
// Phase 1 Refactor: Removed obsolete getters (moved to jtSearchableCombobox)
````

## ✅ Acceptance Criteria

- [ ] Review all code comments for obsolete references
- [ ] Remove or update comments that reference removed code
- [ ] Ensure comments accurately reflect current codebase state
- [ ] Update comments to be helpful, not historical

## 🔧 Technical Notes

- Use grep to find comments with "obsolete", "removed", "Phase", etc.
- Review each comment in context
- Remove historical comments that don't add value
- Keep comments that explain current architecture

## 📍 References

- `force-app/main/default/lwc/jtQueryViewer/jtQueryViewer.js:829`
- Other files with similar patterns

## 📅 Estimated Effort

**<1 story point**

## 🎯 Priority

**Low** - Code documentation clarity

````

---

### Issue #9: Improve Test Data Realism

**Title:** `[Tech Debt] Replace Placeholder IDs with Realistic Salesforce ID Formats`

**Labels:** `tech-debt`, `low-priority`, `testing`

**Body:**
```markdown
## 🟢 Low Priority Tech Debt

## 📝 Description

Test classes use placeholder IDs like `'005XX000000XXXXXXX'` instead of realistic Salesforce ID formats. Tests may not catch real-world ID format issues.

## 🔍 Current Issue

**Examples:**
- `JT_ToolingApiUtil_Test.cls:65` - `'005XX000000XXXXXXX'`
- `JT_RunAsTestEnqueuer_Test.cls:57` - Multiple instances
- Other test classes with similar patterns

## ✅ Acceptance Criteria

- [ ] Audit all test files for placeholder IDs
- [ ] Replace with realistic Salesforce ID formats (15 or 18 character)
- [ ] Use proper ID prefixes (005 for User, 001 for Account, etc.)
- [ ] Ensure IDs follow Salesforce ID format rules
- [ ] Update test assertions if needed
- [ ] Verify tests still pass with realistic IDs

## 🔧 Technical Notes

- Salesforce IDs: 15 characters (case-sensitive) or 18 characters (case-insensitive)
- Common prefixes: 005 (User), 001 (Account), 003 (Contact), etc.
- Can use `Id.valueOf()` or generate realistic test IDs
- Consider using TestDataFactory pattern

## 📍 References

- `force-app/main/default/classes/JT_ToolingApiUtil_Test.cls:65`
- `force-app/main/default/classes/JT_RunAsTestEnqueuer_Test.cls:57`
- Salesforce ID format documentation

## 📅 Estimated Effort

**2-3 story points**

## 🎯 Priority

**Low** - Test data quality
````

---

### Issue #10: Extract Hardcoded Values

**Title:** `[Tech Debt] Extract Hardcoded Values to Configuration Constants`

**Labels:** `tech-debt`, `low-priority`, `refactoring`

**Body:**

```markdown
## 🟢 Low Priority Tech Debt

## 📝 Description

Some magic numbers and hardcoded values throughout codebase reduce configuration flexibility. Should be extracted to constants or configuration.

## 🔍 Current Issue

**Examples:**

- Retry attempts: `maxRetries = 3` (could be configurable)
- Timeout values: Various `waitForTimeout` calls with hardcoded milliseconds
- Pagination limits: Hardcoded record limits
- Other magic numbers in business logic

## ✅ Acceptance Criteria

- [ ] Identify all hardcoded values (retries, timeouts, limits)
- [ ] Create constants class or configuration object
- [ ] Extract hardcoded values to constants
- [ ] Consider making configurable via Custom Metadata or Settings
- [ ] Update all references
- [ ] Document configuration options

## 🔧 Technical Notes

- Create `JT_Constants.cls` or similar for Apex constants
- Use Custom Metadata for user-configurable values
- Keep reasonable defaults
- Document each constant's purpose

## 📍 References

- `force-app/main/default/lwc/jtQueryViewer/jtQueryViewer.js` - retry logic
- Various test files - timeout values
- Apex classes - pagination limits

## 📅 Estimated Effort

**2-3 story points**

## 🎯 Priority

**Low** - Code maintainability
```

---

## 📊 Summary

**Total Issues:** 10

**By Priority:**

- 🔴 High Priority: 3 issues (12-16 story points)
- 🟡 Medium Priority: 2 issues (6-9 story points)
- 🟢 Low Priority: 5 issues (5-8 story points)

**Total Estimated Effort:** 23-33 story points

---

## 🚀 How to Create Issues

### Option 1: Automated Script

```bash
cd /Users/jterrats/dev/JT_DynamicQueries
./scripts/create-tech-debt-issues.sh
```

### Option 2: Manual Creation

1. Go to: https://github.com/jterrats/JT_DynamicQueries/issues/new
2. Copy/paste title, labels, and body from above
3. Create issue

### Option 3: GitHub CLI (Manual)

```bash
gh issue create \
  --title "[Tech Debt] Issue Title" \
  --label "tech-debt,priority" \
  --body-file issue-body.md
```

---

_Last Updated: December 30, 2025_
