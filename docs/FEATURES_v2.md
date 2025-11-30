# Features Documentation - v2.0

## 🎨 User Interface Components

### 1. Searchable Combobox Component

**Component:** `jtSearchableCombobox`

**Purpose:** Generic, reusable dropdown with real-time filtering

**Features:**

- ✅ Client-side filtering (no server round-trips)
- ✅ Keyboard navigation (Arrow keys, Enter, Escape)
- ✅ Accessibility (WCAG 2.1 AA)
- ✅ Validation states (required fields, custom messages)
- ✅ Clear selection button
- ✅ Customizable via @api properties

**Usage Example:**

```html
<c-jt-searchable-combobox
  label="Select Configuration"
  placeholder="Type to search..."
  options="{configOptions}"
  required
  onselect="{handleSelect}"
  onclear="{handleClear}"
></c-jt-searchable-combobox>
```

**API Properties:**
| Property | Type | Description |
|----------|------|-------------|
| `label` | String | Display label |
| `placeholder` | String | Input placeholder text |
| `options` | Array | `[{value, label}]` |
| `required` | Boolean | Validation flag |
| `disabled` | Boolean | Disabled state |
| `noResultsText` | String | Message when no results |
| `errorText` | String | Validation error message |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `select` | `{value, label, data}` | Option selected |
| `clear` | none | Selection cleared |

---

### 2. Dynamic Parameter Inputs

**Component:** `jtParameterInputs`

**Purpose:** Auto-generate input fields from SOQL bind variables

**Features:**

- ✅ Regex extraction of `:variable` from SOQL
- ✅ Handles various spacing: `= :var`, `=:var`, `= : var`
- ✅ Contextual tooltips (shows variable usage in query)
- ✅ Type inference (String by default, extensible)
- ✅ Validation support

**Auto-Detection:**

```sql
-- SOQL Query:
SELECT Id, Name FROM Account WHERE Type = :accountType AND Industry = :industry

-- Auto-Generated Inputs:
┌─────────────────────────────────────────┐
│ accountType: [____________]  ℹ️          │
│ industry:    [____________]  ℹ️          │
└─────────────────────────────────────────┘
```

**Tooltip Example:**

```
ℹ️ accountType
Used in query: WHERE Type = :accountType
```

---

### 3. Query Results Viewer

**Component:** `jtQueryResults`

**Purpose:** Advanced results display with multiple view modes

**View Modes:**

#### **Table View** (Default)

- Lightning DataTable for desktop
- Sortable columns
- Client-side pagination (10 records/page)
- Always shows column headers (even with 0 results)

#### **JSON View**

- Syntax-highlighted JSON
- Includes metadata (query, count, timestamp)
- Copy-friendly formatting
- Useful for LLMs and debugging

```json
{
  "metadata": {
    "query": "SELECT Id, Name FROM Account...",
    "count": 5,
    "executedAt": "2025-11-30T10:30:00Z"
  },
  "records": [...]
}
```

#### **CSV View**

- Plain text CSV format
- Downloadable as `.csv` file
- Includes headers
- Excel-compatible

#### **Mobile View** (Auto-responsive)

- Expandable cards instead of table
- Touch-friendly buttons
- Optimized for small screens
- Maintains all functionality

**Toggle Buttons:**

```
┌─────────────────────────────────────┐
│ [Table] [JSON] [CSV]   📥 Export    │
├─────────────────────────────────────┤
│ ... results ...                     │
└─────────────────────────────────────┘
```

---

## 🔐 Advanced Features

### 4. "Where is this used?" Search

**Purpose:** Find all references to a query configuration in code

**Search Scope:**

#### **Apex Classes** (No API consumption)

- Searches all `ApexClass` records via SOQL
- Looks for: `JT_DataSelector.getRecords('ConfigName')`
- Shows: Class name + line number
- **Performance:** ~0 API calls, uses standard SOQL

#### **Flows** (Tooling API - 1-5 API calls)

- Queries Flow metadata via Tooling API
- Looks for: Configuration name in Flow definitions
- Shows: Flow API name + type
- **Performance:** 1-5 API calls per search (based on Flow count)

**Resilient Architecture:**

- ✅ Both searches run independently
- ✅ Partial results displayed if one fails
- ✅ Clear error messages for troubleshooting
- ✅ Apex results always available (no API dependency)

**Example Output:**

```
✓ Apex Search: Complete
✓ Flow Search: Complete

Found 3 references:

Type        | Name                    | Line
------------|-------------------------|------
Apex Class  | AccountController       | 45
Apex Class  | OpportunityService      | 128
Flow        | Account_Update_Flow     | N/A
```

**Error Handling:**

```
✓ Apex Search: Complete
⚠️ Flow Search: Failed
Error: Named Credential not configured

Found 2 references (Apex only):
...
```

