/**
 * @description Usage Modal - Shows where config is used
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Display Modal (Read-only)
 * @fires close - When modal is closed
 */
import { LightningElement, api, track } from "lwc";

export default class JtUsageModal extends LightningElement {
  @api configName = "";
  @api isLoading = false;

  @track _usageData = [];

  // Service status tracking
  @api apexError = null;
  @api flowError = null;
  @api hasPartialResults = false;

  // Translatable labels
  @api titlePrefix = "Where is";
  @api titleSuffix = "used?";
  @api searchingText = "Searching Apex classes and Flows...";
  @api noUsageFoundText = "No usage found";
  @api noUsageMessage =
    "This configuration is not currently referenced in any Apex classes or Flows.";
  @api foundReferencesText = "Found {0} reference(s)";
  @api closeLabel = "Close";
  @api typeColumn = "Type";
  @api nameColumn = "Name";
  @api lineColumn = "Line";

  @api
  setUsageData(data) {
    this._usageData = data || [];
  }

  @api
  getUsageData() {
    return this._usageData;
  }

  // Computed
  get title() {
    return `${this.titlePrefix} "${this.configName}" ${this.titleSuffix}`;
  }

  get hasUsage() {
    return this._usageData && this._usageData.length > 0;
  }

  get usageCount() {
    return this._usageData.length;
  }

  get usageSummary() {
    if (!this.hasUsage) return this.noUsageFoundText;
    return this.foundReferencesText.replace("{0}", this.usageCount);
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
