/**
 * Shared constants and selectors for E2E tests
 * Centralized to avoid duplication across test files
 */

// App Navigation Constants
const TARGET_APP_NAME = "Dynamic Query Framework";
const QUERY_VIEWER_TAB = "Query Viewer";
const DOCUMENTATION_TAB = "Documentation";

// Component Selectors (data-testid attributes)
const SELECTORS = {
  // Main Components
  queryViewer: "c-jt-query-viewer",
  configSelector: 'c-jt-searchable-combobox[data-testid="config-selector"]',
  configSelectorInput: '[data-testid="config-selector-input"]',
  configSelectorDropdown: '[data-testid="config-selector-dropdown"]',
  executeButton: "c-jt-execute-button lightning-button",
  executeButtonTestId: '[data-testid="execute-query-button"]',

  // Results
  queryResults: "c-jt-query-results",
  resultsTable: ".slds-table",

  // Modals
  configModal: "c-jt-config-modal",
  usageModal: "c-jt-usage-modal",
  cacheModal: "c-jt-cache-modal",

  // Inputs
  parameterInputs: "c-jt-parameter-inputs",

  // Run As User
  runAsSection: "c-jt-run-as-section",
  runAsUserSelector: '[data-testid="run-as-user-selector"]',

  // Tabs/Navigation
  tabLink: (tabName) => `a[title="${tabName}"]`,

  // Toast Messages
  toastContainer: "lightning-toast",
  toastMessage: ".toastMessage"
};

// Common Wait Times (in milliseconds)
const TIMEOUTS = {
  short: 1000,
  medium: 3000,
  long: 5000,
  component: 15000,
  navigation: 30000,
  auth: 45000
};

// Test Data Configuration Names
const TEST_CONFIGS = {
  noParams: "Customer 360 View", // Has bindings, no empty params
  simple: "Test Record", // Simple query
  withParams: "Test Account", // Has parameters
  allActive: "All Active Accounts" // Many records
};

// Expected Messages
const MESSAGES = {
  success: {
    queryExecuted: "Query executed successfully",
    configCreated: "Configuration created successfully",
    cacheCleared: "Cache cleared successfully"
  },
  error: {
    noConfig: "Please select a configuration",
    invalidQuery: "Invalid query"
  }
};

module.exports = {
  TARGET_APP_NAME,
  QUERY_VIEWER_TAB,
  DOCUMENTATION_TAB,
  SELECTORS,
  TIMEOUTS,
  TEST_CONFIGS,
  MESSAGES
};
