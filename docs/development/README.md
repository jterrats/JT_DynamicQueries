# Internal Development Documentation

> **⚠️ INTERNAL USE ONLY** - This directory contains internal development documentation, analysis reports, and technical decision records. This documentation is **not intended for end users** and may contain technical details, implementation decisions, and analysis that are subject to change.

## Purpose

This directory contains:

- **Analysis Reports**: Technical analysis of code patterns, refactoring opportunities, and architectural decisions
- **Implementation Summaries**: Detailed records of feature implementations and changes
- **Refactoring Plans**: Documentation of refactoring efforts and code improvements
- **Error Analysis**: Deep-dive analysis of bugs and their resolutions
- **Testing Reports**: E2E test updates and progress tracking

## Structure

- `*_ANALYSIS.md` - Technical analysis documents
- `*_IMPLEMENTATION.md` - Implementation details and summaries
- `*_PLAN.md` - Refactoring and improvement plans
- `*_SUMMARY.md` - Progress and status summaries
- `*_REPORT.md` - Detailed technical reports

## Language

All documentation in this directory is written in **English** for consistency and to facilitate collaboration with international development teams.

## Git Tracking Policy

### ✅ **Tracked in Git** (Important Technical Decisions)

These documents should be tracked because they document important architectural decisions and provide context for future developers:

- **Architectural Analysis**: `JSON_SERIALIZATION_ANALYSIS.md`, `ERROR_HANDLING_ANALYSIS.md`
- **Implementation Records**: `ERROR_LOGGING_IMPLEMENTATION.md`, `IMPLEMENTATION_SUMMARY.md`
- **Refactoring Plans**: `REFACTORING_PLAN.md`, `REFACTORING_PLAN_jtQueryViewer.md`
- **Error Analysis**: `ERROR_ANALYSIS_ClassCastException.md`
- **State Management**: `FSM_ANALYSIS.md`

**Rationale**: These documents provide valuable context for understanding why certain technical decisions were made and help prevent repeating past mistakes.

### ⚠️ **Consider Not Tracking** (Temporary/Personal Notes)

These documents may be temporary analysis or personal development notes:

- **Progress Summaries**: `E2E_PROGRESS_SUMMARY.md`, `E2E_TESTS_UPDATE_SUMMARY.md`
- **Temporary Analysis**: Very specific, one-time analysis that won't be referenced later
- **Personal Development Notes**: Notes specific to a developer's workflow

**Recommendation**: If a document is truly temporary or personal, consider:
1. Moving it to a local `docs/development/_local/` directory (gitignored)
2. Or deleting it after the work is complete

### 📋 **Current Status**

All files in this directory are currently tracked in git. If you want to exclude temporary analysis files, add them to `.gitignore`:

```gitignore
# Temporary development analysis (not tracked)
docs/development/_local/
docs/development/*_TEMP.md
docs/development/*_DRAFT.md
```

## User-Facing Documentation

For end-user documentation, please refer to:

- `/docs/guides/` - User guides and tutorials
- `/docs/architecture/` - Public architecture documentation
- `/README.md` - Main project README
