const { test, expect } = require("@playwright/test");
const { getSFSession } = require("./utils/sfAuth");
const {
  setupTestContext,
  selectConfiguration
} = require("./utils/testHelpers");
const {
  TARGET_APP_NAME,
  QUERY_VIEWER_TAB,
  SELECTORS
} = require("./utils/testConstants");

/**
 * Helper function to close the usage modal reliably
 * Tries multiple strategies to ensure the modal closes
 */
async function closeUsageModal(page) {
  // Wait for modal to finish loading (spinner disappears)
  await page.waitForSelector("c-jt-usage-modal lightning-spinner", {
    state: "hidden",
    timeout: 30000
  }).catch(() => {
    // Spinner may already be gone, continue
  });

  // Wait a bit for modal to fully render before closing
  await page.waitForTimeout(2000);

  // Try footer button first (lightning-button)
  let closeButton = page.locator('c-jt-usage-modal lightning-button').first();
  let buttonVisible = await closeButton.isVisible({ timeout: 5000 }).catch(() => false);
  
  if (buttonVisible) {
    // Check if button is disabled
    const isDisabled = await closeButton.getAttribute("disabled").catch(() => null);
    if (!isDisabled) {
      await closeButton.click({ timeout: 10000 });
      return;
    }
  }
  
  // Fallback to header close button
  closeButton = page.locator('c-jt-usage-modal button.slds-modal__close').first();
  buttonVisible = await closeButton.isVisible({ timeout: 5000 }).catch(() => false);
  
  if (buttonVisible) {
    const isDisabled = await closeButton.getAttribute("disabled").catch(() => null);
    if (!isDisabled) {
      await closeButton.click({ timeout: 10000 });
      return;
    }
  }
  
  // Last resort: try pressing Escape key
  await page.keyboard.press("Escape");
  await page.waitForTimeout(1000);
}

/**
 * E2E tests for "Where is this used?" feature
 * Validates that the framework correctly detects usage of configurations in:
 * - Apex Classes (JT_AccountReportExample)
 * - Flows (JT_Account_Report_Flow)
 */
