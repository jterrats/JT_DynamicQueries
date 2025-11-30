# jtSearchableCombobox - Usage Guide

## Overview

Generic, functional combobox component for searching and selecting from a list of options.

## Features

- ✅ Real-time search/filter
- ✅ Keyboard accessible
- ✅ Clear selection button
- ✅ Custom icons
- ✅ Validation support
- ✅ Fully reusable

## API

### Props

```javascript
@api label           // Label text
@api placeholder     // Input placeholder
@api required        // Boolean - shows * and validation
@api iconName        // SLDS icon (e.g., 'standard:user')
@api disabled        // Boolean
@api variant         // 'standard' | 'label-hidden'
@api options         // Array of { value, label, ...otherData }
```

### Events

```javascript
onselect; // Fired when option selected - detail: { value, label, data }
onclear; // Fired when selection cleared
```

### Public Methods

```javascript
@api validate()  // Returns { valid: boolean, message?: string }
@api reset()     // Clears selection
@api getValue()  // Returns selected value
@api getLabel()  // Returns selected label
```

## Usage Examples

### Example 1: Select Query Configuration

```html
<c-jt-searchable-combobox
  label="Select Query Configuration"
  placeholder="Type to search configurations..."
  options="{configurationOptions}"
  icon-name="standard:configuration"
  required
  onselect="{handleConfigSelect}"
  onclear="{handleConfigClear}"
></c-jt-searchable-combobox>
```

```javascript
// options format
configurationOptions = [
  {
    value: 'Account_By_Name',
    label: 'Account By Name (Simple)',
    baseQuery: 'SELECT Id, Name FROM Account WHERE Name LIKE :searchName',
    bindings: null,
    objectName: 'Account'
  },
  ...
];

// Handler
handleConfigSelect(event) {
  const { value, label, data } = event.detail;
  this.selectedConfig = value;
  this.baseQuery = data.baseQuery;
  this.bindings = data.bindings;
  this.objectName = data.objectName;
  // Extract parameters, reset results, etc.
}

handleConfigClear() {
  this.selectedConfig = null;
  this.baseQuery = '';
  // Reset state
}
```

### Example 2: Select User to Impersonate

```html
<c-jt-searchable-combobox
  label="Select User to Impersonate (Optional)"
  placeholder="Type to search users..."
  options="{userOptions}"
  icon-name="standard:user"
  onselect="{handleUserSelect}"
  onclear="{handleUserClear}"
></c-jt-searchable-combobox>
```

```javascript
// options format
userOptions = [
  {
    value: '005xx000001Sv5YAAS',
    label: 'John Doe (john@example.com)',
    username: 'john@example.com',
    isActive: true
  },
  ...
];

// Handler
handleUserSelect(event) {
  const { value, label, data } = event.detail;
  this.runAsUserId = value;
  this.runAsUserName = label;
}

handleUserClear() {
  this.runAsUserId = null;
  this.runAsUserName = '';
}
```

### Example 3: Generic Picklist

```html
<c-jt-searchable-combobox
  label="Select Industry"
  placeholder="Choose an industry..."
  options="{industryOptions}"
  icon-name="standard:account"
  required
  onselect="{handleIndustrySelect}"
></c-jt-searchable-combobox>
```

## Benefits

1. **DRY Principle**: Single component for all dropdowns
2. **Consistency**: Same UX across the app
3. **Maintainability**: Fix once, works everywhere
4. **Testing**: Test one component thoroughly
5. **Accessibility**: Built-in ARIA support
6. **Performance**: Optimized filtering logic

## Before vs After

### Before (Duplicated Code)

```javascript
// jtQueryViewer.js: 1,223 lines
// - Config dropdown logic: ~100 lines
// - User dropdown logic: ~100 lines
// - Total dropdown code: ~200 lines
```

### After (Reusable Component)

```javascript
// jtSearchableCombobox.js: 180 lines (reusable)
// jtQueryViewer.js: ~950 lines (23% reduction)
// - Config: <c-jt-searchable-combobox /> (1 line)
// - User: <c-jt-searchable-combobox /> (1 line)
```

## Phase 1 Refactor Complete ✅

- [x] Extract generic combobox
- [x] Deploy component
- [ ] Update jtQueryViewer HTML (Config)
- [ ] Update jtQueryViewer HTML (User)
- [ ] Update jtQueryViewer JS (Remove duplicate logic)
- [ ] Update E2E tests
- [ ] Final deploy & test
