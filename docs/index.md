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
- [📚 API Reference](api/) - Developer documentation

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

## 📚 Documentation Structure

```
docs/
├── getting-started/    # Installation and setup guides
├── features/           # Feature documentation
├── architecture/       # System design docs
├── api/               # API reference
├── guides/            # How-to guides
└── releases/          # Release notes
```

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.html) for guidelines.

## 📄 License

MIT License - See [LICENSE](https://github.com/jterrats/JT_DynamicQueries/blob/main/LICENSE) for details.

## 🔗 Links

- [GitHub Repository](https://github.com/jterrats/JT_DynamicQueries)
- [Issue Tracker](https://github.com/jterrats/JT_DynamicQueries/issues)
- [Changelog](CHANGELOG_v2.html)

---

**Last Updated:** November 30, 2025
**Version:** 2.0
**Status:** Production Ready ✅
