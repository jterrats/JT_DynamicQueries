/**
 * @description Shared Utility Functions for JT Dynamic Queries
 * @author Jaime Terrats
 * @date 2025-12-10
 * @pattern DRY (Don't Repeat Yourself) - Centralized utilities
 *
 * This module contains reusable functions extracted from multiple components
 * to eliminate code duplication and improve maintainability.
 */

import { ShowToastEvent } from "lightning/platformShowToastEvent";

// ========================================================================
// FORMATTING UTILITIES
// ========================================================================

/**
 * Format a field/parameter name into a human-readable label
 * @param {string} fieldName - The field or parameter name
 * @returns {string} Formatted label
 * @example formatLabel('accountName') → 'Account Name'
 */
export function formatLabel(fieldName) {
  if (!fieldName) return "";
  return fieldName
    .replace(/([A-Z])/g, " $1") // Add space before capital letters
    .replace(/_/g, " ") // Replace underscores with spaces
    .replace(/^\w/, (c) => c.toUpperCase()) // Capitalize first letter
    .trim();
}

/**
 * Determine the appropriate field type for lightning-datatable
 * @param {string} fieldName - The field name
 * @returns {string} Field type (text, date, email, phone, url, currency)
 * @example getFieldType('CreatedDate') → 'date'
 */
export function getFieldType(fieldName) {
  if (!fieldName) return "text";

  const lowerField = fieldName.toLowerCase();

  // ID fields
  if (lowerField === "id" || lowerField.endsWith("id")) return "text";

  // Date/Time fields
  if (lowerField.includes("date") || lowerField.includes("time")) return "date";

  // Email fields
  if (lowerField.includes("email")) return "email";

  // Phone fields
  if (lowerField.includes("phone")) return "phone";

  // URL fields
  if (lowerField.includes("url") || lowerField.includes("website")) return "url";

  // Currency fields
  if (lowerField.includes("amount") || lowerField.includes("price")) return "currency";

  return "text";
}

/**
 * Generate a valid Salesforce API Developer Name from a label
 * @param {string} label - The human-readable label
 * @param {number} maxLength - Maximum length (default: 40)
 * @returns {string} Valid API name (alphanumeric + underscore)
 * @example generateDeveloperName('My Config!') → 'My_Config'
 */
export function generateDeveloperName(label, maxLength = 40) {
  if (!label) return "";

  return label
    .replace(/[^a-zA-Z0-9]/g, "_") // Replace non-alphanumeric with underscore
    .replace(/_+/g, "_") // Collapse multiple underscores
    .replace(/^([^a-zA-Z])/, "Config_$1") // Ensure starts with letter
    .replace(/_$/, "") // Remove trailing underscore
    .substring(0, maxLength);
}

// ========================================================================
// TOAST UTILITIES
// ========================================================================

// Private: Track last toast timeout
let _toastTimeout = null;

/**
 * Show a success toast notification
 * @param {Object} context - Component context (this)
 * @param {string} message - Success message
 * @param {string} title - Toast title (default: 'Success')
 * @example showSuccessToast(this, 'Configuration saved!')
 */
export function showSuccessToast(context, message, title = "Success") {
  clearPreviousToast();

  context.dispatchEvent(
    new ShowToastEvent({
      title: title,
      message: message,
      variant: "success",
      mode: "dismissible"
    })
  );

  scheduleToastCleanup();
  announceToScreenReader(context, `Success: ${message}`);
}

/**
 * Show an error toast notification
 * @param {Object} context - Component context (this)
 * @param {string} title - Error title
 * @param {string} message - Error message
 * @example showErrorToast(this, 'Validation Error', 'Name is required')
 */
export function showErrorToast(context, title, message) {
  clearPreviousToast();

  context.dispatchEvent(
    new ShowToastEvent({
      title: title,
      message: message,
      variant: "error",
      mode: "dismissible"
    })
  );

  scheduleToastCleanup();
  announceToScreenReader(context, `Error: ${title}. ${message}`, true);
}

/**
 * Show a warning toast notification
 * @param {Object} context - Component context (this)
 * @param {string} title - Warning title
 * @param {string} message - Warning message
 * @example showWarningToast(this, 'Partial Results', 'Some searches failed')
 */
export function showWarningToast(context, title, message) {
  clearPreviousToast();

  context.dispatchEvent(
    new ShowToastEvent({
      title: title,
      message: message,
      variant: "warning",
      mode: "dismissible"
    })
  );

  scheduleToastCleanup();
}

