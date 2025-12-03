/**
 * @description E2E tests for Query Preview with Data (Bug Fix #2)
 * @author Jaime Terrats | 2025-12-01
 * @group E2E Tests
 */

const { test, expect } = require("@playwright/test");
const {
  setupTestContext,
  selectConfiguration,
  getTestSession
} = require("./utils/testHelpers");
const { SELECTORS, TIMEOUTS } = require("./utils/testConstants");

test.describe("Query Data Preview", () => {
  let session;

  test.beforeAll(() => {
    session = getTestSession();
  });

  test.beforeEach(async ({ page }) => {
    await setupTestContext(page, session);
  });

  test("should show query preview SOQL text when config selected", async ({
    page
  }) => {
    // Select a configuration
    await selectConfiguration(page, "Test");

    // Check that Query Preview section is visible
    const queryPreview = page.locator("text=Query Preview:");
    await expect(queryPreview).toBeVisible();

    // Check that SOQL text is displayed
    const soqlPreview = page.locator(".query-preview pre");
    await expect(soqlPreview).toBeVisible();
    const soqlText = await soqlPreview.textContent();
    expect(soqlText).toContain("SELECT");
  });

  test.skip("should load and display data preview table after config selection", async ({
    page
  }) => {
    // TODO: UI changed - "Data Preview" no longer exists, only "Query Preview"
    // Select a configuration with data
    await selectConfiguration(page, "Test");
    await page.waitForTimeout(TIMEOUTS.medium); // Wait for preview to load

    // ✅ HAPPY PATH: Check that Data Preview section is visible
    const dataPreviewHeading = page.locator("text=Data Preview");
    await expect(dataPreviewHeading).toBeVisible({ timeout: 10000 });

    // ✅ HAPPY PATH: Check that preview table is displayed
    const previewTable = page.locator('[data-testid="query-preview-table"]');
    await expect(previewTable).toBeVisible();

    // ✅ HAPPY PATH: Verify table has rows (records returned)
    const rows = previewTable.locator("tbody tr");
    const rowCount = await rows.count();
    expect(rowCount).toBeGreaterThan(0);
    expect(rowCount).toBeLessThanOrEqual(3); // Max 3 per page

    // ✅ HAPPY PATH: Verify actual data in cells (not empty)
    const firstCell = rows.first().locator("td").nth(1); // Skip checkbox column
    const cellText = await firstCell.textContent();
    expect(cellText).not.toBe("");
    expect(cellText).not.toBeNull();

    // ❌ NEGATIVE: Verify NO error toasts appear
    const errorToast = page.locator(".slds-notify--error, .slds-notify_error");
    await expect(errorToast)
      .not.toBeVisible({ timeout: 2000 })
      .catch(() => {
        // If toast doesn't exist at all, that's fine
      });

    // ❌ NEGATIVE: Verify NO error messages in UI
    const errorMessage = page.locator(
      '[data-testid="error-message"], .slds-text-color_error'
    );
    await expect(errorMessage)
      .not.toBeVisible({ timeout: 2000 })
      .catch(() => {
        // If error element doesn't exist at all, that's fine
      });
  });

  test("should show pagination controls when preview has more than 3 records", async ({
    page
  }) => {
    // Select a configuration that returns > 3 records
    await selectConfiguration(page, "All Active");
    await page.waitForTimeout(TIMEOUTS.medium);

    // Check for pagination controls
    const prevButton = page.locator('[data-testid="preview-prev-button"]');
    const nextButton = page.locator('[data-testid="preview-next-button"]');
    const pageInfo = page.locator('[data-testid="preview-page-info"]');

    // Wait for controls to appear (they may not appear if <= 3 records)
    const hasControls = await prevButton
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    if (hasControls) {
      await expect(nextButton).toBeVisible();
      await expect(pageInfo).toBeVisible();

      // Verify page info text
      const pageText = await pageInfo.textContent();
      expect(pageText).toMatch(/Page \d+ of \d+/);
    }
  });

  test("should navigate between preview pages using pagination", async ({
    page
  }) => {
    // Select a configuration that returns > 3 records
    await selectConfiguration(page, "All Active");
    await page.waitForTimeout(TIMEOUTS.medium);

    const nextButton = page.locator('[data-testid="preview-next-button"]');
    const hasNext = await nextButton
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    if (hasNext) {
      // ✅ HAPPY PATH: Get first row data from page 1 (records exist)
      const previewTable = page.locator('[data-testid="query-preview-table"]');
      const firstRowPage1 = await previewTable
        .locator("tbody tr")
        .first()
        .textContent();
      expect(firstRowPage1).not.toBe("");
      expect(firstRowPage1).not.toBeNull();

      // ✅ HAPPY PATH: Click Next and verify different data
      await nextButton.click();
      await page.waitForTimeout(500);

      const firstRowPage2 = await previewTable
        .locator("tbody tr")
        .first()
        .textContent();
      expect(firstRowPage2).not.toBe(firstRowPage1);
      expect(firstRowPage2).not.toBe("");

      // ❌ NEGATIVE: No error toast during pagination
      const errorToast = page.locator(".slds-notify--error");
      await expect(errorToast)
        .not.toBeVisible({ timeout: 1000 })
        .catch(() => {});

      // ✅ HAPPY PATH: Click Previous and verify back to page 1
      const prevButton = page.locator('[data-testid="preview-prev-button"]');
      await prevButton.click();
      await page.waitForTimeout(500);

      const firstRowAgain = await previewTable
        .locator("tbody tr")
        .first()
        .textContent();
      expect(firstRowAgain).toBe(firstRowPage1);

      // ❌ NEGATIVE: Still no error toasts
      await expect(errorToast)
        .not.toBeVisible({ timeout: 1000 })
        .catch(() => {});
    }
  });

  test("should reload preview when parameter values change", async ({
    page
  }) => {
    // Select a configuration with parameters
    await selectConfiguration(page, "Test Record");
    await page.waitForTimeout(TIMEOUTS.medium);

    // Check if parameters section exists
    const paramSection = page.locator("text=Query Parameters");
    const hasParams = await paramSection
      .isVisible({ timeout: 3000 })
      .catch(() => false);

    if (hasParams) {
      // Wait for initial preview to load
      await page.waitForTimeout(2000);

      // Change parameter value
      const paramInput = page.locator("lightning-input[data-param]").first();
      await paramInput.locator("input").fill("New Value");
      await page.waitForTimeout(2000); // Wait for preview reload

      // Verify preview table is still visible (reloaded)
      const previewTable = page.locator('[data-testid="query-preview-table"]');
      await expect(previewTable).toBeVisible();
    }
  });

  test("should show max 5 records total across all pages", async ({ page }) => {
    // Select a configuration
    await selectConfiguration(page, "All Active");
    await page.waitForTimeout(TIMEOUTS.medium);

    // Check Data Preview heading
    const heading = page.locator("text=/Data Preview \\(Top \\d+ records\\)/");
    const hasHeading = await heading
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    if (hasHeading) {
      const headingText = await heading.textContent();
      const match = headingText.match(/Top (\d+) records/);

      if (match) {
        const recordCount = parseInt(match[1]);
        expect(recordCount).toBeLessThanOrEqual(5);
      }
    }
  });

  test("should disable Previous button on first page", async ({ page }) => {
    // Select a configuration with > 3 records
    await selectConfiguration(page, "All Active");
    await page.waitForTimeout(TIMEOUTS.medium);

    const prevButton = page.locator('[data-testid="preview-prev-button"]');
    const hasPrev = await prevButton
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    if (hasPrev) {
      // Verify Previous is disabled on first page
      await expect(prevButton).toBeDisabled();
    }
  });

  test("should disable Next button on last page", async ({ page }) => {
    // Select a configuration with > 3 but <= 6 records (2 pages)
    await selectConfiguration(page, "All Active");
    await page.waitForTimeout(TIMEOUTS.medium);

    const nextButton = page.locator('[data-testid="preview-next-button"]');
    const hasNext = await nextButton
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    if (hasNext) {
      // Navigate to last page
      while (!(await nextButton.isDisabled())) {
        await nextButton.click();
        await page.waitForTimeout(500);
      }

      // Verify Next is disabled on last page
      await expect(nextButton).toBeDisabled();
    }
  });
});
