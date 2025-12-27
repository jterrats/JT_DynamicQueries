# Scripts Directory

This directory contains utility scripts for development, testing, and maintenance.

## 📁 Available Scripts

### Development & Deployment

- **`validate-pipeline.sh`** - Validates GitHub Actions workflows locally using `act`
- **`create-github-issues.sh`** - Creates GitHub issues from templates

### Translation & Localization

- **`migrate-to-custom-labels.js`** - Migrates hardcoded strings to Custom Labels
- **`extract-en-labels-only.js`** - Extracts English labels only
- **`generate-label-imports.js`** - Generates import statements for labels
- **`convert-translations-to-yaml.js`** - Converts translations to YAML format

### Documentation

- **`convert-index-to-jekyll.js`** - Converts index to Jekyll format
- **`convert-testing-to-jekyll.js`** - Converts testing docs to Jekyll format
- **`fix-ascii-diagrams.sh`** - Fixes ASCII diagrams in markdown files

### Apex Scripts

- **`apex/assign-permset.apex`** - Assigns Permission Set to current user
- **`apex/hello.apex`** - Simple hello world script
- **`apex/test-queueable.apex`** - Test script for JT_UsageFinderQueueable (executes job and shows results)
- **`apex/retrieve-queueable-results.apex`** - Retrieve cached results from Queueable job
- **`apex/run-queueable-tests.apex`** - Run all unit tests for JT_UsageFinderQueueable

### SOQL Queries

- **`soql/account.soql`** - Example SOQL query for Account

## 📚 Documentation Files

- **`ACT_USAGE.md`** - Guide for using `act` to test GitHub Actions locally
- **`CROSS_PLATFORM.md`** - Cross-platform development notes
- **`ENABLE_TRANSLATION_WORKBENCH.md`** - Translation workbench setup
- **`TRANSLATION_WORKBENCH_MIGRATION.md`** - Migration guide for translations

## 🚀 Usage

Most scripts can be run directly:

```bash
# Shell scripts
./scripts/validate-pipeline.sh

# Node.js scripts
node scripts/migrate-to-custom-labels.js

# Apex scripts (via Developer Console or CLI)
sf apex run --file scripts/apex/assign-permset.apex

# Test Queueable (copy to Developer Console > Anonymous Apex)
# 1. Execute: scripts/apex/test-queueable.apex
# 2. Wait a few seconds, then retrieve: scripts/apex/retrieve-queueable-results.apex
# 3. Run tests: scripts/apex/run-queueable-tests.apex
```

## 📝 Notes

- All scripts are designed to be run from the project root
- Shell scripts require Unix-like environment (macOS, Linux, Git Bash, WSL)
- Node.js scripts work cross-platform (Windows, macOS, Linux)
