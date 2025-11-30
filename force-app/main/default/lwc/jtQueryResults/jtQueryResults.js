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

    // Side effect: Generate JSON only when needed
    if (view === "json") {
      this.jsonOutput = this.generateJsonOutput();
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

  handleCopyJson() {
    this.copyToClipboard(this.jsonOutput)
      .then(() => this.showToast("success", "Success", "JSON copied"))
      .catch(() => this.showToast("error", "Error", "Copy failed"));
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
    const headers = this.columns.map((col) => col.label).join(",");
    const rows = this.records.map(createCSVRow(this.columns));
    return [headers, ...rows].join("\n");
  }

  // Side effect functions (clearly separated)
  copyToClipboard(text) {
    return navigator.clipboard?.writeText(text) || Promise.reject();
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
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  // Public API
  @api
  reset() {
    this.currentPage = 1;
    this.expandedCards = new Set();
    this.viewMode = { table: true, json: false, csv: false };
    this.jsonOutput = "";
  }

  @api
  goToPage(pageNumber) {
    this.currentPage = Math.max(1, Math.min(this.totalPages, pageNumber));
  }
}
