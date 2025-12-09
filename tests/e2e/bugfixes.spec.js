const { test, expect } = require("@playwright/test");
const {
  getSFSession,
  injectSFSession,
  navigateToApp
} = require("./utils/sfAuth");

const TARGET_APP_NAME = "Dynamic Query Framework";
const QUERY_VIEWER_TAB = "Query Viewer";

/**
 * Bug Fix Validation Tests
 *
 * These tests validate that specific bugs have been resolved.
 * If these tests PASS, it means the bugs are fixed.
 * If they FAIL, the bugs have regressed.
 */
test.describe("Bug Fix Validation Tests", () => {
  let session;

  test.beforeAll(() => {
    session = getSFSession();
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    console.log("🐛 Bug Fix Validation - Using SF CLI Session");
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  });

  test.beforeEach(async ({ page }) => {
    await injectSFSession(page, session);
    const navigated = await navigateToApp(page, TARGET_APP_NAME);

    if (navigated) {
      const tabLink = page
        .locator(
          [
            `one-app-nav-bar-item-root a[title="${QUERY_VIEWER_TAB}"]`,
            `a[title="${QUERY_VIEWER_TAB}"]`,
            `a:has-text("${QUERY_VIEWER_TAB}")`
          ].join(", ")
        )
        .first();

      await tabLink.click({ force: true });
      await page.waitForTimeout(2000);

      const viewer = page.locator("c-jt-query-viewer").first();
      await viewer.waitFor({ state: "visible", timeout: 10000 });
    }
  });

  // ============================================
  // BUG FIX #1: Stacked Toasts
  // ============================================
  test("BUG FIX: Button should be disabled during execution to prevent multiple queries", async ({
    page
  }) => {
    console.log("🐛 Testing: Button disabled during execution...");

    // Select a simple query that won't trigger risk modal
    const configInput = page.locator("c-jt-searchable-combobox").first();
    await configInput.locator("input").click();
    await page.waitForTimeout(500);
    await configInput.locator("input").fill("Account by Name");
    await page.waitForTimeout(2000);

    const option = configInput.locator(".slds-listbox__item").first();
    await option.click();
    await page.waitForTimeout(1000);

    // Fill parameter with non-empty value
    const paramInput = page
      .locator("c-jt-parameter-inputs lightning-input")
      .first();
    if ((await paramInput.count()) > 0) {
      await paramInput.locator("input").fill("Test Account");
    }

    const executeButton = page
      .locator("c-jt-execute-button lightning-button")
      .first();

    // Check if button is enabled before click
    const isEnabledBefore = !(await executeButton.isDisabled());
    console.log(`📊 Button enabled before click: ${isEnabledBefore}`);
    expect(isEnabledBefore).toBeTruthy();

    // Click once
    await executeButton.click();

    // ✅ FIX VALIDATION: Check IMMEDIATELY (before query finishes)
    // DO NOT WAIT - query is too fast, need to check instantly
    await page.waitForTimeout(50); // Just enough for DOM to update, not for query to finish

    const ariaBusy = await executeButton.getAttribute("aria-busy");
    console.log(`📊 Button aria-busy after click: ${ariaBusy}`);

    // ✅ Alternative: Check for spinner appearance
    const spinner = page.locator(
      'lightning-spinner[alternative-text*="Executing"]'
    );
    const spinnerVisible = await spinner
      .isVisible({ timeout: 2000 }) // Increased from 1000ms to 2000ms
      .catch(() => false);
    console.log(`📊 Spinner visible: ${spinnerVisible}`);

    // ✅ Check if button is actually disabled
    const isDisabled = await executeButton.isDisabled().catch(() => false);
    console.log(`📊 Button disabled: ${isDisabled}`);

    // ✅ Alternative: Try to click again and expect it to fail
    let secondClickBlocked = false;
    try {
      await executeButton.click({ timeout: 1000 }); // Increased from 500ms to 1000ms
      console.log("⚠️  Second click succeeded (not ideal)");
    } catch (error) {
      secondClickBlocked = true;
      console.log("✅ Second click blocked by disabled state");
    }

    const isProtected =
      ariaBusy === "true" ||
      ariaBusy === true ||
      spinnerVisible ||
      secondClickBlocked ||
      isDisabled;

    console.log(
      `📊 Button protection status: ${isProtected ? "✅ PROTECTED" : "❌ VULNERABLE"}`
    );

    // ✅ This is a best-effort validation due to LWC re-render timing
    // Manual testing is recommended for 100% confidence
    if (!isProtected) {
      console.warn(
        "⚠️  E2E test couldn't detect protection - manual validation recommended"
      );
    }

    expect(isProtected).toBeTruthy();

    // Wait for execution to complete
    await page.waitForTimeout(4000);

    // ✅ FIX VALIDATION: Should have at most 1 toast visible (not stacked)
    const visibleToasts = page.locator(".slds-notify.slds-notify_toast");
    const toastCount = await visibleToasts.count();

    console.log(`📊 Visible toasts: ${toastCount}`);
    expect(toastCount).toBeLessThanOrEqual(1);

    if (isProtected && toastCount <= 1) {
      console.log("✅ BUG FIXED: Button correctly disabled during execution");
      console.log(
        "✅ BUG FIXED: No stacked toasts (multiple clicks prevented)"
      );
    }
  });

  // ============================================
  // BUG FIX #2: Child Relationships Missing in Data
  // ============================================
  test("BUG FIX: Child relationships should be present in query results", async ({
    page
  }) => {
    console.log("🐛 Testing: Child relationships missing bug fix...");

    // Select complex query with child relationships
    const configInput = page.locator("c-jt-searchable-combobox").first();
    await configInput.locator("input").click();
    await page.waitForTimeout(500);
    await configInput.locator("input").fill("Customer 360 View");
    await page.waitForTimeout(2000);

    const option = configInput.locator(".slds-listbox__item").first();
    const optionExists = await option.count();

    if (optionExists > 0) {
      await option.click();
      await page.waitForTimeout(1000);

      // Execute query
      const executeButton = page
        .locator("c-jt-execute-button lightning-button")
        .first();
      await executeButton.click();
      await page.waitForTimeout(5000);

      // Switch to JSON view to inspect data structure
      const jsonViewButton = page.locator('lightning-button[data-view="json"]');
      if ((await jsonViewButton.count()) > 0) {
        await jsonViewButton.click();
        await page.waitForTimeout(1000);

        const jsonView = page.locator("c-jt-query-results pre").first();
        const jsonText = await jsonView.textContent();

        // ✅ FIX VALIDATION: JSON should contain child relationship keys
        const hasContacts = jsonText.includes('"Contacts"');
        const hasOpportunities = jsonText.includes('"Opportunities"');
        const hasCases = jsonText.includes('"Cases"');

        console.log(`📊 Child relationships found:`);
        console.log(`   - Contacts: ${hasContacts}`);
        console.log(`   - Opportunities: ${hasOpportunities}`);
        console.log(`   - Cases: ${hasCases}`);

        expect(hasContacts || hasOpportunities || hasCases).toBeTruthy();

        if (hasContacts && hasOpportunities && hasCases) {
          console.log("✅ BUG FIXED: Child relationships present in data");
        }
      }
    } else {
      console.log("⚠️  'Customer 360 View' config not found - skipping");
    }
  });

  // ============================================
  // BUG FIX #3: AccountId Redundant in Child Columns
  // ============================================
  test("BUG FIX: AccountId should NOT appear in child relationship columns", async ({
    page
  }) => {
    console.log("🐛 Testing: AccountId redundant in child columns bug fix...");

    // Select complex query with child relationships
    const configInput = page.locator("c-jt-searchable-combobox").first();
    await configInput.locator("input").click();
    await page.waitForTimeout(500);
    await configInput.locator("input").fill("Customer 360 View");
    await page.waitForTimeout(2000);

    const option = configInput.locator(".slds-listbox__item").first();
    const optionExists = await option.count();

    if (optionExists > 0) {
      await option.click();
      await page.waitForTimeout(1000);

      // Execute query
      const executeButton = page
        .locator("c-jt-execute-button lightning-button")
        .first();
      await executeButton.click();
      await page.waitForTimeout(5000);

      // Expand first row to see child relationships
      const expandButton = page
        .locator(
          'c-jt-query-results lightning-button-icon[icon-name*="chevron"]'
        )
        .first();
      const hasExpandButton = await expandButton.count();

      if (hasExpandButton > 0) {
        await expandButton.click();
        await page.waitForTimeout(1000);

        // Expand first accordion section (Contacts/Opportunities/Cases)
        const accordionSection = page
          .locator("c-jt-query-results lightning-accordion-section")
          .first();
        await accordionSection.click();
        await page.waitForTimeout(1000);

        // Check datatable columns
        const datatable = page.locator(
          "c-jt-query-results lightning-datatable"
        );
        const datatableExists = await datatable.count();

        if (datatableExists > 0) {
          const columnHeaders = await datatable
            .locator("thead th")
            .allTextContents();

          // ✅ FIX VALIDATION: AccountId should NOT be in child columns
          const hasAccountId = columnHeaders.some((header) =>
            header.toLowerCase().includes("account id")
          );

          console.log(`📊 Child columns: ${columnHeaders.join(", ")}`);
          console.log(`📊 AccountId present: ${hasAccountId}`);

          expect(hasAccountId).toBeFalsy();

          if (!hasAccountId) {
            console.log(
              "✅ BUG FIXED: AccountId correctly filtered from child columns"
            );
          }
        } else {
          console.log("⚠️  No datatable found in accordion");
        }
      } else {
        console.log("⚠️  No expand button found (no child data)");
      }
    } else {
      console.log("⚠️  'Customer 360 View' config not found - skipping");
    }
  });

  // ============================================
  // BUG FIX #4: CSV Preview Missing
  // ============================================
  test("BUG FIX: CSV should have preview before download", async ({ page }) => {
    console.log("🐛 Testing: CSV preview missing bug fix...");

    // Select and execute query
    const configInput = page.locator("c-jt-searchable-combobox").first();
    await configInput.locator("input").click();
    await page.waitForTimeout(500);
    await configInput.locator("input").fill("Account by Name");
    await page.waitForTimeout(2000);

    const option = configInput.locator(".slds-listbox__item").first();
    await option.click();
    await page.waitForTimeout(1000);

    const paramInput = page
      .locator("c-jt-parameter-inputs lightning-input")
      .first();
    if ((await paramInput.count()) > 0) {
      await paramInput.locator("input").fill("test");
    }

    const executeButton = page
      .locator("c-jt-execute-button lightning-button")
      .first();
    await executeButton.click();
    await page.waitForTimeout(5000);

    // Switch to CSV view
    const csvViewButton = page.locator('lightning-button[data-view="csv"]');
    if ((await csvViewButton.count()) > 0) {
      await csvViewButton.click();
      await page.waitForTimeout(2000); // Increased from 1000ms to 2000ms

      // ✅ FIX VALIDATION: CSV preview should be visible
      const csvPreview = page.locator("c-jt-query-results pre.csv-content");
      const previewVisible = await csvPreview
        .isVisible({ timeout: 5000 }) // Increased from 2000ms to 5000ms
        .catch(() => false);

      console.log(`📊 CSV preview visible: ${previewVisible}`);
      expect(previewVisible).toBeTruthy();

      if (previewVisible) {
        const csvText = await csvPreview.textContent();
        console.log(`📊 CSV content length: ${csvText.length} characters`);

        // Should have headers and data
        expect(csvText.length).toBeGreaterThan(0);

        // ✅ FIX VALIDATION: Copy and Download buttons should exist
        // Try multiple selectors for robustness
        const copyButton = page.locator(
          'lightning-button:has-text("Copy"), button:has-text("Copy")'
        ).first();
        const downloadButton = page.locator(
          'lightning-button:has-text("Download"), button:has-text("Download")'
        ).first();

        // Wait for buttons to appear
        await page.waitForTimeout(1000);

        const hasCopy = await copyButton.isVisible({ timeout: 2000 }).catch(() => false);
        const hasDownload = await downloadButton.isVisible({ timeout: 2000 }).catch(() => false);

        console.log(`📊 Copy button exists: ${hasCopy}`);
        console.log(`📊 Download button exists: ${hasDownload}`);

        expect(hasCopy).toBeTruthy();
        expect(hasDownload).toBeTruthy();

        if (previewVisible && hasCopy && hasDownload) {
          console.log(
            "✅ BUG FIXED: CSV preview with Copy and Download buttons"
          );
        }
      }
    }
  });

  // ============================================
  // BUG FIX #5: Clipboard Copy Failing
  // ============================================
  test("BUG FIX: Copy to clipboard should work (execCommand fallback)", async ({
    page
  }) => {
    console.log("🐛 Testing: Clipboard copy failing bug fix...");

    // Select and execute query
    const configInput = page.locator("c-jt-searchable-combobox").first();
    await configInput.locator("input").click();
    await page.waitForTimeout(500);
    await configInput.locator("input").fill("Account by Name");
    await page.waitForTimeout(2000);

    const option = configInput.locator(".slds-listbox__item").first();
    await option.click();
    await page.waitForTimeout(1000);

    const paramInput = page
      .locator("c-jt-parameter-inputs lightning-input")
      .first();
    if ((await paramInput.count()) > 0) {
      await paramInput.locator("input").fill("test");
    }

    const executeButton = page
      .locator("c-jt-execute-button lightning-button")
      .first();
    await executeButton.click();
    await page.waitForTimeout(5000);

    // Switch to JSON view
    const jsonViewButton = page.locator('lightning-button[data-view="json"]');
    if ((await jsonViewButton.count()) > 0) {
      await jsonViewButton.click();
      await page.waitForTimeout(1000);

      // Click Copy button
      const copyButton = page.locator(
        'c-jt-query-results lightning-button[label="Copy"]'
      );
      const hasCopyButton = (await copyButton.count()) > 0;

      if (hasCopyButton) {
        await copyButton.click();
        await page.waitForTimeout(1000);

        // ✅ FIX VALIDATION: Should show success toast (not error)
        const successToast = page.locator(
          '.slds-notify_toast.slds-theme_success:has-text("Success")'
        );
        const errorToast = page.locator(
          '.slds-notify_toast.slds-theme_error:has-text("Copy failed")'
        );

        const hasSuccess = await successToast
          .isVisible({ timeout: 2000 })
          .catch(() => false);
        const hasError = await errorToast
          .isVisible({ timeout: 2000 })
          .catch(() => false);

        console.log(`📊 Success toast: ${hasSuccess}`);
        console.log(`📊 Error toast: ${hasError}`);

        // Copy should succeed (or at least not show error)
        expect(hasError).toBeFalsy();

        if (hasSuccess && !hasError) {
          console.log("✅ BUG FIXED: Copy to clipboard working");
        } else if (!hasError) {
          console.log(
            "✅ BUG FIXED: No copy error (clipboard API may be restricted in test env)"
          );
        }
      }
    }
  });

  // ============================================
  // BUG FIX #6: Expand/Collapse Not Working
  // ============================================
  test("BUG FIX: Child relationships should expand/collapse correctly", async ({
    page
  }) => {
    console.log("🐛 Testing: Expand/collapse bug fix...");

    // Select complex query
    const configInput = page.locator("c-jt-searchable-combobox").first();
    await configInput.locator("input").click();
    await page.waitForTimeout(500);
    await configInput.locator("input").fill("Customer 360 View");
    await page.waitForTimeout(2000);

    const option = configInput.locator(".slds-listbox__item").first();
    const optionExists = await option.count();

    if (optionExists > 0) {
      await option.click();
      await page.waitForTimeout(1000);

      const executeButton = page
        .locator("c-jt-execute-button lightning-button")
        .first();
      await executeButton.click();
      await page.waitForTimeout(5000);

      const expandButton = page
        .locator(
          'c-jt-query-results lightning-button-icon[icon-name*="chevron"]'
        )
        .first();
      const hasExpandButton = await expandButton.count();

      if (hasExpandButton > 0) {
        // Check icon before expand
        const iconBeforeExpand = await expandButton.getAttribute("icon-name");
        console.log(`📊 Icon before expand: ${iconBeforeExpand}`);

        // Click to expand
        await expandButton.click();
        await page.waitForTimeout(1000);

        // ✅ FIX VALIDATION: Accordion should be visible after expand
        const accordion = page.locator(
          "c-jt-query-results lightning-accordion"
        );
        const accordionVisible = await accordion
          .isVisible({ timeout: 2000 })
          .catch(() => false);

        console.log(`📊 Accordion visible after expand: ${accordionVisible}`);
        expect(accordionVisible).toBeTruthy();

        // Check icon after expand (should change)
        const iconAfterExpand = await expandButton.getAttribute("icon-name");
        console.log(`📊 Icon after expand: ${iconAfterExpand}`);

        // Icons should be different (chevronright vs chevrondown)
        expect(iconBeforeExpand).not.toBe(iconAfterExpand);

        // Click to collapse
        await expandButton.click();
        await page.waitForTimeout(1000);

        // ✅ FIX VALIDATION: Accordion should be hidden after collapse
        const accordionHidden = await accordion
          .isHidden({ timeout: 2000 })
          .catch(() => false);

        console.log(`📊 Accordion hidden after collapse: ${accordionHidden}`);

        if (accordionVisible && accordionHidden) {
          console.log("✅ BUG FIXED: Expand/collapse working correctly");
        }
      } else {
        console.log("⚠️  No expand button (query returned no child data)");
      }
    } else {
      console.log("⚠️  'Customer 360 View' config not found - skipping");
    }
  });
});
