/**
 * @description Execute Button Component (Functional - Phase 3)
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Smart Button with Built-in Validation
 *
 * @fires execute - When button is clicked and validations pass
 */
import { LightningElement, api } from "lwc";

export default class JtExecuteButton extends LightningElement {
  @api label = "Execute Query";
  @api variant = "brand";
  @api iconName = "utility:play";
  @api disabled = false;
  @api isLoading = false;

  // Validation requirements (defaults handled in getter)
  @api requireConfig = false;
  @api requireParameters = false;

  // State from parent
  @api selectedConfig;
  @api hasParameters;

  // Computed
  get isDisabled() {
    // Disabled if:
    // 1. Explicitly disabled
    // 2. Loading
    // 3. No config selected (always required)
    return this.disabled || this.isLoading || !this.selectedConfig;
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
    return this.label;
  }

  get ariaDescribedBy() {
    return "execute-button-status";
  }

  // Event Handler
  handleClick() {
    if (!this.isDisabled) {
      // Emit execute event
      this.dispatchEvent(new CustomEvent("execute"));
    }
  }
}
