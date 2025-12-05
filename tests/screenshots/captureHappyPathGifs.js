/**
 * @description Happy Path GIF Generator for Documentation
 * @author Jaime Terrats
 * @date 2025-12-05
 *
 * Captures short, optimized GIFs showing core functionality
 * Perfect for README and GitHub Pages
 */
const { chromium } = require("@playwright/test");
const { getSFSession } = require("../e2e/utils/sfAuth");
const {
  setupTestContext,
  selectConfiguration,
  executeQuery
} = require("../e2e/utils/testHelpers");
const fs = require("fs");
const path = require("path");
const { exec } = require("child_process");
const util = require("util");

const execPromise = util.promisify(exec);

const VIDEOS_DIR = path.join(__dirname, "../../docs/assets/temp-videos");
const GIFS_DIR = path.join(__dirname, "../../docs/assets/gifs");
const TARGET_APP_NAME = "Dynamic Query Framework";
const VIEWPORT = { width: 1200, height: 750 };

// Ensure directories exist
[VIDEOS_DIR, GIFS_DIR].forEach((dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

/**
 * Convert video to optimized GIF using ffmpeg
 * Lower FPS = slower, more visible GIF
 */
async function convertToGif(videoPath, gifPath, fps = 6) {
  console.log(`   🎨 Converting to GIF: ${path.basename(gifPath)} @ ${fps} FPS`);

  // Generate palette for better quality
  const palettePath = videoPath.replace(".webm", "_palette.png");

  try {
    // Step 1: Generate color palette
    await execPromise(
      `ffmpeg -i "${videoPath}" -vf "fps=${fps},scale=800:-1:flags=lanczos,palettegen" -y "${palettePath}"`
    );

    // Step 2: Create GIF using palette
    await execPromise(
      `ffmpeg -i "${videoPath}" -i "${palettePath}" -filter_complex "fps=${fps},scale=800:-1:flags=lanczos[x];[x][1:v]paletteuse" -y "${gifPath}"`
    );

    // Cleanup palette
    if (fs.existsSync(palettePath)) {
      fs.unlinkSync(palettePath);
    }

    const stats = fs.statSync(gifPath);
    const sizeMB = (stats.size / (1024 * 1024)).toFixed(2);
    console.log(`   ✅ GIF created: ${sizeMB} MB (${fps} FPS)`);
  } catch (error) {
    console.error(`   ❌ Failed to convert: ${error.message}`);
    throw error;
  }
}

/**
 * Helper to start recording after navigation
 */
async function setupAndStartRecording(page, session, waitBeforeStart = 2000) {
  await setupTestContext(page, session);
  // Wait for everything to settle before starting the "interesting" part
  await page.waitForTimeout(waitBeforeStart);
}

/**
 * Capture scenarios
 */
async function captureHappyPaths() {
  console.log("🎬 Starting Functional GIF Capture");
  console.log("📁 Output directory:", GIFS_DIR);
  console.log("📐 Viewport:", `${VIEWPORT.width}x${VIEWPORT.height}`);
  console.log("⏱️  Slower GIFs for better visibility");
  console.log("");

  const browser = await chromium.launch({
    headless: true
  });

  const session = getSFSession();
  console.log("✅ Authenticated:", session.username);
  console.log("");

  // ==================================================================
  // GIF 1: Basic Query Execution (10 seconds)
  // Show: Select config → Execute → View results
  // ==================================================================
  console.log("🎥 1/4: Capturing Basic Query Execution...");
  const context1 = await browser.newContext({
    viewport: VIEWPORT,
    recordVideo: {
      dir: VIDEOS_DIR,
      size: VIEWPORT
    }
  });
  const page1 = await context1.newPage();

  try {
    await setupAndStartRecording(page1, session, 1000);

    // Select configuration (slower)
    await selectConfiguration(page1, "Customer 360");
    await page1.waitForTimeout(1500);

    // Execute query (slower)
    await executeQuery(page1);
    await page1.waitForTimeout(3000);

    // Scroll to see results
    await page1.evaluate(() => window.scrollTo({ top: 300, behavior: "smooth" }));
    await page1.waitForTimeout(2000);
    await page1.evaluate(() => window.scrollTo({ top: 0, behavior: "smooth" }));
    await page1.waitForTimeout(1000);

    console.log("   ✅ Basic Query Execution captured");
  } finally {
    await context1.close();
  }

  // ==================================================================
  // GIF 2: Multiple Views - JSON, CSV (15 seconds)
  // Show: Execute query → Switch to JSON → Switch to CSV → Back to Table
  // ==================================================================
  console.log("🎥 2/4: Capturing Multiple Views (JSON, CSV)...");
  const context2 = await browser.newContext({
    viewport: VIEWPORT,
    recordVideo: {
      dir: VIDEOS_DIR,
      size: VIEWPORT
    }
  });
  const page2 = await context2.newPage();

  try {
    await setupAndStartRecording(page2, session, 1000);

    // Select configuration
    await selectConfiguration(page2, "Customer 360");
    await page2.waitForTimeout(1500);

    // Execute query
    await executeQuery(page2);
    await page2.waitForTimeout(2000);

    // Switch to JSON view
    const jsonButton = page2.locator('button:has-text("JSON")').first();
    if (await jsonButton.isVisible()) {
      await jsonButton.click();
      await page2.waitForTimeout(2500);
      
      // Scroll JSON to show content
      await page2.evaluate(() => {
        const jsonView = document.querySelector('.json-content');
        if (jsonView) jsonView.scrollTop = 100;
      });
      await page2.waitForTimeout(2000);
    }

    // Switch to CSV view
    const csvButton = page2.locator('button:has-text("CSV")').first();
    if (await csvButton.isVisible()) {
      await csvButton.click();
      await page2.waitForTimeout(2500);
      
      // Scroll CSV to show content
      await page2.evaluate(() => {
        const csvView = document.querySelector('.csv-content');
        if (csvView) csvView.scrollTop = 50;
      });
      await page2.waitForTimeout(2000);
    }

    // Back to Table view
    const tableButton = page2.locator('button:has-text("Table")').first();
    if (await tableButton.isVisible()) {
      await tableButton.click();
      await page2.waitForTimeout(1500);
    }

    console.log("   ✅ Multiple Views captured");
  } finally {
    await context2.close();
  }

  // ==================================================================
  // GIF 3: Tree View - Child Relationships (12 seconds)
  // Show: Execute query with relationships → Expand parent → Show children
  // ==================================================================
  console.log("🎥 3/4: Capturing Tree View with Child Relationships...");
  const context3 = await browser.newContext({
    viewport: VIEWPORT,
    recordVideo: {
      dir: VIDEOS_DIR,
      size: VIEWPORT
    }
  });
  const page3 = await context3.newPage();

  try {
    await setupAndStartRecording(page3, session, 1000);

    // Select a config that has child relationships (Account usually has Contacts, Opportunities)
    await selectConfiguration(page3, "Customer 360");
    await page3.waitForTimeout(1500);

    // Execute query
    await executeQuery(page3);
    await page3.waitForTimeout(2500);

    // Try to expand first row with children (tree view)
    const expandButton = page3
      .locator('lightning-button-icon[icon-name*="chevronright"], tbody lightning-button-icon')
      .first();
    
    if (await expandButton.isVisible().catch(() => false)) {
      await expandButton.click();
      await page3.waitForTimeout(2500);
      
      // Scroll to see expanded content
      await page3.evaluate(() => window.scrollTo({ top: 300, behavior: "smooth" }));
      await page3.waitForTimeout(2000);
      
      // Collapse it
      const collapseButton = page3
        .locator('lightning-button-icon[icon-name*="chevrondown"]')
        .first();
      if (await collapseButton.isVisible().catch(() => false)) {
        await collapseButton.click();
        await page3.waitForTimeout(1500);
      }
    }

    console.log("   ✅ Tree View captured");
  } finally {
    await context3.close();
  }

  // ==================================================================
  // GIF 4: Large Dataset (Cursors >50k) (12 seconds)
  // Show: Query with many records → Pagination → Performance message
  // ==================================================================
  console.log("🎥 4/4: Capturing Large Dataset with Cursors...");
  const context4 = await browser.newContext({
    viewport: VIEWPORT,
    recordVideo: {
      dir: VIDEOS_DIR,
      size: VIEWPORT
    }
  });
  const page4 = await context4.newPage();

  try {
    await setupAndStartRecording(page4, session, 1000);

    // Select configuration (ideally one that returns many records)
    // If "All Accounts" exists, use it, otherwise use first available
    const combobox = page4.locator("c-jt-searchable-combobox input").first();
    await combobox.waitFor({ state: "visible", timeout: 15000 });
    await combobox.click();
    await page4.waitForTimeout(800);
    
    // Try to find a config with many records
    await combobox.fill("Account");
    await page4.waitForTimeout(800);
    await page4.keyboard.press("ArrowDown");
    await page4.keyboard.press("Enter");
    await page4.waitForTimeout(1500);

    // Execute query
    await executeQuery(page4);
    await page4.waitForTimeout(3000);

    // Look for pagination or performance message
    const paginationInfo = page4.locator('text=/showing|results|records/i').first();
    if (await paginationInfo.isVisible().catch(() => false)) {
      await page4.waitForTimeout(2000);
    }

    // Scroll through results
    await page4.evaluate(() => window.scrollTo({ top: 400, behavior: "smooth" }));
    await page4.waitForTimeout(1500);
    await page4.evaluate(() => window.scrollTo({ top: 0, behavior: "smooth" }));
    await page4.waitForTimeout(1500);

    console.log("   ✅ Large Dataset captured");
  } finally {
    await context4.close();
  }

  await browser.close();

  // ==================================================================
  // Convert videos to GIFs
  // ==================================================================
  console.log("");
  console.log("🎨 Converting videos to GIFs...");

  const videoFiles = fs
    .readdirSync(VIDEOS_DIR)
    .filter((f) => f.endsWith(".webm"))
    .sort();

  if (videoFiles.length >= 4) {
    await convertToGif(
      path.join(VIDEOS_DIR, videoFiles[0]),
      path.join(GIFS_DIR, "01-query-execution.gif"),
      6 // Slower for better visibility
    );

    await convertToGif(
      path.join(VIDEOS_DIR, videoFiles[1]),
      path.join(GIFS_DIR, "02-multiple-views.gif"),
      6 // Slower to see JSON/CSV content
    );

    await convertToGif(
      path.join(VIDEOS_DIR, videoFiles[2]),
      path.join(GIFS_DIR, "03-tree-view.gif"),
      6 // Slower to see relationships expand
    );

    await convertToGif(
      path.join(VIDEOS_DIR, videoFiles[3]),
      path.join(GIFS_DIR, "04-large-dataset.gif"),
      6 // Slower to see pagination
    );
  }

  // Cleanup temp videos
  console.log("");
  console.log("🧹 Cleaning up temporary files...");
  fs.rmSync(VIDEOS_DIR, { recursive: true, force: true });

  console.log("");
  console.log("✨ All GIFs created successfully!");
  console.log("📁 Location:", GIFS_DIR);
  console.log("");
  console.log("🎬 GIFs (6 FPS for better visibility):");
  console.log("   1. 01-query-execution.gif - Basic query execution");
  console.log("   2. 02-multiple-views.gif - Table, JSON, CSV views");
  console.log("   3. 03-tree-view.gif - Child relationships (tree view)");
  console.log("   4. 04-large-dataset.gif - Large datasets with cursors (>50k)");
  console.log("");
}

// Run the script
(async () => {
  try {
    // Check if ffmpeg is available
    try {
      await execPromise("ffmpeg -version");
    } catch (error) {
      console.error("❌ ffmpeg not found. Please install it first:");
      console.error("   macOS: brew install ffmpeg");
      console.error("   Linux: sudo apt-get install ffmpeg");
      console.error("   Windows: Download from https://ffmpeg.org/download.html");
      process.exit(1);
    }

    await captureHappyPaths();
    process.exit(0);
  } catch (error) {
    console.error("❌ Error capturing GIFs:", error);
    process.exit(1);
  }
})();

