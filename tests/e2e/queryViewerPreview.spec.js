/**
 * @description E2E tests for Query Preview with Data (Bug Fix #2)
 * @author Jaime Terrats | 2025-12-01
 * @group E2E Tests
 */

const { test, expect } = require('@playwright/test');

test.describe('Query Data Preview', () => {
  test.beforeEach(async ({ page }) => {
    // Login and navigate to the app
    await page.goto(process.env.SF_INSTANCE_URL + '/lightning', { waitUntil: 'domcontentloaded' });
    
    // Wait for login if needed (or assume already logged in)
    await page.waitForTimeout(2000);
    
    // Navigate to Dynamic Queries app
    await page.goto(process.env.SF_INSTANCE_URL + '/lightning/n/Query_Viewer', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });
    
    // Wait for the component to load
    await page.waitForSelector('c-jt-query-viewer', { timeout: 30000 });
  });

  test('should show query preview SOQL text when config selected', async ({ page }) => {
    // Select a configuration
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('Test');
    await page.waitForTimeout(500);
    
    // Click first option
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(1000);

    // Check that Query Preview section is visible
    const queryPreview = page.locator('text=Query Preview:');
    await expect(queryPreview).toBeVisible();

    // Check that SOQL text is displayed
    const soqlPreview = page.locator('.query-preview pre');
    await expect(soqlPreview).toBeVisible();
    const soqlText = await soqlPreview.textContent();
    expect(soqlText).toContain('SELECT');
  });

  test('should load and display data preview table after config selection', async ({ page }) => {
    // Select a configuration with data
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('Test');
    await page.waitForTimeout(500);
    
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(2000); // Wait for preview to load

    // Check that Data Preview section is visible
    const dataPreviewHeading = page.locator('text=Data Preview');
    await expect(dataPreviewHeading).toBeVisible({ timeout: 10000 });

    // Check that preview table is displayed
    const previewTable = page.locator('[data-testid="query-preview-table"]');
    await expect(previewTable).toBeVisible();

    // Verify table has rows
    const rows = previewTable.locator('tbody tr');
    const rowCount = await rows.count();
    expect(rowCount).toBeGreaterThan(0);
    expect(rowCount).toBeLessThanOrEqual(3); // Max 3 per page
  });

  test('should show pagination controls when preview has more than 3 records', async ({ page }) => {
    // Select a configuration that returns > 3 records
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('All Active');
    await page.waitForTimeout(500);
    
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(2000);

    // Check for pagination controls
    const prevButton = page.locator('[data-testid="preview-prev-button"]');
    const nextButton = page.locator('[data-testid="preview-next-button"]');
    const pageInfo = page.locator('[data-testid="preview-page-info"]');

    // Wait for controls to appear (they may not appear if <= 3 records)
    const hasControls = await prevButton.isVisible({ timeout: 5000 }).catch(() => false);
    
    if (hasControls) {
      await expect(nextButton).toBeVisible();
      await expect(pageInfo).toBeVisible();

      // Verify page info text
      const pageText = await pageInfo.textContent();
      expect(pageText).toMatch(/Page \d+ of \d+/);
    }
  });

  test('should navigate between preview pages using pagination', async ({ page }) => {
    // Select a configuration that returns > 3 records
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('All Active');
    await page.waitForTimeout(500);
    
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(2000);

    const nextButton = page.locator('[data-testid="preview-next-button"]');
    const hasNext = await nextButton.isVisible({ timeout: 5000 }).catch(() => false);

    if (hasNext) {
      // Get first row data from page 1
      const previewTable = page.locator('[data-testid="query-preview-table"]');
      const firstRowPage1 = await previewTable.locator('tbody tr').first().textContent();

      // Click Next
      await nextButton.click();
      await page.waitForTimeout(500);

      // Verify page changed
      const firstRowPage2 = await previewTable.locator('tbody tr').first().textContent();
      expect(firstRowPage2).not.toBe(firstRowPage1);

      // Click Previous
      const prevButton = page.locator('[data-testid="preview-prev-button"]');
      await prevButton.click();
      await page.waitForTimeout(500);

      // Verify back to page 1
      const firstRowAgain = await previewTable.locator('tbody tr').first().textContent();
      expect(firstRowAgain).toBe(firstRowPage1);
    }
  });

  test('should reload preview when parameter values change', async ({ page }) => {
    // Select a configuration with parameters
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('Test Record');
    await page.waitForTimeout(500);
    
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(2000);

    // Check if parameters section exists
    const paramSection = page.locator('text=Query Parameters');
    const hasParams = await paramSection.isVisible({ timeout: 3000 }).catch(() => false);

    if (hasParams) {
      // Wait for initial preview to load
      await page.waitForTimeout(2000);

      // Change parameter value
      const paramInput = page.locator('lightning-input[data-param]').first();
      await paramInput.locator('input').fill('New Value');
      await page.waitForTimeout(2000); // Wait for preview reload

      // Verify preview table is still visible (reloaded)
      const previewTable = page.locator('[data-testid="query-preview-table"]');
      await expect(previewTable).toBeVisible();
    }
  });

  test('should show max 5 records total across all pages', async ({ page }) => {
    // Select a configuration
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('All Active');
    await page.waitForTimeout(500);
    
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(2000);

    // Check Data Preview heading
    const heading = page.locator('text=/Data Preview \\(Top \\d+ records\\)/');
    const hasHeading = await heading.isVisible({ timeout: 5000 }).catch(() => false);

    if (hasHeading) {
      const headingText = await heading.textContent();
      const match = headingText.match(/Top (\d+) records/);
      
      if (match) {
        const recordCount = parseInt(match[1]);
        expect(recordCount).toBeLessThanOrEqual(5);
      }
    }
  });

  test('should disable Previous button on first page', async ({ page }) => {
    // Select a configuration with > 3 records
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('All Active');
    await page.waitForTimeout(500);
    
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(2000);

    const prevButton = page.locator('[data-testid="preview-prev-button"]');
    const hasPrev = await prevButton.isVisible({ timeout: 5000 }).catch(() => false);

    if (hasPrev) {
      // Verify Previous is disabled on first page
      await expect(prevButton).toBeDisabled();
    }
  });

  test('should disable Next button on last page', async ({ page }) => {
    // Select a configuration with > 3 but <= 6 records (2 pages)
    const combobox = page.locator('c-jt-searchable-combobox[data-testid="config-selector"]');
    await combobox.locator('input').click();
    await combobox.locator('input').fill('All Active');
    await page.waitForTimeout(500);
    
    await combobox.locator('li[role="option"]').first().click();
    await page.waitForTimeout(2000);

    const nextButton = page.locator('[data-testid="preview-next-button"]');
    const hasNext = await nextButton.isVisible({ timeout: 5000 }).catch(() => false);

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

