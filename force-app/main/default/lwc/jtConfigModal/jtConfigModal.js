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
import createTitleLabel from "@salesforce/label/c.JT_jtConfigModal_createTitle";
import editTitleLabel from "@salesforce/label/c.JT_jtConfigModal_editTitle";
import saveLabelLabel from "@salesforce/label/c.JT_jtConfigModal_saveLabel";
import updateLabelLabel from "@salesforce/label/c.JT_jtConfigModal_updateLabel";
import cancelLabelLabel from "@salesforce/label/c.JT_jtConfigModal_cancelLabel";
import closeLabel from "@salesforce/label/c.JT_jtConfigModal_close";
import labelFieldLabel from "@salesforce/label/c.JT_jtConfigModal_labelField";
import developerNameFieldLabel from "@salesforce/label/c.JT_jtConfigModal_developerNameField";
import baseQueryFieldLabel from "@salesforce/label/c.JT_jtConfigModal_baseQueryField";
import objectNameFieldLabel from "@salesforce/label/c.JT_jtConfigModal_objectNameField";
import bindingsFieldLabel from "@salesforce/label/c.JT_jtConfigModal_bindingsField";
import validSyntaxLabel from "@salesforce/label/c.JT_jtConfigModal_validSyntax";
import objectLabelLabel from "@salesforce/label/c.JT_jtConfigModal_objectLabel";
import queryPreviewLabelLabel from "@salesforce/label/c.JT_jtConfigModal_queryPreviewLabel";
import autoDetectedPlaceholderLabel from "@salesforce/label/c.JT_jtConfigModal_autoDetectedPlaceholder";
import toolingNoteLabel from "@salesforce/label/c.JT_jtConfigModal_toolingNote";
import sandboxWarningLabel from "@salesforce/label/c.JT_jtConfigModal_sandboxWarning";
import labelPlaceholderLabel from "@salesforce/label/c.JT_jtConfigModal_labelPlaceholder";
import developerNamePlaceholderLabel from "@salesforce/label/c.JT_jtConfigModal_developerNamePlaceholder";
import baseQueryPlaceholderLabel from "@salesforce/label/c.JT_jtConfigModal_baseQueryPlaceholder";
import developerNameHelpTextLabel from "@salesforce/label/c.JT_jtConfigModal_developerNameHelpText";
import warningLabel from "@salesforce/label/c.JT_jtConfigModal_warning";
import dataPreviewTitleLabel from "@salesforce/label/c.JT_jtConfigModal_dataPreviewTitle";
import toggleDataPreviewLabel from "@salesforce/label/c.JT_jtConfigModal_toggleDataPreview";
import loadingPreviewLabel from "@salesforce/label/c.JT_jtConfigModal_loadingPreview";
import loadingPreviewDataLabel from "@salesforce/label/c.JT_jtConfigModal_loadingPreviewData";
import noPreviewDataLabel from "@salesforce/label/c.JT_jtConfigModal_noPreviewData";
import bindingsPlaceholderLabel from "@salesforce/label/c.JT_jtConfigModal_bindingsPlaceholder";
import bindingsHelpTextLabel from "@salesforce/label/c.JT_jtConfigModal_bindingsHelpText";
import noteLabel from "@salesforce/label/c.JT_jtConfigModal_note";
import savingLabel from "@salesforce/label/c.JT_jtConfigModal_saving";
import toolingNoteUpdateLabel from "@salesforce/label/c.JT_jtConfigModal_toolingNoteUpdate";
import hideQueryPreviewLabel from "@salesforce/label/c.JT_jtConfigModal_hideQueryPreview";
import showQueryPreviewLabel from "@salesforce/label/c.JT_jtConfigModal_showQueryPreview";
import hideDataPreviewLabel from "@salesforce/label/c.JT_jtConfigModal_hideDataPreview";
import showDataPreviewLabel from "@salesforce/label/c.JT_jtConfigModal_showDataPreview";
import queryMustStartWithSelectLabel from "@salesforce/label/c.JT_jtConfigModal_queryMustStartWithSelect";
import queryValidationFailedLabel from "@salesforce/label/c.JT_jtConfigModal_queryValidationFailed";
import errorValidatingQueryLabel from "@salesforce/label/c.JT_jtConfigModal_errorValidatingQuery";

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
    developerNameChangeWarning,
    createTitle: createTitleLabel,
    editTitle: editTitleLabel,
    saveLabel: saveLabelLabel,
    updateLabel: updateLabelLabel,
    cancelLabel: cancelLabelLabel,
    close: closeLabel,
    labelField: labelFieldLabel,
    developerNameField: developerNameFieldLabel,
    baseQueryField: baseQueryFieldLabel,
    objectNameField: objectNameFieldLabel,
    bindingsField: bindingsFieldLabel,
    validSyntax: validSyntaxLabel,
    objectLabel: objectLabelLabel,
    queryPreviewLabel: queryPreviewLabelLabel,
    autoDetectedPlaceholder: autoDetectedPlaceholderLabel,
    toolingNote: toolingNoteLabel,
    sandboxWarning: sandboxWarningLabel,
    labelPlaceholder: labelPlaceholderLabel,
    developerNamePlaceholder: developerNamePlaceholderLabel,
    baseQueryPlaceholder: baseQueryPlaceholderLabel,
    developerNameHelpText: developerNameHelpTextLabel,
    warning: warningLabel,
    dataPreviewTitle: dataPreviewTitleLabel,
    toggleDataPreview: toggleDataPreviewLabel,
    loadingPreview: loadingPreviewLabel,
    loadingPreviewData: loadingPreviewDataLabel,
    noPreviewData: noPreviewDataLabel,
    bindingsPlaceholder: bindingsPlaceholderLabel,
    bindingsHelpText: bindingsHelpTextLabel,
    note: noteLabel,
    saving: savingLabel,
    toolingNoteUpdate: toolingNoteUpdateLabel,
    hideQueryPreview: hideQueryPreviewLabel,
    showQueryPreview: showQueryPreviewLabel,
    hideDataPreview: hideDataPreviewLabel,
    showDataPreview: showDataPreviewLabel,
    queryMustStartWithSelect: queryMustStartWithSelectLabel,
    queryValidationFailed: queryValidationFailedLabel,
    errorValidatingQuery: errorValidatingQueryLabel
  };

  // Public API
  @api mode = "create"; // 'create' | 'edit'
  @api isSaving = false;
  @api canCreateMetadata = false;
  @api isLoadingQueryPreview = false;
  @api queryPreviewResults = [];
  @api queryPreviewColumns = [];
  @api queryPreviewPageSize = 5; // Page size for preview (max 5 records)

  // Config data
  @track _config = {
    label: "",
    developerName: "",
    baseQuery: "",
    bindings: "",
    objectName: ""
  };

  // Debounce timeout for query validation
  _queryValidationTimeout = null;
  _isValidatingQuery = false;

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
    return this.mode === "edit"
      ? this.labels.editTitle
      : this.labels.createTitle;
  }

  get saveButtonLabel() {
    return this.mode === "edit"
      ? this.labels.updateLabel
      : this.labels.saveLabel;
  }

  get dynamicToolingNote() {
    return this.mode === "edit"
      ? this.labels.toolingNoteUpdate
      : this.labels.toolingNote;
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
    return (
      this.isSaving ||
      !this._config.label ||
      !this._config.developerName ||
      !this._config.baseQuery ||
      !this.labelValidation.isValid ||
      !this.developerNameValidation.isValid
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

    // Validate query when it changes (with debounce to prevent excessive calls)
    if (field === "baseQuery") {
      // Clear any pending timeout
      if (this._queryValidationTimeout) {
        clearTimeout(this._queryValidationTimeout);
        this._queryValidationTimeout = null;
      }
      // Prevent validation if already validating (avoid race conditions)
      if (this._isValidatingQuery) {
        return;
      }
      // Debounce query validation to prevent excessive API calls
      // Increased timeout to 800ms to prevent UI blocking during fast typing
      this._queryValidationTimeout = setTimeout(() => {
        this.validateQuery(value);
        this._queryValidationTimeout = null;
      }, 800);
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

  disconnectedCallback() {
    // Clean up timeout when component is destroyed
    if (this._queryValidationTimeout) {
      clearTimeout(this._queryValidationTimeout);
      this._queryValidationTimeout = null;
    }
  }

  handleCancel() {
    // Clear any pending validation timeout
    if (this._queryValidationTimeout) {
      clearTimeout(this._queryValidationTimeout);
      this._queryValidationTimeout = null;
    }
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
    // Prevent multiple simultaneous validations
    if (this._isValidatingQuery) {
      return;
    }

    // Simple client-side validation
    if (!query || query.trim().length === 0) {
      this.queryValidation = { isValid: false, message: "", objectName: "" };
      return;
    }

    // Check if starts with SELECT
    if (!query.trim().toUpperCase().startsWith("SELECT")) {
      this.queryValidation = {
        isValid: false,
        message: this.labels.queryMustStartWithSelect,
        objectName: ""
      };
      return;
    }

    // Extract object name for display
    const fromMatch = query.match(/FROM\s+(\w+)/i);
    const objectName = fromMatch ? fromMatch[1] : "";

    // Check if query has bind variables (e.g., :searchName, :accountType)
    const hasBindings = /:\w+/.test(query);
    const bindingsProvided =
      this._config.bindings && this._config.bindings.trim().length > 0;

    // If query has bindings but no bindings JSON is provided, mark as valid
    // (bindings will be required at execution time, not at configuration time)
    if (hasBindings && !bindingsProvided) {
      this.queryValidation = {
        isValid: true,
        message:
          this.labels.validSyntax +
          " (bindings will be required at execution time)",
        objectName: objectName
      };
      this._config.objectName = objectName;
      return;
    }

    // Set validation flag
    this._isValidatingQuery = true;

    // Call Apex to validate against real Salesforce metadata
    try {
      const result = await executeQueryPreview({
        devName: null,
        bindingsJson: this._config.bindings || null,
        queryOverride: query
      });

      if (result.success) {
        // Only update objectName if it changed to prevent unnecessary re-renders
        // Use a flag to prevent re-triggering validation during update
        const objectNameChanged = this._config.objectName !== objectName;
        if (objectNameChanged && objectName) {
          // Defer update to next frame to prevent UI blocking
          // eslint-disable-next-line @lwc/lwc/no-async-operation
          setTimeout(() => {
            if (!this._isValidatingQuery) {
              this._config.objectName = objectName;
            }
          }, 0);
        }

        this.queryValidation = {
          isValid: true,
          message: this.labels.validSyntax,
          objectName: objectName
        };

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
        // Only clear objectName if it was set
        if (this._config.objectName) {
          this._config.objectName = "";
        }
        this.queryValidation = {
          isValid: false,
          message: result.errorMessage || this.labels.queryValidationFailed,
          objectName: ""
        };
      }
    } catch (error) {
      // Network or other error
      this.queryValidation = {
        isValid: false,
        message: error.body?.message || this.labels.errorValidatingQuery,
        objectName: ""
      };
      this._config.objectName = "";
    } finally {
      // Clear validation flag
      this._isValidatingQuery = false;
    }
  }

  // Getters for dynamic icon names and labels
  get queryPreviewIconName() {
    return this.showQueryPreviewContent ? "utility:preview" : "utility:hide";
  }

  get queryPreviewIconAlt() {
    return this.showQueryPreviewContent
      ? this.labels.hideQueryPreview
      : this.labels.showQueryPreview;
  }

  get dataPreviewIconName() {
    return this.showDataPreviewContent ? "utility:preview" : "utility:hide";
  }

  get dataPreviewIconAlt() {
    return this.showDataPreviewContent
      ? this.labels.hideDataPreview
      : this.labels.showDataPreview;
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
