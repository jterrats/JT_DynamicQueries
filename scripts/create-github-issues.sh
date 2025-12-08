#!/bin/bash
# Script to create GitHub issues for v3.0 features
# Requires: GitHub CLI (gh) installed and authenticated

set -e

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Please install it:"
    echo "   brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub. Run: gh auth login"
    exit 1
fi

echo "🚀 Creating GitHub Issues for JT Dynamic Queries v3.0"
echo "======================================================"
echo ""

# Issue 1: Visual SOQL Builder
echo "Creating Issue #1: Visual SOQL Builder..."
gh issue create \
  --title "[Feature] Visual SOQL Builder with Drag & Drop Field Selector" \
  --label "enhancement,v3.0,high-priority,ui/ux" \
  --body "## 🎯 User Story

**As a** Salesforce Administrator with limited SOQL knowledge
**I want** a visual drag-and-drop SOQL builder
**So that** I can create queries without writing code manually

## 📝 Description

Implement a visual SOQL builder that allows users to:
- Select objects from a dropdown
- Drag & drop fields from the object schema
- Add WHERE conditions using visual controls
- Preview the generated SOQL in real-time
- Convert visual query to configuration with one click

## ✅ Acceptance Criteria

- [ ] Object selector dropdown with search
- [ ] Field list panel with drag-and-drop capability
- [ ] WHERE clause builder with operators (=, !=, <, >, LIKE, IN)
- [ ] Real-time SOQL preview
- [ ] \"Save as Configuration\" button
- [ ] Support for related objects (parent.field)
- [ ] Mobile-responsive interface

## 🔧 Technical Notes

- Use LWC with drag-and-drop events
- Leverage Tooling API for object metadata
- Generate SOQL programmatically
- Validate syntax before saving
- Support for relationships up to 5 levels

## 🎯 Priority

**High** - Major v3.0 feature

## 📅 Estimated Effort

**13 points** (2 sprints)"

# Issue 2: Query History and Favorites
echo "Creating Issue #2: Query History and Favorites..."
gh issue create \
  --title "[Feature] Query History and Favorites Management" \
  --label "enhancement,v3.0,medium-priority,user-experience" \
  --body "## 🎯 User Story

**As a** power user who runs queries frequently
**I want** to track my query history and mark favorites
**So that** I can quickly re-run my most common queries

## 📝 Description

Add query history tracking and favorites system:
- Track last 50 executed queries per user
- Star/favorite frequently used queries
- Quick access panel for history
- Search through history
- Re-execute with one click

## ✅ Acceptance Criteria

- [ ] History tab showing last 50 queries
- [ ] Each entry shows: config name, parameters, timestamp, result count
- [ ] \"Star\" button to mark favorites
- [ ] Favorites section at top of history
- [ ] Search/filter history by config name or date
- [ ] One-click re-execute with same parameters
- [ ] Clear history option
- [ ] Export history to CSV

## 🔧 Technical Implementation

