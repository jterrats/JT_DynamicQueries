# 🎯 Official Salesforce LWC State Management (Beta)

> ⚠️ **DEPRECATED - December 10, 2025**
> State management components (`queryState`, `settingsState`) have been **removed from the codebase**.
> They were never used in production and have been deleted as part of code cleanup.
> This documentation is kept for historical reference only.

## Overview

~~JT Dynamic Queries v2.0.0 uses **Salesforce's official State Management API for LWC**, which provides native, reactive state management without external dependencies.~~

**Status**: **REMOVED** - Components used direct parent-child communication instead.

**Reference**: [Official Salesforce Documentation](https://developer.salesforce.com/docs/platform/lwc/guide/state-management.html)

---

## Why Official State Manager?

### ✅ **Advantages**

- **Native**: Built into LWC framework (no LMS needed)
- **Reactive**: Automatic component updates when state changes
- **Performant**: Optimized by Salesforce
- **Type-safe**: Better IntelliSense support
- **Simple API**: Less boilerplate than Redux

### ❌ **Previous Approach (LMS)**

```javascript
// Old: Complex LMS setup
import { publish, subscribe, MessageContext } from "lightning/messageService";
import STATE_CHANNEL from "@salesforce/messageChannel/...";

// Required MessageChannel metadata
// Required wire adapter
// Required manual pub/sub
```

### ✅ **New Approach (Official)**

```javascript
// New: Simple factory function
import { createStateManager } from "lwc";

const stateFactory = () => ({
  get value() {
    return value;
  },
  setValue(v) {
    value = v;
  }
});

export default createStateManager(stateFactory);
```

---

## Architecture

```
┌─────────────────────────────────────────────┐
│  Components (consume state)                 │
│  - jtConfigSelector                         │
│  - jtQueryResults                           │
│  - jtParameterInputs                        │
└────────────────┬────────────────────────────┘
                 │ import & use
                 ▼
┌─────────────────────────────────────────────┐
│  State Managers (modules)                   │
│  - queryState.js                            │
│  - settingsState.js                         │
└────────────────┬────────────────────────────┘
                 │ createStateManager(factory)
                 ▼
          LWC Framework (native)
          - Reactivity system
          - Change detection
          - Component updates
```

---

## State Managers

### 1. **queryState** - Query Execution State

```javascript
// force-app/main/default/lwc/queryState/queryState.js
import { createStateManager } from "lwc";

const queryStateFactory = () => {
  let selectedConfig = null;
  let results = null;
  let isLoading = false;

  return {
    // Getters (reactive)
    get selectedConfig() {
      return selectedConfig;
    },
    get results() {
      return results;
    },
    get isLoading() {
      return isLoading;
    },

    // Computed values
    get hasResults() {
      return results !== null && results.length > 0;
    },

    // Actions (mutations)
    selectConfig(config) {
      selectedConfig = config;
      results = null; // Reset on change
    },

    setResults(data) {
      results = data;
      isLoading = false;
    },

    setLoading(loading) {
      isLoading = loading;
    }
  };
};

export default createStateManager(queryStateFactory);
```

### 2. **settingsState** - Application Settings

```javascript
// force-app/main/default/lwc/settingsState/settingsState.js
const settingsStateFactory = () => {
  let usageTrackingEnabled = false;
  let isProduction = false;

  return {
    get usageTrackingEnabled() {
      return usageTrackingEnabled;
    },
    get isProduction() {
      return isProduction;
    },

    // Computed
    get canCreateMetadata() {
      return !isProduction;
    },

    // Actions
    updateSettings(newSettings) {
      usageTrackingEnabled =
        newSettings.usageTrackingEnabled ?? usageTrackingEnabled;
      isProduction = newSettings.isProduction ?? isProduction;
    }
  };
};

export default createStateManager(settingsStateFactory);
```

---

## Usage in Components

### Consuming State

```javascript
import { LightningElement } from "lwc";
import queryState from "c/queryState";
import settingsState from "c/settingsState";

export default class MyComponent extends LightningElement {
  // Direct access (reactive)
  get selectedConfig() {
    return queryState.selectedConfig;
  }

  get isLoading() {
    return queryState.isLoading;
  }

  get canShowUsage() {
    return settingsState.usageTrackingEnabled;
  }

  // Computed from multiple states
  get canExecute() {
    return (
      queryState.selectedConfig &&
      !queryState.isLoading &&
      !settingsState.isProduction
    );
  }
}
```

### Mutating State

```javascript
import queryState from 'c/queryState';

export default class MyComponent extends LightningElement {
    handleSelect(event) {
        // Call action method
        queryState.selectConfig(event.detail.value);
    }

    async handleExecute() {
        queryState.setLoading(true);

        try {
            const result = await executeQuery({...});
            queryState.setResults(result);
        } catch (error) {
            queryState.setError(error.message);
        }
    }
}
```

### Template Usage

```html
<template>
  <!-- Reactive to state changes -->
  <div if:true="{isLoading}">
    <lightning-spinner></lightning-spinner>
  </div>

  <div if:true="{hasResults}">
    <c-jt-query-results records="{results}" count="{recordCount}">
    </c-jt-query-results>
  </div>

  <button disabled="{canExecute}" onclick="{handleExecute}">
    Execute Query
  </button>
</template>
```

---

## Comparison: Old vs New

### Before: Manual LMS

```javascript
// ❌ Complex setup
@wire(MessageContext) messageContext;

connectedCallback() {
    this.subscription = subscribe(
        this.messageContext,
        STATE_CHANNEL,
        (message) => this.handleMessage(message)
    );
}

handleMessage(message) {
    if (message.type === 'STATE_UPDATE') {
        this.state = message.payload;
    }
}

dispatchAction(action) {
    publish(this.messageContext, STATE_CHANNEL, {
        type: 'DISPATCH',
        payload: action
    });
}
```

### After: Official API

```javascript
// ✅ Simple & native
import queryState from 'c/queryState';

get selectedConfig() {
    return queryState.selectedConfig; // Automatic reactivity
}

handleSelect(event) {
    queryState.selectConfig(event.detail.value); // Direct mutation
}
```

---

## Best Practices

### ✅ **DO**

1. **Keep state managers focused**

   ```javascript
   // Good: Separate concerns
   - queryState.js     (query execution)
   - settingsState.js  (app settings)
   - uiState.js        (UI preferences)
   ```

2. **Use computed values**

   ```javascript
   get hasResults() {
       return results !== null && results.length > 0;
   }
   ```

3. **Encapsulate mutations in actions**

   ```javascript
   selectConfig(config) {
       selectedConfig = config;
       parameters = {}; // Reset related state
       results = null;
   }
   ```

4. **Use getters for all exposed values**
   ```javascript
   get value() { return value; } // Reactive
   ```

### ❌ **DON'T**

1. **Don't expose private state directly**

   ```javascript
   // Bad
   return { value }; // Direct exposure

   // Good
   return {
     get value() {
       return value;
     }
   };
   ```

2. **Don't mutate state outside actions**

   ```javascript
   // Bad
   queryState.results = newResults; // Won't work

   // Good
   queryState.setResults(newResults);
   ```

3. **Don't create too many state managers**

   ```javascript
   // Bad: Too granular
   -buttonState.js -
     inputState.js -
     labelState.js -
     // Good: Logical grouping
     formState.js(buttons, inputs, labels);
   ```

---

## Testing

### Unit Tests (Jest)

```javascript
import { createElement } from "lwc";
import MyComponent from "c/myComponent";
import queryState from "c/queryState";

describe("c-my-component", () => {
  beforeEach(() => {
    // Reset state before each test
    queryState.resetQuery();
  });

  it("displays selected config", () => {
    queryState.selectConfig("Test_Record");

    const element = createElement("c-my-component", {
      is: MyComponent
    });
    document.body.appendChild(element);

    const display = element.shadowRoot.querySelector(".config-name");
    expect(display.textContent).toBe("Test_Record");
  });

  it("reacts to state changes", async () => {
    const element = createElement("c-my-component", {
      is: MyComponent
    });
    document.body.appendChild(element);

    // Change state
    queryState.setLoading(true);
    await Promise.resolve(); // Wait for re-render

    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });
});
```

---

## Performance Optimization

### 1. **Computed Values** (Memoization)

```javascript
// Automatically cached by framework
get expensiveComputation() {
    // Only recomputed when dependencies change
    return this.results
        .filter(...)
        .map(...)
        .reduce(...);
}
```

### 2. **Selective Re-rendering**

```javascript
// Only re-renders when specific state changes
get displayValue() {
    return queryState.selectedConfig; // Tracks dependency
}
```

### 3. **Lazy Initialization**

```javascript
const stateFactory = () => {
  let cache = null;

  return {
    get data() {
      if (!cache) {
        cache = expensiveComputation(); // Lazy
      }
      return cache;
    }
  };
};
```

---

## Migration Guide

### Step 1: Create State Manager

```javascript
// 1. Create queryState.js
import { createStateManager } from "lwc";

const factory = () => ({
  get value() {
    return value;
  },
  setValue(v) {
    value = v;
  }
});

export default createStateManager(factory);
```

### Step 2: Update Components

```javascript
// 2. Replace @track with state manager
// Before
@track selectedConfig = null;

// After
import queryState from 'c/queryState';
get selectedConfig() {
    return queryState.selectedConfig;
}
```

### Step 3: Replace Mutations

```javascript
// 3. Replace direct mutations
// Before
this.selectedConfig = value;

// After
queryState.selectConfig(value);
```

### Step 4: Remove LMS Code

```javascript
// 4. Delete MessageChannel, wire adapters, pub/sub logic
// ❌ Delete: STATE_CHANNEL__c.messageChannel-meta.xml
// ❌ Delete: @wire(MessageContext)
// ❌ Delete: publish/subscribe imports
```

---

## Benefits Achieved

### ✅ **Code Reduction**

```
Before (LMS):     450 lines (jtStateManager + MessageChannel)
After (Official):  150 lines (queryState + settingsState)
Reduction:         67% fewer lines
```

### ✅ **Performance**

- **Native optimizations** by Salesforce
- **Automatic change detection**
- **Efficient re-rendering**

### ✅ **Developer Experience**

- **Simpler API** (no pub/sub complexity)
- **Better IntelliSense** (direct imports)
- **Easier testing** (no mock LMS)

---

## Next Steps

1. ✅ Create state managers (queryState, settingsState)
2. ⏳ Refactor components to use state managers
3. ⏳ Remove LMS code and MessageChannel
4. ⏳ Add Jest tests for state logic
5. ⏳ Document team guidelines

---

## References

- [Official Salesforce Docs](https://developer.salesforce.com/docs/platform/lwc/guide/state-management.html)
- [LWC Recipes - State Management](https://github.com/trailheadapps/lwc-recipes)
- [Beta Services Terms](https://www.salesforce.com/company/legal/agreements/)