---

### 5. Run As User (Advanced Testing)

**Purpose:** Test queries in another user's permission context

**Modes:**

#### **Standard Execution**

- Uses `WITH USER_MODE` in SOQL
- Validates user has access to required objects
- Fast execution (no test context overhead)
- Shows: Results the selected user would see

#### **System.runAs() Mode** (Test Context)

- True impersonation using Apex test context
- Executes query inside `System.runAs(selectedUser)`
- Returns JSON with:
  - Actual records the user can see
  - Sharing rule enforcement
  - Field-level security validation
- **Note:** Runs in test context (may have slight differences from production)

**User Selection:**

- Searchable dropdown with all active users
- Excludes current user
- Client-side filtering for performance
- Shows: Username + Full Name

**Security Note:**

```
⚠️ Note: This validates user permissions but executes
with USER_MODE security. Results reflect sharing rules
and field-level security.
```

---

### 6. Metadata Creation UI

**Purpose:** Create/edit query configurations without code

**Features:**

#### **Real-Time Validation**

- SOQL syntax check as you type
- Error messages for invalid queries
- Success indicator when valid

#### **Auto-Detection**

- Object name extracted from `FROM` clause
- Read-only once detected
- Updates automatically as you edit query

#### **Query Preview**

- Shows formatted SOQL once valid
- Highlights bind variables
- Shows extracted object name

#### **Environment Awareness**

- ✅ **Sandbox/Scratch/Developer:** Create button visible
- ❌ **Production:** Create button hidden
- ⚠️ **Starter/Free Edition:** Optional checkbox with security warning

**Fields:**
| Field | Required | Auto-Generated | Editable |
|-------|----------|----------------|----------|
| Label | ✅ Yes | No | ✅ Yes |
| Developer Name | ✅ Yes | Yes (from label) | ✅ Yes |
| Base Query | ✅ Yes | No | ✅ Yes |
| Object Name | ✅ Yes | Yes (from query) | ❌ No (read-only) |
| Bindings (JSON) | No | No | ✅ Yes |

**Example Workflow:**

1. Click **+ Create Configuration**
2. Enter label: `"Active Opportunities"`
3. Developer name auto-fills: `Active_Opportunities`
4. Enter query:
   ```sql
   SELECT Id, Name, Amount FROM Opportunity
   WHERE StageName = 'Closed Won'
   ```
5. Object name auto-detects: `Opportunity` (read-only)
6. (Optional) Add bindings JSON:
   ```json
   { "stageName": "Prospecting" }
   ```
7. Preview shows formatted query
8. Click **Save** → Deploys via Tooling API (2-3 API calls)
9. Configuration list auto-refreshes

---

## 🌍 Internationalization (i18n)

### Supported Languages (v2.0)

| Language             | Code    | Status      |
| -------------------- | ------- | ----------- |
| English              | `en`    | ✅ Complete |
| Spanish              | `es`    | ✅ Complete |
| French               | `fr`    | ✅ Complete |
| German               | `de`    | ✅ Complete |
| Italian              | `it`    | ✅ Complete |
| Japanese             | `ja`    | ✅ Complete |
| Portuguese (BR)      | `pt_BR` | ✅ Complete |
| Chinese (Simplified) | `zh_CN` | ✅ Complete |

### Translation Strategy

**JavaScript Labels** (`labels.js`):

- All UI text stored in centralized file
- Detects user locale automatically
- Falls back to English if locale not supported
- Dynamic label resolution

**Custom Labels** (Future):

- Plan to migrate to Custom Labels for admin customization
- Currently using JS for faster iteration

**Object Translations:**

- Custom Metadata: Translated (8 languages)
- Custom Objects: Translated (8 languages)
- Custom Settings: Translated (8 languages)

---

## 🔒 Security & Compliance

### Named Credentials (v2.0)

**Why Named Credentials?**

1. ✅ **AppExchange Requirement**: Security Review compliant
2. ✅ **Credential Encryption**: Client secrets encrypted by Salesforce
3. ✅ **No Code Changes**: Admin can update credentials without redeployment
4. ✅ **OAuth 2.0**: Industry-standard authentication
5. ✅ **Audit Trail**: All callouts logged

**Setup Required:**

1. Create Connected App
2. Configure External Credential (OAuth 2.0)
3. Link Named Credential to External Credential
4. Test configuration

**See:** [TOOLING_API_SETUP.md](./TOOLING_API_SETUP.md) for complete guide

### API Consumption Monitoring

**Features That Consume API Calls:**

| Feature                       | API Calls | Can Disable?                 |
| ----------------------------- | --------- | ---------------------------- |
| "Where is this used?" (Apex)  | 0         | N/A (always available)       |
| "Where is this used?" (Flows) | 1-5       | ✅ Yes (checkbox toggle)     |
| Create Configuration          | 2-3       | ✅ Yes (hide button in prod) |
| Edit Configuration            | 2-3       | ✅ Yes (hide button in prod) |

