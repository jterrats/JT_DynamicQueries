/**
 * @description Reusable query results viewer with functional programming patterns
 * @author Jaime Terrats
 * @date 2025-11-30
 */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
// Import Custom Labels
import queryResultsLabel from "@salesforce/label/c.JT_jtQueryResults_queryResults";
import viewModeSelectionLabel from "@salesforce/label/c.JT_jtQueryResults_viewModeSelection";
import tableLabel from "@salesforce/label/c.JT_jtQueryResults_table";
import viewAsTableLabel from "@salesforce/label/c.JT_jtQueryResults_viewAsTable";
import viewResultsAsTableLabel from "@salesforce/label/c.JT_jtQueryResults_viewResultsAsTable";
import jsonLabel from "@salesforce/label/c.JT_jtQueryResults_json";
import viewAsJsonLabel from "@salesforce/label/c.JT_jtQueryResults_viewAsJson";
import viewResultsAsJsonLabel from "@salesforce/label/c.JT_jtQueryResults_viewResultsAsJson";
import csvLabel from "@salesforce/label/c.JT_jtQueryResults_csv";
import downloadAsCsvLabel from "@salesforce/label/c.JT_jtQueryResults_downloadAsCsv";
import downloadResultsAsCsvFileLabel from "@salesforce/label/c.JT_jtQueryResults_downloadResultsAsCsvFile";
import expandCollapseLabel from "@salesforce/label/c.JT_jtQueryResults_expandCollapse";
import resultsAsExpandableCardsLabel from "@salesforce/label/c.JT_jtQueryResults_resultsAsExpandableCards";
import recordLabel from "@salesforce/label/c.JT_jtQueryResults_record";
import toggleDetailsForLabel from "@salesforce/label/c.JT_jtQueryResults_toggleDetailsFor";
import rowNumberLabel from "@salesforce/label/c.JT_jtQueryResults_rowNumber";
import jsonOutputLabel from "@salesforce/label/c.JT_jtQueryResults_jsonOutput";
import copyLabel from "@salesforce/label/c.JT_jtQueryResults_copy";
import csvPreviewLabel from "@salesforce/label/c.JT_jtQueryResults_csvPreview";
import downloadLabel from "@salesforce/label/c.JT_jtQueryResults_download";
import noteLabel from "@salesforce/label/c.JT_jtQueryResults_note";
import csvNoteLabel from "@salesforce/label/c.JT_jtQueryResults_csvNote";
import paginationNavigationLabel from "@salesforce/label/c.JT_jtQueryResults_paginationNavigation";
import paginationControlsLabel from "@salesforce/label/c.JT_jtQueryResults_paginationControls";
import previousPageLabel from "@salesforce/label/c.JT_jtQueryResults_previousPage";
import goToPreviousPageLabel from "@salesforce/label/c.JT_jtQueryResults_goToPreviousPage";
import nextPageLabel from "@salesforce/label/c.JT_jtQueryResults_nextPage";
import goToNextPageLabel from "@salesforce/label/c.JT_jtQueryResults_goToNextPage";
import recordsLabel from "@salesforce/label/c.JT_jtQueryResults_records";
import recordSingularLabel from "@salesforce/label/c.JT_jtQueryResults_recordSingular";
import successLabel from "@salesforce/label/c.JT_jtQueryResults_success";
import jsonCopiedLabel from "@salesforce/label/c.JT_jtQueryResults_jsonCopied";
import errorLabel from "@salesforce/label/c.JT_jtQueryResults_error";
import copyFailedLabel from "@salesforce/label/c.JT_jtQueryResults_copyFailed";
import csvCopiedLabel from "@salesforce/label/c.JT_jtQueryResults_csvCopied";
import csvDownloadedLabel from "@salesforce/label/c.JT_jtQueryResults_csvDownloaded";
import noDataLabel from "@salesforce/label/c.JT_jtQueryResults_noData";
import noRecordsToExportLabel from "@salesforce/label/c.JT_jtQueryResults_noRecordsToExport";
import jsonErrorLabel from "@salesforce/label/c.JT_jtQueryResults_jsonError";
import generationFailedLabel from "@salesforce/label/c.JT_jtQueryResults_generationFailed";

// Pure functions for data transformation
const toggleSetMembership = (set, item) => {
  const newSet = new Set(set);
  newSet.has(item) ? newSet.delete(item) : newSet.add(item);
  return newSet;
};

const escapeCSV = (value) => `"${String(value || "").replace(/"/g, '""')}"`;

const createCSVRow = (columns) => (row) =>
  columns.map((col) => escapeCSV(row[col.fieldName])).join(",");

