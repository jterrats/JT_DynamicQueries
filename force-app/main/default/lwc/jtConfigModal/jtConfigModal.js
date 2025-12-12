/**
 * @description Generic Config Modal (Create + Edit)
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Smart Modal Component
 * @fires save - When Save is clicked
 * @fires cancel - When Cancel/Close is clicked
 */
import { LightningElement, api, track } from "lwc";
import executeQueryPreview from "@salesforce/apex/JT_QueryViewerController.executeQueryPreview";

// Import Custom Labels from Salesforce Translation Workbench
import labelRequired from "@salesforce/label/c.JT_jtConfigModal_labelRequired";
import labelTooLong from "@salesforce/label/c.JT_jtConfigModal_labelTooLong";
import developerNameRequired from "@salesforce/label/c.JT_jtConfigModal_developerNameRequired";
import developerNameTooLong from "@salesforce/label/c.JT_jtConfigModal_developerNameTooLong";
import developerNameInvalidChars from "@salesforce/label/c.JT_jtConfigModal_developerNameInvalidChars";
import developerNameMustStartWithLetter from "@salesforce/label/c.JT_jtConfigModal_developerNameMustStartWithLetter";
import developerNameCannotEndWithUnderscore from "@salesforce/label/c.JT_jtConfigModal_developerNameCannotEndWithUnderscore";
import developerNameNoConsecutiveUnderscores from "@salesforce/label/c.JT_jtConfigModal_developerNameNoConsecutiveUnderscores";
import developerNameChangeWarning from "@salesforce/label/c.JT_jtConfigModal_developerNameChangeWarning";

export default class JtConfigModal extends LightningElement {
  // Custom Labels (imported from Translation Workbench)
  labels = {
    labelRequired,
    labelTooLong,
    developerNameRequired,
    developerNameTooLong,
    developerNameInvalidChars,
    developerNameMustStartWithLetter,
    developerNameCannotEndWithUnderscore,
    developerNameNoConsecutiveUnderscores,
    developerNameChangeWarning
  };

  // Public API
  @api mode = "create"; // 'create' | 'edit'
  @api isSaving = false;
  @api canCreateMetadata = false;
  @api isLoadingQueryPreview = false;
  @api queryPreviewResults = [];
  @api queryPreviewColumns = [];
  @api queryPreviewPageSize = 5; // Page size for preview (max 5 records)

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

  @track labelValidation = {
    isValid: true,
    message: ""
  };

  @track developerNameValidation = {
    isValid: true,
    message: ""
  };

  @track originalDeveloperName = ""; // Store original Developer Name for edit mode

  // Visibility toggles for preview sections
  @track showQueryPreviewContent = true; // Toggle for Query Preview content
  @track showDataPreviewContent = true; // Toggle for Data Preview content

  // Public API to set initial config (for edit mode)
  @api
  setConfig(config) {
    if (config) {
      this._config = { ...config };
      // Store original Developer Name when loading config for edit
      if (this.mode === "edit" && config.developerName) {
        this.originalDeveloperName = config.developerName;
      }
    }
  }

  @api
  getConfig() {
    return { ...this._config };
  }

  @api
  getQueryValidation() {
    return { ...this.queryValidation };
  }

  // Computed
  get title() {
    return this.mode === "edit" ? this.editTitle : this.createTitle;
  }

  get saveButtonLabel() {
    return this.mode === "edit" ? this.updateLabel : this.saveLabel;
  }

  get dynamicToolingNote() {
    if (this.mode === "edit") {
      return "This updates a Custom Metadata record via Tooling API. The configuration will be immediately available for use.";
    }
    return "This creates a Custom Metadata record via Tooling API. The configuration will be immediately available for use.";
  }

  get isEditMode() {
    return this.mode === "edit";
  }

  // Check if Developer Name changed in edit mode
  get hasDeveloperNameChanged() {
    return (
      this.isEditMode &&
      this.originalDeveloperName &&
      this._config.developerName &&
      this._config.developerName !== this.originalDeveloperName
    );
  }

