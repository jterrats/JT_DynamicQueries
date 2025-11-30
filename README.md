# Dynamic Query Viewer for Salesforce

A powerful, enterprise-ready Salesforce solution for executing dynamic, configurable SOQL queries with advanced security controls, multi-language support, and a modern Lightning Web Component interface.

<a href="https://githubsfdeploy.herokuapp.com?owner=jterrats&repo=JT_DynamicQueries&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

[![Code Quality](https://img.shields.io/badge/PMD-0%20violations-brightgreen)](./CODE_QUALITY_REPORT.md)
[![Test Coverage](https://img.shields.io/badge/coverage-84.5%25-brightgreen)](./COVERAGE_REPORT.txt)
[![API Version](https://img.shields.io/badge/API-v65.0-blue)](https://developer.salesforce.com/)
[![License](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)

## ✨ Features

### 🔧 Core Functionality

- **Metadata-Driven Queries** - Define SOQL queries in Custom Metadata for easy management
- **Dynamic Parameters** - Auto-generates input fields for bind variables
- **Query Preview** - See the query before execution
- **Results Pagination** - Auto-paginates results when > 10 records
- **Empty State Handling** - Shows table structure even with 0 results

### 🔒 Security & Permissions

- **USER_MODE Enforcement** - Respects FLS, CRUD, and sharing rules
- **Run As User** - Test queries in another user's permission context (2 modes)
- **Permission Validation** - Requires appropriate permissions for advanced features
- **Production Safeguard** - Metadata creation disabled in production orgs

### 👤 Advanced Run As Feature

- **Standard Mode** - USER_MODE execution with permission validation
- **System.runAs Mode** - True impersonation using Apex test context
- **User Dropdown** - Client-side filtered dropdown with all active users
- **Results Comparison** - See exactly what another user would see

### 🎨 Modern UI/UX

- **Lightning Web Components** - Modern, responsive interface
- **Multi-Language Support** - English, Spanish, French, German
- **Responsive Design** - Optimized for mobile, tablet, and desktop
- **Dark Theme Compatible** - Works with Salesforce themes

### 📚 Built-in Documentation

- **In-App Documentation** - Complete docs accessible within the app
- **Multi-Language Docs** - Documentation in 4 languages
- **API Reference** - Complete Apex and LWC API documentation
- **Troubleshooting Guide** - Common issues and solutions

### 🛠️ Developer Experience

- **Metadata Creation UI** - Create/edit configurations in sandbox
- **SOQL Validation** - Real-time query validation
- **Auto-Refresh** - Configuration list updates after creation
- **Usage Finder** - "Where is this used?" shows Apex class references
- **Invocable Methods** - Use queries in Flows and Agentforce
- **Comprehensive Testing** - Apex tests (84.5% coverage) + E2E Playwright tests
- **Audit Trail** - Track all production editing setting changes

## 🚀 Quick Start

### 1. Deploy to Your Org

#### Option A: Using Salesforce CLI

```bash
git clone https://github.com/jterrats/JT_DynamicQueries.git
cd JT_DynamicQueries
sf project deploy start --target-org your-org-alias
```

#### Option B: One-Click Deploy

<a href="https://githubsfdeploy.herokuapp.com?owner=jterrats&repo=JT_DynamicQueries&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

### 2. Assign Permission Set

```bash
sf org assign permset --name JT_Dynamic_Queries
```

Or use the Apex script:

```bash
sf apex run --file scripts/apex/assign-permset.apex
```

### 3. Access the App

Navigate to **App Launcher** → **Dynamic Queries**

The app includes four tabs:

- **Query Viewer** - Execute and manage queries
- **Documentation** - Complete in-app documentation
- **Audit History** - Track production editing setting changes
- **Reports** - Access standard reporting functionality

### 4. (Optional) Configure Tooling API

To enable advanced features like **"Where is this used?"** (search in Flows) and **Create/Edit Configurations** (metadata deployment via UI), configure Named Credentials for Tooling API access.

> **📚 Detailed Setup Guide:** See [TOOLING_API_SETUP.md](./docs/TOOLING_API_SETUP.md) for step-by-step instructions with screenshots.
> **🌐 Guía en Español:** Ver [TOOLING_API_SETUP_ES.md](./docs/TOOLING_API_SETUP_ES.md) para instrucciones detalladas.

**Quick Automated Setup:**

```bash
./scripts/setup-tooling-api.sh
```

**Manual Setup:**

Follow the step-by-step guide: [**Tooling API Setup Guide**](./docs/TOOLING_API_SETUP.md)

**Note:** The application works WITHOUT Tooling API (core query execution features remain fully functional). Tooling API is only required for:

- Searching configuration references in Flows
- Creating/editing configurations via UI

## 📖 Documentation

### In-App Documentation

Complete documentation is available within the app in the **Documentation** tab, including:

- Overview and features
- Step-by-step usage guide
- Configuration examples
- Security model
- Troubleshooting
- API reference

Documentation automatically displays in your browser's language (English, Spanish, French, or German).

### External Documentation

- [**Tooling API Setup Guide**](./docs/TOOLING_API_SETUP.md) - Configure Named Credentials for advanced features
- [Run As User Feature](./RUN_AS_USER_FEATURE.md) - Detailed explanation of Run As modes
- [E2E Testing Guide](./tests/e2e/README.md) - Playwright E2E test documentation
- [Code Quality Report](./CODE_QUALITY_REPORT.md) - PMD and ESLint analysis
- [AppExchange Readiness](./APPEXCHANGE_READINESS.md) - Security review checklist

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│   Lightning Web Components                                              │
│   ┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐    │
│   │ jtQueryViewer   │  │ jtProjectDocs    │  │ jtAuditHistory   │    │
│   │ - Query Exec    │  │ - Documentation  │  │ - Audit Logs     │    │
│   │ - Pagination    │  │ - Multi-language │  │ - Change Track   │    │
│   │ - Run As        │  │ - API Reference  │  │ - i18n           │    │
│   │ - Usage Finder  │  │ - Responsive     │  │                  │    │
│   │ - i18n          │  │                  │  │                  │    │
│   └────────┬────────┘  └──────────────────┘  └──────────────────┘    │
└────────────┼────────────────────────────────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────────────────────────────────────┐
│   Apex Controllers                                                       │
│   ┌──────────────────────┐  ┌──────────────────────┐  ┌─────────────┐ │
│   │ JT_QueryViewController│  │ JT_MetadataCreator  │  │ JT_UsageFinder│
│   │ - getConfigurations  │  │ - createConfiguration│  │ - findUsage  │ │
│   │ - executeQuery       │  │ - updateConfiguration│  │ - scanClasses│ │
│   │ - getAllActiveUsers  │  │ - validateQuery      │  └─────────────┘ │
│   │ - extractParameters  │  │ - getOrgInfo         │                   │
│   └──────────┬───────────┘  └──────────────────────┘                   │
│              │                                                           │
│   ┌──────────────────────────┐  ┌──────────────────────────────────┐  │
│   │ JT_ProductionSettingsCtrl│  │ JT_RunAsTestExecutor             │  │
│   │ - getProductionSetting   │  │ - executeAsUser                  │  │
│   │ - updateProductionSetting│  │ - getTestResults                 │  │
│   │ - getAuditLogs           │  │ - Platform Cache integration     │  │
│   │ - isStarterOrFreeEdition │  └──────────────────────────────────┘  │
│   └──────────────────────────┘                                          │
└──────────────┼──────────────────────────────────────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────────────────────────────────────┐
│   Core Query Engine                                                      │
│   ┌──────────────────────────────────────────────────────────────────┐ │
│   │ JT_DataSelector                                                  │ │
│   │ - Singleton Pattern  │  │ - executeAsUser      │   │
│   │ - Config Caching     │  │ - getTestResults     │   │
│   │ - Query Execution    │  │ - Platform Cache     │   │
│   │ - Security Enforc.   │  │                      │   │
│   └──────────┬───────────┘  └──────────┬───────────┘   │
└──────────────┼──────────────────────────┼───────────────┘
               │                          │
               ↓                          ↓
┌──────────────────────────┐  ┌──────────────────────┐
│ JT_DynamicQuery          │  │ JT_GenericRunAsTest  │
│ Configuration__mdt       │  │ - System.runAs       │
│ - Base Query             │  │ - Test Context       │
│ - Bindings               │  │ - JSON Serialization │
│ - Object Name            │  │                      │
└──────────────────────────┘  └──────────────────────┘
```

## 📦 Components

### Custom Metadata Type: `JT_DynamicQueryConfiguration__mdt`

| Field                  | Type      | Description                     | Required |
| ---------------------- | --------- | ------------------------------- | -------- |
| **Label**              | Text      | Display name in the UI          | Yes      |
| **DeveloperName**      | Text      | API name for the configuration  | Yes      |
| **JT_BaseQuery\_\_c**  | Long Text | SOQL query with bind variables  | Yes      |
| **JT_Bindings\_\_c**   | Long Text | JSON object with default values | No       |
| **JT_ObjectName\_\_c** | Text      | Primary object being queried    | No       |

### Apex Classes

#### Core Classes

- **`JT_DataSelector`** - Query execution engine with static cache pattern (Custom Metadata cached per transaction, singleton instance managed internally)
- **`JT_QueryViewerController`** - LWC backend controller with configuration management and parameter extraction
- **`JT_MetadataCreator`** - Handles metadata creation/update and validation (sandbox/scratch org only)
- **`JT_RunAsTestExecutor`** - Orchestrates System.runAs test execution with Platform Cache
- **`JT_GenericRunAsTest`** - Pre-compiled test class for true user impersonation

#### Test Classes

- **`JT_DataSelector_Test`** - Comprehensive tests for query execution
- **`JT_QueryViewerController_Test`** - Controller tests
- **`JT_MetadataCreator_Test`** - Metadata operations tests
- **`JT_RunAsTestExecutor_Test`** - Run As functionality tests
- **`JT_ToolingAPIMock`** - HTTP callout mock for Tooling API

### Lightning Web Components

#### `jtQueryViewer`

Main component for query execution with features:

- Configuration selection dropdown
- Dynamic parameter generation
- Query preview
- Execute query button
- Results datatable with pagination
- Run As user selection (admin only)
- Create/edit configuration modal (sandbox only)
- Multi-language support (EN, ES, FR, DE)

#### `jtProjectDocs`

Documentation component with:

- 9 comprehensive sections
- Multi-language content
- Sticky navigation with table of contents
- Smooth scrolling
- Responsive design
- Code examples and API reference

## 💻 Usage Examples

### Example 1: Simple Query Configuration

```yaml
Label: All Active Accounts
Developer Name: All_Active_Accounts
Base Query: SELECT Id, Name, Industry, AnnualRevenue FROM Account WHERE IsActive__c = true
Bindings: (leave empty)
Object Name: Account
```

### Example 2: Query with Parameters

```yaml
Label: Account Contacts
Developer Name: Account_Contacts
Base Query: SELECT Id, Name, Email, Phone FROM Contact WHERE AccountId = :accountId
Bindings: { "accountId": "0015g00000XXXXXX" }
Object Name: Contact
```

### Example 3: Multiple Parameters

```yaml
Label: Opportunities by Stage and Amount
Developer Name: Opportunities_Stage_Amount
Base Query: SELECT Id, Name, Amount, StageName FROM Opportunity WHERE StageName = :stage AND Amount >= :minAmount
Bindings: { "stage": "Closed Won", "minAmount": 100000 }
Object Name: Opportunity
```

### Programmatic Usage

```apex
// Using predefined bindings from metadata
List<SObject> records = JT_DataSelector.getRecords('All_Active_Accounts');

// Using custom bindings
Map<String, Object> bindings = new Map<String, Object>{
    'accountId' => '0015g00000XXXXXX'
};
List<SObject> contacts = JT_DataSelector.getRecords('Account_Contacts', bindings);

// With access level control
List<SObject> records = JT_DataSelector.getRecords('ConfigName', bindings, AccessLevel.USER_MODE);
```

## 🧪 Testing

### Apex Tests

Run all local tests:

```bash
sf apex run test --test-level RunLocalTests --result-format human
```

Generate coverage report:

```bash
sf apex run test --test-level RunLocalTests --code-coverage --result-format human > COVERAGE_REPORT.txt
```

**Current Coverage**: 84.5% (exceeds 75% requirement)

### E2E Tests with Playwright

#### Install Dependencies

```bash
npm install
npx playwright install chromium
```

#### Run Tests

```bash
# Run all E2E tests
npm run test:e2e

# Run with UI mode (headed)
npx playwright test --headed

# Run specific test file
npx playwright test tests/e2e/queryViewer.spec.js

# Run with debug mode
npx playwright test --debug
```

#### Test Scenarios Covered

1. Component loading and visibility
2. Configuration selection
3. Query execution and results display
4. Dynamic parameter handling
5. Run As user functionality
6. Metadata creation (sandbox only)
7. Production safeguards
8. Pagination controls
9. Empty state handling
10. i18n label verification

See [E2E Testing Documentation](./tests/e2e/README.md) for detailed information.

### Code Quality

Run PMD and ESLint scans:

```bash
# PMD scan for Apex
sf scanner run --format csv --target "force-app/main/default/classes/*.cls" --outfile code-quality.csv

# ESLint for LWC
npm run lint
```

**Current Status**:

- ✅ 0 PMD violations
- ✅ 0 ESLint errors
- ✅ All ApexDoc comments present
- ✅ No hardcoded IDs in production code

## 🔐 Security Model

### Permission Requirements

#### For All Users

- **Permission Set**: `JT_Dynamic_Queries`
  - Grants access to Apex classes
  - Grants access to custom metadata
  - Grants access to the application

#### For Run As Feature

- **View All Data** OR **Modify All Data** permission
  - Required to search and select users
  - Required to execute queries as other users

### Security Features

1. **USER_MODE Enforcement**
   - All queries execute with `WITH USER_MODE`
   - Respects FLS, CRUD, and sharing rules
   - Cannot bypass user permissions

2. **Production Safeguards**
   - Metadata creation UI hidden in production
   - Detection via `Organization.IsSandbox` and `TrialExpirationDate`
   - Forces use of Setup UI for production changes

3. **Input Validation**
   - SOQL queries validated before execution
   - JSON bindings validated
   - Parameter types checked

4. **Run As Validation**
   - Requires admin-level permissions
   - Current user excluded from selection
   - Results reflect target user's actual permissions

## 🌍 Internationalization

The application supports 4 languages with automatic detection:

| Language | Code | Coverage |
| -------- | ---- | -------- |
| English  | en   | 100%     |
| Spanish  | es   | 100%     |
| French   | fr   | 100%     |
| German   | de   | 100%     |

Language is detected from the browser's locale and falls back to English if not supported.

### Translated Components

- All LWC labels and messages
- Button text and tooltips
- Error messages
- Documentation content
- Pagination controls

## 🚀 Performance Optimizations

### Static Configuration Cache

```apex
private static Map<String, JT_DynamicQueryConfiguration__mdt> configCache;
```

- **Custom Metadata cached per transaction** (no repeated SOQL queries)
- Cache persists across method calls within same execution context
- Significantly reduces SOQL consumption (from N queries to 1)
- Improves response time for repeated configuration access

**Pattern Used:** Static factory method with internal singleton instance

- Public methods are `static` for easy access: `JT_DataSelector.getRecords()`
- Internally uses singleton pattern: `getInstance()` maintains instance state
- Best of both worlds: simple API + efficient caching

### Single JSON Deserialization

- Bindings deserialized **once per execution** (not per field access)
- Reduced CPU time and memory allocation
- Better memory management
- Avoids redundant parsing operations

### Efficient Query Execution

- Uses `Database.queryWithBinds()` for **parameterized queries**
- **Prevents SOQL injection** attacks
- Optimized for large result sets
- Enforces `USER_MODE` or `SYSTEM_MODE` as specified

### Client-Side Filtering & Pagination

- User dropdown loaded **once** (cacheable=true)
- Filtered in JavaScript (no repeated Apex calls)
- Pagination handled **client-side** (10 records per page)
- Reduces server round-trips and improves UX

## 📋 Requirements

- Salesforce API v65.0 or higher
- Lightning Experience enabled
- Custom Metadata Types enabled
- Platform Cache enabled (for Run As System.runAs mode)

### Optional for Development

- Node.js 18+ (for E2E tests)
- Playwright (for E2E tests)
- Salesforce CLI (for deployment)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Write/update tests (maintain >75% coverage)
5. Run code quality scans
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Development Guidelines

- Follow Salesforce best practices
- Add ApexDoc comments to all public methods
- Write comprehensive test classes
- Update documentation for new features
- Ensure all tests pass before submitting PR

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 🙏 Acknowledgments

- Salesforce Developer Community
- Lightning Web Components documentation
- PMD and ESLint teams
- Playwright testing framework

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/jterrats/JT_DynamicQueries/issues)
- **Documentation**: Available in-app or in `/docs` folder
- **Questions**: Open a GitHub Discussion

## 🗺️ Roadmap

- [ ] Export results to CSV
- [ ] Query history and favorites
- [ ] Bulk query execution
- [ ] Advanced filtering UI
- [ ] Query builder interface
- [ ] Additional language support

---

<div align="center">

**Made with ❤️ for the Salesforce Community**

<a href="https://githubsfdeploy.herokuapp.com?owner=jterrats&repo=JT_DynamicQueries&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

</div>