const createJSONMetadata = (recordCount, columns) => ({
  totalRecords: recordCount,
  fields: columns.map((col) => col.fieldName),
  exportDate: new Date().toISOString()
});

export default class JtQueryResults extends LightningElement {
  @api columns = [];
  @api recordCount = 0;
  @api pageSize = 10;

  @track currentPage = 1;
  @track viewMode = { table: true, json: false, csv: false };
  @track jsonOutput = "";
  @track csvOutput = "";
  expandedCards = new Set();

  _records = [];
  _previousRecordCount = 0;

  // Custom Labels
  labels = {
    queryResults: queryResultsLabel,
    viewModeSelection: viewModeSelectionLabel,
    table: tableLabel,
    viewAsTable: viewAsTableLabel,
    viewResultsAsTable: viewResultsAsTableLabel,
    json: jsonLabel,
    viewAsJson: viewAsJsonLabel,
    viewResultsAsJson: viewResultsAsJsonLabel,
    csv: csvLabel,
    downloadAsCsv: downloadAsCsvLabel,
    downloadResultsAsCsvFile: downloadResultsAsCsvFileLabel,
    expandCollapse: expandCollapseLabel,
    resultsAsExpandableCards: resultsAsExpandableCardsLabel,
    record: recordLabel,
    toggleDetailsFor: toggleDetailsForLabel,
    rowNumber: rowNumberLabel,
    jsonOutput: jsonOutputLabel,
    copy: copyLabel,
    csvPreview: csvPreviewLabel,
    download: downloadLabel,
    note: noteLabel,
    csvNote: csvNoteLabel,
    paginationNavigation: paginationNavigationLabel,
    paginationControls: paginationControlsLabel,
    previousPage: previousPageLabel,
    goToPreviousPage: goToPreviousPageLabel,
    nextPage: nextPageLabel,
    goToNextPage: goToNextPageLabel,
    records: recordsLabel,
    recordSingular: recordSingularLabel,
    success: successLabel,
    jsonCopied: jsonCopiedLabel,
    error: errorLabel,
    copyFailed: copyFailedLabel,
    csvCopied: csvCopiedLabel,
    csvDownloaded: csvDownloadedLabel,
    noData: noDataLabel,
    noRecordsToExport: noRecordsToExportLabel,
    jsonError: jsonErrorLabel,
    generationFailed: generationFailedLabel
  };

  // 🐛 FIX: Reset pagination when records change
  @api
  get records() {
    return this._records;
  }

  set records(value) {
    // Debug: Log when records are set
    console.log("jtQueryResults: records setter called", {
      valueLength: value?.length,
      value: value,
      recordCount: this.recordCount,
      previousRecordCount: this._previousRecordCount
    });

    // Create a new array reference for LWC reactivity
    this._records = value ? [...value] : [];

    // Reset to page 1 when new data arrives
    if (
      value &&
      value.length > 0 &&
      this.recordCount !== this._previousRecordCount
    ) {
      this.currentPage = 1;
      this._previousRecordCount = this.recordCount;
    }

    // Debug: Log after assignment
    console.log("jtQueryResults: _records after assignment", {
      _recordsLength: this._records?.length,
      paginatedResultsLength: this.paginatedResults?.length
    });
  }

  // Computed - View mode
  get isTableView() {
    return this.viewMode.table ? "brand" : "neutral";
  }

  get isJsonView() {
    return this.viewMode.json ? "brand" : "neutral";
  }

  get isCsvView() {
    return this.viewMode.csv ? "brand" : "neutral";
  }

  get totalPages() {
    return Math.ceil(this.recordCount / this.pageSize);
  }

  get showPagination() {
    return this.recordCount > this.pageSize;
  }

  get firstRecordIndex() {
    return (this.currentPage - 1) * this.pageSize + 1;
  }

  get lastRecordIndex() {
    return Math.min(this.currentPage * this.pageSize, this.recordCount);
  }

  get disablePrevious() {
    return this.currentPage <= 1;
  }

  get disableNext() {
    return this.currentPage >= this.totalPages;
  }

  get recordCountLabel() {
    return this.recordCount !== 1 ? this.labels.records : this.labels.recordSingular;
  }

  // Event handlers - Pure intent, side effects isolated
  handleViewChange(event) {
    const view = event.currentTarget.dataset.view;

    this.viewMode = {
      table: view === "table",
      json: view === "json",
      csv: view === "csv"
    };

    // Side effect: Generate output only when needed
    if (view === "json") {
      this.jsonOutput = this.generateJsonOutput();
    } else if (view === "csv") {
      this.csvOutput = this.generateCSV();
    }
  }