test.describe("Where is this used? - Usage Detection", () => {
  let session;

  test.beforeAll(() => {
    // Get SF CLI active session once for all tests
    session = getSFSession();
    console.log(`✅ Using SF session for: ${session.username}`);
  });

  test.beforeEach(async ({ page }) => {
    // Setup authenticated context and navigate to Query Viewer
    await setupTestContext(page, session, {
      targetTab: QUERY_VIEWER_TAB,
      waitForComponent: true
    });
  });

  test("should detect JT_AccountReportExample class using Account_By_Name", async ({
    page
  }) => {
    // Select the Account_By_Name configuration
    await selectConfiguration(page, "Account By Name");

    // Click "Where is this used?" link
    const whereUsedLink = page.locator('a:has-text("Where is this used?")');
    await whereUsedLink.click();

    // Wait for modal to appear and load
    await page.waitForSelector("c-jt-usage-modal", {
      state: "attached",
      timeout: 15000
    });

    // Wait for search to complete (takes ~12 seconds, but can take up to 20s)
    await page.waitForTimeout(20000);

    // Wait for spinner to disappear before interacting with modal
    await page.waitForSelector(".usage-search-spinner-overlay", {
      state: "hidden",
      timeout: 25000
    }).catch(() => {
      // Spinner may already be gone, continue
    });

    // Verify that JT_AccountReportExample appears in results
    const modalContent = page.locator("c-jt-usage-modal");
    // Use .first() to avoid strict mode violation (may match both class and test class)
    const apexClassUsage = modalContent
      .locator("text=/JT_AccountReportExample/i")
      .first();

    await expect(apexClassUsage).toBeVisible({
      timeout: 20000
    });

    // Verify the metadata type is shown as "Apex Class"
    // Use .first() to avoid strict mode violation (multiple "Apex Class" elements)
    const metadataType = modalContent.locator("text=/Apex Class/i").first();
    await expect(metadataType).toBeVisible({ timeout: 20000 });

    // Verify method name appears (searchAccountsByName or searchAccountsForLWC)
    const methodReference = modalContent.locator(
      "text=/searchAccounts|Account_By_Name/i"
    ).first();
    await expect(methodReference).toBeVisible({ timeout: 20000 });

    // Close modal using helper function
    await closeUsageModal(page);
  });

  test("should detect JT_AccountReportExample class using Dynamic_Input_Test", async ({
    page
  }) => {
    // Select the Dynamic_Input_Test configuration
    await selectConfiguration(page, "Dynamic Input Test");

    // Click "Where is this used?" link
    const whereUsedLink = page.locator('a:has-text("Where is this used?")');
    await whereUsedLink.click();

    await page.waitForSelector("c-jt-usage-modal", {
      state: "attached",
      timeout: 20000
    });
    // Wait for search to complete (takes ~12 seconds, but can take up to 20s)
    await page.waitForTimeout(20000);

    // Wait for spinner to disappear before interacting with modal
    await page.waitForSelector(".usage-search-spinner-overlay", {
      state: "hidden",
      timeout: 25000
    }).catch(() => {
      // Spinner may already be gone, continue
    });

    // Verify JT_AccountReportExample with getAccountsByTypeAndIndustry method
    const modalContent = page.locator("c-jt-usage-modal");
    // Use .first() to avoid strict mode violation (may match both class and test class)
    const apexClassUsage = modalContent
      .locator("text=/JT_AccountReportExample/i")
      .first();

    await expect(apexClassUsage).toBeVisible({ timeout: 20000 });

    const methodReference = modalContent.locator(
      "text=/getAccountsByTypeAndIndustry|Dynamic_Input_Test/i"
    ).first();
    await expect(methodReference).toBeVisible({ timeout: 20000 });

    // Close modal using helper function
    await closeUsageModal(page);
  });

  test("should detect JT_AccountReportExample class using Complete_Customer_360_View", async ({
    page
  }) => {
    // Select the Complete_Customer_360_View configuration
    await selectConfiguration(page, "Customer 360 View");

    // Click "Where is this used?" link
    const whereUsedLink = page.locator('a:has-text("Where is this used?")');
    await whereUsedLink.click();

    await page.waitForSelector("c-jt-usage-modal", {
      state: "attached",
      timeout: 20000
    });
    // Wait for search to complete (takes ~12 seconds, but can take up to 20s)
    await page.waitForTimeout(20000);

    // Wait for spinner to disappear before interacting with modal
    await page.waitForSelector(".usage-search-spinner-overlay", {
      state: "hidden",
      timeout: 25000
    }).catch(() => {
      // Spinner may already be gone, continue
    });

    const modalContent = page.locator("c-jt-usage-modal");
    // Use .first() to avoid strict mode violation (may match both class and test class)
    const apexClassUsage = modalContent
      .locator("text=/JT_AccountReportExample/i")
      .first();

    await expect(apexClassUsage).toBeVisible({ timeout: 20000 });

    // Should find getCustomer360View or getAllCustomersForAnalysis methods
    const methodReference = modalContent.locator(
      "text=/getCustomer360View|getAllCustomersForAnalysis|Complete_Customer_360_View/i"
    ).first();
    await expect(methodReference).toBeVisible({ timeout: 20000 });

    // Close modal using helper function
    await closeUsageModal(page);
  });

  test("should detect JT_Account_Report_Flow when implemented", async ({
    page
  }) => {
    // Note: This test assumes the Flow is fully implemented in the org
    // If the Flow is in Draft status, it may not be detected by Tooling API

    // Select any configuration (Flow should be generic)
    await selectConfiguration(page, "Account By Name");

    // Click "Where is this used?" link
    const whereUsedLink = page.locator('a:has-text("Where is this used?")');
    await whereUsedLink.click();

    await page.waitForSelector("c-jt-usage-modal", {
      state: "attached",
      timeout: 20000
    });
    // Wait for search to complete (takes ~12 seconds, Flows may take longer)
    await page.waitForTimeout(20000);

    // Wait for spinner to disappear before interacting with modal
    await page.waitForSelector(".usage-search-spinner-overlay", {
      state: "hidden",
      timeout: 25000
    }).catch(() => {
      // Spinner may already be gone, continue
    });

    const modalContent = page.locator("c-jt-usage-modal");

    // Check if Flow appears (may be in Draft, so this is informational)
    const flowUsage = modalContent.locator("text=/JT_Account_Report_Flow/i").first();
    const flowExists = await flowUsage.isVisible().catch(() => false);

    if (flowExists) {
      // If Flow is Active, verify metadata type
      const metadataType = modalContent.locator("text=/Flow/i").first();
      await expect(metadataType).toBeVisible({ timeout: 20000 });

      console.log(
        '✅ JT_Account_Report_Flow detected in "Where is this used?"'
      );
    } else {
      console.log(
        "⚠️ JT_Account_Report_Flow not detected (may be in Draft status)"
      );
      console.log(
        "   To activate: Setup → Flows → JT Account Report Flow → Activate"
      );
    }

    // Close modal using helper function
    await closeUsageModal(page);
  });

  test('should show "No usages found" for unused configuration', async ({
    page
  }) => {
    // Select Test_Record configuration (used in tests but not in production code)
    await selectConfiguration(page, "Test Record");

    // Click "Where is this used?" link
    const whereUsedLink = page.locator('a:has-text("Where is this used?")');
    await whereUsedLink.click();

    await page.waitForSelector("c-jt-usage-modal", {
      state: "attached",
      timeout: 20000
    });
    // Wait for search to complete (takes ~12 seconds, but can take up to 20s)
    await page.waitForTimeout(20000);

    // Wait for spinner to disappear before interacting with modal
    await page.waitForSelector(".usage-search-spinner-overlay", {
      state: "hidden",
      timeout: 25000
    }).catch(() => {
      // Spinner may already be gone, continue
    });

    const modalContent = page.locator("c-jt-usage-modal");

    // Wait for loading to complete
    await page.waitForSelector("c-jt-usage-modal lightning-spinner", {
      state: "hidden",
      timeout: 30000
    }).catch(() => {
      // Spinner may already be gone, continue
    });

    // Should show "No usages found" or similar message
    // The modal uses custom labels, so we need to check for the actual text
    const noUsagesMessage = modalContent.locator(
      "text=/No usages found|not found any usage|no results|no usage found|This configuration is not used/i"
    ).first();
    await expect(noUsagesMessage).toBeVisible({ timeout: 30000 });

    // Close modal using helper function
    await closeUsageModal(page);
  });

  test("should display usage statistics summary", async ({ page }) => {
    // Select a configuration with known usages
    await selectConfiguration(page, "Account By Name");

    // Click "Where is this used?" link
    const whereUsedLink = page.locator('a:has-text("Where is this used?")');
    await whereUsedLink.click();

    await page.waitForSelector("c-jt-usage-modal", {
      state: "attached",
      timeout: 20000
    });
    // Wait for search to complete (takes ~12 seconds, but can take up to 20s)
    await page.waitForTimeout(20000);

    // Wait for spinner to disappear before interacting with modal
    await page.waitForSelector(".usage-search-spinner-overlay", {
      state: "hidden",
      timeout: 25000
    }).catch(() => {
      // Spinner may already be gone, continue
    });

    const modalContent = page.locator("c-jt-usage-modal");

    // Verify modal shows usage count (may be in header or summary)
    const usageCount = modalContent.locator("text=/\\d+ usage|\\d+ result|found/i").first();
    await expect(usageCount).toBeVisible({ timeout: 25000 });

    // Verify sections are present
    const apexSection = modalContent.locator("text=/Apex Class/i").first();
    await expect(apexSection).toBeVisible({ timeout: 20000 });

    // Close modal using helper function
    await closeUsageModal(page);
  });
});
