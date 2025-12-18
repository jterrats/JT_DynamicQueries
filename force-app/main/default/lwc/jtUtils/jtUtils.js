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
// Import Custom Labels for default values
import successTitleLabel from "@salesforce/label/c.JT_jtUtils_successTitle";
import unknownErrorLabel from "@salesforce/label/c.JT_jtUtils_unknownError";
import fixQuerySyntaxLabel from "@salesforce/label/c.JT_jtUtils_fixQuerySyntax";
import cannotUpdateConfigurationLabel from "@salesforce/label/c.JT_jtUtils_cannotUpdateConfiguration";
import errorTitleLabel from "@salesforce/label/c.JT_jtUtils_errorTitle";

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
  if (lowerField.includes("url") || lowerField.includes("website"))
    return "url";

  // Currency fields
  if (lowerField.includes("amount") || lowerField.includes("price"))
    return "currency";

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
 * @param {string} title - Toast title (default: uses Custom Label)
 * @example showSuccessToast(this, 'Configuration saved!')
 */
export function showSuccessToast(context, message, title = successTitleLabel) {
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
 * Get nested field value from an object using dot notation
 * Handles related fields like Recordtype.Name, Account.Name, etc.
 * @param {Object} obj - The object to navigate
 * @param {string} fieldPath - Field path with dots (e.g., "Recordtype.Name")
 * @returns {string} The value as a string, or empty string if not found
 * @example getNestedFieldValue(record, "Recordtype.Name") → "Account"
 */
export function getNestedFieldValue(obj, fieldPath) {
  if (!obj || !fieldPath) return "";

  // If fieldPath has no dots, access directly
  if (!fieldPath.includes(".")) {
    const value = obj[fieldPath];
    return formatFieldValue(value);
  }

  // Split path and navigate nested object
  const parts = fieldPath.split(".");
  let current = obj;

  for (let i = 0; i < parts.length; i++) {
    if (current == null || typeof current !== "object") {
      return "";
    }
    current = current[parts[i]];
    if (current == null) {
      return "";
    }
  }

  return formatFieldValue(current);
}

/**
 * Format a field value for display (handles objects, arrays, null, etc.)
 * @param {*} value - The value to format
 * @returns {string} Formatted string value
 */
function formatFieldValue(value) {
  if (value == null) return "";
  if (typeof value === "string") return value;
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  if (typeof value === "object") {
    // If it's an object with Name property, use that
    if (value.Name !== undefined) return String(value.Name);
    // If it's an object with DeveloperName property, use that
    if (value.DeveloperName !== undefined) return String(value.DeveloperName);
    // Otherwise, try to stringify (but avoid [object Object])
    try {
      const str = JSON.stringify(value);
      // If it's a simple object like {"Name": "value"}, extract the value
      const parsed = JSON.parse(str);
      if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
        // Try common fields
        if (parsed.Name) return String(parsed.Name);
        if (parsed.DeveloperName) return String(parsed.DeveloperName);
        if (parsed.Id) return String(parsed.Id);
        // If it's a single-key object, return that value
        const keys = Object.keys(parsed);
        if (keys.length === 1) return String(parsed[keys[0]]);
      }
      return str;
    } catch {
      return String(value);
    }
  }
  return String(value);
}

/**
 * Escape CSV values (wraps in quotes and escapes internal quotes)
 * @param {*} value - Value to escape
 * @returns {string} Escaped CSV value
 * @example escapeCSV('test"value') → '"test""value"'
 */
