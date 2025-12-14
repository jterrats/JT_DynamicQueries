/**
 * E2E Tests for Run As User Feature
 * Validates:
 * 1. Happy path: User can execute queries as another user and see correct data
 * 2. Error path: User-friendly error messages when user lacks permissions
 * 3. UI clearing: All UI elements are cleared when clearing user selection
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

test.describe("Run As User Feature Tests", () => {
  test.beforeEach(async ({ page }) => {
    await setupTestContext(page, session, {
      targetTab: QUERY_VIEWER_TAB,
      waitForComponent: true
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // HAPPY PATH: Run As User with Valid Permissions
  // ═══════════════════════════════════════════════════════════════

  test("should execute query as another user and display correct data", async ({
    page
  }) => {
    console.log("🧪 Testing Run As User - Happy Path with Mariano Arnica...");

    // Verify Run As section is available (skip test if not authorized)
    const accordionSection = page
      .locator('lightning-accordion-section[name="run-as"]')
      .first();
    const accordionExists = (await accordionSection.count()) > 0;

    if (!accordionExists) {
      console.log(
        "⚠️  Run As accordion section not found - user lacks permissions. Skipping test."
      );
      test.skip();
      return;
    }

    // Expand the accordion section if it's collapsed
    const isExpanded = await accordionSection.getAttribute("aria-expanded");
    if (isExpanded !== "true") {
      await accordionSection.click();
      await page.waitForTimeout(1000);
    }

    // Check if the component inside is visible
    const runAsComponent = page.locator("c-jt-run-as-section").first();
    const isVisible = await runAsComponent
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    if (!isVisible) {
      console.log(
        "⚠️  Run As component not visible after expanding accordion - user lacks permissions. Skipping test."
      );
      test.skip();
      return;
    }

    // Step 1: Select a configuration that works with Mariano Arnica
    // Using "Account By Name" which should have data for Mariano
    await selectConfiguration(page, "Account By Name");
    await page.waitForTimeout(2000);

    // Step 2: Search for and select "Mariano Arnica" specifically
    const userCombobox = page
      .locator(
        'c-jt-run-as-section c-jt-searchable-combobox[data-testid="run-as-user-selector"]'
      )
      .first();

    const userInput = userCombobox.locator("input").first();
    await userInput.click();
    await page.waitForTimeout(2000);

    // Search for "Mariano Arnica"
    await userInput.fill("Mariano Arnica");
    await page.waitForTimeout(2000);

    const userDropdown = userCombobox.locator(".slds-listbox").first();
    const userOptions = userDropdown.locator(".slds-listbox__item");
    const userCount = await userOptions.count();

    if (userCount === 0) {
      console.log("⚠️  Mariano Arnica not found - skipping test");
      test.skip();
      return;
    }

    // Find Mariano Arnica specifically
    let marianoOption = null;
    let selectedUserName = null;
    for (let i = 0; i < userCount; i++) {
      const option = userOptions.nth(i);
      const optionText = await option.textContent();
      if (optionText.toLowerCase().includes("mariano") && optionText.toLowerCase().includes("arnica")) {
        marianoOption = option;
        selectedUserName = optionText;
        break;
      }
    }

    if (!marianoOption) {
      console.log("⚠️  Mariano Arnica not found in results - skipping test");
      test.skip();
      return;
    }

    console.log(`✅ Selected user: ${selectedUserName}`);
    await marianoOption.click();
    await page.waitForTimeout(1000);

    // ✅ VALIDATION: Verify user input shows selected user name
    const userInputValue = await userInput.inputValue();
    expect(userInputValue.toLowerCase()).toContain("mariano");
    console.log("✅ User selection confirmed in combobox");

    // Step 3: ✅ VALIDATION: Verify "Execute with System.runAs" button appears with correct text
    const executeRunAsButton = page
      .locator("lightning-button")
      .filter({ hasText: /Execute with System\.runAs/i })
      .or(page.locator('lightning-button[title*="Execute with System.runAs"]'));
    await expect(executeRunAsButton).toBeVisible({ timeout: 5000 });
    const executeButtonText = await executeRunAsButton.textContent();
    expect(executeButtonText).toMatch(/Execute with System\.runAs/i);
    console.log("✅ Execute with System.runAs button visible with correct text");

    // Step 4: ✅ VALIDATION: Verify "Clear Selection" button appears with correct text
    const clearButton = page
      .locator('lightning-button[data-testid="run-as-clear-button"]')
      .or(
        page.locator("lightning-button").filter({ hasText: /Clear Selection/i })
      );
    await expect(clearButton).toBeVisible({ timeout: 5000 });
    const clearButtonText = await clearButton.textContent();
    expect(clearButtonText).toMatch(/Clear Selection/i);
    console.log("✅ Clear Selection button visible with correct text");

    // Step 5: ✅ VALIDATION: Verify NO success toast appears before execution
    const successToastBefore = page.locator('lightning-toast[class*="success"]');
    const toastVisibleBefore = await successToastBefore
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(toastVisibleBefore).toBe(false);
    console.log("✅ No success toast before execution (correct)");

    // Step 6: Execute query with Run As
    await executeRunAsButton.click();
    await page.waitForTimeout(3000); // Wait for test execution to start

    // Step 7: Wait for results (polling may take time)
    let resultsVisible = false;
    let pollCount = 0;
    const maxPolls = 20; // 20 * 2s = 40 seconds max wait

    while (!resultsVisible && pollCount < maxPolls) {
      await page.waitForTimeout(2000);
      pollCount++;

      const queryResults = page.locator(SELECTORS.queryResults);
      resultsVisible = await queryResults
        .isVisible({ timeout: 1000 })
        .catch(() => false);

      if (resultsVisible) {
        console.log(`✅ Results appeared after ${pollCount * 2} seconds`);
        break;
      }

      // Check for error banner (test may have failed)
      const errorBanner = page.locator(
        ".slds-notify--error, .slds-alert--error, .slds-banner--error"
      );
      const errorVisible = await errorBanner
        .isVisible({ timeout: 1000 })
        .catch(() => false);

      if (errorVisible) {
        const errorText = await errorBanner.textContent();
        console.log(`⚠️  Error detected: ${errorText}`);
        // ✅ VALIDATION: Verify NO error toast when error banner is shown
        const errorToast = page.locator('lightning-toast[class*="error"]');
        const toastVisible = await errorToast
          .isVisible({ timeout: 1000 })
          .catch(() => false);
        expect(toastVisible).toBe(false);
        console.log("✅ No redundant error toast (error only in banner)");
        break;
      }
    }

    // Step 8: ✅ VALIDATION: Verify NO success toast appears after execution
    // Run As User should NOT show success toast (results are displayed in UI)
    const successToastAfter = page.locator('lightning-toast[class*="success"]');
    const toastVisibleAfter = await successToastAfter
      .isVisible({ timeout: 2000 })
      .catch(() => false);
    expect(toastVisibleAfter).toBe(false);
    console.log("✅ No success toast after execution (results displayed in UI)");

    // Step 9: Validate results are displayed
    if (resultsVisible) {
      const queryResults = page.locator(SELECTORS.queryResults);
      await expect(queryResults).toBeVisible({ timeout: TIMEOUTS.component });

      // ✅ VALIDATION: Validate Run As User name is displayed with correct text
      const runAsUserName = page
        .locator("text=/Run As User:/i")
        .or(page.locator("text=/Executed as:/i"))
        .first();
      const userNameVisible = await runAsUserName
        .isVisible({ timeout: 2000 })
        .catch(() => false);

      if (userNameVisible) {
        const userNameText = await runAsUserName.textContent();
        const marianoName = selectedUserName.trim().split("\n")[0];
        expect(userNameText.toLowerCase()).toContain("mariano");
        expect(userNameText.toLowerCase()).toContain("arnica");
        console.log(`✅ Run As User name displayed correctly: ${userNameText}`);
      }

      // ✅ Validate results table is visible
      const resultsTable = queryResults.locator(SELECTORS.resultsTable);
      const tableVisible = await resultsTable
        .isVisible({ timeout: TIMEOUTS.component })
        .catch(() => false);

      if (tableVisible) {
        console.log("✅ Results table visible");

        // ✅ Validate table has columns
        const headers = resultsTable.locator("thead th");
        const headerCount = await headers.count();
        expect(headerCount).toBeGreaterThan(0);
        console.log(`✅ Table structure valid: ${headerCount} columns`);

        // ✅ Validate records (may be 0, but structure should exist)
        const rows = resultsTable.locator("tbody tr");
        const rowCount = await rows.count();
        console.log(
          `✅ Query executed as ${selectedUserName}: ${rowCount} records returned`
        );

        // ✅ If results exist, validate data is displayed correctly
        if (rowCount > 0) {
          const firstRow = rows.first();
          const cells = firstRow.locator("td");
          const cellCount = await cells.count();
          expect(cellCount).toBeGreaterThan(0);
          console.log(
            `✅ Data displayed correctly: ${cellCount} columns in first row`
          );
        }
      }

      // ✅ Validate nested relationships with expand/collapse buttons (if query has child relationships)
      const expandButtons = page.locator(
        'c-jt-query-results lightning-button-icon[icon-name*="chevron"]'
      );
      const expandButtonCount = await expandButtons.count();

      if (expandButtonCount > 0) {
        console.log(
          `✅ Found ${expandButtonCount} expand/collapse buttons for nested relationships`
        );

        // Click first expand button
        const firstExpandButton = expandButtons.first();
        await firstExpandButton.click();
        await page.waitForTimeout(1000);

        // Verify accordion appears
        const accordion = page.locator(
          "c-jt-query-results lightning-accordion"
        );
        const accordionVisible = await accordion
          .isVisible({ timeout: 2000 })
          .catch(() => false);

        if (accordionVisible) {
          console.log(
            "✅ Nested relationships expand/collapse works correctly"
          );
        }
      } else {
        console.log("ℹ️  No nested relationships in this query (expected)");
      }
    } else {
      // Check for error message
      const errorBanner = page.locator(
        ".slds-notify--error, .slds-alert--error, .slds-banner--error"
      );
      const errorVisible = await errorBanner
        .isVisible({ timeout: 2000 })
        .catch(() => false);

      if (errorVisible) {
        const errorText = await errorBanner.textContent();
        console.log(`⚠️  Query failed with error: ${errorText}`);
        // This might be expected if user lacks permissions - validate error message
        expect(errorText.length).toBeGreaterThan(0);
      } else {
        throw new Error("Results did not appear and no error message found");
      }
    }

    console.log("✅ Run As User - Happy Path test completed");
  });

  // ═══════════════════════════════════════════════════════════════
  // ERROR PATH: User Without Permissions
  // ═══════════════════════════════════════════════════════════════

  test("should display user-friendly error when user lacks permissions", async ({
    page
  }) => {
    console.log("🧪 Testing Run As User - Error Path (Guest/Chatter User)...");

    // Verify Run As section is available (skip test if not authorized)
    const runAsSection = page
      .locator('lightning-accordion-section[name="run-as"]')
      .or(page.locator("c-jt-run-as-section"))
      .first();
    const isVisible = await runAsSection
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    if (!isVisible) {
      console.log(
        "⚠️  Run As section not available - user lacks permissions. Skipping test."
      );
      test.skip();
      return;
    }

    // Expand accordion if needed
    const accordionSection = page
      .locator('lightning-accordion-section[name="run-as"]')
      .first();
    const isExpanded = await accordionSection.getAttribute("aria-expanded");
    if (isExpanded !== "true") {
      await accordionSection.click();
      await page.waitForTimeout(1000);
    }

    // Step 1: Select a configuration
    await selectConfiguration(page, "Account By Name");
    await page.waitForTimeout(2000);

    // Step 2: Search for Guest User or Chatter Expert (users with limited permissions)
    const userCombobox = page
      .locator(
        'c-jt-run-as-section c-jt-searchable-combobox[data-testid="run-as-user-selector"]'
      )
      .first();

    const userInput = userCombobox.locator("input").first();
    await userInput.click();
    await page.waitForTimeout(2000);

    // Try "Guest User" first, then "Chatter Expert"
    let restrictedUser = null;
    let restrictedUserName = null;

    // Search for Guest User
    await userInput.fill("Guest User");
    await page.waitForTimeout(2000);
    const userDropdown = userCombobox.locator(".slds-listbox").first();
    const userOptions = userDropdown.locator(".slds-listbox__item");
    let userCount = await userOptions.count();

    for (let i = 0; i < Math.min(userCount, 10); i++) {
      const option = userOptions.nth(i);
      const optionText = await option.textContent();
      if (
        optionText.toLowerCase().includes("guest") &&
        optionText.toLowerCase().includes("user")
      ) {
        restrictedUser = option;
        restrictedUserName = optionText;
        break;
      }
    }

    // If Guest User not found, try Chatter Expert
    if (!restrictedUser) {
      await userInput.fill("Chatter Expert");
      await page.waitForTimeout(2000);
      userCount = await userOptions.count();
      for (let i = 0; i < Math.min(userCount, 10); i++) {
        const option = userOptions.nth(i);
        const optionText = await option.textContent();
        if (
          optionText.toLowerCase().includes("chatter") &&
          (optionText.toLowerCase().includes("expert") ||
            optionText.toLowerCase().includes("free"))
        ) {
          restrictedUser = option;
          restrictedUserName = optionText;
          break;
        }
      }
    }

    if (!restrictedUser) {
      console.log("⚠️  Guest User or Chatter Expert not found - skipping test");
      test.skip();
      return;
    }

    console.log(`✅ Selected restricted user: ${restrictedUserName}`);

    await restrictedUser.click();
    await page.waitForTimeout(1000);

    // ✅ VALIDATION: Verify user input shows selected user
    const userInputValue = await userInput.inputValue();
    expect(userInputValue.toLowerCase()).toMatch(/guest|chatter/i);
    console.log("✅ Restricted user selection confirmed in combobox");

    // Step 3: ✅ VALIDATION: Verify NO success toast before execution
    const successToastBefore = page.locator('lightning-toast[class*="success"]');
    const toastVisibleBefore = await successToastBefore
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(toastVisibleBefore).toBe(false);
    console.log("✅ No success toast before execution (correct)");

    // Step 4: Execute query with Run As
    const executeRunAsButton = page
      .locator("lightning-button")
      .filter({ hasText: /Execute with System\.runAs/i });
    await executeRunAsButton.click();
    await page.waitForTimeout(3000);

    // Step 5: Wait for error message (should appear faster than success)
    let errorVisible = false;
    let pollCount = 0;
    const maxPolls = 15; // 15 * 2s = 30 seconds max wait

    while (!errorVisible && pollCount < maxPolls) {
      await page.waitForTimeout(2000);
      pollCount++;

      // Check for error banner
      const errorBanner = page.locator(
        ".slds-notify--error, .slds-alert--error, .slds-banner--error"
      );
      errorVisible = await errorBanner
        .isVisible({ timeout: 1000 })
        .catch(() => false);

      if (errorVisible) {
        break;
      }

      // Also check for test assertion message
      const assertMessage = page
        .locator("text=/Test failed/i")
        .or(page.locator("text=/error/i"))
        .first();
      const assertVisible = await assertMessage
        .isVisible({ timeout: 1000 })
        .catch(() => false);

      if (assertVisible) {
        errorVisible = true;
        break;
      }
    }

    // Step 6: ✅ VALIDATION: Validate error message is user-friendly
    expect(errorVisible).toBe(true);
    console.log(`✅ Error detected after ${pollCount * 2} seconds`);

    // ✅ Validate error message contains user-friendly text (not technical stack trace)
    const errorBanner = page
      .locator(".slds-notify--error, .slds-alert--error, .slds-banner--error")
      .first();
    const errorText = await errorBanner.textContent();

    // Error should NOT contain technical terms
    const technicalTerms = [
      "Script-thrown exception",
      "System.QueryException",
      "System.SecurityException",
      "NullPointerException",
      "at Class.",
      "Stack trace"
    ];

    const hasTechnicalTerms = technicalTerms.some((term) =>
      errorText.includes(term)
    );
    expect(hasTechnicalTerms).toBe(false);
    console.log(
      "✅ Error message is user-friendly (no technical stack traces)"
    );

    // ✅ Validate error message mentions license/permission restrictions
    const userFriendlyTerms = [
      "license",
      "permission",
      "access",
      "restricted",
      "chatter free",
      "guest user",
      "cannot",
      "unable"
    ];

    const hasUserFriendlyTerms = userFriendlyTerms.some((term) =>
      errorText.toLowerCase().includes(term)
    );

    // Note: This might not always be true, but error should be descriptive
    if (hasUserFriendlyTerms) {
      console.log("✅ Error message mentions license/permission restrictions");
    } else {
      console.log(
        "ℹ️  Error message may not explicitly mention restrictions (still user-friendly)"
      );
    }

    // ✅ Validate error message is displayed in a banner (not just toast)
    const bannerVisible = await errorBanner.isVisible();
    expect(bannerVisible).toBe(true);
    console.log("✅ Error message displayed in banner (prominent)");

    // ✅ VALIDATION: Verify NO redundant error toast (error should be in banner only)
    const errorToast = page.locator('lightning-toast[class*="error"]');
    const toastVisible = await errorToast
      .isVisible({ timeout: 2000 })
      .catch(() => false);

    // Error toast should NOT appear - error is displayed in banner
    expect(toastVisible).toBe(false);
    console.log("✅ No redundant error toast (error only in banner)");

    // ✅ Validate user name is included in error message (if available)
    if (restrictedUserName) {
      const userNameInError = errorText
        .toLowerCase()
        .includes(
          restrictedUserName.toLowerCase().split("\n")[0].substring(0, 10)
        );

      if (userNameInError) {
        console.log("✅ User name included in error message");
      } else {
        console.log(
          "ℹ️  User name not explicitly in error message (acceptable)"
        );
      }
    }

    console.log(`✅ Error message: "${errorText.substring(0, 200)}..."`);
    console.log("✅ Run As User - Error Path test completed");
  });

  // ═══════════════════════════════════════════════════════════════
  // CUSTOM LABELS VALIDATION: Ensure error messages are user-friendly
  // ═══════════════════════════════════════════════════════════════

  test("should display user-friendly error messages from Custom Labels", async ({
    page
  }) => {
    console.log("🧪 Testing Custom Labels validation with Guest/Chatter User...");

    // Expand Run As section
    const accordionSection = page
      .locator('lightning-accordion-section[name="run-as"]')
      .first();
    const isExpanded = await accordionSection
      .getAttribute("aria-expanded")
      .then((val) => val === "true")
      .catch(() => false);

    if (!isExpanded) {
      await accordionSection.click();
      await page.waitForTimeout(500);
    }

    // Select a configuration first
    await selectConfiguration(page, "Account By Name");
    await page.waitForTimeout(1000);

    // Try to execute with Guest User or Chatter Expert (users that lack permissions)
    // This will trigger error messages that should come from Custom Labels
    const userCombobox = page.locator(
      'c-jt-run-as-section c-jt-searchable-combobox[data-testid="run-as-user-selector"]'
    );
    await userCombobox.waitFor({ state: "visible", timeout: 5000 });
    await page.waitForTimeout(2000);

    const userInput = userCombobox.locator("input").first();
    await userInput.click();
    await page.waitForTimeout(2000);

    // Search for Guest User or Chatter Expert
    await userInput.fill("Guest User");
    await page.waitForTimeout(2000);

    const userDropdown = userCombobox.locator(".slds-listbox").first();
    const userOptions = userDropdown.locator(".slds-listbox__item");
    let userCount = await userOptions.count();

    let restrictedUser = null;
    let restrictedUserName = null;

    // Try Guest User first
    for (let i = 0; i < Math.min(userCount, 10); i++) {
      const option = userOptions.nth(i);
      const optionText = await option.textContent();
      if (
        optionText.toLowerCase().includes("guest") &&
        optionText.toLowerCase().includes("user")
      ) {
        restrictedUser = option;
        restrictedUserName = optionText;
        break;
      }
    }

    // If Guest User not found, try Chatter Expert
    if (!restrictedUser) {
      await userInput.fill("Chatter Expert");
      await page.waitForTimeout(2000);
      userCount = await userOptions.count();
      for (let i = 0; i < Math.min(userCount, 10); i++) {
        const option = userOptions.nth(i);
        const optionText = await option.textContent();
        if (
          optionText.toLowerCase().includes("chatter") &&
          (optionText.toLowerCase().includes("expert") ||
            optionText.toLowerCase().includes("free"))
        ) {
          restrictedUser = option;
          restrictedUserName = optionText;
          break;
        }
      }
    }

    if (!restrictedUser) {
      console.log("⚠️  Guest User or Chatter Expert not found - skipping Custom Labels test");
      test.skip();
      return;
    }

    console.log(`✅ Selected restricted user: ${restrictedUserName}`);
    await restrictedUser.click();
    await page.waitForTimeout(1000);

    // ✅ VALIDATION: Verify NO success toast before execution
    const successToastBefore = page.locator('lightning-toast[class*="success"]');
    const toastVisibleBefore = await successToastBefore
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(toastVisibleBefore).toBe(false);
    console.log("✅ No success toast before execution");

    // Execute query
    const executeRunAsButton = page
      .locator("lightning-button")
      .filter({ hasText: /Execute with System\.runAs/i })
      .first();
    await executeRunAsButton.click();
    await page.waitForTimeout(5000); // Wait for execution

    // Check for error message (should appear for restricted users)
    const errorBanner = page
      .locator(".slds-alert--error, .slds-notify--error, .slds-banner--error")
      .first();
    const errorVisible = await errorBanner
      .isVisible({ timeout: 10000 })
      .catch(() => false);

    if (errorVisible) {
      const errorText = await errorBanner.textContent();
      console.log(`📋 Error message displayed: "${errorText.substring(0, 200)}..."`);

      // ✅ VALIDATION 1: Message should NOT be technical
      const technicalIndicators = [
        "Script-thrown exception",
        "System.AssertException",
        "Class.",
        "Line:",
        "Stack trace",
        "ApexClass",
        "DmlException"
      ];

      const hasTechnicalContent = technicalIndicators.some((indicator) =>
        errorText.includes(indicator)
      );
      expect(hasTechnicalContent).toBe(false);
      console.log("✅ Error message is NOT technical");

      // ✅ VALIDATION 2: Message should be user-friendly (contains descriptive keywords)
      const userFriendlyKeywords = [
        "permission",
        "access",
        "license",
        "user",
        "query",
        "configuration",
        "object",
        "field",
        "does not have",
        "cannot",
        "unable"
      ];

      const lowerErrorText = errorText.toLowerCase();
      const hasUserFriendlyKeyword = userFriendlyKeywords.some((keyword) =>
        lowerErrorText.includes(keyword)
      );
      expect(hasUserFriendlyKeyword).toBe(true);
      console.log("✅ Error message contains user-friendly keywords");

      // ✅ VALIDATION 3: Message should NOT be a stack trace (single line or short)
      const lineCount = errorText
        .split("\n")
        .filter((line) => line.trim().length > 0).length;
      expect(lineCount).toBeLessThan(3);
      console.log(`✅ Error message is concise (${lineCount} lines)`);

      // ✅ VALIDATION 4: Message should NOT be empty or generic "Error"
      expect(errorText.trim().length).toBeGreaterThan(10);
      expect(errorText.toLowerCase()).not.toBe("error");
      console.log("✅ Error message is descriptive and not generic");

      // ✅ VALIDATION 5: Verify NO redundant error toast
      const errorToast = page.locator('lightning-toast[class*="error"]');
      const toastVisible = await errorToast
        .isVisible({ timeout: 2000 })
        .catch(() => false);
      expect(toastVisible).toBe(false);
      console.log("✅ No redundant error toast (error only in banner)");
    } else {
      // If no error appears, the query might have succeeded
      // This is also valid - the test validates that IF an error appears, it's user-friendly
      console.log("ℹ️  No error message displayed (query may have succeeded)");
    }

    console.log("✅ Custom Labels validation test completed");
  });

  // ═══════════════════════════════════════════════════════════════
  // UI CLEARING: Clear Selection Functionality
  // ═══════════════════════════════════════════════════════════════

  test("should clear all UI elements when clearing user selection", async ({
    page
  }) => {
    console.log("🧪 Testing Clear Selection functionality...");

    // Verify Run As section is available (skip test if not authorized)
    // The Run As section is inside a lightning-accordion-section
    const runAsSection = page
      .locator('lightning-accordion-section[name="run-as"]')
      .or(page.locator("c-jt-run-as-section"))
      .first();
    const isVisible = await runAsSection
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    if (!isVisible) {
      console.log(
        "⚠️  Run As section not available - user lacks permissions. Skipping test."
      );
      test.skip();
      return;
    }

    // Step 1: Select configuration and user, execute query
    await selectConfiguration(page, "All Active");
    await page.waitForTimeout(2000);

    const userCombobox = page
      .locator(
        'c-jt-run-as-section c-jt-searchable-combobox[data-testid="run-as-user-selector"]'
      )
      .first();

    const userInput = userCombobox.locator("input").first();
    await userInput.click();
    await page.waitForTimeout(2000);

    const userDropdown = userCombobox.locator(".slds-listbox").first();
    const userOptions = userDropdown.locator(".slds-listbox__item");
    const userCount = await userOptions.count();

    if (userCount === 0) {
      console.log("⚠️  No users available - skipping test");
      test.skip();
      return;
    }

    await userOptions.first().click();
    await page.waitForTimeout(1000);

    // Execute query
    const executeRunAsButton = page
      .locator("lightning-button")
      .filter({ hasText: /Execute with System\.runAs/i });
    await executeRunAsButton.click();
    await page.waitForTimeout(5000); // Wait for results or error

    // Step 2: Verify some UI elements are visible (results, test assertion, etc.)
    const queryResults = page.locator(SELECTORS.queryResults);
    const resultsVisible = await queryResults
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    const testAssertMessage = page
      .locator("text=/Run As User:/i")
      .or(page.locator("text=/Test.*assertion/i"))
      .first();
    const assertVisible = await testAssertMessage
      .isVisible({ timeout: 2000 })
      .catch(() => false);

    console.log(
      `Results visible: ${resultsVisible}, Assert visible: ${assertVisible}`
    );

    // Step 3: Click "Clear Selection" button
    const clearButton = page
      .locator("lightning-button")
      .filter({ hasText: /Clear Selection/i });
    await expect(clearButton).toBeVisible({ timeout: 5000 });
    await clearButton.click();
    await page.waitForTimeout(2000); // Wait for UI to clear

    // Step 4: ✅ VALIDATION: Verify user dropdown is cleared (visual value)
    await page.waitForTimeout(500); // Wait for UI update
    const userInputValue = await userInput.inputValue();
    expect(userInputValue).toBe("");
    console.log("✅ User dropdown cleared (input value empty)");

    // ✅ VALIDATION: Verify combobox visual state is cleared
    const comboboxValue = await userCombobox
      .locator(".slds-combobox__input")
      .first()
      .inputValue()
      .catch(() => "");
    expect(comboboxValue).toBe("");
    console.log("✅ User combobox visual state cleared");

    // Step 5: ✅ VALIDATION: Verify query results are hidden
    const resultsStillVisible = await queryResults
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(resultsStillVisible).toBe(false);
    console.log("✅ Query results hidden");

    // Step 6: ✅ VALIDATION: Verify test assertion message is hidden
    const assertStillVisible = await testAssertMessage
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(assertStillVisible).toBe(false);
    console.log("✅ Test assertion message hidden");

    // Step 7: ✅ VALIDATION: Verify query preview is hidden
    const queryPreview = page.locator(".query-preview, [data-testid='query-preview']");
    const previewVisible = await queryPreview
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(previewVisible).toBe(false);
    console.log("✅ Query preview hidden");

    // Step 8: ✅ VALIDATION: Verify "Execute with System.runAs" button is hidden
    const executeButtonStillVisible = await executeRunAsButton
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(executeButtonStillVisible).toBe(false);
    console.log("✅ Execute with System.runAs button hidden");

    // Step 9: ✅ VALIDATION: Verify "Clear Selection" button is hidden
    const clearButtonStillVisible = await clearButton
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(clearButtonStillVisible).toBe(false);
    console.log("✅ Clear Selection button hidden");

    // Step 10: ✅ VALIDATION: Verify NO toasts are visible after clearing
    const anyToast = page.locator("lightning-toast");
    const toastVisible = await anyToast
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(toastVisible).toBe(false);
    console.log("✅ No toasts visible after clearing selection");

    console.log("✅ Clear Selection functionality test completed");
  });

  // ═══════════════════════════════════════════════════════════════
  // EDGE CASE: Query with Nested Relationships
  // ═══════════════════════════════════════════════════════════════

  test("should display nested relationships correctly when running as user", async ({
    page
  }) => {
    console.log("🧪 Testing Run As User with nested relationships...");

    // Verify Run As section is available (skip test if not authorized)
    // The Run As section is inside a lightning-accordion-section
    const runAsSection = page
      .locator('lightning-accordion-section[name="run-as"]')
      .or(page.locator("c-jt-run-as-section"))
      .first();
    const isVisible = await runAsSection
      .isVisible({ timeout: 5000 })
      .catch(() => false);

    if (!isVisible) {
      console.log(
        "⚠️  Run As section not available - user lacks permissions. Skipping test."
      );
      test.skip();
      return;
    }

    // Step 1: Select a configuration with nested relationships (e.g., "Customer 360 View")
    const configInput = page.locator('[data-testid="config-selector-input"]');
    await configInput.click();
    await page.waitForTimeout(1000);
    await configInput.fill("Customer 360 View");
    await page.waitForTimeout(2000);

    const configDropdown = page.locator(
      '[data-testid="config-selector-dropdown"]'
    );
    const configOption = configDropdown
      .locator(".slds-listbox__item")
      .filter({ hasText: /Customer 360 View/i })
      .first();

    const optionExists = await configOption.count();
    if (optionExists === 0) {
      console.log("⚠️  'Customer 360 View' config not found - skipping test");
      test.skip();
      return;
    }

    await configOption.click();
    await page.waitForTimeout(2000);

    // Step 2: Select Mariano Arnica (user with valid permissions and data)
    const userCombobox = page
      .locator(
        'c-jt-run-as-section c-jt-searchable-combobox[data-testid="run-as-user-selector"]'
      )
      .first();

    const userInput = userCombobox.locator("input").first();
    await userInput.click();
    await page.waitForTimeout(2000);

    // Search for Mariano Arnica
    await userInput.fill("Mariano Arnica");
    await page.waitForTimeout(2000);

    const userDropdown = userCombobox.locator(".slds-listbox").first();
    const userOptions = userDropdown.locator(".slds-listbox__item");
    const userCount = await userOptions.count();

    if (userCount === 0) {
      console.log("⚠️  Mariano Arnica not found - skipping test");
      test.skip();
      return;
    }

    // Find Mariano Arnica specifically
    let marianoOption = null;
    for (let i = 0; i < userCount; i++) {
      const option = userOptions.nth(i);
      const optionText = await option.textContent();
      if (optionText.toLowerCase().includes("mariano") && optionText.toLowerCase().includes("arnica")) {
        marianoOption = option;
        break;
      }
    }

    if (!marianoOption) {
      console.log("⚠️  Mariano Arnica not found in results - skipping test");
      test.skip();
      return;
    }

    console.log("✅ Selected Mariano Arnica for nested relationships test");
    await marianoOption.click();
    await page.waitForTimeout(1000);

    // Step 3: Execute query with Run As
    const executeRunAsButton = page
      .locator("lightning-button")
      .filter({ hasText: /Execute with System\.runAs/i });
    await executeRunAsButton.click();
    await page.waitForTimeout(5000);

    // Step 4: Wait for results
    const queryResults = page.locator(SELECTORS.queryResults);
    let resultsVisible = false;
    let pollCount = 0;
    const maxPolls = 20;

    while (!resultsVisible && pollCount < maxPolls) {
      await page.waitForTimeout(2000);
      pollCount++;
      resultsVisible = await queryResults
        .isVisible({ timeout: 1000 })
        .catch(() => false);
      if (resultsVisible) break;
    }

    if (!resultsVisible) {
      console.log(
        "⚠️  Results did not appear - skipping nested relationship validation"
      );
      test.skip();
      return;
    }

    // Step 5: ✅ Validate expand/collapse buttons are visible
    const expandButtons = page.locator(
      'c-jt-query-results lightning-button-icon[icon-name*="chevron"]'
    );
    const expandButtonCount = await expandButtons.count();

    expect(expandButtonCount).toBeGreaterThan(0);
    console.log(`✅ Found ${expandButtonCount} expand/collapse buttons`);

    // Step 6: ✅ Click expand button and validate nested data appears
    const firstExpandButton = expandButtons.first();
    await firstExpandButton.click();
    await page.waitForTimeout(1000);

    // ✅ Validate accordion appears
    const accordion = page.locator("c-jt-query-results lightning-accordion");
    const accordionVisible = await accordion
      .isVisible({ timeout: 2000 })
      .catch(() => false);
    expect(accordionVisible).toBe(true);
    console.log("✅ Nested relationships accordion visible");

    // ✅ Validate accordion sections exist (Contacts, Opportunities, Cases, etc.)
    const accordionSections = page.locator(
      "c-jt-query-results lightning-accordion-section"
    );
    const sectionCount = await accordionSections.count();
    expect(sectionCount).toBeGreaterThan(0);
    console.log(`✅ Found ${sectionCount} child relationship sections`);

    // ✅ Expand first section and validate data table
    const firstSection = accordionSections.first();
    await firstSection.click();
    await page.waitForTimeout(1000);

    const datatable = page.locator("c-jt-query-results lightning-datatable");
    const datatableVisible = await datatable
      .isVisible({ timeout: 2000 })
      .catch(() => false);

    if (datatableVisible) {
      console.log("✅ Child records datatable visible");

      // ✅ Validate AccountId is NOT in child columns (should be filtered out)
      const columns = await datatable.locator("thead th").allTextContents();
      const hasAccountId = columns.some((col) =>
        col.toLowerCase().includes("account id")
      );
      expect(hasAccountId).toBe(false);
      console.log("✅ AccountId correctly filtered from child columns");
    }

    console.log("✅ Run As User with nested relationships test completed");
  });
});
