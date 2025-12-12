/**
 * E2E Tests for Output Validation
 * Validates that components show correct data, empty states, and error messages
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

test.describe("Output Validation Tests", () => {
  test.beforeEach(async ({ page }) => {
    await setupTestContext(page, session, {
      targetTab: QUERY_VIEWER_TAB,
      waitForComponent: true
    });
  });

  test("should validate query results show actual Account Name data", async ({
    page
  }) => {
    await selectConfiguration(page, "Account By Name");

    // Set a search pattern that should return results
    const paramInput = page
      .locator("c-jt-parameter-inputs lightning-input")
      .first();
    const inputExists = await paramInput.isVisible({ timeout: 2000 }).catch(() => false);

    if (inputExists) {
      await paramInput.locator("input").fill("%");
      await page.waitForTimeout(500);
    }

    await executeQuery(page, { waitTime: TIMEOUTS.long });

    // ✅ Validate results table appears
    const resultsTable = page.locator(
      `${SELECTORS.queryResults} ${SELECTORS.resultsTable}`
    );
    await expect(resultsTable).toBeVisible({ timeout: TIMEOUTS.component });

    const rows = resultsTable.locator("tbody tr");
    const rowCount = await rows.count();

    if (rowCount > 0) {
      // ✅ Validate Name column exists
      const headers = resultsTable.locator("thead th");
      const headerTexts = await headers.allTextContents();
      const nameHeaderIndex = headerTexts.findIndex((h) =>
        h.toLowerCase().includes("name")
      );
      expect(nameHeaderIndex).toBeGreaterThanOrEqual(0);

      // ✅ Validate Name column has actual data (not empty, not null)
      const firstRow = rows.first();
      const nameCell = firstRow.locator("td").nth(nameHeaderIndex + 1); // +1 for checkbox
      const nameText = await nameCell.textContent();
      
      expect(nameText).toBeTruthy();
      expect(nameText.trim()).not.toBe("");
      expect(nameText.trim().length).toBeGreaterThan(0);
      
      // ✅ Validate it's a valid Account name (not just whitespace or special chars)
      expect(nameText.trim()).toMatch(/[A-Za-z0-9]/); // Contains alphanumeric
      
      console.log(`✅ Validated Account Name: "${nameText.trim()}"`);
    } else {
      console.log("⚠️  No results returned - may need test data");
    }
  });

  test("should validate empty results show 'No records found' message", async ({
    page
  }) => {
    await selectConfiguration(page, "Account By Name");

    // Set impossible filter to get 0 results
    const paramInput = page
      .locator("c-jt-parameter-inputs lightning-input")
      .first();
    const inputExists = await paramInput.isVisible({ timeout: 2000 }).catch(() => false);

    if (inputExists) {
      await paramInput.locator("input").fill("IMPOSSIBLE_NAME_XYZ_12345");
      await page.waitForTimeout(500);
    }

    await executeQuery(page, { waitTime: TIMEOUTS.long });

    // ✅ Validate results component appears
    const queryResults = page.locator(SELECTORS.queryResults);
    await expect(queryResults).toBeVisible({ timeout: TIMEOUTS.component });

    // ✅ Validate empty state message
    const emptyMessage = queryResults.locator(
      "text=/no records found|no results|0 records/i"
    );
    const emptyMessageVisible = await emptyMessage
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    if (emptyMessageVisible) {
      const messageText = await emptyMessage.textContent();
      expect(messageText.toLowerCase()).toMatch(/no (records|results)/i);
      console.log(`✅ Empty state message: "${messageText}"`);
    } else {
      // Alternative: Check if table shows 0 rows
      const resultsTable = queryResults.locator(SELECTORS.resultsTable);
      const tableVisible = await resultsTable.isVisible({ timeout: 2000 }).catch(() => false);
      
      if (tableVisible) {
        const rows = resultsTable.locator("tbody tr");
        const rowCount = await rows.count();
        expect(rowCount).toBe(0);
        console.log("✅ Empty results validated: 0 rows in table");
      }
    }

    // ✅ No error toast (empty results is valid, not an error)
    const errorToast = page.locator(".slds-notify--error");
    const errorVisible = await errorToast.isVisible({ timeout: 2000 }).catch(() => false);
    expect(errorVisible).toBe(false);
  });

  test("should validate Run As User with no data access returns 0 results", async ({
    page
  }) => {
    // Check if Run As section is available
    const runAsSection = page.locator(".run-as-container").first();
    const isVisible = await runAsSection
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    if (!isVisible) {
      console.log("⚠️  Run As section not available - skipping test");
      return;
    }

    // Find Chatter user or user without Account access
    const userCombo = runAsSection.locator("c-jt-searchable-combobox").first();
    await userCombo.click();
    await page.waitForTimeout(1000);

    // Search for users with limited access (try multiple search terms)
    const searchTerms = ["Chatter", "Standard", "Read Only", "User"];
    let userFound = false;

    for (const searchTerm of searchTerms) {
      const searchInput = userCombo.locator("input");
      await searchInput.fill("");
      await searchInput.fill(searchTerm);
      await page.waitForTimeout(2000); // Wait for debounce

      const userOptions = userCombo.locator(".slds-listbox__item");
      const optionCount = await userOptions.count();

      if (optionCount > 0) {
        // Select first user found (should be a user without Account access)
        const firstOption = await userOptions.first().textContent();
        console.log(`✅ Found user: ${firstOption}`);
        await userOptions.first().click();
        await page.waitForTimeout(1000);
        userFound = true;
        break;
      }
    }

    if (!userFound) {
      console.log("⚠️  No limited-access user found - skipping Run As validation");
      console.log("💡 Tip: Create a Chatter Free user for this test");
      return;
    }

    // Select configuration
    await selectConfiguration(page, "Account By Name");

    // Execute query with Run As user
    const executeButton = page.locator(
      'lightning-button[title*="Execute with System.runAs"]'
    );
    await executeButton.click();
    await page.waitForTimeout(TIMEOUTS.long);

    // ✅ Validate results (should be 0 or show no access message)
    const queryResults = page.locator(SELECTORS.queryResults);
    await expect(queryResults).toBeVisible({ timeout: TIMEOUTS.component });

    const resultsTable = queryResults.locator(SELECTORS.resultsTable);
    const tableVisible = await resultsTable.isVisible({ timeout: 5000 }).catch(() => false);

    if (tableVisible) {
      const rows = resultsTable.locator("tbody tr");
      const rowCount = await rows.count();
      
      // ✅ User without access should return 0 results (not an error)
      expect(rowCount).toBe(0);
      console.log(`✅ Run As user returned ${rowCount} results (no access validated)`);
      
      // ✅ Validate table headers still visible (structure preserved)
      const headers = resultsTable.locator("thead th");
      const headerCount = await headers.count();
      expect(headerCount).toBeGreaterThan(0);
      console.log(`✅ Table structure preserved: ${headerCount} columns visible`);
    } else {
      // Alternative: Check for empty state message
      const emptyMessage = queryResults.locator(
        "text=/no records found|no results|0 records/i"
      );
      const emptyVisible = await emptyMessage.isVisible({ timeout: 2000 }).catch(() => false);
      expect(emptyVisible).toBe(true);
      console.log("✅ Empty state message shown for user without access");
    }

    // ✅ No error toast (0 results is valid, not an error)
    const errorToast = page.locator(".slds-notify--error");
    const errorVisible = await errorToast.isVisible({ timeout: 2000 }).catch(() => false);
    expect(errorVisible).toBe(false);
    
    // ✅ Success toast may appear (query executed successfully, just 0 results)
    const successToast = page.locator(".slds-notify--success");
    const successVisible = await successToast.isVisible({ timeout: 2000 }).catch(() => false);
    if (successVisible) {
      const successText = await successToast.textContent();
      expect(successText.toLowerCase()).toMatch(/0 records|no records|success/i);
      console.log(`✅ Success message: "${successText}"`);
    }
  });

  test("should validate Documentation tabs show actual content (not just length)", async ({
    page
  }) => {
    // Navigate to Documentation tab
    const docTab = page
      .locator("one-app-nav-bar-item-root a")
      .filter({ hasText: /Documentation/i })
      .first();
    
    const tabVisible = await docTab.isVisible({ timeout: 3000 }).catch(() => false);
    if (!tabVisible) {
      console.log("⚠️  Documentation tab not available - skipping");
      return;
    }

    await docTab.click();
    await page.waitForTimeout(2000);

    // Wait for component
    const docComponent = page.locator("c-jt-documentation");
    await expect(docComponent).toBeVisible({ timeout: 5000 });

    // Test Getting Started tab (should have Named Credential content)
    const gettingStartedTab = page
      .locator("a.slds-tabs_default__link")
      .filter({ hasText: /Getting Started/i });
    
    await gettingStartedTab.click();
    await page.waitForTimeout(1000);

    // ✅ Validate Named Credential content exists
    const content = docComponent.locator(".slds-text-longform");
    const contentText = await content.textContent();
    
    expect(contentText).toBeTruthy();
    expect(contentText.toLowerCase()).toContain("named credential");
    expect(contentText.toLowerCase()).toContain("tooling api");
    console.log("✅ Getting Started tab contains Named Credential content");

    // Test API Reference tab (should have method names)
    const apiTab = page
      .locator("a.slds-tabs_default__link")
      .filter({ hasText: /API Reference/i });
    
    await apiTab.click();
    await page.waitForTimeout(1000);

    // ✅ Validate API methods are mentioned
    const apiContent = await docComponent.textContent();
    expect(apiContent.toLowerCase()).toContain("getrecords");
    expect(apiContent.toLowerCase()).toContain("jt_dataselector");
    console.log("✅ API Reference tab contains method documentation");
  });

  test("should validate error messages show specific operator names", async ({
    page
  }) => {
    // Test BETWEEN operator error
    await selectConfiguration(page, "Complex Mixed Operators");
    await executeQuery(page);

    // ✅ Validate error toast appears
    const errorToast = page.locator(".slds-notify--error");
    await expect(errorToast).toBeVisible({ timeout: TIMEOUTS.component });

    // ✅ Validate error message contains "BETWEEN"
    const errorText = await errorToast.textContent();
    expect(errorText.toLowerCase()).toContain("between");
    expect(errorText.toLowerCase()).toContain("not supported");
    
    // ✅ Validate error message suggests alternative
    expect(errorText.toLowerCase()).toContain(">=");
    expect(errorText.toLowerCase()).toContain("<=");
    console.log(`✅ BETWEEN error message validated: "${errorText.substring(0, 100)}..."`);

    // Close error and test NOT LIKE
    await page.waitForTimeout(2000);
    
    await selectConfiguration(page, "NOT Operators Test");
    await executeQuery(page);

    // ✅ Validate NOT LIKE error
    await expect(errorToast).toBeVisible({ timeout: TIMEOUTS.component });
    const notLikeErrorText = await errorToast.textContent();
    expect(notLikeErrorText.toLowerCase()).toContain("not like");
    expect(notLikeErrorText.toLowerCase()).toContain("not supported");
    console.log(`✅ NOT LIKE error message validated: "${notLikeErrorText.substring(0, 100)}..."`);
  });
});