export function escapeCSV(value) {
  return `"${String(value || "").replace(/"/g, '""')}"`;
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
// LABEL MANAGEMENT UTILITIES
// ========================================================================

/**
 * Get labels for a component
 * This function centralizes label management and provides a consistent API
 * for retrieving Custom Labels by component name.
 *
 * @param {string} componentName - Name of the component (e.g., 'jtQueryViewer', 'jtConfigModal')
 * @param {Object} importedLabels - Object containing imported Custom Labels from the component
 * @returns {Object} Object with labels keyed by their usage identifier (data-id, data-name, etc.)
 *
 * @example
 * // In component:
 * import label1 from "@salesforce/label/c.JT_jtQueryViewer_label1";
 * import label2 from "@salesforce/label/c.JT_jtQueryViewer_label2";
 *
 * const labels = getLabels('jtQueryViewer', {
 *   label1,
 *   label2
 * });
 *
 * // Usage in template:
 * // {labels['data-id-button-save']}
 */
export function getLabels(componentName, importedLabels = {}) {
  if (!componentName) {
    console.warn("getLabels: componentName is required");
    return {};
  }

  // Return the imported labels as-is, but with component name prefix for namespacing
  // This allows components to organize their labels however they want
  // The function serves as a central point for label management patterns
  const labels = {};

  // Copy all imported labels to the result object
  // Components can use keys like 'data-id-button-save', 'data-name-input-query', etc.
  Object.keys(importedLabels).forEach((key) => {
    labels[key] = importedLabels[key];
  });

  // Add component name metadata for debugging
  labels._componentName = componentName;

  return labels;
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
    return {
      isValid: false,
      message: "Developer Name cannot exceed 40 characters"
    };
  }

  if (!/^[a-zA-Z]/.test(devName)) {
    return {
      isValid: false,
      message: "Developer Name must start with a letter"
    };
  }

  if (!/^[a-zA-Z0-9_]+$/.test(devName)) {
    return {
      isValid: false,
      message:
        "Developer Name can only contain letters, numbers, and underscores"
    };
  }

  if (/__/.test(devName)) {
    return {
      isValid: false,
      message: "Developer Name cannot contain consecutive underscores"
    };
  }

  if (/_$/.test(devName)) {
    return {
      isValid: false,
      message: "Developer Name cannot end with an underscore"
    };
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

// ========================================================================
// ERROR HANDLING UTILITIES
// ========================================================================

/**
 * Extract error message from various possible locations in Apex error objects
 * Handles different error formats from Aura/LWC framework
 * @param {Object} error - Error object from Apex call
 * @param {string} fallback - Fallback message if no error found
 * @returns {string} Extracted error message
 * @example
 * extractErrorMessage(error, 'Unknown error')
 * // Returns error.body?.message || error.body?.pageErrors?.[0]?.message || ...
 */
export function extractErrorMessage(error, fallback = unknownErrorLabel) {
  if (!error) return fallback;

  // Try various locations where error messages might be
  return (
    error.body?.message ||
    error.body?.pageErrors?.[0]?.message ||
    error.body?.output?.errors?.[0]?.message ||
    error.body?.exceptionType ||
    error.message ||
    fallback
  );
}

/**
 * Extract detailed error information for debugging
 * @param {Object} error - Error object from Apex call
 * @returns {Object} { message: string, details: Object }
 */
export function extractErrorDetails(error) {
  const message = extractErrorMessage(error, "Unknown error");
  const details = {
    body: error.body,
    status: error.status,
    statusText: error.statusText,
    stack: error.stack
  };
  return { message, details };
}

// ========================================================================
// CONFIGURATION VALIDATION UTILITIES
// ========================================================================

/**
 * Validates that a configuration object exists and is not null/undefined
 * @param {Object} config - Configuration object to validate
 * @returns {Object} { isValid: boolean, errorMessage?: string }
 */
export function validateConfigExists(config) {
  if (!config) {
    return {
      isValid: false,
      errorMessage:
        "Configuration data is missing. Please close and reopen the modal."
    };
  }
  return { isValid: true };
}

/**
 * Validates required fields in a configuration object
 * @param {Object} config - Configuration object to validate
 * @param {Array<string>} requiredFields - Array of required field names (default: ['label', 'developerName', 'baseQuery'])
 * @returns {Object} { isValid: boolean, errorMessage?: string, missingFields?: Array<string> }
 */
export function validateRequiredFields(
  config,
  requiredFields = ["label", "developerName", "baseQuery"]
) {
  if (!config) {
    return {
      isValid: false,
      errorMessage: "Configuration object is required"
    };
  }

  const missingFields = requiredFields.filter((field) => {
    const value = config[field];
    return !value || (typeof value === "string" && value.trim().length === 0);
  });

  if (missingFields.length > 0) {
    const fieldLabels = {
      label: "Label",
      developerName: "Developer Name",
      baseQuery: "Base Query",
      originalDevName: "Original Developer Name"
    };
    const missingLabels = missingFields
      .map((f) => fieldLabels[f] || f)
      .join(", ");
    return {
      isValid: false,
      errorMessage: `${missingLabels} ${missingFields.length === 1 ? "is" : "are"} required.`,
      missingFields
    };
  }

  return { isValid: true };
}

/**
 * Validates query syntax validation object
 * @param {Object} queryValidation - Query validation object from modal or component
 * @returns {Object} { isValid: boolean, errorMessage?: string }
 */
export function validateQuerySyntax(queryValidation) {
  if (!queryValidation || !queryValidation.isValid) {
    return {
      isValid: false,
      errorMessage: fixQuerySyntaxLabel
    };
  }
  return { isValid: true };
}

/**
 * Sanitizes configuration data by trimming string fields
 * @param {Object} config - Configuration object to sanitize
 * @returns {Object} Sanitized configuration object
 */
export function sanitizeConfigData(config) {
  if (!config) return {};

  return {
    label: config.label?.trim() || "",
    developerName: config.developerName?.trim() || "",
    baseQuery: config.baseQuery?.trim() || "",
    bindings: config.bindings?.trim() || "",
    objectName: config.objectName?.trim() || "",
    originalDevName: config.originalDevName?.trim() || ""
  };
}

/**
 * Validates configuration for edit mode (requires originalDevName)
 * @param {string} mode - Mode ('create' | 'edit')
 * @param {string} originalDevName - Original developer name for edit mode
 * @returns {Object} { isValid: boolean, errorMessage?: string }
 */
export function validateEditMode(mode, originalDevName) {
  if (mode === "edit" && !originalDevName) {
    return {
      isValid: false,
      errorMessage: cannotUpdateConfigurationLabel
    };
  }
  return { isValid: true };
}

// ========================================================================
// POLLING UTILITIES
// ========================================================================

/**
 * Generic polling helper function
 * Polls a function until a condition is met or timeout is reached
 * @param {Function} pollFunction - Async function to call for polling (should return a Promise)
 * @param {Function} checkComplete - Function to check if polling is complete (receives result, returns boolean)
 * @param {Function} onComplete - Callback when polling completes successfully (receives result)
 * @param {Function} onError - Callback when polling fails (receives error)
 * @param {Function} onTimeout - Callback when polling times out
 * @param {Object} options - Polling options
 * @param {number} options.interval - Polling interval in milliseconds (default: 2000)
 * @param {number} options.maxPolls - Maximum number of polls before timeout (default: 60)
 * @param {Function} options.onProgress - Optional callback for progress updates (receives pollCount, result)
 * @returns {Function} Function to stop polling (clearInterval)
 * @example
 * const stopPolling = pollUntilComplete(
 *   () => getTestResults({ executionId: '123' }),
 *   (result) => result.success !== undefined,
 *   (result) => handleResults(result),
 *   (error) => showError(error),
 *   () => showTimeout(),
 *   { interval: 2000, maxPolls: 60 }
 * );
 */
export function pollUntilComplete(
  pollFunction,
  checkComplete,
  onComplete,
  onError,
  onTimeout,
  options = {}
) {
  const {
    interval = 2000,
    maxPolls = 60,
    onProgress = null,
    immediateFirstPoll = false,
    exponentialBackoff = false,
    maxInterval = 5000
  } = options;

  let pollCount = 0;
  let pollInterval = null;
  let currentInterval = interval;
  let timeoutId = null;

  const stopPolling = () => {
    if (pollInterval) {
      clearInterval(pollInterval);
      pollInterval = null;
    }
    if (timeoutId) {
      clearTimeout(timeoutId);
      timeoutId = null;
    }
  };

  const scheduleNextPoll = () => {
    // Apply exponential backoff if enabled
    if (exponentialBackoff && pollCount > 0) {
      currentInterval = Math.min(currentInterval * 1.5, maxInterval);
    }

    // eslint-disable-next-line @lwc/lwc/no-async-operation
    timeoutId = setTimeout(() => {
      performPoll();
    }, currentInterval);
  };

  const performPoll = () => {
    pollCount++;

    pollFunction()
      .then((result) => {
        // Call progress callback if provided
        if (onProgress) {
          onProgress(pollCount, result);
        }

        // Check if polling is complete
        if (checkComplete(result)) {
          stopPolling();
          onComplete(result);
          return;
        }

        // Check for timeout
        if (pollCount >= maxPolls) {
          stopPolling();
          if (onTimeout) {
            onTimeout();
          }
          return;
        }

        // Schedule next poll
        scheduleNextPoll();
      })
      .catch((error) => {
        stopPolling();
        if (onError) {
          onError(error);
        }
      });
  };

  // Perform first poll immediately if requested
  if (immediateFirstPoll) {
    performPoll();
  } else {
    // Start polling with initial interval
    scheduleNextPoll();
  }

  return stopPolling;
}

// ========================================================================
// EVENT HANDLER UTILITIES
// ========================================================================

/**
 * Validates that a configuration is selected
 * @param {string} selectedConfig - Selected configuration value
 * @param {Object} labels - Component labels object
 * @param {string} actionLabel - Label key for the action (e.g., 'pleaseSelectConfigurationToEdit')
 * @returns {Object} { isValid: boolean, errorMessage?: string }
 */
export function validateConfigSelected(
  selectedConfig,
  labels,
  actionLabel = "pleaseSelectConfiguration"
) {
  if (!selectedConfig) {
    return {
      isValid: false,
      errorMessage:
        labels[actionLabel] || "Please select a configuration first."
    };
  }
  return { isValid: true };
}

/**
 * Finds a configuration from options array
 * @param {string} selectedConfig - Selected configuration value
 * @param {Array} configurationOptions - Array of configuration options
 * @returns {Object|null} Found configuration or null
 */
export function findConfiguration(selectedConfig, configurationOptions) {
  if (
    !selectedConfig ||
    !configurationOptions ||
    !Array.isArray(configurationOptions)
  ) {
    return null;
  }
  return (
    configurationOptions.find((cfg) => cfg.value === selectedConfig) || null
  );
}

/**
 * Validates and finds configuration with error handling
 * @param {string} selectedConfig - Selected configuration value
 * @param {Array} configurationOptions - Array of configuration options
 * @param {Object} labels - Component labels object
 * @param {string} actionLabel - Label key for the action
 * @returns {Object} { isValid: boolean, config?: Object, errorMessage?: string }
 */
export function validateAndFindConfig(
  selectedConfig,
  configurationOptions,
  labels,
  actionLabel = "pleaseSelectConfiguration"
) {
  // Validate config is selected
  const selectionValidation = validateConfigSelected(
    selectedConfig,
    labels,
    actionLabel
  );
  if (!selectionValidation.isValid) {
    return {
      isValid: false,
      errorMessage: selectionValidation.errorMessage
    };
  }

  // Find configuration
  const config = findConfiguration(selectedConfig, configurationOptions);
  if (!config) {
    return {
      isValid: false,
      errorMessage:
        "Could not find the selected configuration. Please refresh and try again."
    };
  }

  return {
    isValid: true,
    config
  };
}