  get showObjectName() {
    return this.queryValidation.isValid && this.queryValidation.objectName;
  }

  get showQueryPreview() {
    return this.queryValidation.isValid && this._config.baseQuery;
  }

  get hasPreviewData() {
    return this.queryPreviewResults && this.queryPreviewResults.length > 0;
  }

  get saveDisabled() {
    // DEBUG TEMPORAL
    console.log("=== DEBUG saveDisabled ===");
    console.log("isSaving:", this.isSaving);
    console.log("_config:", JSON.stringify(this._config, null, 2));
    console.log(
      "labelValidation:",
      JSON.stringify(this.labelValidation, null, 2)
    );
    console.log(
      "developerNameValidation:",
      JSON.stringify(this.developerNameValidation, null, 2)
    );
    console.log(
      "queryValidation:",
      JSON.stringify(this.queryValidation, null, 2)
    );
    const disabled =
      this.isSaving ||
      !this._config.label ||
      !this._config.developerName ||
      !this._config.baseQuery ||
      !this.labelValidation.isValid ||
      !this.developerNameValidation.isValid;
    console.log("saveDisabled result:", disabled);
    console.log("=========================");
    return disabled;
  }

  // Event Handlers
  handleFieldChange(event) {
    const field = event.target.dataset.field;
    const value = event.target.value;

    // DEBUG TEMPORAL
    console.log("=== DEBUG handleFieldChange ===");
    console.log("field:", field);
    console.log("value:", value);
    console.log("value type:", typeof value);
    console.log("value length:", value ? value.length : 0);
    console.log("value trimmed:", value ? value.trim() : "");
    console.log("value trimmed length:", value ? value.trim().length : 0);
    console.log("_config before:", JSON.stringify(this._config, null, 2));

    this._config[field] = value;

    console.log("_config after:", JSON.stringify(this._config, null, 2));
    console.log("==============================");

    // Auto-generate developer name from label
    if (field === "label" && this.mode === "create") {
      this._config.developerName = this.generateDeveloperName(value);
      this.validateDeveloperName(this._config.developerName);
    }

    // Validate label
    if (field === "label") {
      this.validateLabel(value);
    }

    // Validate developer name
    if (field === "developerName") {
      this.validateDeveloperName(value);
    }

    // Validate query when it changes
    if (field === "baseQuery") {
      this.validateQuery(value);
    }
  }

  handleSave() {
    // DEBUG TEMPORAL
    console.log("=== DEBUG handleSave ===");
    console.log("mode:", this.mode);
    console.log("_config:", JSON.stringify(this._config, null, 2));
    console.log("getConfig():", JSON.stringify(this.getConfig(), null, 2));
    console.log(
      "labelValidation:",
      JSON.stringify(this.labelValidation, null, 2)
    );
    console.log(
      "developerNameValidation:",
      JSON.stringify(this.developerNameValidation, null, 2)
    );
    console.log(
      "queryValidation:",
      JSON.stringify(this.queryValidation, null, 2)
    );
    console.log("saveDisabled:", this.saveDisabled);
    console.log("========================");

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
    if (!label) return "";

    let apiName = label
      .trim()
      .replace(/[^a-zA-Z0-9\s]/g, "") // Solo alfanuméricos y espacios
      .replace(/\s+/g, "_"); // Espacios → guiones bajos

    // Debe empezar con letra
    if (apiName && !/^[a-zA-Z]/.test(apiName)) {
      apiName = "Config_" + apiName;
    }

    // Remover guiones bajos consecutivos
    apiName = apiName.replace(/_+/g, "_");

    // No puede terminar con guión bajo
    apiName = apiName.replace(/_+$/, "");

    // Máximo 40 caracteres
    return apiName.substring(0, 40).replace(/_+$/, ""); // Trim again si substring cortó en _
  }

  validateLabel(label) {
    if (!label || label.trim().length === 0) {
      this.labelValidation = {
        isValid: false,
        message: this.labels.labelRequired
      };
      return;
    }

    if (label.length > 40) {
      this.labelValidation = {
        isValid: false,
        message: this.labels.labelTooLong
      };
      return;
    }

    this.labelValidation = {
      isValid: true,
      message: ""
    };
  }

