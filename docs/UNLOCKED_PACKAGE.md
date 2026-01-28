# Unlocked Package Installation Guide

## 📦 What is an Unlocked Package?

An **Unlocked Package** is Salesforce's modern way to distribute and install applications. Unlike Unmanaged Packages, Unlocked Packages provide:

- ✅ **Versioning**: Track versions and update incrementally
- ✅ **Incremental Updates**: Only changed components are updated
- ✅ **Better Dependency Management**: Clear dependencies between packages
- ✅ **No Namespace Required**: Can be installed without a namespace
- ✅ **Code Visibility**: Code remains editable after installation

## 🚀 Installation Methods

### Method 1: Install via Salesforce CLI (Recommended)

```bash
# Authenticate to your target org
sf org login web --alias myorg --set-default

# Install the package
sf package install --package <VERSION_ID> --wait 10 --target-org myorg

# Assign permission set
sf org assign permset --name JT_Dynamic_Queries --target-org myorg
```

### Method 2: Install via Setup UI

1. Go to **Setup** → **Installed Packages**
2. Click **Install a Package**
3. Enter the Package Version ID (provided after package creation)
4. Click **Install**
5. Follow the installation wizard

### Method 3: Install via URL

```
https://login.salesforce.com/packaging/installPackage.apexp?p0=<VERSION_ID>
```

Replace `<VERSION_ID>` with the actual version ID from the package.

## 📋 Prerequisites

Before installing the package, ensure your org has:

- ✅ **Salesforce API v65.0+**
- ✅ **Lightning Experience** enabled
- ✅ **Custom Metadata Types** enabled
- ✅ **Platform Cache** enabled (for Run As System.runAs mode)
- ✅ **DevHub** org (for creating packages, not required for installation)

## 🔧 Post-Installation Steps

### 1. Assign Permission Set

Users need the `JT_Dynamic_Queries` permission set to access the application:

```bash
sf org assign permset --name JT_Dynamic_Queries --target-org myorg
```

Or via Setup UI:

1. **Setup** → **Users** → **Permission Sets**
2. Find **JT Dynamic Queries**
3. Click **Manage Assignments**
4. Add users

### 2. Create Query Configurations

Create Custom Metadata records for your queries:

1. **Setup** → **Custom Metadata Types** → **JT Dynamic Query Configuration**
2. Click **Manage Records**
3. Click **New**
4. Fill in:
   - **Label**: Display name
   - **Developer Name**: Unique identifier
   - **Base Query**: Your SOQL query
   - **Object Name**: Target object
   - **Bindings** (optional): JSON with default values

### 3. Access the Application

1. Open **App Launcher** (9-dot menu)
2. Search for **Dynamic Queries**
3. Click the app
4. Navigate to **Query Viewer** tab

## 🔄 Updating the Package

When a new version is available:

```bash
# Update to latest version
sf package install --package <NEW_VERSION_ID> --wait 10 --target-org myorg --upgrade-type Delete
```

**Note**: The `--upgrade-type Delete` option removes components that were deleted in the new version. Use with caution.

## 📊 Package Contents

The Unlocked Package includes:

- ✅ **51 Apex Classes** (including test classes)
- ✅ **16 Lightning Web Components**
- ✅ **Custom Objects**: `JT_RunAsTest_Execution__c`, `JT_SettingsAuditLog__c`, `JT_ErrorLog__c`
- ✅ **Custom Metadata Types**: `JT_DynamicQueryConfiguration__mdt`, `JT_SystemSettings__mdt`
- ✅ **Permission Set**: `JT_Dynamic_Queries`
- ✅ **Lightning Application**: `JT_Dynamic_Queries`
- ✅ **Tabs**: Query Viewer, Documentation, Support, Settings Audit Log
- ✅ **Custom Labels**: 142+ labels in 8 languages
- ✅ **Flows**: `JT_Account_Report_Flow`
- ✅ **Layouts** and **Record Types**

## 🛠️ Creating a New Package Version

If you're a maintainer and want to create a new version:

```bash
# Make sure you're authenticated to a DevHub
sf org login web --alias devhub --set-default

# Run the package creation script
./scripts/create-unlocked-package.sh
```

Or manually:

```bash
# Create package version
sf package version create \
    --package JT_DynamicQueries \
    --installation-key-bypass \
    --wait 10 \
    --code-coverage

# The script will output the Version ID for installation
```

## ⚠️ Important Notes

1. **Code Coverage**: Package creation requires 75%+ code coverage
2. **Test Execution**: All tests run during package creation
3. **Dependencies**: No external dependencies required
4. **Namespace**: Package is installed without namespace (code is editable)
5. **Updates**: Incremental updates only change modified components

## 🐛 Troubleshooting

### Installation Fails

- Check API version compatibility (requires v65.0+)
- Verify Lightning Experience is enabled
- Ensure Custom Metadata Types are enabled

### Permission Set Not Found

- Verify package installation completed successfully
- Check that Permission Set was included in package
- Try assigning via Setup UI instead of CLI

### Components Not Visible

- Assign the Permission Set to your user
- Check App Launcher visibility settings
- Verify tabs are included in your app

## 📚 Additional Resources

- [Salesforce Unlocked Packages Documentation](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_intro.htm)
- [Package Versioning Best Practices](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_versioning.htm)
- [Installation Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_install.htm)

## 🤝 Support

For issues or questions:

- **GitHub Issues**: [Create an issue](https://github.com/jterrats/JT_DynamicQueries/issues)
- **Documentation**: See `/docs` folder
- **Questions**: Open a GitHub Discussion
