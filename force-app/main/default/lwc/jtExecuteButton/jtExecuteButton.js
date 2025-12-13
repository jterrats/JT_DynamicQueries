/**
 * @description Execute Button Component (Functional - Phase 3)
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Smart Button with Built-in Validation
 *
 * @fires execute - When button is clicked and validations pass
 */
import { LightningElement, api, track } from "lwc";
// Import Custom Labels
import executeQueryLabel from "@salesforce/label/c.JT_jtExecuteButton_executeQuery";
import queryExecutionControlsLabel from "@salesforce/label/c.JT_jtExecuteButton_queryExecutionControls";
import executingQueryPleaseWaitLabel from "@salesforce/label/c.JT_jtExecuteButton_executingQueryPleaseWait";
import disabledSelectConfigurationLabel from "@salesforce/label/c.JT_jtExecuteButton_disabledSelectConfiguration";
import disabledEnterParameterLabel from "@salesforce/label/c.JT_jtExecuteButton_disabledEnterParameter";
import queryIsExecutingLabel from "@salesforce/label/c.JT_jtExecuteButton_queryIsExecuting";
import selectConfigurationToEnableLabel from "@salesforce/label/c.JT_jtExecuteButton_selectConfigurationToEnable";

export default class JtExecuteButton extends LightningElement {
  @api label = executeQueryLabel;

  // Custom Labels
  labels = {
    executeQuery: executeQueryLabel,
    queryExecutionControls: queryExecutionControlsLabel,
    executingQueryPleaseWait: executingQueryPleaseWaitLabel,
    disabledSelectConfiguration: disabledSelectConfigurationLabel,
    disabledEnterParameter: disabledEnterParameterLabel,
    queryIsExecuting: queryIsExecutingLabel,
    selectConfigurationToEnable: selectConfigurationToEnableLabel
  };
  @api variant = "brand";
  @api iconName = "utility:play";
  @api disabled = false;
  @api isLoading = false;
  @api isRunningTest = false; // Block button when Run As User test is executing

  // ✅ Local state for immediate UI feedback (reactive)
  @track _isExecuting = false;

  // Semantic HTML attributes (for E2E testing & accessibility)
  @api testId = "execute-query-button";
  @api name = "execute-query";

  // Validation requirements (defaults handled in getter)
  @api requireConfig = false;
  @api requireParameters = false;

  // State from parent
  @api selectedConfig;
  @api hasParameters;
  @api parameterValues; // Object with parameter values

  // Computed
  get isDisabled() {
    // Disabled if:
    // 1. Explicitly disabled
    // 2. Loading (from parent)
    // 3. Executing (local state - immediate)
    // 4. Running test (Run As User execution in progress)
    // 5. No config selected (always required)
    // 6. Has parameters but all are empty (avoid 50k+ records query)
    if (
      this.disabled ||
      this.isLoading ||
      this._isExecuting ||
      this.isRunningTest ||
      !this.selectedConfig
    ) {
      return true;
    }

    // If config has parameters, at least one must have a value
    if (this.hasParameters && this.parameterValues) {
      const hasAnyValue = Object.values(this.parameterValues).some(
        (val) => val !== "" && val !== null && val !== undefined
      );
      return !hasAnyValue; // Disabled if all params are empty
    }

    return false;
  }

  get buttonClass() {
    return this.isLoading ? "slds-m-top_small" : "slds-m-top_small";
  }

  get showSpinner() {
    return this.isLoading;
  }

  // Accessibility attributes
  get ariaLabel() {
    if (this.isLoading) {
      return `${this.label} - ${this.labels.executingQueryPleaseWait}`;
    }
    if (!this.selectedConfig) {
      return `${this.label} - ${this.labels.disabledSelectConfiguration}`;
    }
    if (this.hasParameters && this.parameterValues) {
      const hasAnyValue = Object.values(this.parameterValues).some(
        (val) => val !== "" && val !== null && val !== undefined
      );
      if (!hasAnyValue) {
        return `${this.label} - ${this.labels.disabledEnterParameter}`;
      }
    }
    return this.label;
  }

  get ariaDescribedBy() {
    return "execute-button-status";
  }

  get ariaBusy() {
    return this.isLoading ? "true" : "false";
  }

  // Event Handler
  handleClick() {
    if (!this.isDisabled) {
      // ✅ Set local executing state IMMEDIATELY
      this._isExecuting = true;

      // Emit execute event
      this.dispatchEvent(new CustomEvent("execute"));

      // ✅ Reset after a delay (parent's isLoading will take over)
      setTimeout(() => {
        this._isExecuting = false;
      }, 100);
    }
  }
}