  validateDeveloperName(devName) {
    if (!devName || devName.trim().length === 0) {
      this.developerNameValidation = {
        isValid: false,
        message: this.labels.developerNameRequired
      };
      return;
    }

    // Máximo 40 caracteres
    if (devName.length > 40) {
      this.developerNameValidation = {
        isValid: false,
        message: this.labels.developerNameTooLong
      };
      return;
    }

    // Solo alfanuméricos y guiones bajos
    if (!/^[a-zA-Z0-9_]+$/.test(devName)) {
      this.developerNameValidation = {
        isValid: false,
        message: this.labels.developerNameInvalidChars
      };
      return;
    }

    // Debe empezar con letra
    if (!/^[a-zA-Z]/.test(devName)) {
      this.developerNameValidation = {
        isValid: false,
        message: this.labels.developerNameMustStartWithLetter
      };
      return;
    }

    // No puede terminar con guión bajo
    if (/_$/.test(devName)) {
      this.developerNameValidation = {
        isValid: false,
        message: this.labels.developerNameCannotEndWithUnderscore
      };
      return;
    }

    // No puede tener guiones bajos consecutivos
    if (/__/.test(devName)) {
      this.developerNameValidation = {
        isValid: false,
        message: this.labels.developerNameNoConsecutiveUnderscores
      };
      return;
    }

    this.developerNameValidation = {
      isValid: true,
      message: ""
    };
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

    // Extract object name for display
    const fromMatch = query.match(/FROM\s+(\w+)/i);
    const objectName = fromMatch ? fromMatch[1] : "";

    // Call Apex to validate against real Salesforce metadata
    try {
      const result = await executeQueryPreview({
        devName: null,
        bindingsJson: this._config.bindings || null,
        queryOverride: query
      });

      if (result.success) {
        this.queryValidation = {
          isValid: true,
          message: "Valid SOQL syntax",
          objectName: objectName
        };
        this._config.objectName = objectName;

        // Dispatch preview results to parent
        this.dispatchEvent(
          new CustomEvent("querypreview", {
            detail: {
              records: result.records || [],
              fields: result.fields || [],
              recordCount: result.recordCount || 0
            }
          })
        );
      } else {
        // Apex validation failed - show specific error
        this.queryValidation = {
          isValid: false,
          message: result.errorMessage || "Query validation failed",
          objectName: ""
        };
        this._config.objectName = "";
      }
    } catch (error) {
      // Network or other error
      this.queryValidation = {
        isValid: false,
        message:
          error.body?.message || "Error validating query. Please check syntax.",
        objectName: ""
      };
      this._config.objectName = "";
    }
  }

  // Getters for dynamic icon names and labels
  get queryPreviewIconName() {
    return this.showQueryPreviewContent ? "utility:preview" : "utility:hide";
  }

  get queryPreviewIconAlt() {
    return this.showQueryPreviewContent
      ? "Hide Query Preview"
      : "Show Query Preview";
  }

  get dataPreviewIconName() {
    return this.showDataPreviewContent ? "utility:preview" : "utility:hide";
  }

  get dataPreviewIconAlt() {
    return this.showDataPreviewContent
      ? "Hide Data Preview"
      : "Show Data Preview";
  }

  // Toggle handlers for preview sections
  handleToggleQueryPreview() {
    this.showQueryPreviewContent = !this.showQueryPreviewContent;
  }

  handleToggleDataPreview() {
    this.showDataPreviewContent = !this.showDataPreviewContent;
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
    this.originalDeveloperName = "";
    this.queryValidation = {
      isValid: false,
      message: "",
      objectName: ""
    };
    this.labelValidation = {
      isValid: true,
      message: ""
    };
    this.developerNameValidation = {
      isValid: true,
      message: ""
    };
    this.showQueryPreviewContent = true;
    this.showDataPreviewContent = true;
  }
}
