/**
 * @description Usage Modal - Shows where config is used
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Display Modal (Read-only)
 * @fires close - When modal is closed
 */
import { LightningElement, api, track } from "lwc";
// Import Custom Labels
import titlePrefixLabel from "@salesforce/label/c.JT_jtUsageModal_titlePrefix";
import titleSuffixLabel from "@salesforce/label/c.JT_jtUsageModal_titleSuffix";
import searchingTextLabel from "@salesforce/label/c.JT_jtUsageModal_searchingText";
import noUsageFoundTextLabel from "@salesforce/label/c.JT_jtUsageModal_noUsageFoundText";
import noUsageMessageLabel from "@salesforce/label/c.JT_jtUsageModal_noUsageMessage";
import foundReferencesTextLabel from "@salesforce/label/c.JT_jtUsageModal_foundReferencesText";
import closeLabelLabel from "@salesforce/label/c.JT_jtUsageModal_closeLabel";
import typeColumnLabel from "@salesforce/label/c.JT_jtUsageModal_typeColumn";
import nameColumnLabel from "@salesforce/label/c.JT_jtUsageModal_nameColumn";
import lineColumnLabel from "@salesforce/label/c.JT_jtUsageModal_lineColumn";
import partialResultsLabel from "@salesforce/label/c.JT_jtUsageModal_partialResults";
import partialResultsMessageLabel from "@salesforce/label/c.JT_jtUsageModal_partialResultsMessage";
import apexClassesLabel from "@salesforce/label/c.JT_jtUsageModal_apexClasses";
import flowsToolingApiLabel from "@salesforce/label/c.JT_jtUsageModal_flowsToolingApi";
import availableLabel from "@salesforce/label/c.JT_jtUsageModal_available";
import failedLabel from "@salesforce/label/c.JT_jtUsageModal_failed";
import searchStatusLabel from "@salesforce/label/c.JT_jtUsageModal_searchStatus";
import apexLabel from "@salesforce/label/c.JT_jtUsageModal_apex";
import flowsLabel from "@salesforce/label/c.JT_jtUsageModal_flows";
import searchedLabel from "@salesforce/label/c.JT_jtUsageModal_searched";

export default class JtUsageModal extends LightningElement {
  @api configName = "";
  @api isLoading = false;

  @track _usageData = [];

  // Service status tracking
  @api apexError = null;
  @api flowError = null;
  @api hasPartialResults = false;

  // Custom Labels
  labels = {
    titlePrefix: titlePrefixLabel,
    titleSuffix: titleSuffixLabel,
    searchingText: searchingTextLabel,
    noUsageFoundText: noUsageFoundTextLabel,
    noUsageMessage: noUsageMessageLabel,
    foundReferencesText: foundReferencesTextLabel,
    closeLabel: closeLabelLabel,
    typeColumn: typeColumnLabel,
    nameColumn: nameColumnLabel,
    lineColumn: lineColumnLabel,
    partialResults: partialResultsLabel,
    partialResultsMessage: partialResultsMessageLabel,
    apexClasses: apexClassesLabel,
    flowsToolingApi: flowsToolingApiLabel,
    available: availableLabel,
    failed: failedLabel,
    searchStatus: searchStatusLabel,
    apex: apexLabel,
    flows: flowsLabel,
    searched: searchedLabel
  };

  // Public API property to receive usage data from parent
  @api
  get usageData() {
    return this._usageData;
  }

  set usageData(data) {
    // Map Apex fields to template fields and ensure unique id
    if (Array.isArray(data)) {
      this._usageData = data.map((item, index) => {
        // Generate unique id if not present
        const uniqueId =
          item.id ||
          `${item.classId || "unknown"}-${item.lineNumber || "0"}-${index}`;

        // Map Apex UsageResult fields to template fields
        return {
          id: uniqueId,
          type: item.metadataType || item.type || "Unknown",
          name: item.className || item.name || "Unknown",
          lineNumber: item.lineNumber || 0,
          icon: this.getIconForType(item.metadataType || item.type),
          // Keep original fields for reference
          ...item
        };
      });
    } else {
      this._usageData = [];
    }
  }

  // Helper to get icon based on metadata type
  getIconForType(type) {
    if (!type) return "utility:file";
    const normalizedType = type.toLowerCase();
    if (normalizedType.includes("apex") || normalizedType.includes("class")) {
      return "utility:code";
    }
    if (normalizedType.includes("flow")) {
      return "utility:flow";
    }
    return "utility:file";
  }

  @api
  setUsageData(data) {
    // Use the setter logic to ensure proper mapping
    // Assign directly to _usageData to avoid linter error about reassigning public property
    if (Array.isArray(data)) {
      this._usageData = data.map((item, index) => {
        // Generate unique id if not present
        const uniqueId =
          item.id ||
          `${item.classId || "unknown"}-${item.lineNumber || "0"}-${index}`;

        // Map Apex UsageResult fields to template fields
        return {
          id: uniqueId,
          type: item.metadataType || item.type || "Unknown",
          name: item.className || item.name || "Unknown",
          lineNumber: item.lineNumber || 0,
          icon: this.getIconForType(item.metadataType || item.type),
          // Keep original fields for reference
          ...item
        };
      });
    } else {
      this._usageData = [];
    }
  }

  @api
  getUsageData() {
    return this._usageData;
  }

  // Computed
  get title() {
    return `${this.labels.titlePrefix} "${this.configName}" ${this.labels.titleSuffix}`;
  }

  get hasUsage() {
    return this._usageData && this._usageData.length > 0;
  }

  get usageCount() {
    return this._usageData.length;
  }

  get usageSummary() {
    if (!this.hasUsage) return this.labels.noUsageFoundText;
    return this.labels.foundReferencesText.replace("{0}", this.usageCount);
  }

  // Service status computed properties
  get apexSuccess() {
    return !this.apexError;
  }

  get flowSuccess() {
    return !this.flowError;
  }

  get apexStatusIcon() {
    return this.apexSuccess ? "utility:success" : "utility:error";
  }

  get flowStatusIcon() {
    return this.flowSuccess ? "utility:success" : "utility:error";
  }

  get apexStatusVariant() {
    return this.apexSuccess ? "success" : "error";
  }

  get flowStatusVariant() {
    return this.flowSuccess ? "success" : "error";
  }

  // Only show "Partial Results" warning if we have SOME results but SOME services failed
  get shouldShowPartialWarning() {
    return this.hasPartialResults && this.hasUsage;
  }

  // Show service status even when no results (so user knows why)
  get shouldShowServiceStatus() {
    return this.hasPartialResults;
  }

  // Event Handlers
  handleClose() {
    this.dispatchEvent(new CustomEvent("close"));
  }
}
