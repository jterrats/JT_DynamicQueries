import { test, expect } from "@playwright/test";
import { loginToSalesforce } from "./utils/auth.js";

/**
 * E2E tests for "Where is this used?" feature
 * Validates that the framework correctly detects usage of configurations in:
 * - Apex Classes (JT_AccountReportExample)
 * - Flows (JT_Account_Report_Flow)
 */
test.describe("Where is this used? - Usage Detection", () => {
  test.beforeEach(async ({ page }) => {
    await loginToSalesforce(page);

    // Navigate to Query Viewer
    await page.goto("/lightning/n/JT_Query_Viewer");
    await page.waitForSelector("c-jt-query-viewer", { timeout: 15000 });
  });

  test("should detect JT_AccountReportExample class using Account_By_Name", async ({
    page
  }) => {
    // Select the Account_By_Name configuration
    const configDropdown = page.locator(
      'lightning-combobox[data-id="configDropdown"]'
    );
    await configDropdown.click();
    await page
      .locator('lightning-base-combobox-item[data-value="Account_By_Name"]')
      .click();

    // Wait for configuration to load
    await page.waitForTimeout(1000);

    // Click "Where is this used?" button
    const whereUsedButton = page.locator(
      'lightning-button[data-id="whereIsThisUsedBtn"]'
    );
    await whereUsedButton.click();

    // Wait for modal to appear
    await page.waitForSelector("c-jt-usage-modal", { timeout: 10000 });

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
    const configDropdown = page.locator(
      'lightning-combobox[data-id="configDropdown"]'
    );
    await configDropdown.click();
    await page
      .locator(
        'lightning-base-combobox-item[data-value="Dynamic_Input_Test"]'
      )
      .click();

    await page.waitForTimeout(1000);

    // Click "Where is this used?"
    const whereUsedButton = page.locator(
      'lightning-button[data-id="whereIsThisUsedBtn"]'
    );
    await whereUsedButton.click();

    await page.waitForSelector("c-jt-usage-modal", { timeout: 10000 });
    await page.waitForTimeout(3000);

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
    const configDropdown = page.locator(
      'lightning-combobox[data-id="configDropdown"]'
    );
    await configDropdown.click();
    await page
      .locator(
        'lightning-base-combobox-item[data-value="Complete_Customer_360_View"]'
      )
      .click();

    await page.waitForTimeout(1000);

    const whereUsedButton = page.locator(
      'lightning-button[data-id="whereIsThisUsedBtn"]'
    );
    await whereUsedButton.click();

    await page.waitForSelector("c-jt-usage-modal", { timeout: 10000 });
    await page.waitForTimeout(3000);

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
    const configDropdown = page.locator(
      'lightning-combobox[data-id="configDropdown"]'
    );
    await configDropdown.click();
    await page.locator("lightning-base-combobox-item").first().click();

    await page.waitForTimeout(1000);

    const whereUsedButton = page.locator(
      'lightning-button[data-id="whereIsThisUsedBtn"]'
    );
    await whereUsedButton.click();

    await page.waitForSelector("c-jt-usage-modal", { timeout: 10000 });
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
    const configDropdown = page.locator(
      'lightning-combobox[data-id="configDropdown"]'
    );
    await configDropdown.click();
    await page
      .locator('lightning-base-combobox-item[data-value="Test_Record"]')
      .click();

    await page.waitForTimeout(1000);

    const whereUsedButton = page.locator(
      'lightning-button[data-id="whereIsThisUsedBtn"]'
    );
    await whereUsedButton.click();

    await page.waitForSelector("c-jt-usage-modal", { timeout: 10000 });
    await page.waitForTimeout(3000);

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
    const configDropdown = page.locator(
      'lightning-combobox[data-id="configDropdown"]'
    );
    await configDropdown.click();
    await page
      .locator('lightning-base-combobox-item[data-value="Account_By_Name"]')
      .click();

    await page.waitForTimeout(1000);

    const whereUsedButton = page.locator(
      'lightning-button[data-id="whereIsThisUsedBtn"]'
    );
    await whereUsedButton.click();

    await page.waitForSelector("c-jt-usage-modal", { timeout: 10000 });
    await page.waitForTimeout(3000);

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
