# 🎯 Semantic HTML Improvements - Implementation Plan

## 📋 Objective

Ensure all IDs, names, data-attributes, and CSS classes in LWCs are:

- **Semantic**: Clearly describe their purpose
- **Non-ambiguous**: Unique and specific to context
- **Testable**: Easy to select in E2E tests
- **Maintainable**: Easy to understand for developers

---

## 🔍 Component Analysis

### ✅ **jtSearchableCombobox** - IMPROVE

**Current problems:**

```html
<input id="combobox-input" />
<!-- ❌ Generic -->
<div id="listbox-id" />
<!-- ❌ Not descriptive -->
```

**Proposed improvements:**

```html
<input
  id="searchable-combobox-input"
  data-testid="searchable-combobox-input"
  name="{contextualName}"            <!-- Passed as prop -->
  aria-label="{label}"
/>
<div
  id="searchable-combobox-listbox"
  data-testid="searchable-combobox-dropdown"
  role="listbox"
/>
```

**Benefits:**

- E2E tests can use: `page.locator('[data-testid="config-selector-input"]')`
- Unique in parent component context

---

### ✅ **jtParameterInputs** - IMPROVE

**Current state:**

```html
<lightning-input data-param="{param.name}" />
```

**Proposed improvements:**

```html
<lightning-input
  data-param="{param.name}"
  data-testid="query-parameter-{param.name}"
  name="query-parameter-{param.name}"
  aria-label="Query parameter: {param.label}"
/>
```

**Benefits:**

- Tests can select specific parameters: `page.locator('[data-testid="query-parameter-accountName"]')`

---

### ✅ **jtExecuteButton** - IMPROVE

**Current problem:**

- No specific identifiers beyond label

**Proposed improvements:**

```html
<lightning-button
  data-testid="execute-query-button"
  name="execute-query"
  aria-label="Execute selected query configuration"
/>
```

---

### ✅ **jtCacheModal** - IMPROVE

**Current problems:**

```html
<lightning-input label="Query Configurations" />
<!-- ❌ Only label -->
<button class="slds-button slds-button_brand" />
<!-- ❌ No ID -->
```

**Proposed improvements:**

```html
<lightning-input
  type="checkbox"
  data-testid="cache-option-configurations"
  name="cache-option-configurations"
  label="Query Configurations"
/>

<button
  data-testid="cache-clear-button"
  name="clear-cache"
  aria-label="Clear selected cache options"
/>
```

**Benefits:**

- Tests: `page.locator('[data-testid="cache-option-configurations"]').check()`
- Tests: `page.locator('[data-testid="cache-clear-button"]').click()`

---

### ✅ **jtQueryViewer** - IMPROVE

**Current problems:**

```html
<!-- View toggle buttons -->
<lightning-button data-view="table" />
<!-- ⚠️  Could be improved -->
<lightning-button data-view="json" />
<lightning-button data-view="csv" />

<!-- Pagination -->
<lightning-button icon-name="utility:chevronleft" />
<!-- ❌ No ID -->
<lightning-button icon-name="utility:chevronright" />
<!-- ❌ No ID -->

<!-- Mobile cards -->
<article class="slds-card" data-id="{row.Id}" />
<!-- ⚠️  Minor improvement -->
```

**Proposed improvements:**

```html
<!-- View toggle buttons -->
<lightning-button
  data-view="table"
  data-testid="results-view-toggle-table"
  name="results-view-table"
  aria-label="View results as table"
/>

<!-- Pagination -->
<lightning-button
  data-testid="pagination-previous"
  name="pagination-previous"
  icon-name="utility:chevronleft"
  aria-label="Go to previous page"
/>

<!-- Mobile cards -->
<article
  class="slds-card mobile-result-card"
  data-testid="result-card-{row.Id}"
  data-row-id="{row.Id}"
/>

<!-- Clear Cache Button -->
<lightning-button
  data-testid="header-clear-cache-button"
  name="clear-cache"
  aria-label="Open cache management modal"
/>

<!-- Create Config Button -->
<lightning-button
  data-testid="header-create-config-button"
  name="create-configuration"
  aria-label="Create new query configuration"
/>
```

---

### ✅ **jtRunAsSection** - IMPROVE

**Proposed improvements:**

```html
<c-jt-searchable-combobox
  data-testid="run-as-user-selector"
  name="run-as-user"
/>

<lightning-button data-testid="run-as-clear-button" name="run-as-clear" />

<lightning-button data-testid="run-as-execute-button" name="run-as-execute" />
```

---

### ✅ **jtConfigModal** - IMPROVE

**Proposed improvements:**

