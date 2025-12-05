/**
 * @description AppExchange Screenshot Generator
 * @author Jaime Terrats
 * @date 2025-11-30
 *
 * Captures high-quality screenshots for AppExchange listing
 * Requirements: 1280x800px minimum, professional quality
 */
const { chromium } = require("@playwright/test");
const {
  getSFSession,
  injectSFSession,
  navigateToApp
} = require("../e2e/utils/sfAuth");
const fs = require("fs");
const path = require("path");

const SCREENSHOTS_DIR = path.join(__dirname, "../../screenshots/appexchange");
const TARGET_APP_NAME = "Dynamic Queries";
const QUERY_VIEWER_TAB = "Query Viewer";
const SUPPORT_TAB = "Support";

// Screenshot configuration
const VIEWPORT = { width: 1280, height: 800 };
const QUALITY = 100; // PNG quality

async function captureScreenshots() {
  // Create screenshots directory
  if (!fs.existsSync(SCREENSHOTS_DIR)) {
    fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true });
  }

  console.log("🎬 Starting AppExchange Screenshot Capture");
  console.log("📁 Output directory:", SCREENSHOTS_DIR);
  console.log("📐 Viewport:", `${VIEWPORT.width}x${VIEWPORT.height}`);
  console.log("");

  const browser = await chromium.launch({ headless: false }); // Visible for verification
  const context = await browser.newContext({ viewport: VIEWPORT });
  const page = await context.newPage();

  try {
    // Get SF session
    const session = getSFSession();
    console.log("✅ Authenticated:", session.username);

    // Inject session
    await injectSFSession(page, session);

    // Navigate to app
    const navigated = await navigateToApp(page, TARGET_APP_NAME);
    if (!navigated) {
      throw new Error("Failed to navigate to app");
    }

    await page.waitForTimeout(2000);

    // ==================================================================
    // SCREENSHOT 1: Main Interface - Configuration Selection
    // ==================================================================
    console.log("📸 1/8: Capturing main interface...");
    await page
      .locator(`one-app-nav-bar-item-root a[title="${QUERY_VIEWER_TAB}"]`)
      .first()
      .click();
    await page.waitForLoadState("domcontentloaded");
    await page.waitForSelector("c-jt-query-viewer", { timeout: 30000 });
    await page.waitForTimeout(3000); // Let UI settle

    await page.screenshot({
      path: path.join(SCREENSHOTS_DIR, "01_main_interface.png"),
      fullPage: false
    });
    console.log("   ✅ Saved: 01_main_interface.png");

    // ==================================================================
    // SCREENSHOT 2: Configuration Dropdown Open
    // ==================================================================
    console.log("📸 2/8: Capturing configuration dropdown...");
    const combobox = page.locator("c-jt-searchable-combobox input").first();
    await combobox.click();
    await page.waitForTimeout(500);

    await page.screenshot({
      path: path.join(SCREENSHOTS_DIR, "02_configuration_dropdown.png"),
      fullPage: false
    });
    console.log("   ✅ Saved: 02_configuration_dropdown.png");

    // ==================================================================
    // SCREENSHOT 3: Configuration Selected + Query Preview
    // ==================================================================
    console.log("📸 3/8: Capturing selected configuration...");
    await combobox.fill("Account");
    await page.waitForTimeout(500);
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("Enter");
    await page.waitForTimeout(2000);

    await page.screenshot({
      path: path.join(SCREENSHOTS_DIR, "03_config_selected_preview.png"),
      fullPage: false
    });
    console.log("   ✅ Saved: 03_config_selected_preview.png");

    // ==================================================================
    // SCREENSHOT 4: Query Results - Table View
    // ==================================================================
    console.log("📸 4/8: Capturing query results...");
    const executeButton = page.locator("c-jt-execute-button button").first();
    await executeButton.click();
    await page.waitForSelector("c-jt-query-results", { timeout: 30000 });
    await page.waitForTimeout(3000); // Let results render

    await page.screenshot({
      path: path.join(SCREENSHOTS_DIR, "04_query_results_table.png"),
      fullPage: true // Capture full results
    });
    console.log("   ✅ Saved: 04_query_results_table.png");

    // ==================================================================
    // SCREENSHOT 5: JSON View
    // ==================================================================
    console.log("📸 5/8: Capturing JSON view...");
    const jsonButton = page.locator('button:has-text("JSON")').first();
    if (await jsonButton.isVisible()) {
      await jsonButton.click();
      await page.waitForTimeout(1000);

      await page.screenshot({
        path: path.join(SCREENSHOTS_DIR, "05_json_view.png"),
        fullPage: true
      });
      console.log("   ✅ Saved: 05_json_view.png");
    }

    // ==================================================================
    // SCREENSHOT 6: Mobile Responsive View
    // ==================================================================
    console.log("📸 6/8: Capturing mobile view...");
    await page.setViewportSize({ width: 375, height: 667 });
    await page.waitForTimeout(2000);

    // Go back to table view first
    const tableButton = page.locator('button:has-text("Table")').first();
    if (await tableButton.isVisible()) {
      await tableButton.click();
      await page.waitForTimeout(1000);
    }

    await page.screenshot({
      path: path.join(SCREENSHOTS_DIR, "06_mobile_view.png"),
      fullPage: true
    });
    console.log("   ✅ Saved: 06_mobile_view.png");

    // Reset viewport
    await page.setViewportSize(VIEWPORT);
    await page.waitForTimeout(1000);

    // ==================================================================
    // SCREENSHOT 7: Create Configuration Modal
    // ==================================================================
    console.log("📸 7/8: Capturing create config modal...");
    const createButton = page
      .locator('button:has-text("New Configuration")')
      .first();
    if (await createButton.isVisible()) {
      await createButton.click();
      await page.waitForSelector('[role="dialog"]', { timeout: 5000 });
      await page.waitForTimeout(1000);

      await page.screenshot({
        path: path.join(SCREENSHOTS_DIR, "07_create_config_modal.png"),
        fullPage: false
      });
      console.log("   ✅ Saved: 07_create_config_modal.png");

      // Close modal
      await page.keyboard.press("Escape");
      await page.waitForTimeout(500);
    }

    // ==================================================================
    // SCREENSHOT 8: Support Page
    // ==================================================================
    console.log("📸 8/8: Capturing support page...");
    const supportTab = page
      .locator(`one-app-nav-bar-item-root a[title="${SUPPORT_TAB}"]`)
      .first();
    if (await supportTab.isVisible()) {
      await supportTab.click();
      await page.waitForLoadState("domcontentloaded");
      await page.waitForSelector("c-jt-support", { timeout: 10000 });
      await page.waitForTimeout(2000);

      await page.screenshot({
        path: path.join(SCREENSHOTS_DIR, "08_support_page.png"),
        fullPage: true
      });
      console.log("   ✅ Saved: 08_support_page.png");
    }

    console.log("");
    console.log("✨ All screenshots captured successfully!");
    console.log("📁 Location:", SCREENSHOTS_DIR);
    console.log("");
    console.log("📋 Next steps:");
    console.log("1. Review screenshots for quality");
    console.log("2. Crop/optimize if needed (1280x800 minimum)");
    console.log("3. Add to AppExchange listing");
  } catch (error) {
    console.error("❌ Error capturing screenshots:", error);

    // Capture error screenshot
    await page.screenshot({
      path: path.join(SCREENSHOTS_DIR, "ERROR_screenshot.png")
    });

    throw error;
  } finally {
    await browser.close();
  }
}

// Run the script
(async () => {
  try {
    await captureScreenshots();
    process.exit(0);
  } catch (error) {
    console.error("Fatal error:", error);
    process.exit(1);
  }
})();


