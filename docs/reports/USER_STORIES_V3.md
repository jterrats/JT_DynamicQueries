# User Stories - v3.0 Roadmap

**Last Updated:** 2025-12-02
**Status:** Planning Phase
**Target Release:** Q1 2026

---

## 🎨 **UI/UX Enhancements**

### **US-001: Dark Mode Support** 🌙

**Priority:** Medium
**Story Points:** 8
**Status:** Planned

**As a** user working in low-light environments
**I want** the application to support dark mode
**So that** I can reduce eye strain and match my Salesforce theme preferences

**Acceptance Criteria:**

- [ ] Replace all hardcoded colors (#ffffff, #080707, etc.) with SLDS design tokens
- [ ] Code blocks adapt to theme (light/dark)
- [ ] All 9 LWC components support dark mode
- [ ] Tested with Salesforce dark theme enabled
- [ ] No visual regressions in light mode
- [ ] **Accessibility:** WCAG 2.1 AA color contrast maintained in both themes (4.5:1 for text, 3:1 for UI)
- [ ] **Semantic IDs:** All interactive elements have semantic `test-id` attributes (e.g., `test-id="theme-toggle-button"`)
- [ ] **E2E Tests:** Playwright tests verify dark mode visual consistency and accessibility

**Technical Notes:**

- 129 hardcoded colors identified in CSS files
- Use `var(--slds-g-color-*)` tokens
- Test in both themes before commit

**Dependencies:** None

---

### **US-002: Visual SOQL Builder** 🎨

**Priority:** High
**Story Points:** 21
**Status:** Planned

**As a** user without deep SOQL knowledge
**I want** a drag-and-drop interface to build queries
**So that** I can create configurations without writing raw SOQL

**Acceptance Criteria:**

- [ ] Select object from dropdown
- [ ] Drag fields to query builder
- [ ] Add WHERE conditions visually
- [ ] Add ORDER BY and LIMIT controls
- [ ] Preview generated SOQL in real-time
- [ ] Save as Custom Metadata configuration
- [ ] **Accessibility:** Drag-and-drop has keyboard alternatives (arrow keys + Space/Enter)
- [ ] **Accessibility:** Screen reader announces field selections and query changes (ARIA live regions)
- [ ] **Semantic IDs:** All query builder elements have semantic names (e.g., `test-id="field-selector-Account-Name"`)
- [ ] **E2E Tests:** Playwright tests verify keyboard-only navigation and ARIA announcements

**Technical Notes:**

- New LWC component: `jtQueryBuilder`
- Integrate with `jtConfigModal`
- Use Salesforce Schema API for object/field metadata

**Dependencies:** None

---

## 🔧 **Framework Extensions**

### **US-003: DML Framework (JT_DataModifier)** 💾

**Priority:** Low
**Story Points:** 13
**Status:** Backlog

**As a** developer building data operations
**I want** a DML framework similar to JT_DataSelector
**So that** I can perform INSERT/UPDATE/DELETE/UPSERT with consistent patterns

**Acceptance Criteria:**

- [ ] `JT_DataModifier` class created (public API)
- [ ] Methods: `insertRecords()`, `updateRecords()`, `deleteRecords()`, `upsertRecords()`
- [ ] Support for `allOrNone`, `AccessLevel.USER_MODE/SYSTEM_MODE`
- [ ] Comprehensive error handling and validation
- [ ] 100% test coverage
- [ ] Documentation in API Reference tab
- [ ] Usage examples in docs
- [ ] **Accessibility:** API documentation uses semantic HTML (headings, tables, code blocks)
- [ ] **Semantic Naming:** Method parameters use descriptive names (e.g., `recordsToInsert`, not `records1`)

**Technical Notes:**

- Use `Database.insert/update/delete` with options
- Follow existing Selector/Domain pattern
- NOT included in Permission Set (API only)

**Dependencies:** User feedback required to prioritize

---

## 📊 **Data Management**

### **US-004: Query History & Favorites** ⭐

**Priority:** High
**Story Points:** 8
**Status:** Planned

**As a** frequent user
**I want** to save my favorite queries and see my query history
**So that** I can quickly re-run common queries

**Acceptance Criteria:**

- [ ] Save query + parameters as "favorite" (custom setting)
- [ ] View last 10 executed queries (Platform Cache)
- [ ] One-click to re-run from history
- [ ] Filter favorites by tag/category
- [ ] Export/Import favorites
- [ ] **Accessibility:** Favorite/history modal is keyboard navigable (Tab, Enter, Escape)
- [ ] **Accessibility:** Screen reader announces "Added to favorites" / "Query re-run" confirmations
- [ ] **Semantic IDs:** Favorites/history items have semantic IDs (e.g., `test-id="favorite-AccountSearch-123"`)
- [ ] **E2E Tests:** Playwright tests verify favorites CRUD and keyboard shortcuts (Ctrl+S to save)

**Technical Notes:**

- Use `JT_QueryFavorites__c` custom setting
- Platform Cache for history (last 10)
- New modal component: `jtHistoryModal`

**Dependencies:** None

---

### **US-005: Bulk Query Execution** 📦

**Priority:** Medium
**Story Points:** 5
**Status:** Planned

**As a** data analyst
**I want** to execute multiple configurations at once
**So that** I can compare results side-by-side

**Acceptance Criteria:**

- [ ] Multi-select configurations (checkbox mode)
- [ ] "Execute All" button
- [ ] Show results in tabs or accordion
- [ ] Export all results to single CSV
- [ ] Progress indicator for batch execution
- [ ] **Accessibility:** Checkboxes have proper labels and ARIA attributes (`aria-checked`, `role="checkbox"`)
- [ ] **Accessibility:** Progress indicator announces completion percentage to screen readers
- [ ] **Semantic IDs:** Each configuration checkbox has semantic ID (e.g., `test-id="bulk-select-AccountSearch"`)
- [ ] **E2E Tests:** Playwright tests verify bulk selection, execution order, and progress updates

**Technical Notes:**

- Queue pattern for sequential execution
- Use `Promise.all()` for parallel calls (with limits)
- New component: `jtBulkExecutor`

**Dependencies:** None

---

## 🔍 **Query Features**

### **US-006: Real-Time Query Validation** ✅

**Priority:** Medium
**Story Points:** 5
**Status:** Planned

**As a** query creator
**I want** SOQL syntax validation as I type
**So that** I catch errors before saving

**Acceptance Criteria:**

- [ ] Debounced validation (500ms after typing stops)
- [ ] Show syntax errors inline
- [ ] Highlight invalid bind variables
- [ ] Suggest object/field names (autocomplete)
- [ ] Validate security (FLS/CRUD)
- [ ] **Accessibility:** Error messages announced via ARIA live regions (`role="alert"`, `aria-live="assertive"`)
- [ ] **Accessibility:** Syntax errors have clear focus indicators for keyboard navigation
- [ ] **Semantic IDs:** Validation messages have semantic IDs (e.g., `test-id="validation-error-line-5"`)
- [ ] **E2E Tests:** Playwright tests verify error announcements and keyboard-only correction

**Technical Notes:**

- Use Tooling API for validation
- Client-side regex for basic validation
- Server-side for deep validation

**Dependencies:** Tooling API Named Credential

---

### **US-007: Query Templates Library** 📚

**Priority:** Low
**Story Points:** 3
**Status:** Backlog

**As a** new user
**I want** pre-built query templates
**So that** I can learn by example and get started quickly

**Acceptance Criteria:**

- [ ] 10+ common query templates (Account, Opportunity, Case, etc.)
- [ ] Template categories (Sales, Service, Marketing)
- [ ] "Create from Template" button
- [ ] Templates included in package (Custom Metadata)
- [ ] **Accessibility:** Template cards have descriptive ARIA labels (e.g., `aria-label="Account Sales Template - 5 fields"`)
- [ ] **Semantic IDs:** Templates use semantic naming (e.g., `test-id="template-account-sales"`)
- [ ] **E2E Tests:** Playwright tests verify template selection and preview

**Technical Notes:**

- Ship as part of managed package
- Templates use common objects only (no custom fields)

**Dependencies:** None

---

### **US-008: Advanced Result Filtering** 🔎

**Priority:** Medium
**Story Points:** 8
**Status:** Planned

**As a** user reviewing large result sets
**I want** to filter/search results after execution
**So that** I can find specific records without re-running the query

**Acceptance Criteria:**

- [ ] Column-level filters (text search, date range, picklist)
- [ ] Global search across all columns
- [ ] Filter persistence (remember filters)
- [ ] Clear all filters button
- [ ] Visual indicator for active filters
- [ ] **Accessibility:** Filter inputs have proper labels and placeholders (`aria-label="Filter by Name"`)
- [ ] **Accessibility:** Active filters announced to screen readers (e.g., "3 filters active")
- [ ] **Semantic IDs:** Filter inputs use semantic names (e.g., `test-id="filter-column-Name"`)
- [ ] **E2E Tests:** Playwright tests verify filter combinations and clear functionality

**Technical Notes:**

- Client-side filtering (no server calls)
- Use `Array.filter()` with multiple predicates
- Update `jtQueryResults` component

**Dependencies:** None

---

## 🚀 **Performance & Analytics**

### **US-009: Performance Analytics Dashboard** 📈

**Priority:** Low
**Story Points:** 13
**Status:** Backlog

**As a** system admin
**I want** analytics on query performance
**So that** I can optimize slow queries and monitor API usage

**Acceptance Criteria:**

- [ ] Track query execution time (avg, min, max)
- [ ] Show API calls consumed per query
- [ ] Identify slowest configurations
- [ ] Chart: executions over time
- [ ] Export analytics to CSV
- [ ] **Accessibility:** Charts have text alternatives and data tables for screen readers
- [ ] **Accessibility:** Chart interactions (hover, click) have keyboard equivalents
- [ ] **Semantic IDs:** Analytics widgets use semantic naming (e.g., `test-id="chart-executions-over-time"`)
- [ ] **E2E Tests:** Playwright tests verify chart rendering and CSV export

**Technical Notes:**

- Custom object: `JT_QueryAnalytics__c`
- Aggregate in Apex, visualize in LWC (Chart.js)
- New tab: "Analytics"

**Dependencies:** None

---

### **US-010: Query Optimization Suggestions** 🤖

**Priority:** Low
**Story Points:** 21
**Status:** Backlog (AI/ML required)

**As a** developer
**I want** AI-powered query optimization suggestions
**So that** I can improve query performance automatically

**Acceptance Criteria:**

- [ ] Analyze query structure (missing indexes, full scans)
- [ ] Suggest field reordering for better performance
- [ ] Recommend LIMIT clauses
- [ ] Detect N+1 patterns in subqueries
- [ ] Explain optimization impact
- [ ] **Accessibility:** Optimization suggestions announced to screen readers
- [ ] **Accessibility:** "Apply Suggestion" buttons keyboard accessible
- [ ] **Semantic IDs:** Suggestions use semantic naming (e.g., `test-id="suggestion-add-limit-clause"`)
- [ ] **E2E Tests:** Playwright tests verify suggestion generation and application

**Technical Notes:**

- Requires Salesforce Einstein or external AI
- Complex pattern matching
- Query plan analysis via Tooling API

**Dependencies:** Einstein Analytics, External AI service

---

## 🔌 **Integrations**

### **US-011: External Objects Support** 🌐

**Priority:** Low
**Story Points:** 8
**Status:** Backlog

**As a** user with External Objects
**I want** to query external data sources
**So that** I can use the framework with OData/SAP/etc.

**Acceptance Criteria:**

- [ ] Support External Objects in object selector
- [ ] Handle external IDs correctly
- [ ] Error handling for connection failures
- [ ] Timeout configuration
- [ ] Pagination for external sources
- [ ] **Accessibility:** External object indicators visible to screen readers (`aria-label="External Object - SAP Account"`)
- [ ] **Semantic IDs:** External object configs use semantic naming (e.g., `test-id="external-object-SAP_Account__x"`)
- [ ] **E2E Tests:** Playwright tests verify external object selection and error handling

**Technical Notes:**

- External Objects use different syntax
- May require separate configuration type

**Dependencies:** External Objects enabled in org

---

### **US-012: Scheduled Query Execution** ⏰

**Priority:** Medium
**Story Points:** 13
**Status:** Planned

**As a** business analyst
**I want** to schedule queries to run automatically
**So that** I can receive regular reports without manual execution

**Acceptance Criteria:**

- [ ] Create scheduled job for a configuration
- [ ] Email results as CSV attachment
- [ ] Cron-like scheduling (daily, weekly, monthly)
- [ ] Error notifications
- [ ] Job history and logs
- [ ] **Accessibility:** Schedule modal keyboard navigable (Tab, Enter, Escape)
- [ ] **Accessibility:** Cron inputs have clear labels and help text
- [ ] **Semantic IDs:** Scheduled jobs use semantic naming (e.g., `test-id="schedule-AccountSearch-daily"`)
- [ ] **E2E Tests:** Playwright tests verify schedule creation and email sending

**Technical Notes:**

- Use `Schedulable` interface
- Store schedules in Custom Metadata or Custom Setting
- Email via `Messaging.SingleEmailMessage`

**Dependencies:** Email templates

---

## 🛡️ **Security & Compliance**

### **US-013: Field-Level Security (FLS) Warnings** 🔒

**Priority:** High
**Story Points:** 5
**Status:** Planned

**As a** user executing queries
**I want** warnings if I'm querying fields I can't read
**So that** I understand why some data is missing

**Acceptance Criteria:**

- [ ] Check FLS for all fields in query
- [ ] Show warning icon if restricted fields detected
- [ ] Tooltip listing inaccessible fields
- [ ] Option to strip restricted fields from query
- [ ] Log FLS violations for admin review
- [ ] **Accessibility:** FLS warnings announced to screen readers (`role="alert"`, `aria-live="polite"`)
- [ ] **Accessibility:** Warning icons have descriptive alt text (`aria-label="Field-Level Security Warning: 3 restricted fields"`)
- [ ] **Semantic IDs:** FLS warnings use semantic naming (e.g., `test-id="fls-warning-Account-SSN__c"`)
- [ ] **E2E Tests:** Playwright tests verify warning display and field stripping

**Technical Notes:**

- Use `Schema.DescribeFieldResult.isAccessible()`
- Parse SOQL to extract field list
- Warning UI in `jtConfigModal`

**Dependencies:** None

---

### **US-014: Audit Log Viewer (LWC)** 📋

**Priority:** Medium
**Story Points:** 5
**Status:** Planned

**As a** system admin
**I want** a visual audit log viewer
**So that** I can track who changed settings and when

**Acceptance Criteria:**

- [ ] Table view with filters (date range, action type, user)
- [ ] Timeline view (chronological)
- [ ] Export to CSV
- [ ] Search by action/user
- [ ] Responsive design
- [ ] **Accessibility:** Table sortable via keyboard (Enter to toggle sort)
- [ ] **Accessibility:** Timeline has ARIA landmarks (`role="feed"`, `aria-label="Audit Timeline"`)
- [ ] **Semantic IDs:** Audit log rows use semantic naming (e.g., `test-id="audit-log-row-123"`)
- [ ] **E2E Tests:** Playwright tests verify table sorting, filtering, and export

**Technical Notes:**

- New LWC: `jtAuditLogViewer`
- Read-only (no delete/edit)
- Use existing `JT_SettingsAuditLog__c`

**Dependencies:** `JT_AuditLogDomain` (already implemented)

---

## 🧪 **Testing & Quality**

### **US-015: E2E Tests for Dark Mode** 🌙

**Priority:** Low (depends on US-001)
**Story Points:** 3
**Status:** Backlog

**As a** developer
**I want** automated E2E tests for dark mode
**So that** I ensure visual consistency across themes

**Acceptance Criteria:**

- [ ] Playwright tests with dark theme enabled
- [ ] Screenshot comparison (light vs dark)
- [ ] Accessibility checks in dark mode
- [ ] No color contrast failures
- [ ] **Accessibility:** Axe-core reports 0 violations in both themes
- [ ] **Semantic IDs:** Theme toggle button has semantic ID (e.g., `test-id="theme-toggle"`)
- [ ] **E2E Tests:** Playwright tests use `page.emulateMedia({ colorScheme: 'dark' })`

**Technical Notes:**

- Use `page.emulateMedia({ colorScheme: 'dark' })`
- Visual regression testing

**Dependencies:** US-001 (Dark Mode Support)

---

## 📱 **Mobile & Accessibility**

### **US-016: Mobile App (Salesforce Mobile)** 📱

**Priority:** Low
**Story Points:** 13
**Status:** Backlog

**As a** mobile user
**I want** optimized mobile experience
**So that** I can execute queries from my phone

**Acceptance Criteria:**

- [ ] Touch-optimized controls (larger buttons)
- [ ] Swipe gestures for navigation
- [ ] Offline mode (cache last results)
- [ ] Voice search for configurations
- [ ] Push notifications for scheduled queries
- [ ] **Accessibility:** Touch targets minimum 44x44px (WCAG 2.1 Level AAA)
- [ ] **Accessibility:** Voice search has clear visual feedback for recording state
- [ ] **Semantic IDs:** Mobile controls use semantic naming (e.g., `test-id="mobile-swipe-left"`)
- [ ] **E2E Tests:** Playwright mobile emulation tests verify touch gestures and offline mode

**Technical Notes:**

- Already responsive, but needs mobile polish
- Test on Salesforce Mobile App
- Consider separate mobile-first component

**Dependencies:** Salesforce Mobile App

---

## 🔮 **Advanced Features**

### **US-017: GraphQL Support** 🚀

**Priority:** Low
**Story Points:** 21
**Status:** Backlog (requires Salesforce GraphQL GA)

**As a** modern developer
**I want** GraphQL query support
**So that** I can query related data more efficiently

**Acceptance Criteria:**

- [ ] GraphQL query editor
- [ ] Convert SOQL to GraphQL
- [ ] Execute via Salesforce GraphQL API
- [ ] Handle nested relationships
- [ ] Error handling for GraphQL-specific errors
- [ ] **Accessibility:** GraphQL editor has syntax highlighting with sufficient contrast
- [ ] **Accessibility:** Query conversion button keyboard accessible
- [ ] **Semantic IDs:** GraphQL queries use semantic naming (e.g., `test-id="graphql-query-Account"`)
- [ ] **E2E Tests:** Playwright tests verify SOQL-to-GraphQL conversion and execution

**Technical Notes:**

- Salesforce GraphQL still in Beta (API 60.0+)
- Wait for GA before implementing

**Dependencies:** Salesforce GraphQL API GA

---

### **US-018: Agentforce Integration** 🤖

**Priority:** Medium
**Story Points:** 13
**Status:** Planned

**As an** Agentforce developer
**I want** pre-built actions for query execution
**So that** my agents can retrieve data dynamically

**Acceptance Criteria:**

- [ ] Invocable Apex methods for Agentforce
- [ ] "Execute Query" action (input: config name + params)
- [ ] "Search Configurations" action
- [ ] Natural language to SOQL (future)
- [ ] Integration examples in docs
- [ ] **Accessibility:** Agentforce action descriptions are clear and semantic
- [ ] **Semantic Naming:** Invocable method parameters use descriptive names (e.g., `configurationName`, not `param1`)
- [ ] **E2E Tests:** Apex tests verify Agentforce action inputs/outputs

**Technical Notes:**

- Use `@InvocableMethod` annotation
- Create Agentforce action templates
- Document in new tab: "Agentforce"

**Dependencies:** Agentforce enabled in org

---

### **US-019: Result Comparison Tool** 🔬

**Priority:** Low
**Story Points:** 8
**Status:** Backlog

**As a** data analyst
**I want** to compare results from two query executions
**So that** I can identify data changes over time

**Acceptance Criteria:**

- [ ] Execute query, save snapshot
- [ ] Execute again, compare with snapshot
- [ ] Highlight differences (added, removed, changed)
- [ ] Export diff report
- [ ] Support for different bind parameters
- [ ] **Accessibility:** Diff highlights use colors + patterns (not color alone) for colorblind users
- [ ] **Accessibility:** Comparison results announced to screen readers (e.g., "5 records added, 3 changed, 2 removed")
- [ ] **Semantic IDs:** Diff rows use semantic naming (e.g., `test-id="diff-row-added-001"`)
- [ ] **E2E Tests:** Playwright tests verify snapshot creation and diff display

**Technical Notes:**

- Store snapshots in Platform Cache or Custom Object
- Client-side diff algorithm
- Visual diff UI (green/red highlighting)

**Dependencies:** None

---

## 📦 **Package & Distribution**

### **US-020: Managed Package** 📦

**Priority:** High
**Story Points:** 13
**Status:** Planned (for AppExchange)

**As a** package maintainer
**I want** to distribute as a managed package
**So that** I can provide updates and support to customers

**Acceptance Criteria:**

- [ ] Namespace registered and configured
- [ ] All components namespaced
- [ ] Version numbering implemented
- [ ] Upgrade scripts for breaking changes
- [ ] Security review passed
- [ ] Published to AppExchange
- [ ] **Accessibility:** Salesforce security review includes accessibility audit (WCAG 2.1 AA compliance)
- [ ] **Semantic Naming:** Namespace prefix is descriptive (e.g., `jtdq__`, not `xyz__`)
- [ ] **Documentation:** AppExchange listing highlights accessibility features

**Technical Notes:**

- Register namespace (e.g., `jtdq`)
- Create packaging org
- Test installation in multiple org types

**Dependencies:** Salesforce Partner account

---

## 🔐 **Security Enhancements Suite**

### **US-021: Row-Level Security Warnings** 🛡️

**Priority:** Medium
**Story Points:** 8
**Status:** Planned

**As a** user in a complex sharing model org
**I want** warnings when queries might be restricted by sharing rules
**So that** I understand data visibility limitations

**Acceptance Criteria:**

- [ ] Detect `with sharing` vs `without sharing` mode
- [ ] Show warning if query uses restricted objects
- [ ] Explain sharing model for queried object
- [ ] Option to view "Expected vs Actual" record counts
- [ ] Document sharing behavior in results
- [ ] **Accessibility:** Sharing warnings announced to screen readers (`role="alert"`, `aria-live="polite"`)
- [ ] **Accessibility:** Warning icons have descriptive alt text (`aria-label="Sharing Rule Warning: Limited visibility"`)
- [ ] **Semantic IDs:** Sharing warnings use semantic naming (e.g., `test-id="sharing-warning-Account"`)
- [ ] **E2E Tests:** Playwright tests verify warning display for restricted objects

**Technical Notes:**

- Use `Schema.DescribeSObjectResult.isQueryable()`
- Complex logic for OWD + sharing rules detection

**Dependencies:** None

---

## 📚 **Documentation & Training**

### **US-022: Interactive Tutorial (Guided Tour)** 🎓

**Priority:** Low
**Story Points:** 5
**Status:** Backlog

**As a** new user
**I want** an interactive tutorial
**So that** I can learn features step-by-step

**Acceptance Criteria:**

- [ ] "Take Tour" button in Documentation tab
- [ ] Step-by-step overlay (highlight + tooltip)
- [ ] 5 steps: Select config, Enter params, Execute, View results, Export
- [ ] Skip/Complete tracking (Platform Cache)
- [ ] Multi-language support
- [ ] **Accessibility:** Tour overlay has focus trap (Tab/Shift+Tab cycles within tour)
- [ ] **Accessibility:** Tour steps announced to screen readers (e.g., "Step 1 of 5")
- [ ] **Semantic IDs:** Tour steps use semantic naming (e.g., `test-id="tour-step-1-select-config"`)
- [ ] **E2E Tests:** Playwright tests verify tour navigation (Next/Back/Skip) and keyboard support

**Technical Notes:**

- Use library like Shepherd.js or build custom
- LWC component: `jtGuidedTour`

**Dependencies:** None

---

## 🌍 **Internationalization**

### **US-023: Additional Languages (FR, DE, PT, IT, JA, ZH)** 🌐

**Priority:** Low
**Story Points:** 13
**Status:** Backlog

**As a** non-English speaking user
**I want** the application in my language
**So that** I can use it more effectively

**Acceptance Criteria:**

- [ ] French (FR) translations
- [ ] German (DE) translations
- [ ] Portuguese (PT) translations
- [ ] Italian (IT) translations
- [ ] Japanese (JA) translations
- [ ] Chinese (ZH) translations
- [ ] All labels, errors, and docs translated
- [ ] RTL support for applicable languages
- [ ] **Accessibility:** Screen reader support tested in each language
- [ ] **Accessibility:** RTL layouts maintain logical keyboard navigation (Right→Left)
- [ ] **Semantic IDs:** Language selector uses semantic naming (e.g., `test-id="language-selector-FR"`)
- [ ] **E2E Tests:** Playwright tests verify translations and RTL layout rendering

**Technical Notes:**

- Extend `labels.js` with new language objects
- Community contributions welcome
- Use professional translation service

**Dependencies:** Native speakers for translation review

---

## 🧩 **Integration & APIs**

### **US-024: REST API Endpoint** 🌐

**Priority:** Medium
**Story Points:** 8
**Status:** Planned

**As an** external system
**I want** a REST API to execute queries programmatically
**So that** I can integrate with non-Salesforce tools

**Acceptance Criteria:**

- [ ] `@RestResource` Apex class
- [ ] POST `/services/apexrest/JT/query` endpoint
- [ ] JSON request/response format
- [ ] API key authentication
- [ ] Rate limiting
- [ ] OpenAPI/Swagger documentation
- [ ] **Accessibility:** API documentation (Swagger UI) is keyboard navigable and screen reader compatible
- [ ] **Semantic Naming:** REST endpoints use descriptive paths (e.g., `/query/execute`, not `/q/e`)
- [ ] **E2E Tests:** Postman/Newman tests verify API authentication, rate limiting, and error handling

**Technical Notes:**

- Create `JT_QueryAPI.cls` with `@RestResource`
- Use Named Credential for auth
- Document in API Reference

**Dependencies:** None

---

## 📊 **Summary**

| Priority   | Count  | Story Points |
| ---------- | ------ | ------------ |
| **High**   | 3      | 39           |
| **Medium** | 6      | 55           |
| **Low**    | 9      | 99           |
| **TOTAL**  | **18** | **193 SP**   |

---

## 🎯 **Recommended v3.0 Scope (MVP)**

Focus on **High + Medium priority** (94 SP):

1. ✅ Visual SOQL Builder (US-002)
2. ✅ Query History & Favorites (US-004)
3. ✅ Dark Mode Support (US-001)
4. ✅ Field-Level Security Warnings (US-013)
5. ✅ Agentforce Integration (US-018)
6. ✅ Row-Level Security Warnings (US-021)
7. ✅ Advanced Result Filtering (US-008)
8. ✅ Real-Time Query Validation (US-006)
9. ✅ REST API Endpoint (US-024)

**Postpone to v4.0:**

- DML Framework (needs user feedback)
- GraphQL (wait for Salesforce GA)
- Query Optimization AI (complex)
- Mobile App (separate stream)

---

## 📝 **How to Contribute**

See [CONTRIBUTING.md](./CONTRIBUTING.md) for:

- How to pick a User Story
- Development workflow
- Testing requirements
- Code review process

**Want to work on a User Story?** Comment on the corresponding GitHub Issue!

---

## 🔗 **Related Documents**

- [V3 Roadmap](./V3_ROADMAP.md) - Detailed roadmap
- [GitHub Issues](https://github.com/jterrats/JT_DynamicQueries/issues) - Track progress
- [Architecture](./ARCHITECTURE.md) - Framework architecture
- [Development Approach](./DEVELOPMENT_APPROACH.md) - BDD/TDD/EDD methodology
