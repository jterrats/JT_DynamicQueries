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
    await page.waitForTimeout(2000); // Wait for search to complete

    // Wait for search results
    await page.waitForTimeout(3000);

    // Verify that JT_AccountReportExample appears in results
    const modalContent = page.locator("c-jt-usage-modal");
    const apexClassUsage = modalContent.locator(
      "text=/JT_AccountReportExample/i"
    );

    await expect(apexClassUsage).toBeVisible({
      timeout: 15000
    });

    // Verify the metadata type is shown as "Apex Class"
    const metadataType = modalContent.locator("text=/Apex Class/i");
    await expect(metadataType).toBeVisible();

    // Verify method name appears (searchAccountsByName or searchAccountsForLWC)
    const methodReference = modalContent.locator(
      "text=/searchAccounts|Account_By_Name/i"
    );
    await expect(methodReference).toBeVisible();

    // Close modal
    await page.locator('lightning-button[title="Close"]').first().click();
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
      timeout: 15000
    });
    await page.waitForTimeout(3000); // Wait for search to complete

    // Verify JT_AccountReportExample with getAccountsByTypeAndIndustry method
    const modalContent = page.locator("c-jt-usage-modal");
    const apexClassUsage = modalContent.locator(
      "text=/JT_AccountReportExample/i"
    );

    await expect(apexClassUsage).toBeVisible({ timeout: 15000 });

    const methodReference = modalContent.locator(
      "text=/getAccountsByTypeAndIndustry|Dynamic_Input_Test/i"
    );
    await expect(methodReference).toBeVisible();

    await page.locator('lightning-button[title="Close"]').first().click();
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
      timeout: 15000
    });
    await page.waitForTimeout(3000); // Wait for search to complete

    const modalContent = page.locator("c-jt-usage-modal");
    const apexClassUsage = modalContent.locator(
      "text=/JT_AccountReportExample/i"
    );

    await expect(apexClassUsage).toBeVisible({ timeout: 15000 });

    // Should find getCustomer360View or getAllCustomersForAnalysis methods
    const methodReference = modalContent.locator(
      "text=/getCustomer360View|getAllCustomersForAnalysis|Complete_Customer_360_View/i"
    );
    await expect(methodReference).toBeVisible();

    await page.locator('lightning-button[title="Close"]').first().click();
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
      timeout: 15000
    });
    await page.waitForTimeout(5000); // Flows take longer to search

    const modalContent = page.locator("c-jt-usage-modal");

    // Check if Flow appears (may be in Draft, so this is informational)
    const flowUsage = modalContent.locator("text=/JT_Account_Report_Flow/i");
    const flowExists = await flowUsage.isVisible().catch(() => false);

    if (flowExists) {
      // If Flow is Active, verify metadata type
      const metadataType = modalContent.locator("text=/Flow/i");
      await expect(metadataType).toBeVisible();

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

    await page.locator('lightning-button[title="Close"]').first().click();
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
      timeout: 15000
    });
    await page.waitForTimeout(3000); // Wait for search to complete

    const modalContent = page.locator("c-jt-usage-modal");

    // Should show "No usages found" or similar message
    const noUsagesMessage = modalContent.locator(
      "text=/No usages found|not found any usage/i"
    );
    await expect(noUsagesMessage).toBeVisible({ timeout: 15000 });

    await page.locator('lightning-button[title="Close"]').first().click();
  });

  test("should display usage statistics summary", async ({ page }) => {
    // Select a configuration with known usages
    await selectConfiguration(page, "Account By Name");

    // Click "Where is this used?" link
    const whereUsedLink = page.locator('a:has-text("Where is this used?")');
    await whereUsedLink.click();

    await page.waitForSelector("c-jt-usage-modal", {
      state: "attached",
      timeout: 15000
    });
    await page.waitForTimeout(3000); // Wait for search to complete

    const modalContent = page.locator("c-jt-usage-modal");

    // Verify modal shows usage count
    const usageCount = modalContent.locator("text=/\\d+ usage|\\d+ result/i");
    await expect(usageCount).toBeVisible({ timeout: 15000 });

    // Verify sections are present
    const apexSection = modalContent.locator("text=/Apex Class/i");
    await expect(apexSection).toBeVisible();

    await page.locator('lightning-button[title="Close"]').first().click();
  });
});
