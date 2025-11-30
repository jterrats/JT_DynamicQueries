/**
 * @description AppExchange Video Generator
 * @author Jaime Terrats
 * @date 2025-11-30
 *
 * Captures high-quality demo videos for AppExchange listing
 * Shows complete user flows in action
 */
const { chromium } = require('@playwright/test');
const { getSFSession, injectSFSession, navigateToApp } = require('../e2e/utils/sfAuth');
const fs = require('fs');
const path = require('path');

const VIDEOS_DIR = path.join(__dirname, '../../videos/appexchange');
const TARGET_APP_NAME = 'Dynamic Queries';
const QUERY_VIEWER_TAB = 'Query Viewer';

// Video configuration
const VIEWPORT = { width: 1280, height: 800 };

async function captureVideos() {
  // Create videos directory
  if (!fs.existsSync(VIDEOS_DIR)) {
    fs.mkdirSync(VIDEOS_DIR, { recursive: true });
  }

  console.log('🎬 Starting AppExchange Video Capture');
  console.log('📁 Output directory:', VIDEOS_DIR);
  console.log('📐 Viewport:', `${VIEWPORT.width}x${VIEWPORT.height}`);
  console.log('');

  const browser = await chromium.launch({
    headless: false // Visible for verification
  });

  // ==================================================================
  // VIDEO 1: Complete User Flow (90 seconds)
  // ==================================================================
  console.log('🎥 1/3: Capturing complete user flow...');
  const context1 = await browser.newContext({
    viewport: VIEWPORT,
    recordVideo: {
      dir: VIDEOS_DIR,
      size: VIEWPORT
    }
  });
  const page1 = await context1.newPage();

  try {
    const session = getSFSession();
    console.log('   ✅ Authenticated:', session.username);

    await injectSFSession(page1, session);
    const navigated = await navigateToApp(page1, TARGET_APP_NAME);
    if (!navigated) throw new Error('Failed to navigate to app');

    await page1.waitForTimeout(2000);

    // Navigate to Query Viewer
    await page1.locator(`one-app-nav-bar-item-root a[title="${QUERY_VIEWER_TAB}"]`).first().click();
    await page1.waitForLoadState('domcontentloaded');
    await page1.waitForSelector('c-jt-query-viewer', { timeout: 30000 });
    await page1.waitForTimeout(3000);

    // Show dropdown
    const combobox = page1.locator('c-jt-searchable-combobox input').first();
    await combobox.click();
    await page1.waitForTimeout(1500);

    // Search and select
    await combobox.fill('Account');
    await page1.waitForTimeout(1500);
    await page1.keyboard.press('ArrowDown');
    await page1.waitForTimeout(500);
    await page1.keyboard.press('Enter');
    await page1.waitForTimeout(3000);

    // Execute query
    const executeButton = page1.locator('c-jt-execute-button button').first();
    await executeButton.click();
    await page1.waitForSelector('c-jt-query-results', { timeout: 30000 });
    await page1.waitForTimeout(4000);

    // Scroll through results
    await page1.evaluate(() => window.scrollTo(0, 300));
    await page1.waitForTimeout(2000);
    await page1.evaluate(() => window.scrollTo(0, 0));
    await page1.waitForTimeout(1000);

    // Switch to JSON view
    const jsonButton = page1.locator('button:has-text("JSON")').first();
    if (await jsonButton.isVisible()) {
      await jsonButton.click();
      await page1.waitForTimeout(3000);
    }

    // Back to table view
    const tableButton = page1.locator('button:has-text("Table")').first();
    if (await tableButton.isVisible()) {
      await tableButton.click();
      await page1.waitForTimeout(2000);
    }

    console.log('   ✅ Complete flow captured');
  } finally {
    await context1.close();
  }

  // ==================================================================
  // VIDEO 2: Mobile Responsive Demo (30 seconds)
  // ==================================================================
  console.log('🎥 2/3: Capturing mobile demo...');
  const context2 = await browser.newContext({
    viewport: { width: 375, height: 667 },
    recordVideo: {
      dir: VIDEOS_DIR,
      size: { width: 375, height: 667 }
    }
  });
  const page2 = await context2.newPage();

  try {
    const session = getSFSession();
    await injectSFSession(page2, session);
    await navigateToApp(page2, TARGET_APP_NAME);
    await page2.waitForTimeout(2000);

    // Navigate to Query Viewer
    await page2.locator(`one-app-nav-bar-item-root a[title="${QUERY_VIEWER_TAB}"]`).first().click();
    await page2.waitForLoadState('domcontentloaded');
    await page2.waitForSelector('c-jt-query-viewer', { timeout: 30000 });
    await page2.waitForTimeout(2000);

    // Select config
    const combobox = page2.locator('c-jt-searchable-combobox input').first();
    await combobox.click();
    await page2.waitForTimeout(1000);
    await combobox.fill('Account');
    await page2.waitForTimeout(1000);
    await page2.keyboard.press('ArrowDown');
    await page2.keyboard.press('Enter');
    await page2.waitForTimeout(2000);

    // Execute
    const executeButton = page2.locator('c-jt-execute-button button').first();
    await executeButton.click();
    await page2.waitForSelector('c-jt-query-results', { timeout: 30000 });
    await page2.waitForTimeout(3000);

    // Expand first card
    const firstCard = page2.locator('[role="button"][aria-expanded]').first();
    if (await firstCard.isVisible()) {
      await firstCard.click();
      await page2.waitForTimeout(2000);

      // Collapse
      await firstCard.click();
      await page2.waitForTimeout(1000);
    }

    // Scroll through results
    await page2.evaluate(() => window.scrollTo(0, 400));
    await page2.waitForTimeout(2000);

    console.log('   ✅ Mobile demo captured');
  } finally {
    await context2.close();
  }

  // ==================================================================
  // VIDEO 3: Configuration Creation (40 seconds)
  // ==================================================================
  console.log('🎥 3/3: Capturing configuration creation...');
  const context3 = await browser.newContext({
    viewport: VIEWPORT,
    recordVideo: {
      dir: VIDEOS_DIR,
      size: VIEWPORT
    }
  });
  const page3 = await context3.newPage();

  try {
    const session = getSFSession();
    await injectSFSession(page3, session);
    await navigateToApp(page3, TARGET_APP_NAME);
    await page3.waitForTimeout(2000);

    // Navigate to Query Viewer
    await page3.locator(`one-app-nav-bar-item-root a[title="${QUERY_VIEWER_TAB}"]`).first().click();
    await page3.waitForLoadState('domcontentloaded');
    await page3.waitForSelector('c-jt-query-viewer', { timeout: 30000 });
    await page3.waitForTimeout(3000);

    // Click New Configuration
    const createButton = page3.locator('button:has-text("New Configuration")').first();
    if (await createButton.isVisible()) {
      await createButton.click();
      await page3.waitForSelector('[role="dialog"]', { timeout: 5000 });
      await page3.waitForTimeout(2000);

      // Show form interaction (don't actually submit)
      const nameInput = page3.locator('input[label*="Name"], input[placeholder*="Name"]').first();
      if (await nameInput.isVisible()) {
        await nameInput.click();
        await page3.waitForTimeout(1000);
      }

      await page3.waitForTimeout(3000);

      // Close modal
      await page3.keyboard.press('Escape');
      await page3.waitForTimeout(2000);
    }

    // Show existing configurations
    const combobox = page3.locator('c-jt-searchable-combobox input').first();
    await combobox.click();
    await page3.waitForTimeout(2000);

    await page3.keyboard.press('Escape');
    await page3.waitForTimeout(1000);

    console.log('   ✅ Configuration demo captured');
  } finally {
    await context3.close();
  }

  await browser.close();

  // Rename videos with descriptive names
  console.log('');
  console.log('📝 Renaming videos...');

  const videoFiles = fs.readdirSync(VIDEOS_DIR).filter(f => f.endsWith('.webm'));
  if (videoFiles.length >= 3) {
    fs.renameSync(
      path.join(VIDEOS_DIR, videoFiles[0]),
      path.join(VIDEOS_DIR, '01_complete_user_flow.webm')
    );
    fs.renameSync(
      path.join(VIDEOS_DIR, videoFiles[1]),
      path.join(VIDEOS_DIR, '02_mobile_responsive.webm')
    );
    fs.renameSync(
      path.join(VIDEOS_DIR, videoFiles[2]),
      path.join(VIDEOS_DIR, '03_config_creation.webm')
    );
  }

  console.log('');
  console.log('✨ All videos captured successfully!');
  console.log('📁 Location:', VIDEOS_DIR);
  console.log('');
  console.log('🎬 Videos:');
  console.log('   1. 01_complete_user_flow.webm (~90 seconds)');
  console.log('   2. 02_mobile_responsive.webm (~30 seconds)');
  console.log('   3. 03_config_creation.webm (~40 seconds)');
  console.log('');
  console.log('📋 Next steps:');
  console.log('1. Review videos for quality');
  console.log('2. Convert to MP4 if needed (see docs)');
  console.log('3. Add to AppExchange listing or README');
}

// Run the script
(async () => {
  try {
    await captureVideos();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error capturing videos:', error);
    process.exit(1);
  }
})();

