---
layout: default
title: Home
---

# JT Dynamic Queries Documentation

Welcome to the official documentation for **JT Dynamic Queries** - A powerful Dynamic SOQL Query Execution Tool for Salesforce.

## 🚀 Quick Links

- [📹 Demo Gallery](gallery.html) - Watch live demos and test recordings
- [✨ Features v2.0](FEATURES_v2.html) - Complete feature list and examples
- [🏗️ Architecture](ARCHITECTURE_LAYERS.html) - System design and patterns
- [♿ Accessibility](ACCESSIBILITY.html) - WCAG 2.1 AA compliance
- [🔧 Tooling API Setup](TOOLING_API_SETUP.html) - Configure advanced features
- [🌐 Configuración en Español](TOOLING_API_SETUP_ES.html) - Guía en español

## 🎯 What is JT Dynamic Queries?

JT Dynamic Queries is a Lightning Web Component that enables dynamic SOQL query execution with:

- ✅ **Dynamic Configuration**: Metadata-driven query configurations
- ✅ **Multiple View Modes**: Table, JSON, and CSV export
- ✅ **Run As User**: Execute queries in different user contexts
- ✅ **Responsive Design**: Works on desktop, tablet, and mobile
- ✅ **i18n Support**: Multi-language interface (6 languages)
- ✅ **Accessibility**: WCAG 2.1 Level AA compliant

## 📸 Visual Overview

### Screenshots & Videos

Check out our [Gallery](gallery.html) to see the application in action:

- 🎬 **28 E2E Test Videos** - Real Playwright test recordings
- 📸 **3 HD Screenshots** - Key features highlighted
- 📱 **Mobile Demos** - Responsive design showcase

## 🎓 Getting Started

### Installation

1. Clone the repository:

```bash
git clone https://github.com/jterrats/JT_DynamicQueries.git
cd JT_DynamicQueries
```

2. Deploy to your Salesforce org:

```bash
sfdx force:source:deploy -p force-app/main/default -u YOUR_ORG_ALIAS
```

3. Assign the permission set:

```bash
sfdx force:user:permset:assign -n JT_Dynamic_Queries -u YOUR_ORG_ALIAS
```

### Quick Start

1. Navigate to **Dynamic Queries** app
2. Select a query configuration from the dropdown
3. Review the query preview
4. Click **Execute Query**
5. View results in Table, JSON, or CSV format

## 📊 Features

### Core Functionality

- **Searchable Configuration Selector**: Real-time filtering
- **Query Preview**: See SOQL before execution
- **Dynamic Parameters**: Support for bind variables
- **Result Display**: Multiple view formats
- **Pagination**: Handle large result sets
- **Export**: Download results as CSV

### Advanced Features

- **Run As User**: Execute queries in user context
- **Usage Finder**: Find where configurations are used
- **Tooling API**: Search Apex classes and Flows
- **Audit Trail**: Track query executions
- **Production Protection**: Prevent accidental changes

## 🧪 Quality Assurance

- ✅ **28/28 E2E Tests Passing** - 100% success rate
- ✅ **75%+ Apex Coverage** - Production-ready
- ✅ **Automated Accessibility Tests** - WCAG compliance
- ✅ **Multi-language Validation** - i18n tested

## 🏆 Key Highlights

### Performance

- ⚡ **<2s Load Time** - Lightning-fast UI
- 🚀 **Optimized Queries** - Efficient SOQL execution
- 📦 **Lazy Loading** - On-demand resource fetching

### Security

- 🔒 **WITH USER_MODE** - Enforces user permissions
- 🛡️ **Field-level Security** - Respects FLS
- 🔐 **Sharing Rules** - Honors org sharing model

### User Experience

- 🎨 **Modern UI** - Lightning Design System
- 📱 **Responsive** - Mobile-optimized
- ♿ **Accessible** - WCAG 2.1 AA compliant
- 🌐 **Multi-language** - 6 languages supported

## 📚 Available Documentation

### Core Documentation
- [Features v2.0](FEATURES_v2.html) - Complete feature list
- [Architecture Layers](ARCHITECTURE_LAYERS.html) - System design
- [Accessibility](ACCESSIBILITY.html) - WCAG 2.1 AA compliance
- [Microservices Pattern](MICROSERVICES_PATTERN.html) - Design patterns

### Setup & Configuration
- [Tooling API Setup](TOOLING_API_SETUP.html) - English guide
- [Configuración Tooling API](TOOLING_API_SETUP_ES.html) - Guía en español
- [Setup Tooling API](SETUP_TOOLING_API.html) - Alternative guide
- [Report Type Setup](REPORT_TYPE_SETUP.html) - Reports configuration

### Technical Documentation  
- [Run As User Feature](RUN_AS_USER_FEATURE.html) - User context execution
- [Functional Run As](FUNCTIONAL_RUN_AS.html) - Functional implementation
- [Searchable Combobox Usage](SEARCHABLE_COMBOBOX_USAGE.html) - Component guide
- [State Manager](STATE_MANAGER_OFFICIAL.html) - State management
- [Translations Architecture](TRANSLATIONS_ARCHITECTURE.html) - i18n system

### E2E & Testing
- [E2E Complete Success](E2E_COMPLETE_SUCCESS.html) - Test results
- [E2E Tests Update](E2E_TESTS_UPDATE_SUMMARY.html) - Test updates
- [Semantic HTML Report](SEMANTIC_HTML_FINAL_REPORT.html) - HTML improvements
- [Semantic HTML Summary](SEMANTIC_HTML_IMPLEMENTATION_SUMMARY.html) - Implementation

### Release Notes
- [V2 Release Summary](V2_RELEASE_SUMMARY.html) - Version 2.0 overview
- [Changelog v2](CHANGELOG_v2.html) - Version history
- [V3.0 Roadmap](V3_ROADMAP.html) ⭐ - Future plans
- [GitHub Issues v3.0](GITHUB_ISSUES_V3.html) ⭐ - 18 planned features

## 🤝 Contributing

We welcome contributions! See [Contributing Guide](https://github.com/jterrats/JT_DynamicQueries/blob/main/CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - See [LICENSE](https://github.com/jterrats/JT_DynamicQueries/blob/main/LICENSE) for details.

## 🗺️ Roadmap & Future

### v3.0 and Beyond

- 📋 [**v3.0 Roadmap**](V3_ROADMAP.html) - Comprehensive roadmap with timeline and priorities
- 🎫 [**GitHub Issues (18 features)**](GITHUB_ISSUES_V3.html) - Detailed user stories for all planned features
- 🚀 [**View Issues on GitHub**](https://github.com/jterrats/JT_DynamicQueries/issues) - Track progress and contribute

**Planned Features:**
- Visual SOQL Builder with drag & drop
- Query history and favorites
- Bulk query execution
- Advanced result filtering
- Query templates library
- Real-time query validation
- Performance analytics dashboard
- Additional language support (8 total)

## 🔗 Links

- [GitHub Repository](https://github.com/jterrats/JT_DynamicQueries)
- [Issue Tracker](https://github.com/jterrats/JT_DynamicQueries/issues)
- [Changelog](CHANGELOG_v2.html)

---

**Last Updated:** December 1, 2025
**Version:** 2.0
**Status:** Production Ready ✅