**Daily Limits:**

- Varies by org edition
- Typical range: 15,000 - 100,000 calls/day
- Monitor in Setup → System Overview

**Audit Logging:**

- All usage searches logged to `JT_SettingsAuditLog__c`
- Tracks: User, timestamp, config name, result count
- Filterable in Audit History tab

---

## ♿ Accessibility (WCAG 2.1 AA)

### Compliance Features

**Keyboard Navigation:**

- ✅ Tab order logical and complete
- ✅ All actions accessible via keyboard
- ✅ Visible focus indicators
- ✅ No keyboard traps

**Screen Reader Support:**

- ✅ Proper ARIA labels (`aria-label`, `aria-labelledby`)
- ✅ Live regions for dynamic content (`aria-live`)
- ✅ Required field indicators (`aria-required`)
- ✅ Role attributes (`role="combobox"`, `role="listbox"`)

**Visual Accessibility:**

- ✅ Color contrast ratios meet WCAG AA standards
- ✅ Text resizable up to 200%
- ✅ Clear visual focus indicators
- ✅ Error messages associated with form fields

**Component-Specific:**

| Component              | Accessibility Features                                                |
| ---------------------- | --------------------------------------------------------------------- |
| `jtSearchableCombobox` | ARIA combobox pattern, keyboard nav, screen reader announcements      |
| `jtQueryResults`       | Table headers, row/column associations, expand/collapse announcements |
| `jtConfigModal`        | Modal focus trap, ESC key close, required field validation            |
| `jtExecuteButton`      | Loading state announced, disabled state communicated                  |

---

## 📊 Performance Optimizations (v2.0)

### Client-Side Filtering

**Problem (v1.0):** Server callout for every keystroke in search

**Solution (v2.0):** Filter options in browser

**Impact:**

- Before: 10 keystrokes = 10 server calls
- After: 10 keystrokes = 0 server calls
- **Improvement:** 100% reduction in API calls for filtering

### Component-Based Rendering

**Problem (v1.0):** Full page re-render on any state change

**Solution (v2.0):** Granular component updates

**Impact:**

- Before: Change dropdown → re-render entire 1200-line template
- After: Change dropdown → re-render 50-line component
- **Improvement:** ~80% reduction in DOM operations

### Functional Programming Benefits

**Pure Functions = Memoization**

```javascript
// Can safely memoize this - same input always gives same output
const transformToCSV = memoize((records) => {
  return records.map((r) => Object.values(r).join(",")).join("\n");
});
```

**Benefits:**

- Avoid redundant computations
- Predictable performance
- Easier to optimize with caching

---

## 🔄 State Management (Optional)

### Current Approach: Parent-Driven State

**Architecture:**

```
jtQueryViewer (Parent)
  ├─ State: selectedConfig, parameters, results
  ├─ Passes props to children
  └─ Children emit events back
```

**Why This Works:**

- ✅ Simple mental model
- ✅ Easy to debug (single source of truth)
- ✅ No external state management library needed
- ✅ LWC lifecycle handles reactivity

### Future: State Management Components (Included but Optional)

**Components:** `queryState`, `settingsState`

**When to Use:**

- Multiple unrelated components need same state
- Deep nesting (>3 levels)
- Cross-tab communication

**When to Avoid:**

- Current simple parent-child architecture
- Small to medium component trees

---

## 🐛 Error Handling & Resilience

### Error Boundaries (LWC)

**Implementation:**

```javascript
// jtQueryViewer.js
errorCallback(error, stack) {
    console.error('Component Error:', error);
    console.error('Stack:', stack);

    // Show user-friendly message
    this.showToast('Warning',
        'A component failed to load. Other features remain functional.',
        'warning'
    );

    // Continue execution - don't crash entire app
}
```

**Benefits:**

- ✅ Isolated failures
- ✅ Graceful degradation
- ✅ User-friendly error messages
- ✅ Debug information logged

### Microservices Pattern (Apex)

**See:** [MICROSERVICES_PATTERN.md](./MICROSERVICES_PATTERN.md)

**Key Principle:** Independent services that fail independently

**Example - JT_UsageFinder:**

```apex
// Service 1: Apex search (always works)
ServiceResponse apexResponse = findInApexClasses(configName);

// Service 2: Flow search (may fail due to Tooling API)
ServiceResponse flowResponse = findInFlows(configName);

// Return both, even if one failed
return new AggregatedResponse(apexResponse, flowResponse);
```

**UI Handling:**

- If both succeed: Show complete results
- If Apex succeeds, Flow fails: Show Apex results + error message
- If both fail: Show clear error message

