/**
 * @description Generic Searchable Combobox (Functional Component)
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Pure Presentation Component
 * @reusable For configs, users, picklists, etc.
 *
 * @fires select - When an option is selected
 * @fires clear - When selection is cleared
 *
 * @example
 * <c-jt-searchable-combobox
 *   label="Select Configuration"
 *   placeholder="Type to search..."
 *   options={configOptions}
 *   required
 *   icon-name="standard:configuration"
 *   onselect={handleConfigSelect}
 *   onclear={handleConfigClear}
 * ></c-jt-searchable-combobox>
 */
import { LightningElement, api, track } from "lwc";

export default class JtSearchableCombobox extends LightningElement {
  // Public API
  @api label = "";
  @api placeholder = "Type to search...";
  @api required = false;
  @api iconName = ""; // Optional icon for options
  @api disabled = false;
  @api variant = "standard"; // standard | label-hidden
  @api debugMode = false; // Force dropdown open for CSS debugging

  // Translatable texts (passed from parent)
  @api noResultsText = "No results found";
  @api errorText = "Please select an option";
  @api clearButtonTitle = "Clear selection";
  @api showOptionsTitle = "Show options";

  // Options: [{ value, label, ...otherData }]
  @track _options = [];

  @api
  get options() {
    return this._options;
  }

  set options(value) {
    this._options = value || [];
    this.filterOptions();
  }

  // Internal state
  @track searchTerm = "";
  @track filteredOptions = [];
  @track showDropdown = false;
  @track selectedValue = null;
  @track selectedLabel = "";
  @track hasBlurred = false; // Track if user has interacted and left the field

  // Computed properties
  get hasOptions() {
    return this.filteredOptions && this.filteredOptions.length > 0;
  }

  get dropdownClass() {
    const isOpen = this.debugMode || this.showDropdown;
    return `slds-dropdown slds-dropdown_fluid ${isOpen ? "slds-is-open" : ""}`;
  }

  get comboboxClass() {
    return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${
      this.showDropdown ? "slds-is-open" : ""
    }`;
  }

  get inputClass() {
    let classes = "slds-input slds-combobox__input";
    // Only show error if field has been touched (blurred) and is still invalid
    if (this.required && !this.selectedValue && this.hasBlurred) {
      classes += " slds-has-error";
    }
    return classes;
  }

  get showErrorMessage() {
    return this.required && !this.selectedValue && this.hasBlurred;
  }

  get showClearButton() {
    return this.searchTerm.length > 0 || this.selectedValue;
  }

  get showLabel() {
    return this.variant !== "label-hidden";
  }

  get labelClass() {
    return `slds-form-element__label ${this.required ? "slds-required" : ""}`;
  }

  // Lifecycle
  connectedCallback() {
    this.filterOptions();
  }

  // Event Handlers (Pure - No side effects, just emit events)
  handleInput(event) {
    this.searchTerm = event.target.value;
    this.filterOptions();
    this.showDropdown = true;
    // Clear error state when user starts typing
    if (this.hasBlurred && this.searchTerm) {
      this.hasBlurred = false;
    }
  }

  handleFocus() {
    this.filterOptions();
    this.showDropdown = true;
    // Clear error state when field gains focus
    this.hasBlurred = false;
  }

  handleBlur() {
    // Mark as touched for validation
    this.hasBlurred = true;

    // Delay to allow option click
    setTimeout(() => {
      this.showDropdown = false;
    }, 250);
  }

  handleToggle(event) {
    event.stopPropagation();
    this.showDropdown = !this.showDropdown;

    if (this.showDropdown) {
      this.filterOptions();
      // Focus input
      const input = this.template.querySelector("input");
      if (input) {
        setTimeout(() => input.focus(), 50);
      }
    }
  }

  handleClear(event) {
    event.stopPropagation();
    this.reset();

    // Emit clear event
    this.dispatchEvent(new CustomEvent("clear"));
  }

  handleOptionSelect(event) {
    const value = event.currentTarget.dataset.value;
    const selected = this._options.find((opt) => opt.value === value);

    if (selected) {
      this.selectedValue = selected.value;
      this.selectedLabel = selected.label;
      this.searchTerm = selected.label;
      this.showDropdown = false;
      this.hasBlurred = false; // Clear error state on valid selection

      // Emit selection event with ALL data from option
      this.dispatchEvent(
        new CustomEvent("select", {
          detail: {
            value: selected.value,
            label: selected.label,
            data: selected // Pass entire object for flexibility
          }
        })
      );
    }
  }

  // Helper Methods (Pure Functions)
  filterOptions() {
    const term = (this.searchTerm || "").toLowerCase().trim();

    if (!this._options || this._options.length === 0) {
      this.filteredOptions = [];
      return;
    }

    if (!term) {
      this.filteredOptions = [...this._options];
    } else {
      this.filteredOptions = this._options.filter((opt) => {
        const label = (opt.label || "").toLowerCase();
        const value = (opt.value || "").toLowerCase();
        return label.includes(term) || value.includes(term);
      });
    }
  }

  // Public API Methods
  @api
  validate() {
    if (this.required && !this.selectedValue) {
      return {
        valid: false,
        message: "Please select an option"
      };
    }
    return { valid: true };
  }

  @api
  reset() {
    this.searchTerm = "";
    this.selectedValue = null;
    this.selectedLabel = "";
    this.showDropdown = false;
    this.hasBlurred = false; // Reset validation state
    this.filterOptions();
  }

  @api
  getValue() {
    return this.selectedValue;
  }

  @api
  getLabel() {
    return this.selectedLabel;
  }
}
