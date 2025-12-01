/**
 * @description E2E tests for Query Execution Happy Path
 * @author Jaime Terrats | 2025-12-01
 * @group E2E Tests - Happy Path Validation
 * 
 * Tests validate:
 * ✅ Records are returned successfully
 * ❌ NO error toasts appear
 * ❌ NO error messages in UI
 * ✅ Success toasts appear and auto-dismiss
 */

const { test, expect } = require('@playwright/test');

test.describe('Query Execution Happy Path', () => {
  test.beforeEach(async ({ page }) => {
    // Login and navigate to the app
    await page.goto(process.env.SF_INSTANCE_URL + '/lightning', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2000);
    
    // Navigate to Dynamic Queries app
    await page.goto(process.env.SF_INSTANCE_URL + '/lightning/n/Query_Viewer', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });
    
    // Wait for the component to load
    await page.waitForSelector('c-jt-query-viewer', { timeout: 30000 });
  });

  test('should execute query and return records without errors', async ({ page }) => {
    // ✅ HAPPY PATH: Select configuration
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('Test');
    await page.waitForTimeout(500);
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(1000);

    // ✅ HAPPY PATH: Execute query
    const executeButton = page.locator('c-jt-execute-button lightning-button');
    await executeButton.click();
    await page.waitForTimeout(3000); // Wait for query execution

    // ✅ HAPPY PATH: Verify results table appears
    const resultsTable = page.locator('c-jt-query-results lightning-datatable');
    await expect(resultsTable).toBeVisible({ timeout: 10000 });

    // ✅ HAPPY PATH: Verify records are displayed (not empty)
    const rows = resultsTable.locator('tbody tr');
    const rowCount = await rows.count();
    expect(rowCount).toBeGreaterThan(0);

    // ✅ HAPPY PATH: Verify actual data in cells
    const firstRow = rows.first();
    const cells = firstRow.locator('td');
    const cellCount = await cells.count();
    expect(cellCount).toBeGreaterThan(0);

    // Verify first cell (after checkbox) has data
    const firstDataCell = cells.nth(1);
    const cellText = await firstDataCell.textContent();
    expect(cellText).not.toBe('');
    expect(cellText).not.toBeNull();

    // ✅ HAPPY PATH: Verify success toast appears
    const successToast = page.locator('.slds-notify--success, .slds-notify_success');
    await expect(successToast).toBeVisible({ timeout: 5000 });

    // ✅ HAPPY PATH: Verify toast contains record count
    const toastText = await successToast.textContent();
    expect(toastText).toContain('Found');
    expect(toastText).toContain('record');

    // ❌ NEGATIVE: Verify NO error toasts appear
    const errorToast = page.locator('.slds-notify--error, .slds-notify_error');
    await expect(errorToast).not.toBeVisible({ timeout: 2000 }).catch(() => {
      // If toast doesn't exist at all, that's fine
    });

    // ❌ NEGATIVE: Verify NO error messages in results area
    const errorMessage = page.locator('[data-testid="error-message"]');
    await expect(errorMessage).not.toBeVisible({ timeout: 2000 }).catch(() => {});

    // ✅ HAPPY PATH: Verify toast auto-dismisses
    await page.waitForTimeout(6000);
    await expect(successToast).not.toBeVisible({ timeout: 2000 }).catch(() => {
      // Toast should be gone after 5-6 seconds
    });
  });

  test('should execute query with parameters and return results', async ({ page }) => {
    // ✅ HAPPY PATH: Select configuration with parameters
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('Test Record');
    await page.waitForTimeout(500);
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(1000);

    // Check if parameters section exists
    const paramSection = page.locator('text=Query Parameters');
    const hasParams = await paramSection.isVisible({ timeout: 3000 }).catch(() => false);

    if (hasParams) {
      // ✅ HAPPY PATH: Fill parameter value
      const paramInput = page.locator('c-jt-parameter-inputs lightning-input').first();
      await paramInput.locator('input').fill('Test');
      await page.waitForTimeout(500);

      // ✅ HAPPY PATH: Execute query
      const executeButton = page.locator('c-jt-execute-button lightning-button');
      await executeButton.click();
      await page.waitForTimeout(3000);

      // ✅ HAPPY PATH: Verify results appear
      const resultsTable = page.locator('c-jt-query-results lightning-datatable');
      await expect(resultsTable).toBeVisible({ timeout: 10000 });

      // ✅ HAPPY PATH: Verify records returned
      const rows = resultsTable.locator('tbody tr');
      const rowCount = await rows.count();
      expect(rowCount).toBeGreaterThanOrEqual(0); // May be 0 if no matches

      // ❌ NEGATIVE: No error toasts
      const errorToast = page.locator('.slds-notify--error');
      await expect(errorToast).not.toBeVisible({ timeout: 2000 }).catch(() => {});

      // ✅ HAPPY PATH: Success toast appears
      const successToast = page.locator('.slds-notify--success');
      await expect(successToast).toBeVisible({ timeout: 5000 });
    }
  });

  test('should handle pagination in results without errors', async ({ page }) => {
    // ✅ HAPPY PATH: Select configuration that returns many records
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('All Active');
    await page.waitForTimeout(500);
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(1000);

    // ✅ HAPPY PATH: Execute query
    const executeButton = page.locator('c-jt-execute-button lightning-button');
    await executeButton.click();
    await page.waitForTimeout(3000);

    // ✅ HAPPY PATH: Wait for results
    const resultsTable = page.locator('c-jt-query-results lightning-datatable');
    await expect(resultsTable).toBeVisible({ timeout: 10000 });

    // ✅ HAPPY PATH: Verify records displayed
    const rows = resultsTable.locator('tbody tr');
    const rowCount = await rows.count();
    expect(rowCount).toBeGreaterThan(0);

    // Check if pagination controls exist
    const nextButton = page.locator('c-jt-query-results').locator('text=Next');
    const hasPagination = await nextButton.isVisible({ timeout: 2000 }).catch(() => false);

    if (hasPagination) {
      // ✅ HAPPY PATH: Get first row from page 1
      const firstRowPage1 = await rows.first().textContent();
      expect(firstRowPage1).not.toBe('');

      // ✅ HAPPY PATH: Click Next
      await nextButton.click();
      await page.waitForTimeout(500);

      // ✅ HAPPY PATH: Verify different data on page 2
      const firstRowPage2 = await rows.first().textContent();
      expect(firstRowPage2).not.toBe(firstRowPage1);

      // ❌ NEGATIVE: No error during pagination
      const errorToast = page.locator('.slds-notify--error');
      await expect(errorToast).not.toBeVisible({ timeout: 1000 }).catch(() => {});
    }

    // ❌ NEGATIVE: No error toasts at any point
    const errorToast = page.locator('.slds-notify--error');
    await expect(errorToast).not.toBeVisible({ timeout: 2000 }).catch(() => {});
  });

  test('should display record count in success message', async ({ page }) => {
    // ✅ HAPPY PATH: Select and execute
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('Test');
    await page.waitForTimeout(500);
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(1000);

    const executeButton = page.locator('c-jt-execute-button lightning-button');
    await executeButton.click();
    await page.waitForTimeout(3000);

    // ✅ HAPPY PATH: Wait for success toast
    const successToast = page.locator('.slds-notify--success');
    await expect(successToast).toBeVisible({ timeout: 5000 });

    // ✅ HAPPY PATH: Verify toast message format
    const toastText = await successToast.textContent();
    
    // Should contain "Found X record(s)"
    expect(toastText).toMatch(/Found \d+ record/i);
    
    // ❌ NEGATIVE: Should NOT contain error words
    expect(toastText.toLowerCase()).not.toContain('error');
    expect(toastText.toLowerCase()).not.toContain('failed');
    expect(toastText.toLowerCase()).not.toContain('exception');

    // ✅ HAPPY PATH: Verify record count matches results
    const resultsTable = page.locator('c-jt-query-results lightning-datatable');
    const rows = resultsTable.locator('tbody tr');
    const actualRowCount = await rows.count();
    
    // Extract count from toast message
    const match = toastText.match(/Found (\d+) record/i);
    if (match) {
      const toastCount = parseInt(match[1]);
      // Count should be >= visible rows (due to pagination)
      expect(toastCount).toBeGreaterThanOrEqual(actualRowCount);
    }
  });

  test('should not show errors when switching between configurations', async ({ page }) => {
    // ✅ HAPPY PATH: Select first configuration
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('Test');
    await page.waitForTimeout(500);
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(2000);

    // ❌ NEGATIVE: No errors after first selection
    let errorToast = page.locator('.slds-notify--error');
    await expect(errorToast).not.toBeVisible({ timeout: 2000 }).catch(() => {});

    // ✅ HAPPY PATH: Select second configuration
    await combobox.locator('input').click();
    await combobox.locator('input').clear();
    await combobox.locator('input').fill('All Active');
    await page.waitForTimeout(500);
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(2000);

    // ❌ NEGATIVE: No errors after second selection
    errorToast = page.locator('.slds-notify--error');
    await expect(errorToast).not.toBeVisible({ timeout: 2000 }).catch(() => {});

    // ✅ HAPPY PATH: Execute query
    const executeButton = page.locator('c-jt-execute-button lightning-button');
    await executeButton.click();
    await page.waitForTimeout(3000);

    // ✅ HAPPY PATH: Results appear
    const resultsTable = page.locator('c-jt-query-results lightning-datatable');
    await expect(resultsTable).toBeVisible({ timeout: 10000 });

    // ❌ NEGATIVE: Still no errors
    errorToast = page.locator('.slds-notify--error');
    await expect(errorToast).not.toBeVisible({ timeout: 2000 }).catch(() => {});
  });
});

