# Changelog

All notable changes to the JT Dynamic Queries project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-30

### 🎉 Initial Release

### Added

#### Core Functionality

- **JT_DataSelector Class**: Optimized data selector with static cache and singleton pattern
  - Static factory methods for easy integration
  - Internal singleton for efficient resource management
  - Cache mechanism for Custom Metadata to reduce SOQL queries
  - Support for predefined and dynamic bind variables
  - USER_MODE and SYSTEM_MODE security options
  - **@InvocableMethod**: Flow and Agentforce integration for executing queries from declarative tools

#### Lightning Web Components

- **jtQueryViewer**: Main query execution interface
  - Configuration selection with searchable dropdown
  - Dynamic input generation for queries without predefined bindings
  - Real-time query preview
  - Results display with pagination (10 records per page)
  - "Run As User" feature with two modes:
    - Standard execution with USER_MODE
    - Test context execution with System.runAs() for permission validation
  - Metadata creation and editing (Sandbox/Developer/Trial only)
  - Production override option for Starter/Free editions with security warnings
  - **"Where is this used?" functionality**: Search Apex classes for configuration usage
  - Multi-language support (English, Spanish, French, German)
  - Full WCAG 2.1 AA accessibility compliance
  - Responsive design for mobile, tablet, and desktop

- **jtProjectDocs**: In-app documentation viewer
  - Multi-language documentation
  - Responsive grid layout with icons
  - Table of contents with smooth scrolling
  - Searchable sections

- **jtAuditHistory**: Production editing audit trail
  - Tracks all changes to production editing settings
  - Shows who enabled/disabled metadata editing
  - Displays timestamp, user, org type, and IP address
  - Multi-language support

#### Apex Controllers

- **JT_QueryViewerController**: Main controller for query execution
  - Fetches configurations
  - Executes queries with bind variables
  - Extracts SOQL parameters for dynamic inputs
  - User search for impersonation
  - Query validation

- **JT_MetadataCreator**: Metadata management controller
  - Creates new query configurations via Tooling API
  - Updates existing configurations
  - Environment detection (Sandbox/Production/Developer/Trial)
  - SOQL query validation
  - Automatic object name extraction

- **JT_RunAsTestExecutor**: Test context execution orchestrator
  - Executes queries with System.runAs()
  - Platform Cache for parameter passing
  - Asynchronous test execution

- **JT_ProductionSettingsController**: Production override management
  - Manages JT_DynamicQuerySettings\_\_c Custom Setting
  - Detects Starter/Free editions
  - Creates audit log entries

- **JT_UsageFinder**: Configuration usage analyzer
  - Scans all Apex classes
  - Finds JT_DataSelector references
  - Displays usage by class and line number
  - Regex-based configuration name extraction

#### Custom Metadata Type

- **JT_DynamicQueryConfiguration\_\_mdt**: Query configuration storage
  - Label and Developer Name
  - Base Query (SOQL)
  - Object Name (auto-detected)
  - Bindings (JSON format for predefined variables)
  - Field Mappings

#### Custom Objects

- **JT_SettingsAuditLog\_\_c**: Audit trail for production settings
  - Action (Enabled/Disabled)
  - Changed By (User lookup)
  - Username
  - Timestamp
  - Org Type
  - IP Address

#### Custom Settings

- **JT_DynamicQuerySettings\_\_c**: Hierarchy Custom Setting
  - JT_AllowProductionEditing\_\_c (Checkbox)

#### Security & Permissions

- **JT_Dynamic_Queries Permission Set**: Complete access control
  - Apex class access (all 7 controllers)
  - Custom Metadata Type access
  - Custom Setting access
  - Custom Object permissions (audit logs)
  - Tab visibility (Query Viewer, Documentation, Audit History, Reports)

#### Custom App

- **JT_Dynamic_Queries**: Lightning application
  - Query Viewer tab
  - Documentation tab
  - Audit History tab
  - Reports tab (standard)

#### Testing

- **Apex Tests**: 100% code coverage for all controllers
  - JT_DataSelector_Test
  - JT_QueryViewerController_Test
  - JT_MetadataCreator_Test
  - JT_RunAsTestExecutor_Test
  - JT_GenericRunAsTest

- **E2E Tests (Playwright)**: Comprehensive user flow testing
  - SF CLI session authentication
  - Configuration selection
  - Query execution
  - Dynamic input generation
  - Run As User functionality
  - Metadata creation (sandbox only)
  - Production safeguards

#### Code Quality

- **PMD Compliance**: 0 violations
- **ESLint Compliance**: 0 violations
- **Security Analysis**: No vulnerabilities detected
- **AppExchange Ready**: Meets all submission requirements

#### Internationalization

- **4 Languages Supported**:
  - English (en)
  - Spanish (es)
  - French (fr)
  - German (de)
- Automatic locale detection
- All UI elements translated
- Date/time formatting per locale

#### Documentation

- **README.md**: Comprehensive project overview
- **ACCESSIBILITY.md**: WCAG 2.1 AA compliance details
- **REPORT_TYPE_SETUP.md**: Manual setup instructions
- **E2E Test Documentation**: Playwright test setup and execution
- **ApexDoc**: All public methods documented

#### Scripts

- **setup-test-data.apex**: Idempotent test data creation
- **assign-permset.apex**: Permission set assignment

### Performance Optimizations

- Static cache for Custom Metadata queries
- Single JSON deserialization per query execution
- Client-side filtering for dropdowns (configurations and users)
- Pagination for large result sets
- Cacheable Apex methods where appropriate

### Security Features

- USER_MODE enforcement for all SOQL queries
- Field-level security respect
- Sharing rules enforcement
- Environment-based metadata editing restrictions
- Production override with audit logging
- Explicit security warnings for production editing

### UX/UI Enhancements

- Searchable dropdowns with client-side filtering
- Real-time query validation
- Dynamic input generation based on SOQL parameters
- Tooltips and help text throughout
- Color-coded validation messages
- Bold labels for important fields
- Warning banners for production environments
- Responsive grid layouts
- SLDS2 styling
- Focus management for accessibility
- Screen reader support

### Known Limitations

- Report Types for Custom Metadata cannot be deployed via Metadata API (manual setup required)
- System.runAs() only works in test context (as designed by Salesforce)
- Starter/Free editions require manual override to enable metadata editing

---

## Future Roadmap

- [ ] Scheduled query execution
- [ ] Email notifications for query results
- [ ] Query result export to CSV
- [ ] Version control for configuration changes
- [ ] Query execution history and analytics
- [ ] Support for aggregate queries
- [ ] Query builder UI
- [ ] Integration with External Objects

---

## Contributors

- Jaime Terrats (@jterrats) - Lead Developer

## License

This project is proprietary software intended for Salesforce AppExchange distribution.

---

## Notes

- Initial version developed with focus on enterprise-grade quality
- Designed for production use from day one
- Fully tested and documented
- Ready for AppExchange submission
