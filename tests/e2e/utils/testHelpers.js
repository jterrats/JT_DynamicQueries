/**
 * Reusable test helpers for E2E tests
 * Encapsulates common operations to reduce duplication
 */

const { getSFSession, injectSFSession, navigateToApp } = require("./sfAuth");
const {
  TARGET_APP_NAME,
  QUERY_VIEWER_TAB,
  SELECTORS,
  TIMEOUTS
} = require("./testConstants");

/**
 * Setup context for tests - handles auth and navigation
 * @param {Object} page - Playwright page object
 * @param {Object} session - SF session from getSFSession()
 * @param {Object} options - { skipNavigation: boolean, targetTab: string }
 */
async function setupTestContext(page, session, options = {}) {
  const {
    skipNavigation = false,
    targetTab = QUERY_VIEWER_TAB,
    waitForComponent = true
  } = options;

  // Step 1: Authenticate
  await injectSFSession(page, session);

  // Step 2: Navigate to app (unless skipped)
  if (!skipNavigation) {
    const navigated = await navigateToApp(page, TARGET_APP_NAME);

    if (navigated) {
      // Wait for any modal spinner to disappear before clicking tab
      const modalSpinner = page.locator(".forceModalSpinner, .modal-glass");
      await modalSpinner
        .waitFor({ state: "hidden", timeout: 10000 })
        .catch(() => {
          // If spinner doesn't exist or already hidden, that's fine
        });

      // Click on target tab
      const tabLink = page.locator(SELECTORS.tabLink(targetTab)).first();
      await tabLink.waitFor({ state: "visible", timeout: 10000 });
      await tabLink.click({ timeout: 5000 });
      await page.waitForLoadState("domcontentloaded");

      // Wait for modal spinner to disappear after navigation
      await modalSpinner
        .waitFor({ state: "hidden", timeout: 10000 })
        .catch(() => {
          // If spinner doesn't exist or already hidden, that's fine
        });
    }

    // Step 3: Wait for component to load
    if (waitForComponent) {
      await page.waitForSelector(SELECTORS.queryViewer, {
        timeout: TIMEOUTS.component
      });

      // Extra wait for Shadow DOM and interactivity
      await page.waitForTimeout(TIMEOUTS.medium);
    }
  }
}

/**
 * Select a configuration from the dropdown
 * @param {Object} page - Playwright page object
 * @param {string} configName - Name of the configuration to select
 */
async function selectConfiguration(page, configName) {
  const input = page.locator(SELECTORS.configSelectorInput);
  await input.click({ timeout: TIMEOUTS.component });
  await page.waitForTimeout(1000); // Wait for dropdown to open
  await input.fill(configName);
  await page.waitForTimeout(1000); // Wait for filtering

  const dropdown = page.locator(SELECTORS.configSelectorDropdown);
  await dropdown.locator(".slds-listbox__item").first().click();
  await page.waitForTimeout(TIMEOUTS.short); // Wait for selection to process
}

/**
 * Execute a query by clicking the execute button
 * @param {Object} page - Playwright page object
 * @param {Object} options - { waitTime: number, force: boolean }
 */
async function executeQuery(page, options = {}) {
  const { waitTime = TIMEOUTS.medium, force = true } = options;

  const executeButton = page.locator(SELECTORS.executeButton);
  await executeButton.click({ force }); // force: true to bypass interceptions
  await page.waitForTimeout(waitTime); // Wait for query execution
}

/**
 * Wait for a toast message to appear
 * @param {Object} page - Playwright page object
 * @param {string} expectedMessage - Expected message text (optional)
 * @returns {Promise<string>} The toast message text
 */
async function waitForToast(page, expectedMessage = null) {
  const toast = page.locator(SELECTORS.toastContainer);
  await toast.waitFor({ state: "visible", timeout: TIMEOUTS.long });

  const messageElement = toast.locator(SELECTORS.toastMessage);
  const messageText = await messageElement.textContent();

  if (expectedMessage && !messageText.includes(expectedMessage)) {
    throw new Error(
      `Expected toast message "${expectedMessage}" but got "${messageText}"`
    );
  }

  return messageText;
}

/**
 * Check if error toast is visible
 * @param {Object} page - Playwright page object
 * @returns {Promise<boolean>}
 */
async function hasErrorToast(page) {
  const errorToast = page.locator('lightning-toast[class*="error"]');
  return await errorToast.isVisible({ timeout: 2000 }).catch(() => false);
}

/**
 * Get the session for all tests in a suite (call in beforeAll)
 * @returns {Object} SF session object
 */
function getTestSession() {
  return getSFSession();
}

module.exports = {
  setupTestContext,
  selectConfiguration,
  executeQuery,
  waitForToast,
  hasErrorToast,
  getTestSession
};
