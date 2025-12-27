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
      // Salesforce has its own spinner (forceModalSpinner) that can intercept clicks
      const modalSpinner = page.locator(".forceModalSpinner, .modal-glass");
      await modalSpinner
        .waitFor({ state: "hidden", timeout: 15000 })
        .catch(() => {
          // If spinner doesn't exist or already hidden, that's fine
        });

      // Also wait for our custom spinners
      const customSpinner = page.locator(".usage-search-spinner-overlay, .deletion-spinner-overlay, .initial-loading-overlay");
      await customSpinner
        .waitFor({ state: "hidden", timeout: 10000 })
        .catch(() => {
          // Spinner may already be gone, continue
        });

      // Click on target tab with retry logic for spinner interference
      const tabLink = page.locator(SELECTORS.tabLink(targetTab)).first();
      await tabLink.waitFor({ state: "visible", timeout: 10000 });

      // Retry click if spinner intercepts - increase retries and wait times
      let clickSuccess = false;
      for (let i = 0; i < 5; i++) {
        try {
          // Wait for spinner to be gone before each attempt
          await modalSpinner.waitFor({ state: "hidden", timeout: 5000 }).catch(() => {});
          await customSpinner.waitFor({ state: "hidden", timeout: 3000 }).catch(() => {});
          await page.waitForTimeout(500); // Small delay between attempts
          
          await tabLink.click({ timeout: 15000, force: i >= 3 }); // Force on last 2 attempts
          clickSuccess = true;
          break;
        } catch (error) {
          if (error.message.includes("intercepts pointer events") || error.message.includes("modal-glass") || error.message.includes("forceModalSpinner")) {
            // Wait longer for spinner to disappear
            await page.waitForTimeout(2000);
            await modalSpinner.waitFor({ state: "hidden", timeout: 10000 }).catch(() => {});
            await customSpinner.waitFor({ state: "hidden", timeout: 5000 }).catch(() => {});
          } else {
            throw error;
          }
        }
      }
      
      if (!clickSuccess) {
        throw new Error("Failed to click tab after 5 retries - spinner may be blocking");
      }
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