**Custom Object:**
\`\`\`apex
JT_QueryHistory__c {
  JT_ConfigName__c (Text)
  JT_Parameters__c (LongTextArea - JSON)
  JT_ResultCount__c (Number)
  JT_ExecutedBy__c (Lookup to User)
  JT_ExecutedAt__c (DateTime)
  JT_IsFavorite__c (Checkbox)
}
\`\`\`

## 🎯 Priority

**Medium** - Nice to have for v3.0

## 📅 Estimated Effort

**8 points** (1 sprint)"

# Issue 3: Bulk Query Execution
echo "Creating Issue #3: Bulk Query Execution..."
gh issue create \
  --title "[Feature] Bulk Query Execution - Run Multiple Configs Simultaneously" \
  --label "enhancement,v3.0,performance,high-priority" \
  --body "## 🎯 User Story

**As a** data analyst running multiple reports
**I want** to execute multiple query configurations at once
**So that** I can save time and get all results in one batch

## 📝 Description

Enable bulk execution of multiple query configurations:
- Select multiple configs from a checklist
- Execute all in parallel (Queueable Apex)
- Download combined results as ZIP file
- Progress indicator for each query
- Cancel individual queries in progress

## ✅ Acceptance Criteria

- [ ] Multi-select configuration checklist
- [ ] \"Execute All Selected\" button
- [ ] Progress bar for each query
- [ ] Cancel button for in-progress queries
- [ ] Download all results as ZIP (CSV files)
- [ ] Summary report: X succeeded, Y failed
- [ ] Email notification when batch completes
- [ ] Maximum 10 configs per batch

## 🔧 Technical Implementation

**Queueable Apex:**
\`\`\`apex
public class JT_BulkQueryExecutor implements Queueable {
  private List<String> configNames;
  private Integer currentIndex = 0;

  public void execute(QueueableContext ctx) {
    // Execute current query
    // Store results
    // Chain next query if more exist
    if (currentIndex < configNames.size() - 1) {
      System.enqueueJob(new JT_BulkQueryExecutor(...));
    }
  }
}
\`\`\`

## 🎯 Priority

**High** - Significant value for power users

## 📅 Estimated Effort

**13 points** (2 sprints)"

# Issue 4: Advanced Result Filtering
echo "Creating Issue #4: Advanced Result Filtering..."
gh issue create \
  --title "[Feature] Advanced Result Filtering with Column Filters and Search" \
  --label "enhancement,v3.0,ui/ux,medium-priority" \
  --body "## 🎯 User Story

**As a** user viewing large result sets
**I want** to filter and search within results
**So that** I can quickly find specific records without re-running queries

## 📝 Description

Add client-side filtering capabilities to query results:
- Column-specific filters (text, number, date)
- Global search across all columns
- Multi-column sort
- Filter presets (save filters)
- Export filtered results

## ✅ Acceptance Criteria

- [ ] Filter icon on each column header
- [ ] Click opens filter panel for that column
- [ ] Text filters: contains, equals, starts with, ends with
- [ ] Number filters: equals, >, <, between
- [ ] Date filters: equals, before, after, range
- [ ] Global search box (searches all columns)
- [ ] Multi-column sort (hold Shift + click)
- [ ] \"Save Filter Preset\" option
- [ ] Filter badge showing active filters count
- [ ] \"Clear All Filters\" button
- [ ] Export respects active filters

## 🎯 Priority

**Medium** - Nice UX improvement

## 📅 Estimated Effort

**8 points** (1 sprint)"

# Issue 5: Query Templates Library
echo "Creating Issue #5: Query Templates Library..."
gh issue create \
  --title "[Feature] Pre-built Query Templates Library" \
  --label "enhancement,v3.0,documentation,medium-priority" \
  --body "## 🎯 User Story

**As a** new user learning the system
**I want** access to pre-built query templates
**So that** I can quickly get started with common use cases

## 📝 Description

Create a library of pre-built query templates for common scenarios:
- Account management queries
- Opportunity pipeline reports
- User activity tracking
- Data quality checks
- Security & audit reports

## ✅ Acceptance Criteria

- [ ] Templates tab in main interface
- [ ] 20+ pre-built templates covering common use cases
- [ ] Template categories: Sales, Service, Security, Admin
- [ ] Preview template before using
- [ ] One-click \"Use This Template\"
- [ ] Customize template parameters
- [ ] Save customized template as new config
- [ ] Template search and filtering

## 📚 Template Examples

**Sales Cloud:** Accounts by Industry, Open Opportunities by Stage, Won Deals This Quarter
**Service Cloud:** Open Cases by Priority, Case Resolution Time Analysis
**Admin:** Inactive Users Last 90 Days, Permission Set Assignments, Failed Login Attempts

## 🎯 Priority

**Medium** - Great for onboarding

## 📅 Estimated Effort

**5 points** (1 sprint)"

# Issue 6: Real-time Query Validation
echo "Creating Issue #6: Real-time Query Validation..."
gh issue create \
  --title "[Feature] Real-time SOQL Validation as You Type" \
  --label "enhancement,v3.0,developer-experience,medium-priority" \
  --body "## 🎯 User Story

**As a** user creating a new query configuration
**I want** real-time validation as I type my SOQL
**So that** I can catch syntax errors before saving

## 📝 Description

Implement real-time SOQL validation with:
- Syntax highlighting
- Error underlining
- Auto-complete for object/field names
- Validation tooltips
- Suggest fixes for common errors

## ✅ Acceptance Criteria

- [ ] Syntax highlighting (keywords, strings, operators)
- [ ] Red underline for syntax errors
- [ ] Tooltip showing error message on hover
- [ ] Auto-complete for SELECT, FROM, WHERE, etc.
- [ ] Object name validation against schema
- [ ] Field name validation against object
- [ ] Debounced validation (300ms after typing stops)
- [ ] Show valid/invalid badge
- [ ] Suggest fixes (Did you mean \"Account\"?)
- [ ] Works offline (basic syntax checking)

## 🎯 Priority

**Medium** - Great DX improvement

## 📅 Estimated Effort

**8 points** (1 sprint)"

# Issue 7: Performance Analytics Dashboard
echo "Creating Issue #7: Performance Analytics Dashboard..."
gh issue create \
  --title "[Feature] Performance Analytics Dashboard for Query Monitoring" \
  --label "enhancement,v3.0,analytics,low-priority" \
  --body "## 🎯 User Story

**As an** Admin monitoring query performance
**I want** a dashboard showing query execution metrics
**So that** I can identify slow queries and optimize them

## 📝 Description

Build an analytics dashboard showing:
- Query execution times (avg, min, max)
- Most frequently used configurations
- Slowest queries
- Tooling API consumption
- Error rates by configuration
- Usage trends over time

## ✅ Acceptance Criteria

- [ ] Dashboard tab with 6 key widgets
- [ ] Widget 1: Average execution time by config
- [ ] Widget 2: Top 10 most used configs
- [ ] Widget 3: Top 10 slowest queries
- [ ] Widget 4: API call consumption (daily/weekly)
- [ ] Widget 5: Error rate over time (chart)
- [ ] Widget 6: Storage usage (query results)
- [ ] Date range filter (Last 7/30/90 days)
- [ ] Export dashboard to PDF
- [ ] Drill-down to query details

## 🎯 Priority

**Low** - Nice to have, not critical

## 📅 Estimated Effort

**13 points** (2 sprints)"

# Issue 8: Platform Cache Implementation
echo "Creating Issue #8: Platform Cache Implementation..."
gh issue create \
  --title "[Enhancement] Platform Cache for Query Performance Optimization" \
  --label "enhancement,performance,future,medium-priority" \
  --body "## 🎯 User Story

**As a** user running the same queries frequently
**I want** cached results for recent queries
**So that** I get instant results without hitting governor limits

## 📝 Description

Implement Platform Cache to cache:
1. Configuration list (5 min TTL)
2. User list (10 min TTL)
3. Query results (1 hour TTL, configurable)
4. Usage search results (30 min TTL)

## ✅ Acceptance Criteria

- [ ] Cache configuration metadata (5 min)
- [ ] Cache user dropdown (10 min)
- [ ] Cache query results with TTL (default 1 hour)
- [ ] Cache key includes: config + parameters + runAsUser
- [ ] \"Force Refresh\" option bypasses cache
- [ ] Cache stats in admin panel
- [ ] Configurable TTL per cache type
- [ ] Auto-invalidate on metadata changes

## 🎯 Priority

**Medium** - Performance optimization

## 📅 Estimated Effort

**5 points** (1 sprint)"

# Issue 9: Scheduled Query Execution
echo "Creating Issue #9: Scheduled Query Execution..."
gh issue create \
  --title "[Feature] Scheduled Query Execution with Email Delivery" \
  --label "enhancement,future,automation,medium-priority" \
  --body "## 🎯 User Story

**As a** manager needing daily/weekly reports
**I want** to schedule automatic query execution
**So that** I receive results via email without manual work

## 📝 Description

Enable scheduling of query executions:
- Configure schedule (daily, weekly, monthly)
- Email results to recipients
- Store results for history
- Error notifications
- Pause/resume schedules

## ✅ Acceptance Criteria

- [ ] \"Schedule This Query\" button on each config
- [ ] Schedule configuration modal: Frequency, Time, Recipients
- [ ] Active schedules list
- [ ] Pause/resume/delete schedule
- [ ] Email includes: results, execution time, record count
- [ ] Error email if query fails
- [ ] Schedule history (last 30 runs)

## 🎯 Priority

**Medium** - Valuable automation feature

## 📅 Estimated Effort

**13 points** (2 sprints)"

# Issue 10: Metadata Export/Import
echo "Creating Issue #10: Metadata Export/Import..."
gh issue create \
  --title "[Feature] Configuration Export/Import for Org Migration" \
  --label "enhancement,future,deployment,high-priority" \
  --body "## 🎯 User Story

**As a** DevOps engineer managing multiple orgs
**I want** to export/import configurations as JSON
**So that** I can migrate configs between sandbox and production

## 📝 Description

Enable export and import of query configurations:
- Export all configs to JSON file
- Import configs from JSON file
- Conflict resolution (skip, overwrite, rename)
- Validation before import
- Dry-run mode

## ✅ Acceptance Criteria

- [ ] \"Export All Configurations\" button
- [ ] Downloads JSON file with all configs
- [ ] \"Import Configurations\" button with file upload
- [ ] Validation: check SOQL syntax, object existence
- [ ] Conflict detection and resolution options
- [ ] Preview import before applying
- [ ] Import summary: X succeeded, Y skipped, Z failed
- [ ] Rollback option (undo import)

## 🎯 Priority

**High** - Critical for enterprise deployments

## 📅 Estimated Effort

**13 points** (2 sprints)"

# Issue 11: Queueable Apex for Large Usage Searches
echo "Creating Issue #11: Queueable Apex for Large Usage Searches..."
gh issue create \
  --title "[Enhancement] Queueable Apex for Large-Scale \"Where is this used?\" Searches" \
  --label "enhancement,performance,scalability,medium-priority" \
  --body "## 🎯 User Story

**As a** user in an org with 500+ Apex classes
**I want** \"Where is this used?\" to run in background
**So that** I don't hit timeout limits and get complete results

## 📝 Description

Convert synchronous usage search to asynchronous Queueable:
- Runs in background for large orgs
- Progress indicator in UI
- Email notification when complete
- Results stored for later viewing
- Cancel in-progress searches

## ✅ Acceptance Criteria

- [ ] Auto-detect: if org has >100 Apex classes, use Queueable
- [ ] Progress modal: \"Searching... 45/234 classes checked\"
- [ ] Cancel button stops the job
- [ ] Email sent when complete with results summary
- [ ] Results accessible for 7 days
- [ ] Error handling: partial results if some checks fail

## 🎯 Priority

**Medium** - Important for scalability

## 📅 Estimated Effort

**8 points** (1 sprint)"

# Issue 12: Additional Language Support
echo "Creating Issue #12: Additional Language Support..."
gh issue create \
  --title "[Enhancement] Add Support for Italian, Japanese, Portuguese, and Chinese" \
  --label "enhancement,i18n,v3.0,low-priority" \
  --body "## 🎯 User Story

**As a** global user speaking Italian/Japanese/Portuguese/Chinese
**I want** the app in my native language
**So that** I can use it more effectively

## 📝 Description

Expand i18n support to 8 languages total:
- Current: English, Spanish, French, German (4)
- New: Italian, Japanese, Portuguese (BR), Chinese (Simplified) (4)

## ✅ Acceptance Criteria

- [ ] Italian (IT) translations
- [ ] Japanese (JA) translations
- [ ] Portuguese-Brazil (PT_BR) translations
- [ ] Chinese Simplified (ZH_CN) translations
- [ ] Object translations for Custom Metadata
- [ ] Custom Labels for all UI strings
- [ ] Test in each language

## 🎯 Priority

**Low** - Nice to have for global users

## 📅 Estimated Effort

**20 points total** (3 sprints)"

# Issue 13: GraphQL Support
echo "Creating Issue #13: GraphQL Support..."
gh issue create \
  --title "[Feature] GraphQL Support for Modern API Integration" \
  --label "enhancement,future,api,low-priority" \
  --body "## 🎯 User Story

**As a** developer integrating with external systems
**I want** to query Salesforce data using GraphQL
**So that** I can fetch exactly the data I need with one request

## 📝 Description

Add GraphQL query support alongside SOQL:
- Convert SOQL to GraphQL
- Execute GraphQL queries via API
- Support nested relationships
- GraphQL schema explorer
- Mutations for data modification

## ✅ Acceptance Criteria

- [ ] GraphQL query editor
- [ ] SOQL to GraphQL converter
- [ ] GraphQL schema browser
- [ ] Support for nested queries (5 levels deep)
- [ ] Variables support (@param syntax)
- [ ] Execute via Salesforce GraphQL API
- [ ] Response formatting (same as SOQL results)
- [ ] Mutations support (Insert/Update/Delete)

## 🎯 Priority

**Low** - Advanced feature, limited demand

## 📅 Estimated Effort

**21 points** (3 sprints)"

# Issue 14: Result Comparison Tool
echo "Creating Issue #14: Result Comparison Tool..."
gh issue create \
  --title "[Feature] Query Result Comparison Tool" \
  --label "enhancement,future,analytics,low-priority" \
  --body "## 🎯 User Story

**As an** analyst comparing data over time
**I want** to compare two query result sets
**So that** I can identify changes, additions, and deletions

## 📝 Description

Build a comparison tool to compare two query executions:
- Compare same query, different times
- Compare different queries on same object
- Highlight differences (added, removed, changed)
- Export diff report
- Visual diff view

## ✅ Acceptance Criteria

- [ ] \"Compare\" tab in results section
- [ ] Select two result sets to compare
- [ ] Three-way view: Left (A), Diff, Right (B)
- [ ] Color coding: Green (added), Red (removed), Yellow (modified)
- [ ] Record matching by ID or custom key
- [ ] Field-level diff for modified records
- [ ] Summary: X added, Y removed, Z modified
- [ ] Export diff report as CSV

## 🎯 Priority

**Low** - Niche use case

## 📅 Estimated Effort

**13 points** (2 sprints)"

# Issue 15: Query Optimization Suggestions
echo "Creating Issue #15: Query Optimization Suggestions..."
gh issue create \
  --title "[Feature] AI-Powered Query Optimization Suggestions" \
  --label "enhancement,future,ai,performance,low-priority" \
  --body "## 🎯 User Story

**As a** developer writing SOQL queries
**I want** automatic optimization suggestions
**So that** my queries run faster and consume fewer resources

## 📝 Description

Analyze SOQL queries and suggest optimizations:
- Detect missing indexes
- Suggest selective WHERE clauses
- Warn about full table scans
- Recommend LIMIT usage
- Identify inefficient relationships

## ✅ Acceptance Criteria

- [ ] Analyze query on save/execute
- [ ] Show optimization score (1-100)
- [ ] List specific suggestions with explanations
- [ ] One-click apply suggestion
- [ ] Before/after comparison
- [ ] Performance impact estimate
- [ ] Link to documentation for each suggestion

## 🎯 Priority

**Low** - Advanced feature

## 📅 Estimated Effort

**21 points** (3 sprints)"

# Issue 16: Advanced Agentforce Actions
echo "Creating Issue #16: Advanced Agentforce Actions..."
gh issue create \
  --title "[Feature] Extended Agentforce Actions for AI Integration" \
  --label "enhancement,future,agentforce,ai,medium-priority" \
  --body "## 🎯 User Story

**As an** Agentforce AI agent
**I want** more granular query actions
**So that** I can help users more effectively with data queries

## 📝 Description

Extend current @InvocableMethod with additional actions:
- Validate configuration exists
- Get configuration metadata
- Count results without fetching data
- List available configurations
- Execute with dynamic filters

## ✅ Acceptance Criteria

- [ ] \`validateConfiguration()\` - Check if config exists & is valid
- [ ] \`getConfigurationMetadata()\` - Return object info, field list
- [ ] \`countResults()\` - Return only count without full data
- [ ] \`listConfigurations()\` - Get all available configs
- [ ] \`executeWithFilters()\` - Dynamic WHERE clause

## 🎯 Priority

**Medium** - Growing importance with Agentforce adoption

## 📅 Estimated Effort

**8 points** (1 sprint)"

# Issue 17: Security Enhancements Suite
echo "Creating Issue #17: Security Enhancements Suite..."
gh issue create \
  --title "[Enhancement] Advanced Security Features - CSRF, Rate Limiting, Audit Trail" \
  --label "enhancement,security,future,high-priority" \
  --body "## 🎯 User Story

**As a** Security Administrator
**I want** enhanced security controls
**So that** I can protect against abuse and maintain audit compliance

## 📝 Description

Implement comprehensive security enhancements:
1. CSRF token validation for Tooling API calls
2. Rate limiting for expensive operations
3. Complete audit trail with retention policy
4. IP whitelisting for production

## ✅ Acceptance Criteria

**CSRF Protection:**
- [ ] Generate CSRF token for each session
- [ ] Validate token on all Tooling API calls

**Rate Limiting:**
- [ ] Max 10 usage searches per user per hour
- [ ] Max 50 query executions per user per hour
- [ ] Show remaining quota in UI

**Audit Trail:**
- [ ] Track all query executions
- [ ] Track configuration changes
- [ ] Track \"Run As User\" usage
- [ ] Retention policy: 90 days (configurable)

## 🎯 Priority

**High** - Critical for enterprise/AppExchange

## 📅 Estimated Effort

**21 points** (3 sprints)"

# Issue 18: Reports & Analytics Dashboard
echo "Creating Issue #18: Reports & Analytics Dashboard..."
gh issue create \
  --title "[Feature] Usage Statistics Reports and Analytics Dashboard" \
  --label "enhancement,future,analytics,reporting,medium-priority" \
  --body "## 🎯 User Story

**As an** Admin managing the application
**I want** pre-built reports and dashboards
**So that** I can track usage patterns and identify optimization opportunities

## 📝 Description

Create standard Reports and Dashboard for usage analytics:
- Report Type for usage statistics
- Dashboard with key metrics
- Trending analysis
- Cleanup recommendations

## ✅ Acceptance Criteria

**Report Type:**
- [ ] Report Type: \"Query Configuration Usage\"
- [ ] Fields: Config Name, # of Uses, Last Used Date, Used By, Avg Time

**Dashboard Widgets:**
- [ ] Widget 1: Most Used Configurations (bar chart)
- [ ] Widget 2: Unused Configurations (cleanup candidates)
- [ ] Widget 3: Usage Over Time (line chart)
- [ ] Widget 4: Tooling API Call Consumption (gauge)
- [ ] Widget 5: Average Execution Time by Config
- [ ] Widget 6: Error Rate (metric)

## 🎯 Priority

**Medium** - Valuable for admins

## 📅 Estimated Effort

**8 points** (1 sprint)"

echo ""
echo "✅ Successfully created 18 GitHub issues!"
echo ""
echo "View all issues at: https://github.com/jterrats/JT_DynamicQueries/issues"




