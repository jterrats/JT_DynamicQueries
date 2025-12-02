/**
 * @description Reusable query results viewer with functional programming patterns
 * @author Jaime Terrats
 * @date 2025-11-30
 */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// Pure functions for data transformation
const pipe =
  (...fns) =>
  (x) =>
    fns.reduce((v, f) => f(v), x);

const addRowMetadata = (start) => (row, index) => ({
  ...row,
  _rowNumber: start + index + 1,
  _displayName: row.Name || row.Id || `Record ${start + index + 1}`
});

const addExpandState = (expandedSet) => (row) => {
  const isExpanded = expandedSet.has(row.Id);
  return {
    ...row,
    _expanded: isExpanded,
    _expandIcon: isExpanded ? "utility:chevrondown" : "utility:chevronright",
    _expandLabel: isExpanded ? "Collapse" : "Expand"
  };
};

const createCells = (columns) => (row) => ({
  ...row,
  _cells: columns.map((col) => ({
    key: col.fieldName,
    label: col.label,
    value: row[col.fieldName] || ""
  }))
});

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
  @api records = [];
  @api recordCount = 0;
  @api pageSize = 10;

  @track currentPage = 1;
  @track viewMode = { table: true, json: false, csv: false };
  @track jsonOutput = "";
  @track csvOutput = "";
  expandedCards = new Set();

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

  // Computed - Pagination using functional composition
  get paginatedResults() {
    if (!this.records?.length) return [];

    const start = (this.currentPage - 1) * this.pageSize;
    const end = start + this.pageSize;

    const transformRecord = pipe(
      addRowMetadata(start),
      addExpandState(this.expandedCards),
      createCells(this.columns)
    );

    return this.records.slice(start, end).map(transformRecord);
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
    return this.recordCount !== 1 ? "records" : "record";
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
    this.records = [...this.records]; // Immutable update trigger
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
    console.log("🔥 parentColumns CALLED");
    console.log("🔥 this.columns:", this.columns);
    console.log("🔥 this.columns.length:", this.columns?.length);

    if (!this.columns || this.columns.length === 0) {
      console.log("🔥 No columns, returning []");
      return [];
    }

    const filtered = this.columns.filter((col) => {
      if (this.records.length === 0) return true;

      const firstRecord = this.records[0];
      const value = firstRecord[col.fieldName];

      const isChildRelationship =
        value &&
        typeof value === "object" &&
        value.records &&
        Array.isArray(value.records);

      console.log(
        `🔥 Column ${col.fieldName}: isChildRelationship=${isChildRelationship}`
      );

      return !isChildRelationship;
    });

    console.log("🔥 parentColumns filtered:", filtered);
    return filtered;
  }

  // Override paginatedResults to include child relationship metadata
  get paginatedResults() {
    console.log("🔥 paginatedResults CALLED");
    console.log("🔥 this.records:", this.records);
    console.log("🔥 this.records.length:", this.records?.length);

    if (!this.records || this.records.length === 0) {
      console.log("🔥 No records, returning []");
      return [];
    }

    const start = (this.currentPage - 1) * this.pageSize;
    const end = start + this.pageSize;
    const pageRecords = this.records.slice(start, end);

    console.log("🔥 pageRecords.length:", pageRecords.length);

    const enriched = pageRecords.map((row, index) => {
      const enrichedRow = { ...row };

      // Add row metadata
      enrichedRow._rowNumber = start + index + 1;
      enrichedRow._displayName =
        row.Name || row.Id || `Record ${start + index + 1}`;

      // ✅ Create _cells array for template iteration (LWC doesn't allow computed property access)
      enrichedRow._cells = this.parentColumns.map((col) => ({
        key: col.fieldName,
        label: col.label,
        value: row[col.fieldName] || ""
      }));

      // Detect child relationships
      const childRelationships = [];
      Object.keys(row).forEach((key) => {
        const value = row[key];
        if (
          value &&
          typeof value === "object" &&
          value.records &&
          Array.isArray(value.records) &&
          value.records.length > 0
        ) {
          // Generate columns for this child relationship
          const childColumns = this.generateColumnsForRecords(value.records);

          childRelationships.push({
            name: key,
            label: `${this.formatLabel(key)} (${value.records.length})`,
            records: value.records,
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

    console.log("🔥 enriched paginatedResults:", enriched);
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

    this.records = this.records.map((row) => {
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
      .then(() => this.showToast("success", "Success", "JSON copied"))
      .catch((err) => {
        console.error("Copy failed:", err);
        this.showToast(
          "error",
          "Error",
          "Copy failed: " + (err.message || "Unknown error")
        );
      });
  }

  handleCopyCsv() {
    // Generate CSV if not already generated
    if (!this.csvOutput) {
      this.csvOutput = this.generateCSV();
    }

    this.copyToClipboard(this.csvOutput)
      .then(() => this.showToast("success", "Success", "CSV copied"))
      .catch((err) => {
        console.error("Copy failed:", err);
        this.showToast(
          "error",
          "Error",
          "Copy failed: " + (err?.message || "Unknown error")
        );
      });
  }

  handleDownloadCsv() {
    if (!this.records?.length) {
      return this.showToast("error", "No Data", "No records to export");
    }

    const csv = this.generateCSV();
    this.downloadFile(csv, `query_results_${Date.now()}.csv`, "text/csv");
    this.showToast("success", "Success", "CSV downloaded");
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
          records: this.records
        },
        null,
        2
      );
    } catch (error) {
      this.showToast("error", "JSON Error", "Generation failed");
      return "{}";
    }
  }

  generateCSV() {
    // Check if records have child relationships
    const hasChildren = this.records.some((record) => {
      return Object.keys(record).some((key) => {
        const value = record[key];
        return (
          value &&
          typeof value === "object" &&
          value.records &&
          Array.isArray(value.records) &&
          value.records.length > 0
        );
      });
    });

    if (hasChildren) {
      return this.generateFlattenedCSV();
    } else {
      // Simple CSV without children
      const headers = this.parentColumns.map((col) => col.label).join(",");
      const rows = this.records.map(createCSVRow(this.parentColumns));
      return [headers, ...rows].join("\n");
    }
  }

  // Generate flattened CSV with parent + children (LEFT JOIN style)
  generateFlattenedCSV() {
    const parentFields = this.parentColumns.map((col) => col.fieldName);
    const childFieldsSet = new Set();

    // Collect all unique child fields
    this.records.forEach((record) => {
      Object.keys(record).forEach((key) => {
        const value = record[key];
        if (
          value &&
          typeof value === "object" &&
          value.records &&
          Array.isArray(value.records)
        ) {
          value.records.forEach((childRecord) => {
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
    this.records.forEach((record) => {
      // Extract parent data
      const parentData = {};
      parentFields.forEach((field) => {
        parentData[field] = record[field];
      });

      // Collect all children from all relationships
      const children = [];
      Object.keys(record).forEach((key) => {
        const value = record[key];
        if (
          value &&
          typeof value === "object" &&
          value.records &&
          Array.isArray(value.records) &&
          value.records.length > 0
        ) {
          value.records.forEach((childRecord) => {
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
