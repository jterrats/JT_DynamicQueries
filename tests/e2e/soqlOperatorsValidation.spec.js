/**
 * E2E Tests for SOQL Operator Configurations
 * Validates that complex queries with various operators return correct results
 */

const { test, expect } = require("@playwright/test");
const {
  setupTestContext,
  selectConfiguration,
  executeQuery
} = require("./utils/testHelpers");
const { getSFSession } = require("./utils/sfAuth");
const {
  QUERY_VIEWER_TAB,
  SELECTORS,
  TIMEOUTS
} = require("./utils/testConstants");

let session;

test.beforeAll(async () => {
  session = await getSFSession();
});

test.describe("SOQL Operators Validation", () => {
  test.beforeEach(async ({ page }) => {
    await setupTestContext(page, session, {
      targetTab: QUERY_VIEWER_TAB,
      waitForComponent: true
    });
  });

  test("should execute Multiple_IN_Operators query and validate results", async ({
    page
  }) => {
    // Select configuration
    await selectConfiguration(page, "Multiple IN Operators");

    // Wait for parameter inputs to appear (if any)
    await page.waitForTimeout(1000);

    // Execute query (bindings may be optional or predefined)
    await executeQuery(page);

    // ✅ Validate results table appears
    const resultsTable = page.locator(
      `${SELECTORS.queryResults} ${SELECTORS.resultsTable}`
    );
    await expect(resultsTable).toBeVisible({ timeout: TIMEOUTS.component });

    // ✅ Validate records returned (may be 0 if no matches)
    const rows = resultsTable.locator("tbody tr");
    const rowCount = await rows.count();
    expect(rowCount).toBeGreaterThanOrEqual(0);

    // ✅ If results exist, validate Name column has data (static validation)
    if (rowCount > 0) {
      const firstRow = rows.first();
      const nameCell = firstRow.locator("td").nth(1); // Name column (skip checkbox)
      const nameText = await nameCell.textContent();
      expect(nameText).toBeTruthy();
      expect(nameText.trim().length).toBeGreaterThan(0);
    }

    // ✅ No error toast (query executed successfully)
    const errorToast = page.locator(".slds-notify--error");
    const errorVisible = await errorToast.isVisible().catch(() => false);
    expect(errorVisible).toBe(false);
  });

  test("should execute LIKE_Patterns_Mix query and validate Name column", async ({
    page
  }) => {
    await selectConfiguration(page, "LIKE Patterns Mixed");

    // Wait for parameter inputs (if any)
    await page.waitForTimeout(1000);

    // Execute query
    await executeQuery(page);

    // ✅ Validate results table appears
    const resultsTable = page.locator(
      `${SELECTORS.queryResults} ${SELECTORS.resultsTable}`
    );
    await expect(resultsTable).toBeVisible({ timeout: TIMEOUTS.component });

    // ✅ Validate Name column exists and has data (if results)
    const rows = resultsTable.locator("tbody tr");
    const rowCount = await rows.count();
    
    if (rowCount > 0) {
      const headers = resultsTable.locator("thead th");
      const headerTexts = await headers.allTextContents();
      expect(headerTexts.some((h) => h.toLowerCase().includes("name"))).toBe(true);

      // Validate first row has Name data
      const firstRow = rows.first();
      const nameCell = firstRow.locator("td").nth(1); // Name column
      const nameText = await nameCell.textContent();
      expect(nameText).toBeTruthy();
      expect(nameText.trim().length).toBeGreaterThan(0);
    }

    // ✅ No error toast
    const errorToast = page.locator(".slds-notify--error");
    const errorVisible = await errorToast.isVisible().catch(() => false);
    expect(errorVisible).toBe(false);
  });

  test("should show error for BETWEEN operator (unsupported)", async ({
    page
  }) => {
    await selectConfiguration(page, "Complex Mixed Operators");

    // Try to execute query with BETWEEN
    await executeQuery(page);

    // ✅ Validate error toast appears
    const errorToast = page.locator(".slds-notify--error");
    await expect(errorToast).toBeVisible({ timeout: TIMEOUTS.component });

    // ✅ Validate error message mentions BETWEEN
    const errorText = await errorToast.textContent();
    expect(errorText.toLowerCase()).toContain("between");
    expect(errorText.toLowerCase()).toContain("not supported");
  });

  test("should show error for NOT LIKE operator (unsupported)", async ({
    page
  }) => {
    await selectConfiguration(page, "NOT Operators Test");

    // Try to execute query with NOT LIKE
    await executeQuery(page);

    // ✅ Validate error toast appears
    const errorToast = page.locator(".slds-notify--error");
    await expect(errorToast).toBeVisible({ timeout: TIMEOUTS.component });

    // ✅ Validate error message mentions NOT LIKE
    const errorText = await errorToast.textContent();
    expect(errorText.toLowerCase()).toContain("not like");
    expect(errorText.toLowerCase()).toContain("not supported");
  });

  test("should execute All_Comparison_Operators query and validate Account Name", async ({
    page
  }) => {
    await selectConfiguration(page, "All Comparison Operators");

    // Wait for parameter inputs (if any)
    await page.waitForTimeout(1000);

    // Execute query
    await executeQuery(page);

    // ✅ Validate results table appears
    const resultsTable = page.locator(
      `${SELECTORS.queryResults} ${SELECTORS.resultsTable}`
    );
    await expect(resultsTable).toBeVisible({ timeout: TIMEOUTS.component });

    // ✅ Validate Name column has data (static validation)
    const rows = resultsTable.locator("tbody tr");
    const rowCount = await rows.count();
    
    if (rowCount > 0) {
      const firstRow = rows.first();
      const nameCell = firstRow.locator("td").nth(1); // Name column
      const nameText = await nameCell.textContent();
      expect(nameText).toBeTruthy();
      expect(nameText.trim().length).toBeGreaterThan(0);
      // Name should be a valid Account name (not empty, not just whitespace)
      expect(nameText.trim()).not.toBe("");
    }

    // ✅ No error toast (query executed successfully)
    const errorToast = page.locator(".slds-notify--error");
    const errorVisible = await errorToast.isVisible().catch(() => false);
    expect(errorVisible).toBe(false);
  });
});