/**
 * Show an info toast notification
 * @param {Object} context - Component context (this)
 * @param {string} title - Info title
 * @param {string} message - Info message
 * @example showInfoToast(this, 'No Changes', 'Configuration already up to date')
 */
export function showInfoToast(context, title, message) {
  clearPreviousToast();

  context.dispatchEvent(
    new ShowToastEvent({
      title: title,
      message: message,
      variant: "info",
      mode: "dismissible"
    })
  );

  scheduleToastCleanup();
}

// ========================================================================
// ACCESSIBILITY UTILITIES
// ========================================================================

/**
 * Announce a message to screen readers
 * @param {Object} context - Component context (this)
 * @param {string} message - Message to announce
 * @param {boolean} assertive - Use assertive (urgent) announcement
 * @private
 */
function announceToScreenReader(context, message, assertive = false) {
  const announcement = context.template.querySelector(".slds-assistive-text");
  if (announcement) {
    announcement.textContent = message;
    announcement.setAttribute("aria-live", assertive ? "assertive" : "polite");
    announcement.setAttribute("aria-atomic", "true");
  }
}

// ========================================================================
// PRIVATE TOAST HELPERS
// ========================================================================

/**
 * Clear any previous toast timeout to avoid stacking
 * @private
 */
function clearPreviousToast() {
  if (_toastTimeout) {
    clearTimeout(_toastTimeout);
    _toastTimeout = null;
  }
}

/**
 * Schedule cleanup after toast is shown
 * @private
 */
function scheduleToastCleanup() {
  _toastTimeout = setTimeout(() => {
    _toastTimeout = null;
  }, 3000);
}

// ========================================================================
// DATA TRANSFORMATION UTILITIES
// ========================================================================

/**
 * Build column definitions for lightning-datatable
 * @param {Array<string>} fields - Field names
 * @returns {Array<Object>} Column definitions
 * @example buildTableColumns(['Id', 'Name', 'CreatedDate'])
 */
export function buildTableColumns(fields) {
  if (!fields || !Array.isArray(fields)) return [];

  return fields.map((field) => ({
    label: formatLabel(field),
    fieldName: field,
    type: getFieldType(field),
    wrapText: false
  }));
}

/**
 * Escape special characters for use in SOQL LIKE clauses
 * @param {string} value - Value to escape
 * @returns {string} Escaped value
 * @example escapeLikeValue("test%") → "test\\%"
 */
export function escapeLikeValue(value) {
  if (!value) return value;
  return value
    .replace(/\\/g, "\\\\") // Backslash
    .replace(/%/g, "\\%") // Percent
    .replace(/_/g, "\\_") // Underscore
    .replace(/'/g, "\\'"); // Single quote
}

// ========================================================================
// VALIDATION UTILITIES
// ========================================================================

/**
 * Validate Salesforce API Developer Name
 * @param {string} devName - Developer name to validate
 * @returns {Object} { isValid: boolean, message: string }
 */
export function validateDeveloperName(devName) {
  if (!devName || devName.trim().length === 0) {
    return { isValid: false, message: "Developer Name is required" };
  }

  if (devName.length > 40) {
    return { isValid: false, message: "Developer Name cannot exceed 40 characters" };
  }

  if (!/^[a-zA-Z]/.test(devName)) {
    return { isValid: false, message: "Developer Name must start with a letter" };
  }

  if (!/^[a-zA-Z0-9_]+$/.test(devName)) {
    return { isValid: false, message: "Developer Name can only contain letters, numbers, and underscores" };
  }

  if (/__/.test(devName)) {
    return { isValid: false, message: "Developer Name cannot contain consecutive underscores" };
  }

  if (/_$/.test(devName)) {
    return { isValid: false, message: "Developer Name cannot end with an underscore" };
  }

  return { isValid: true, message: "" };
}

/**
 * Validate Salesforce Custom Label
 * @param {string} label - Label to validate
 * @returns {Object} { isValid: boolean, message: string }
 */
export function validateLabel(label) {
  if (!label || label.trim().length === 0) {
    return { isValid: false, message: "Label is required" };
  }

  if (label.length > 40) {
    return { isValid: false, message: "Label cannot exceed 40 characters" };
  }

  return { isValid: true, message: "" };
}