---

## 📱 Responsive Design

### Breakpoints

| Breakpoint | Width          | Layout                           |
| ---------- | -------------- | -------------------------------- |
| Mobile     | < 768px        | Expandable cards, stacked inputs |
| Tablet     | 768px - 1024px | Hybrid (some cards, some tables) |
| Desktop    | > 1024px       | Full tables, side-by-side layout |

### Mobile-Specific Features

**Query Results:**

- Desktop: `lightning-datatable`
- Mobile: Expandable cards with toggle buttons

**Forms:**

- Desktop: Multi-column layout (2-3 columns)
- Mobile: Single column, full-width inputs

**Modals:**

- Desktop: Centered, fixed width
- Mobile: Full-screen overlay

---

## 🧪 Testing Strategy

### E2E Tests (Playwright)

**Test Categories:**

1. **Component Loading** (3 tests)
2. **User Interactions** (8 tests)
3. **Data Operations** (5 tests)
4. **Accessibility** (4 tests)
5. **Responsive Design** (2 tests)
6. **i18n** (2 tests)
7. **Component Integration** (4 tests)

**Key Features:**

- ✅ No manual login (uses SF CLI session)
- ✅ Cookie injection for fast authentication
- ✅ Screenshots and videos on failure
- ✅ Parallel execution support
- ✅ Headless mode for CI/CD

### Apex Unit Tests

**Coverage by Class:**
| Class | Coverage | Tests |
|-------|----------|-------|
| JT_DataSelector | 95% | 12 methods |
| JT_UsageFinder | 92% | 8 methods |
| JT_MetadataCreator | 88% | 6 methods |
| JT_QueryViewerController | 91% | 10 methods |
| JT_RunAsTestExecutor | 89% | 5 methods |
| JT_ProductionSettingsController | 90% | 7 methods |

**Overall:** 84.5% average coverage

---

## 📚 Documentation

### Available Guides

| Document                                                       | Language | Topic                                |
| -------------------------------------------------------------- | -------- | ------------------------------------ |
| [README.md](../README.md)                                      | EN       | Overview, quick start, features      |
| [ARCHITECTURE.md](./ARCHITECTURE.md)                           | EN       | System design, patterns, performance |
| [CHANGELOG.md](../CHANGELOG.md)                                | EN       | Version history, breaking changes    |
| [TOOLING_API_SETUP.md](./TOOLING_API_SETUP.md)                 | EN       | Step-by-step Tooling API setup       |
| [TOOLING_API_SETUP_ES.md](./TOOLING_API_SETUP_ES.md)           | ES       | Guía de configuración Tooling API    |
| [SEARCHABLE_COMBOBOX_USAGE.md](./SEARCHABLE_COMBOBOX_USAGE.md) | EN       | Component API reference              |
| [MICROSERVICES_PATTERN.md](./MICROSERVICES_PATTERN.md)         | EN       | Resilient architecture               |
| [TRANSLATIONS_ARCHITECTURE.md](./TRANSLATIONS_ARCHITECTURE.md) | EN       | i18n implementation                  |
| [ACCESSIBILITY.md](../ACCESSIBILITY.md)                        | EN       | WCAG 2.1 compliance details          |

### In-App Documentation

Accessible via **Documentation** tab, includes:

- Overview (translated to 8 languages)
- How to use (with examples)
- Security model
- Troubleshooting
- API reference

---

## 🚀 Future Enhancements (v2.1+)

### Planned Features

1. **GitHub Actions CI/CD**
   - Automated E2E tests on PR
   - Jekyll GitHub Pages for documentation
   - Test result videos

2. **Reports & Dashboards**
   - Report Type over custom metadata
   - Dashboard showing most-used configurations
   - API consumption analytics

3. **Bulk Operations**
   - Multi-select configurations
   - Batch execution
   - Results comparison

4. **Export/Import**
   - Export configurations to JSON
   - Import from other orgs
   - Version control integration

5. **Advanced Search**
   - Full-text search in configurations
   - Search by object name
   - Search by query content

6. **More Languages**
   - Korean
   - Dutch
   - Russian
   - Arabic (RTL support)

---

## 📞 Support & Contributing

**Need Help?**

- 📖 Check [Documentation tab](./docs/TOOLING_API_SETUP.md)
- 🐛 [Open an Issue](https://github.com/YOUR_REPO/issues)
- 💬 [Salesforce Trailblazer Community](https://trailhead.salesforce.com/)

**Want to Contribute?**

- 🔧 Fork the repo
- 🌿 Create a feature branch
- ✅ Add tests (E2E + Apex)
- 📝 Update documentation
- 🚀 Submit a Pull Request

---

**Version:** 2.0.0
**Last Updated:** 2025-11-30
**License:** MIT
