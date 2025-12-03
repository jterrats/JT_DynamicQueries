const { getSFSession, injectSFSession, navigateToApp } = require("./sfAuth");
const { setupTestData } = require("./setupTestData");

const TARGET_APP_NAME = "Dynamic Query Framework";
const QUERY_VIEWER_TAB = "Query Viewer";
const DOCUMENTATION_TAB = "Documentation";

/**
 * Test Context Manager
 * Handles authentication, navigation, and test data setup
 */
class TestContext {
  constructor() {
    this.session = null;
    this.isSetupComplete = false;
  }

  /**
   * Initialize test context (call in beforeAll)
   * Sets up SF session and creates test data if needed
   */
  initialize() {
    if (!this.session) {
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      console.log("🚀 Initializing Test Context");
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      // Get SF CLI active session
      this.session = getSFSession();

      // Setup test data (idempotent - only creates if missing)
      if (!this.isSetupComplete) {
        setupTestData();
        this.isSetupComplete = true;
      }

      console.log("✅ Test Context Initialized");
      console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    }
    return this.session;
  }

  /**
   * Authenticate and navigate to the Query Viewer tab (call in beforeEach)
   * @param {import('@playwright/test').Page} page
   * @param {Object} options - { skipNavigation: boolean, targetTab: string }
   */
  async setupPage(page, options = {}) {
    const { skipNavigation = false, targetTab = QUERY_VIEWER_TAB } = options;

    // Ensure session is initialized
    if (!this.session) {
      this.initialize();
    }

    // Step 1: Inject authentication
    await injectSFSession(page, this.session);

    // Step 2: Navigate to app (unless skipped)
    if (!skipNavigation) {
      await this.navigateToTab(page, targetTab);
    }
  }

  /**
   * Navigate to a specific tab in the Dynamic Query Framework app
   * @param {import('@playwright/test').Page} page
   * @param {string} tabName - Name of the tab to navigate to
   */
  async navigateToTab(page, tabName = QUERY_VIEWER_TAB) {
    console.log(`📱 Navigating to ${TARGET_APP_NAME} - ${tabName}...`);

    // Navigate to app via App Launcher
    const navigated = await navigateToApp(page, TARGET_APP_NAME);

    if (navigated) {
      console.log(`✅ In ${TARGET_APP_NAME} app`);

      // Click on the target tab
      console.log(`🎯 Looking for "${tabName}" tab...`);

      const tabLink = page
        .locator(
          [
            `one-app-nav-bar-item-root a[title="${tabName}"]`,
            `a[title="${tabName}"]`,
            `a:has-text("${tabName}")`
          ].join(", ")
        )
        .first();

      await tabLink.click({ timeout: 5000 });
      console.log(`✅ Clicked on "${tabName}" tab`);

      await page.waitForLoadState("domcontentloaded");
    } else {
      console.log(`⚠️  Navigation failed, trying direct URL approach...`);
      // Fallback: try direct URL navigation if available
    }
  }

  /**
   * Wait for the main LWC component to load
   * @param {import('@playwright/test').Page} page
   * @param {string} componentSelector - CSS selector for the component
   */
  async waitForComponent(page, componentSelector = "c-jt-query-viewer") {
    console.log(`⏳ Waiting for ${componentSelector} to load...`);
    await page.waitForSelector(componentSelector, { timeout: 15000 });
    console.log(`✅ ${componentSelector} loaded successfully`);
  }

  /**
   * Complete setup: auth + navigate + wait for component
   * @param {import('@playwright/test').Page} page
   * @param {Object} options - { targetTab: string, componentSelector: string }
   */
  async setupAndWaitForComponent(page, options = {}) {
    const {
      targetTab = QUERY_VIEWER_TAB,
      componentSelector = "c-jt-query-viewer"
    } = options;

    await this.setupPage(page, { targetTab });
    await this.waitForComponent(page, componentSelector);
  }
}

// Export singleton instance
const testContext = new TestContext();

module.exports = {
  testContext,
  TARGET_APP_NAME,
  QUERY_VIEWER_TAB,
  DOCUMENTATION_TAB
};

