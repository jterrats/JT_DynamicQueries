/**
 * @description Generic Config Modal (Create + Edit)
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Smart Modal Component
 * @fires save - When Save is clicked
 * @fires cancel - When Cancel/Close is clicked
 */
import { LightningElement, api, track } from "lwc";

export default class JtConfigModal extends LightningElement {
  // Public API
  @api mode = "create"; // 'create' | 'edit'
  @api isSaving = false;
  @api canCreateMetadata = false;

  // Translatable labels
  @api createTitle = "Create New Configuration";
  @api editTitle = "Edit Configuration";
  @api saveLabel = "Save Configuration";
  @api updateLabel = "Update Configuration";
  @api cancelLabel = "Cancel";
  @api labelField = "Label";
  @api developerNameField = "Developer Name";
  @api baseQueryField = "Base Query (SOQL)";
  @api objectNameField = "Object Name";
  @api bindingsField = "Bindings (JSON)";
  @api validSyntax = "Valid SOQL syntax";
  @api objectLabel = "Object";
  @api queryPreviewLabel = "Query Preview";
  @api autoDetectedPlaceholder = "Auto-detected from query";
  @api toolingNote =
    "This creates a Custom Metadata record via Tooling API. The configuration will be immediately available for use.";
  @api sandboxWarning =
    "Only available in Sandbox/Scratch/Developer Orgs. Use Setup UI in Production.";

  // Config data
  @track _config = {
    label: "",
    developerName: "",
    baseQuery: "",
    bindings: "",
    objectName: ""
  };

  @track queryValidation = {
    isValid: false,
    message: "",
    objectName: ""
  };

  // Public API to set initial config (for edit mode)
  @api
  setConfig(config) {
    if (config) {
      this._config = { ...config };
    }
  }

  @api
  getConfig() {
    return { ...this._config };
  }

  // Computed
  get title() {
    return this.mode === "edit" ? this.editTitle : this.createTitle;
  }

  get saveButtonLabel() {
    return this.mode === "edit" ? this.updateLabel : this.saveLabel;
  }

  get showObjectName() {
    return this.queryValidation.isValid && this.queryValidation.objectName;
  }

  get showQueryPreview() {
    return this.queryValidation.isValid && this._config.baseQuery;
  }

  get saveDisabled() {
    return (
      this.isSaving ||
      !this._config.label ||
      !this._config.developerName ||
      !this._config.baseQuery
    );
  }

  // Event Handlers
  handleFieldChange(event) {
    const field = event.target.dataset.field;
    const value = event.target.value;

    this._config[field] = value;

    // Auto-generate developer name from label
    if (field === "label" && this.mode === "create") {
      this._config.developerName = this.generateDeveloperName(value);
    }

    // Validate query when it changes
    if (field === "baseQuery") {
      this.validateQuery(value);
    }
  }

  handleSave() {
    // Emit save event with config data
    this.dispatchEvent(
      new CustomEvent("save", {
        detail: { config: this.getConfig(), mode: this.mode }
      })
    );
  }

  handleCancel() {
    this.dispatchEvent(new CustomEvent("cancel"));
  }

  // Helper Methods
  generateDeveloperName(label) {
    return label
      .trim()
      .replace(/[^a-zA-Z0-9\s]/g, "")
      .replace(/\s+/g, "_")
      .substring(0, 40);
  }

  async validateQuery(query) {
    // Simple client-side validation
    if (!query || query.trim().length === 0) {
      this.queryValidation = { isValid: false, message: "", objectName: "" };
      return;
    }

    // Check if starts with SELECT
    if (!query.trim().toUpperCase().startsWith("SELECT")) {
      this.queryValidation = {
        isValid: false,
        message: "Query must start with SELECT",
        objectName: ""
      };
      return;
    }

    // Extract object name
    const fromMatch = query.match(/FROM\s+(\w+)/i);
    const objectName = fromMatch ? fromMatch[1] : "";

    this.queryValidation = {
      isValid: true,
      message: "Valid SOQL syntax",
      objectName
    };

    this._config.objectName = objectName;
  }

  // Public API to reset
  @api
  reset() {
    this._config = {
      label: "",
      developerName: "",
      baseQuery: "",
      bindings: "",
      objectName: ""
    };
    this.queryValidation = {
      isValid: false,
      message: "",
      objectName: ""
    };
  }
}
