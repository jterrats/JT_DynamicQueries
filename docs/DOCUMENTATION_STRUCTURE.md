# Documentation Structure

## Overview

This project maintains documentation in **English only** for consistency and international collaboration.

## Documentation Categories

### 📚 User-Facing Documentation

**Location**: `/docs/guides/`, `/docs/architecture/`, `/README.md`

These documents are intended for end users, administrators, and developers using the framework:

- **User Guides**: Step-by-step instructions for using features
- **Architecture Documentation**: Public-facing technical documentation
- **API Reference**: Documentation for public APIs
- **Getting Started**: Quick start guides and tutorials

### 🔧 Internal Development Documentation

**Location**: `/docs/development/`

> **⚠️ INTERNAL USE ONLY** - These documents contain internal analysis, technical decisions, and implementation details that are not intended for end users.

**Contents**:
- Analysis reports (`*_ANALYSIS.md`)
- Implementation summaries (`*_IMPLEMENTATION.md`)
- Refactoring plans (`*_PLAN.md`)
- Progress reports (`*_SUMMARY.md`)
- Technical reports (`*_REPORT.md`)

**Language**: All internal documentation is in **English**.

### 📊 Reports and Summaries

**Location**: `/docs/reports/`

Historical reports and summaries that may be referenced but are not actively maintained:

- Code quality reports
- Test coverage reports
- Release summaries
- Historical analysis

## Translation Status

### ✅ Completed Translations

- `docs/development/JSON_SERIALIZATION_ANALYSIS.md`
- `docs/development/ERROR_LOGGING_IMPLEMENTATION.md`
- `docs/development/DUPLICATED_LOGIC_ANALYSIS.md`
- `docs/development/README.md` (new)

### ⚠️ Pending Translations

The following files in `/docs/development/` contain Spanish content and should be translated:

- `ERROR_HANDLING_ANALYSIS.md`
- `FSM_ANALYSIS.md`
- `E2E_TESTS_UPDATE_SUMMARY.md`
- `SEMANTIC_HTML_FINAL_REPORT.md`
- `REFACTORING_PLAN.md`
- `E2E_PROGRESS_SUMMARY.md`
- `SEMANTIC_HTML_IMPROVEMENTS.md`
- `REFACTORING_PLAN_jtQueryViewer.md`
- `ERROR_ANALYSIS_ClassCastException.md`
- `SEMANTIC_HTML_IMPLEMENTATION_SUMMARY.md`

**Note**: These are internal analysis documents. Translation can be done incrementally as they are referenced.

## Guidelines

1. **All new documentation** must be written in **English**
2. **User-facing documentation** should be clear, concise, and accessible
3. **Internal documentation** should be clearly marked with the `⚠️ INTERNAL USE ONLY` notice
4. **Code examples** should be language-agnostic (use English comments)
5. **File names** should use English (e.g., `ERROR_LOGGING_IMPLEMENTATION.md` not `IMPLEMENTACION_LOG_ERRORES.md`)

