/**
 * @description Execute Button Component (Functional - Phase 3)
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Smart Button with Built-in Validation
 *
 * @fires execute - When button is clicked and validations pass
 */
import { LightningElement, api, track } from "lwc";

export default class JtExecuteButton extends LightningElement {
  @api label = "Execute Query";
  @api variant = "brand";
  @api iconName = "utility:play";
  @api disabled = false;
  @api isLoading = false;

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
    // 4. No config selected (always required)
    // 5. Has parameters but all are empty (avoid 50k+ records query)
    if (
      this.disabled ||
      this.isLoading ||
      this._isExecuting ||
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
      return `${this.label} - Executing query, please wait`;
    }
    if (!this.selectedConfig) {
      return `${this.label} - Disabled: Select a configuration first`;
    }
    if (this.hasParameters && this.parameterValues) {
      const hasAnyValue = Object.values(this.parameterValues).some(
        (val) => val !== "" && val !== null && val !== undefined
      );
      if (!hasAnyValue) {
        return `${this.label} - Disabled: Enter at least one parameter value to avoid returning too many records`;
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
