/**
 * @description Parameter Inputs Component (Functional - Phase 2)
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Pure Presentation Component
 * @reusable For dynamic SOQL parameters
 *
 * @fires change - When any parameter value changes
 *
 * @example
 * <c-jt-parameter-inputs
 *   parameters={parameters}
 *   onchange={handleParameterChange}
 * ></c-jt-parameter-inputs>
 */
import { LightningElement, api, track } from "lwc";
// Import Custom Labels
import queryParametersLabel from "@salesforce/label/c.JT_jtParameterInputs_queryParameters";
import noParametersRequiredLabel from "@salesforce/label/c.JT_jtParameterInputs_noParametersRequired";
import helpTextLabel from "@salesforce/label/c.JT_jtParameterInputs_helpText";
import queryParameterLabel from "@salesforce/label/c.JT_jtParameterInputs_queryParameter";
import pleaseFillInLabel from "@salesforce/label/c.JT_jtParameterInputs_pleaseFillIn";

export default class JtParameterInputs extends LightningElement {
  // Public API - Parameters from parent
  @track _parameters = [];
  @track _values = {};
  @api baseQuery = ""; // Query string to detect IN/NOT IN/INCLUDES/EXCLUDES operators

  // Custom Labels
  labels = {
    queryParameters: queryParametersLabel,
    noParametersRequired: noParametersRequiredLabel,
    helpText: helpTextLabel,
    queryParameter: queryParameterLabel,
    pleaseFillIn: pleaseFillInLabel
  };

  @api
  get parameters() {
    return this._parameters;
  }

  set parameters(value) {
    this._parameters = value || [];
    // Initialize values object
    this._values = {};
    this._parameters.forEach((param) => {
      this._values[param.name] = param.value || "";
    });
  }

  // Computed
  get hasParameters() {
    return this._parameters && this._parameters.length > 0;
  }

  /**
   * Detects if a parameter is used with IN/NOT IN/INCLUDES/EXCLUDES operators
   * @param {string} paramName - Parameter name
   * @returns {boolean} True if parameter requires list values
   */
  requiresListValue(paramName) {
    if (!this.baseQuery || !paramName) {
      return false;
    }

    const normalizedQuery = this.baseQuery.toLowerCase();
    const paramNameLower = paramName.toLowerCase();

    // Create regex patterns to match the binding variable
    // Match patterns like: IN :paramName, NOT IN :paramName, INCLUDES :paramName, EXCLUDES :paramName
    // Also handle cases with/without spaces: IN:paramName, NOT IN:paramName, etc.
    const patterns = [
      new RegExp(`\\bin\\s+:${paramNameLower}\\b`, "i"),
      new RegExp(`\\bnot\\s+in\\s+:${paramNameLower}\\b`, "i"),
      new RegExp(`\\bincludes\\s+:${paramNameLower}\\b`, "i"),
      new RegExp(`\\bexcludes\\s+:${paramNameLower}\\b`, "i")
    ];

    return patterns.some((pattern) => pattern.test(normalizedQuery));
  }

  /**
   * Generates help text for a parameter
   * @param {Object} param - Parameter object
   * @returns {string} Help text with additional info for list operators
   */
  getHelpText(param) {
    let helpText = this.labels.helpText.replace("{0}", param.name);

    if (this.requiresListValue(param.name)) {
      helpText +=
        " Separate multiple values with commas (e.g., 'Value1, Value2, Value3').";
    }

    return helpText;
  }

  get parametersWithValues() {
    // Merge parameters with current values and add helpful tooltips + semantic attributes
    return this._parameters.map((param) => ({
      ...param,
      value: this._values[param.name] || "",
      helpText: this.getHelpText(param),
      // Semantic HTML attributes for E2E testing
      testId: `query-parameter-${param.name}`,
      inputName: `query-parameter-${param.name}`,
      ariaLabel: `${this.labels.queryParameter} ${param.label || param.name}`
    }));
  }

  // Event Handlers (Pure - No side effects)
  handleInputChange(event) {
    const paramName = event.target.dataset.param;
    const value = event.target.value;

    // Update internal state
    this._values[paramName] = value;

    // Emit change event with all values
    this.dispatchEvent(
      new CustomEvent("change", {
        detail: {
          paramName,
          value,
          allValues: { ...this._values }
        }
      })
    );
  }

  // Public API Methods

  /**
   * Get all parameter values as an object
   * @returns {Object} { paramName: value, ... }
   */
  @api
  getValues() {
    return { ...this._values };
  }

  /**
   * Validate all parameters (can be extended for required fields)
   * @returns {Object} { valid: boolean, message?: string, missingParams?: string[] }
   */
  @api
  validate() {
    // For now, just check if any parameter is empty
    const missingParams = this._parameters
      .filter((param) => param.required && !this._values[param.name])
      .map((param) => param.label || param.name);

    if (missingParams.length > 0) {
      return {
        valid: false,
        message: this.labels.pleaseFillIn.replace(
          "{0}",
          missingParams.join(", ")
        ),
        missingParams
      };
    }

    return { valid: true };
  }

  /**
   * Reset all parameter values
   */
  @api
  reset() {
    this._values = {};
    this._parameters.forEach((param) => {
      this._values[param.name] = "";
    });
  }

  /**
   * Set values programmatically
   * @param {Object} values - { paramName: value, ... }
   */
  @api
  setValues(values) {
    if (values && typeof values === "object") {
      this._values = { ...this._values, ...values };
    }
  }
}