```html
<lightning-input
  data-testid="config-label-input"
  name="config-label"
  label="Label"
/>

<lightning-textarea
  data-testid="config-query-input"
  name="config-base-query"
  label="SOQL Query"
/>

<lightning-button data-testid="config-save-button" name="save-configuration" />
```

---

## 🎯 Naming Conventions

### **data-testid Pattern:**

```
{componentContext}-{element}-{type}

Examples:
- "config-selector-input"
- "query-parameter-accountName"
- "execute-query-button"
- "cache-option-configurations"
- "pagination-previous"
- "results-view-toggle-table"
```

### **name Pattern:**

```
{function}-{detail}

Examples:
- "execute-query"
- "clear-cache"
- "create-configuration"
- "run-as-user"
- "query-parameter-accountName"
```

### **ID Pattern (if necessary):**

```
{componentName}-{element}-{uniqueId}

Examples:
- "searchable-combobox-input"
- "cache-modal-heading"
- "execute-button-status"
```

---

## 📊 Implementation Priority

### **High Priority (Critical for E2E)**

1. ✅ **jtSearchableCombobox** - Used in multiple places
2. ✅ **jtExecuteButton** - Main action
3. ✅ **jtParameterInputs** - Critical data input
4. ✅ **jtCacheModal** - Cache management tests

### **Medium Priority**

5. ✅ **jtQueryViewer** - Main component
6. ✅ **jtRunAsSection** - Important feature

### **Low Priority**

7. ⚠️ **jtConfigModal** - Less used in tests
8. ⚠️ **jtQueryResults** - Already has clear structure
9. ⚠️ **jtUsageModal** - Read-only modal

---

## 🚀 Implementation

### Step 1: Add `data-testid` to reusable components

Components that RECEIVE `data-testid` as prop:

- `c-jt-searchable-combobox`
- `c-jt-execute-button`
- `c-jt-parameter-inputs`

### Step 2: Add `data-testid` to elements in parent components

Components that USE reusables with specific `data-testid`:

- `c-jt-query-viewer`
- `c-jt-cache-modal`
- `c-jt-run-as-section`

### Step 3: Update E2E tests

Change from:

```javascript
page.locator("lightning-button").filter({ hasText: /Execute/i });
```

To:

```javascript
page.locator('[data-testid="execute-query-button"]');
```

---

## ✅ Benefits

1. **More robust E2E tests**: Don't depend on text that can change with i18n
2. **Faster selectors**: `data-testid` is faster than text filters
3. **More maintainable code**: Clear names facilitate debugging
4. **Improved accessibility**: More specific ARIA labels
5. **Fewer failures due to ambiguity**: Unique selectors avoid "strict mode violations"

---

## 📝 Implementation Checklist

### jtSearchableCombobox

- [ ] Add prop `dataTestId`
- [ ] Add prop `name`
- [ ] Use in input: `data-testid="{dataTestId}-input"`
- [ ] Use in dropdown: `data-testid="{dataTestId}-dropdown"`
- [ ] Use in options: `data-testid="{dataTestId}-option-{value}"`

### jtExecuteButton

- [ ] Add prop `dataTestId`
- [ ] Add prop `name`
- [ ] Default: `data-testid="execute-query-button"`

### jtParameterInputs

- [ ] Add `data-testid` to each input
- [ ] Pattern: `query-parameter-{paramName}`

### jtCacheModal

- [ ] Add `data-testid` to each checkbox
- [ ] Add `data-testid` to buttons
- [ ] Add `data-testid` to select all

### jtQueryViewer

- [ ] Add `data-testid` to view toggle buttons
- [ ] Add `data-testid` to pagination buttons
- [ ] Add `data-testid` to header actions
- [ ] Pass `data-testid` to child components

### jtRunAsSection

- [ ] Pass `data-testid` to searchable combobox
- [ ] Add `data-testid` to buttons

---

## 🎉 Expected Result

**Before:**

```javascript
// Fragile test
const button = page.locator("lightning-button").filter({ hasText: /Execute/i });
```

**After:**

```javascript
// Robust test
const button = page.locator('[data-testid="execute-query-button"]');
```

**Before:**

```javascript
// Ambiguous selector
const combobox = page.locator("c-jt-query-viewer lightning-combobox");
// Error: found 2 elements ❌
```

**After:**

```javascript
// Specific selector
const configSelector = page.locator('[data-testid="config-selector-input"]');
const userSelector = page.locator('[data-testid="run-as-user-selector-input"]');
// ✅ No ambiguity
```

---

**Creation date**: December 1, 2024
**Status**: 🚧 In Progress