  handleCardToggle(event) {
    const recordId = event.currentTarget.dataset.id;
    this.expandedCards = toggleSetMembership(this.expandedCards, recordId);
    this._records = [...this._records]; // Immutable update trigger
  }

  /**
   * @description Handles keyboard events for card toggle (Enter/Space)
   * @param {KeyboardEvent} event - The keyboard event
   */
  handleCardKeyPress(event) {
    // Handle Enter or Space key
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.handleCardToggle(event);
    }
  }

  // 🆕 Computed: Parent columns only (exclude child relationships)
  get parentColumns() {
    if (!this.columns || this.columns.length === 0) {
      return [];
    }

    const filtered = this.columns.filter((col) => {
      if (this._records.length === 0) return true;

      const firstRecord = this._records[0];
      const value = firstRecord[col.fieldName];

      // Support two formats:
      // 1. Direct array (from JT_GenericRunAsTest): value = [record1, record2, ...]
      // 2. Wrapped format (from regular queries): value = { records: [record1, record2, ...] }
      const isDirectArray = Array.isArray(value) && value.length > 0 && value[0] && typeof value[0] === "object";
      const isWrappedFormat = value &&
        typeof value === "object" &&
        value.records &&
        Array.isArray(value.records);

      const isChildRelationship = isDirectArray || isWrappedFormat;

      return !isChildRelationship;
    });

    return filtered;
  }

  // Override paginatedResults to include child relationship metadata
  get paginatedResults() {
    // Debug: Log when paginatedResults is computed
    if (!this._records || this._records.length === 0) {
      console.log("jtQueryResults: paginatedResults - no records", {
        _records: this._records,
        _recordsLength: this._records?.length,
        recordCount: this.recordCount
      });
      return [];
    }

    const start = (this.currentPage - 1) * this.pageSize;
    const end = start + this.pageSize;
    const pageRecords = this._records.slice(start, end);

    const enriched = pageRecords.map((row, index) => {
      const enrichedRow = { ...row };

      // Add row metadata
      enrichedRow._rowNumber = start + index + 1;
      enrichedRow._displayName =
        row.Name || row.Id || `Record ${start + index + 1}`;
      enrichedRow._ariaLabel = `${this.labels.record} ${enrichedRow._rowNumber}`;
      enrichedRow._toggleAriaLabel = `${this.labels.toggleDetailsFor} ${enrichedRow._displayName}`;

      // ✅ Create _cells array for template iteration (LWC doesn't allow computed property access)
      enrichedRow._cells = this.parentColumns.map((col) => ({
        key: col.fieldName,
        label: col.label,
        value: row[col.fieldName] || ""
      }));

      // Detect child relationships
      // Support two formats:
      // 1. Direct array (from JT_GenericRunAsTest): value = [record1, record2, ...]
      // 2. Wrapped format (from regular queries): value = { records: [record1, record2, ...] }
      const childRelationships = [];
      Object.keys(row).forEach((key) => {
        const value = row[key];
        let childRecords = null;

        // Check if it's a direct array (from Run As User test)
        if (Array.isArray(value) && value.length > 0) {
          // Verify it's an array of objects (not primitives)
          if (value[0] && typeof value[0] === "object") {
            childRecords = value;
          }
        }
        // Check if it's wrapped format (from regular queries)
        else if (
          value &&
          typeof value === "object" &&
          value.records &&
          Array.isArray(value.records) &&
          value.records.length > 0
        ) {
          childRecords = value.records;
        }

        if (childRecords) {
          // Generate columns for this child relationship
          const childColumns = this.generateColumnsForRecords(childRecords);

          childRelationships.push({
            name: key,
            label: `${this.formatLabel(key)} (${childRecords.length})`,
            records: childRecords,
            columns: childColumns
          });
        }
      });

      enrichedRow._hasChildren = childRelationships.length > 0;
      enrichedRow._childRelationships = childRelationships;
      enrichedRow._expanded = enrichedRow._expanded || false;
      enrichedRow._expandIcon = enrichedRow._expanded
        ? "utility:chevrondown"
        : "utility:chevronright";
      enrichedRow._expandLabel = enrichedRow._expanded ? "Collapse" : "Expand";
      enrichedRow._activeChildSections = enrichedRow._expanded
        ? childRelationships.map((r) => r.name)
        : [];
      enrichedRow._childrenKey = `${row.Id}_children`; // ✅ Valid LWC key

      return enrichedRow;
    });

    return enriched;
  }

  // Helper: Generate columns dynamically from records
  generateColumnsForRecords(records) {
    if (!records || records.length === 0) return [];

    const firstRecord = records[0];
    const fields = Object.keys(firstRecord).filter(
      (key) => key !== "attributes" && key !== "AccountId" // ✅ Filter redundant parent FK
    );

    return fields.map((field) => ({
      label: this.formatLabel(field),
      fieldName: field,
      type: "text",
      wrapText: false
    }));
  }

  // Helper: Format field label
  formatLabel(fieldName) {
    if (!fieldName) return "";
    return fieldName
      .replace(/([A-Z])/g, " $1")
      .replace(/^./, (str) => str.toUpperCase())
      .trim();
  }

  // Handle row toggle (expand/collapse)
  handleRowToggle(event) {
    const recordId = event.currentTarget.dataset.id;

    this._records = this._records.map((row) => {
      if (row.Id === recordId) {
        return {
          ...row,
          _expanded: !row._expanded
        };
      }
      return row;
    });
  }

  // 🆕 Computed: Generate columns for tree-grid

  handleCopyJson() {
    // Generate JSON if not already generated
    if (!this.jsonOutput) {
      this.jsonOutput = this.generateJsonOutput();
    }

    this.copyToClipboard(this.jsonOutput)
      .then(() => this.showToast("success", this.labels.success, this.labels.jsonCopied))
      .catch((error) => {
        const errorMessage = error.message || "Unknown error";
        this.showToast(
          "error",
          this.labels.error,
          this.labels.copyFailed.replace("{0}", errorMessage)
        );
      });
  }

  handleCopyCsv() {
    // Generate CSV if not already generated
    if (!this.csvOutput) {
      this.csvOutput = this.generateCSV();
    }

    this.copyToClipboard(this.csvOutput)
      .then(() => this.showToast("success", this.labels.success, this.labels.csvCopied))
      .catch((error) => {
        const errorMessage = error?.message || "Unknown error";
        this.showToast(
          "error",
          this.labels.error,
          this.labels.copyFailed.replace("{0}", errorMessage)
        );
      });
  }

  handleDownloadCsv() {
    if (!this._records?.length) {
      return this.showToast("error", this.labels.noData, this.labels.noRecordsToExport);
    }

    const csv = this.generateCSV();
    this.downloadFile(csv, `query_results_${Date.now()}.csv`, "text/csv");
    this.showToast("success", this.labels.success, this.labels.csvDownloaded);
  }

  handlePreviousPage() {
    this.currentPage = Math.max(1, this.currentPage - 1);
  }

  handleNextPage() {
    this.currentPage = Math.min(this.totalPages, this.currentPage + 1);
  }

  // Pure functions for data generation
  generateJsonOutput() {
    try {
      return JSON.stringify(
        {
          metadata: createJSONMetadata(this.recordCount, this.columns),
          records: this._records
        },
        null,
        2
      );
    } catch {
      this.showToast("error", this.labels.jsonError, this.labels.generationFailed);
      return "{}";
    }
  }

  generateCSV() {
    // Check if records have child relationships
    // Support both formats: direct arrays and wrapped format
    const hasChildren = this._records.some((record) => {
      return Object.keys(record).some((key) => {
        const value = record[key];
        // Check for direct array format
        const isDirectArray = Array.isArray(value) && value.length > 0 && value[0] && typeof value[0] === "object";
        // Check for wrapped format
        const isWrappedFormat = value &&
          typeof value === "object" &&
          value.records &&
          Array.isArray(value.records) &&
          value.records.length > 0;
        return isDirectArray || isWrappedFormat;
      });
    });

    if (hasChildren) {
      return this.generateFlattenedCSV();
    } else {
      // Simple CSV without children
      const headers = this.parentColumns.map((col) => col.label).join(",");
      const rows = this._records.map(createCSVRow(this.parentColumns));
      return [headers, ...rows].join("\n");
    }
  }

  // Generate flattened CSV with parent + children (LEFT JOIN style)
  generateFlattenedCSV() {
    const parentFields = this.parentColumns.map((col) => col.fieldName);
    const childFieldsSet = new Set();

    // Collect all unique child fields
    // Support both formats: direct arrays and wrapped format
    this._records.forEach((record) => {
      Object.keys(record).forEach((key) => {
        const value = record[key];
        let childRecords = null;

        // Check for direct array format
        if (Array.isArray(value) && value.length > 0 && value[0] && typeof value[0] === "object") {
          childRecords = value;
        }
        // Check for wrapped format
        else if (
          value &&
          typeof value === "object" &&
          value.records &&
          Array.isArray(value.records)
        ) {
          childRecords = value.records;
        }

        if (childRecords) {
          childRecords.forEach((childRecord) => {
            Object.keys(childRecord).forEach((childKey) => {
              if (childKey !== "attributes" && childKey !== "AccountId") {
                childFieldsSet.add(childKey);
              }
            });
          });
        }
      });
    });

    const childFields = Array.from(childFieldsSet);

    // Build CSV header
    const allFields = [
      ...parentFields.map((f) => `Parent_${this.formatLabel(f)}`),
      "RelationshipType",
      ...childFields.map((f) => `Child_${this.formatLabel(f)}`)
    ];
    const header = allFields.join(",");

    // Build CSV rows
    const rows = [];
    this._records.forEach((record) => {
      // Extract parent data
      const parentData = {};
      parentFields.forEach((field) => {
        parentData[field] = record[field];
      });

      // Collect all children from all relationships
      // Support both formats: direct arrays and wrapped format
      const children = [];
      Object.keys(record).forEach((key) => {
        const value = record[key];
        let childRecords = null;

        // Check for direct array format
        if (Array.isArray(value) && value.length > 0 && value[0] && typeof value[0] === "object") {
          childRecords = value;
        }
        // Check for wrapped format
        else if (
          value &&
          typeof value === "object" &&
          value.records &&
          Array.isArray(value.records) &&
          value.records.length > 0
        ) {
          childRecords = value.records;
        }

        if (childRecords) {
          childRecords.forEach((childRecord) => {
            children.push({
              type: key,
              data: childRecord
            });
          });
        }
      });

      if (children.length > 0) {
        // Create one row per child (duplication)
        children.forEach((child) => {
          const row = [];

          // Add parent fields (duplicate for each child)
          parentFields.forEach((field) => {
            row.push(escapeCSV(parentData[field]));
          });

          // Add relationship type
          row.push(escapeCSV(child.type));

          // Add child fields
          childFields.forEach((field) => {
            row.push(escapeCSV(child.data[field]));
          });

          rows.push(row.join(","));
        });
      } else {
        // No children - single row with parent only
        const row = [];

        // Add parent fields
        parentFields.forEach((field) => {
          row.push(escapeCSV(parentData[field]));
        });

        // Add empty relationship type and child fields
        row.push(""); // RelationshipType
        childFields.forEach(() => {
          row.push(""); // Empty child fields
        });

        rows.push(row.join(","));
      }
    });

    return `${header}\n${rows.join("\n")}`;
  }

  // Side effect functions (clearly separated)
  copyToClipboard(text) {
    // ✅ Try modern Clipboard API first (LWS orgs)
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(text).catch(() => {
        // If Clipboard API fails, fallback to execCommand
        return this.copyToClipboardFallback(text);
      });
    }

    // ⚠️ Fallback for Locker Service orgs
    return this.copyToClipboardFallback(text);
  }

  copyToClipboardFallback(text) {
    return new Promise((resolve, reject) => {
      const textarea = document.createElement("textarea");
      textarea.value = text;
      textarea.style.position = "fixed";
      textarea.style.opacity = "0";
      textarea.style.pointerEvents = "none";

      document.body.appendChild(textarea);
      textarea.select();

      try {
        const successful = document.execCommand("copy");
        document.body.removeChild(textarea);

        if (successful) {
          resolve();
        } else {
          reject(new Error("Copy command failed"));
        }
      } catch (err) {
        document.body.removeChild(textarea);
        reject(err);
      }
    });
  }

  downloadFile(content, filename, mimeType) {
    const blob = new Blob([content], { type: `${mimeType};charset=utf-8;` });
    const link = document.createElement("a");
    const url = URL.createObjectURL(blob);

    link.href = url;
    link.download = filename;
    link.style.visibility = "hidden";

    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    URL.revokeObjectURL(url);
  }

  showToast(variant, title, message) {
    // ✅ Clear any pending toast timeout to prevent stacking
    if (this._toastTimeout) {
      clearTimeout(this._toastTimeout);
      this._toastTimeout = null;
    }

    // ✅ Dispatch toast with auto-dismiss mode (3 seconds)
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant,
        mode: "dismissible" // Allow manual dismiss but auto-dismiss after 3s
      })
    );

    // ✅ Set timeout to clear reference (prevents memory leaks)
    this._toastTimeout = setTimeout(() => {
      this._toastTimeout = null;
    }, 3000);
  }

  // Public API
  @api
  reset() {
    this.currentPage = 1;
    this.expandedCards = new Set();
    this.viewMode = { table: true, json: false, csv: false };
    this.jsonOutput = "";
    this.csvOutput = "";
  }

  @api
  goToPage(pageNumber) {
    this.currentPage = Math.max(1, Math.min(this.totalPages, pageNumber));
  }
}