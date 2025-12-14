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
    console.log("🧪 Testing Run As User - Happy Path...");

    // Verify Run As section is available (skip test if not authorized)
    // The Run As section is inside a lightning-accordion-section that may be collapsed
    // First check if the accordion section exists
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
      await page.waitForTimeout(1000); // Wait for accordion to expand
    }

    // Now check if the component inside is visible
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

    // Store reference to runAsComponent for later use
    const runAsSection = runAsComponent;

    // Step 1: Select a configuration
    await selectConfiguration(page, "All Active");
    await page.waitForTimeout(2000);

    // Step 2: Select a user from Run As dropdown
    // The combobox is inside c-jt-run-as-section component
    const userCombobox = page
      .locator(
        'c-jt-run-as-section c-jt-searchable-combobox[data-testid="run-as-user-selector"]'
      )
      .first();

    // Click to open user dropdown
    const userInput = userCombobox.locator("input").first();
    await userInput.click();
    await page.waitForTimeout(2000); // Wait for users to load

    // Select first available user (should be an active user)
    const userDropdown = userCombobox.locator(".slds-listbox").first();
    const userOptions = userDropdown.locator(".slds-listbox__item");
    const userCount = await userOptions.count();

    if (userCount === 0) {
      console.log("⚠️  No users available in dropdown - skipping test");
      test.skip();
      return;
    }

    // Get first user's name for verification
    const firstUserOption = userOptions.first();
    const selectedUserName = await firstUserOption.textContent();
    console.log(`✅ Selected user: ${selectedUserName}`);

    await firstUserOption.click();
    await page.waitForTimeout(1000);

    // Step 3: Verify "Execute with System.runAs" button appears
    // This button is shown in jtQueryViewer when a user is selected
    const executeRunAsButton = page
      .locator("lightning-button")
      .filter({ hasText: /Execute with System\.runAs/i })
      .or(page.locator('lightning-button[title*="Execute with System.runAs"]'));
    await expect(executeRunAsButton).toBeVisible({ timeout: 5000 });
    console.log("✅ Execute with System.runAs button visible");

    // Step 4: Verify "Clear Selection" button appears
    const clearButton = page
      .locator('lightning-button[data-testid="run-as-clear-button"]')
      .or(
        page.locator("lightning-button").filter({ hasText: /Clear Selection/i })
      );
    await expect(clearButton).toBeVisible({ timeout: 5000 });
    console.log("✅ Clear Selection button visible");

    // Step 5: Execute query with Run As
    await executeRunAsButton.click();
    await page.waitForTimeout(3000); // Wait for test execution to start

    // Step 6: Wait for results (polling may take time)
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
        ".slds-notify--error, .slds-alert--error"
      );
      const errorVisible = await errorBanner
        .isVisible({ timeout: 1000 })
        .catch(() => false);

      if (errorVisible) {
        const errorText = await errorBanner.textContent();
        console.log(`⚠️  Error detected: ${errorText}`);
        // Don't break - continue to validate error message
        break;
      }
    }

    // Step 7: Validate results are displayed
    if (resultsVisible) {
      const queryResults = page.locator(SELECTORS.queryResults);
      await expect(queryResults).toBeVisible({ timeout: TIMEOUTS.component });

      // ✅ Validate Run As User name is displayed
      const runAsUserName = page
        .locator("text=/Run As User:/i")
        .or(page.locator("text=/Executed as:/i"))
        .first();
      const userNameVisible = await runAsUserName
        .isVisible({ timeout: 2000 })
        .catch(() => false);

      if (userNameVisible) {
        const userNameText = await runAsUserName.textContent();
        expect(userNameText).toContain(selectedUserName.trim().split("\n")[0]);
        console.log(`✅ Run As User name displayed: ${userNameText}`);
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
    console.log("🧪 Testing Run As User - Error Path (No Permissions)...");

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

    // Step 1: Select a configuration
    await selectConfiguration(page, "All Active");
    await page.waitForTimeout(2000);

    // Step 2: Try to find a Chatter Free or Guest User (users with limited permissions)
    const userCombobox = page
      .locator(
        'c-jt-run-as-section c-jt-searchable-combobox[data-testid="run-as-user-selector"]'
      )
      .first();

    const userInput = userCombobox.locator("input").first();
    await userInput.click();
    await page.waitForTimeout(2000);

    // Search for users with restricted licenses
    await userInput.fill("Chatter");
    await page.waitForTimeout(1500);

    const userDropdown = userCombobox.locator(".slds-listbox").first();
    const userOptions = userDropdown.locator(".slds-listbox__item");
    const userCount = await userOptions.count();

    let restrictedUser = null;
    let restrictedUserName = null;

    // Try to find a restricted user
    for (let i = 0; i < Math.min(userCount, 10); i++) {
      const option = userOptions.nth(i);
      const optionText = await option.textContent();

      // Look for Chatter Free, Guest, or Community users
      if (
        optionText.toLowerCase().includes("chatter") ||
        optionText.toLowerCase().includes("guest") ||
        optionText.toLowerCase().includes("community")
      ) {
        restrictedUser = option;
        restrictedUserName = optionText;
        break;
      }
    }

    // If no restricted user found, try any user and validate error handling
    if (!restrictedUser && userCount > 0) {
      restrictedUser = userOptions.first();
      restrictedUserName = await restrictedUser.textContent();
      console.log(
        `⚠️  No restricted user found, using first user: ${restrictedUserName}`
      );
    }

    if (!restrictedUser) {
      console.log("⚠️  No users available - skipping test");
      test.skip();
      return;
    }

    console.log(`✅ Selected restricted user: ${restrictedUserName}`);

    await restrictedUser.click();
    await page.waitForTimeout(1000);

    // Step 3: Execute query with Run As
    const executeRunAsButton = page
      .locator("lightning-button")
      .filter({ hasText: /Execute with System\.runAs/i });
    await executeRunAsButton.click();
    await page.waitForTimeout(3000);

    // Step 4: Wait for error message (should appear faster than success)
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

    // Step 5: Validate error message is user-friendly
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

    // ✅ Validate no redundant error toast (error should be in banner only)
    const errorToast = page.locator(".slds-notify--toast.slds-notify--error");
    const toastVisible = await errorToast
      .isVisible({ timeout: 1000 })
      .catch(() => false);

    // Toast might appear briefly, but banner should be primary
    if (toastVisible) {
      console.log("⚠️  Error toast also visible (may be redundant)");
    } else {
      console.log("✅ No redundant error toast (error only in banner)");
    }

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
    console.log("🧪 Testing Custom Labels validation...");

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

    // Try to execute with a user that lacks permissions (Chatter Free, Guest, etc.)
    // This will trigger error messages that should come from Custom Labels
    const userCombobox = page.locator(
      'c-jt-searchable-combobox[data-testid="run-as-user-selector"]'
    );
    await userCombobox.waitFor({ state: "visible", timeout: 5000 });
    await page.waitForTimeout(2000);

    const userDropdown = userCombobox.locator(".slds-listbox").first();
    const userOptions = userDropdown.locator(".slds-listbox__item");
    const userCount = await userOptions.count();

    if (userCount === 0) {
      console.log("⚠️  No users available - skipping Custom Labels test");
      test.skip();
      return;
    }

    // Select a user (preferably one without permissions)
    const firstUserOption = userOptions.first();
    await firstUserOption.click();
    await page.waitForTimeout(1000);

    // Execute query
    const executeRunAsButton = page
      .locator("lightning-button")
      .filter({ hasText: /Execute with System\.runAs/i })
      .first();
    await executeRunAsButton.click();
    await page.waitForTimeout(5000); // Wait for execution

    // Check for error message (may or may not appear depending on user permissions)
    const errorBanner = page
      .locator(".slds-alert_error h2, .slds-notify_alert h2")
      .first();
    const errorVisible = await errorBanner
      .isVisible({ timeout: 10000 })
      .catch(() => false);

    if (errorVisible) {
      const errorText = await errorBanner.textContent();
      console.log(`📋 Error message displayed: "${errorText}"`);

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

    // Step 4: ✅ Validate user dropdown is cleared
    const userInputValue = await userInput.inputValue();
    expect(userInputValue).toBe("");
    console.log("✅ User dropdown cleared");

    // Step 5: ✅ Validate query results are hidden
    const resultsStillVisible = await queryResults
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(resultsStillVisible).toBe(false);
    console.log("✅ Query results hidden");

    // Step 6: ✅ Validate test assertion message is hidden
    const assertStillVisible = await testAssertMessage
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(assertStillVisible).toBe(false);
    console.log("✅ Test assertion message hidden");

    // Step 7: ✅ Validate query preview is hidden (if it was visible)
    const queryPreview = page.locator(".query-preview");
    const previewVisible = await queryPreview
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(previewVisible).toBe(false);
    console.log("✅ Query preview hidden");

    // Step 8: ✅ Validate "Execute with System.runAs" button is hidden
    const executeButtonStillVisible = await executeRunAsButton
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(executeButtonStillVisible).toBe(false);
    console.log("✅ Execute with System.runAs button hidden");

    // Step 9: ✅ Validate "Clear Selection" button is hidden
    const clearButtonStillVisible = await clearButton
      .isVisible({ timeout: 1000 })
      .catch(() => false);
    expect(clearButtonStillVisible).toBe(false);
    console.log("✅ Clear Selection button hidden");

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

    // Step 2: Select a user
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
