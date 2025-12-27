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
  console.log(
    `   🎨 Converting to GIF: ${path.basename(gifPath)} @ ${fps} FPS`
  );

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
 * Navigate to app and get component URL (WITHOUT recording)
 */
async function getComponentURL(browser, session) {
  console.log("   📍 Getting component URL (not recorded)...");
  const tempContext = await browser.newContext({
    viewport: VIEWPORT
  });
  const tempPage = await tempContext.newPage();

  await setupTestContext(tempPage, session);
  await tempPage.waitForTimeout(2000);

  // Get the current URL (should be the component page)
  const componentURL = tempPage.url();

  // Save storage state (cookies)
  const storageState = await tempContext.storageState();
  await tempContext.close();

  console.log("   ✅ Component URL:", componentURL);
  return { componentURL, storageState };
}

/**
 * Create recording context and go directly to component
 */
async function createRecordingContextAndNavigate(
  browser,
  componentURL,
  storageState
) {
  const context = await browser.newContext({
    viewport: VIEWPORT,
    storageState: storageState,
    recordVideo: {
      dir: VIDEOS_DIR,
      size: VIEWPORT
    }
  });

  const page = await context.newPage();

  // Go directly to component URL (skips App Launcher)
  await page.goto(componentURL, {
    waitUntil: "domcontentloaded",
    timeout: 30000
  });
  await page.waitForSelector("c-jt-query-viewer", { timeout: 30000 });
  await page.waitForTimeout(1500);

  return { context, page };
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

  // Get component URL once (skips navigation in all GIFs)
  const { componentURL, storageState } = await getComponentURL(
    browser,
    session
  );
  console.log("");

  // ==================================================================
  // GIF 1: Basic Query Execution (10 seconds)
  // Show: Select config → Execute → View results
  // ==================================================================
  console.log("🎥 1/6: Capturing Basic Query Execution...");
  const { context: context1, page: page1 } =
    await createRecordingContextAndNavigate(
      browser,
      componentURL,
      storageState
    );

  try {
    // Select configuration (slower)
    await selectConfiguration(page1, "Customer 360");
    await page1.waitForTimeout(1500);

    // Execute query (slower)
    await executeQuery(page1);
    await page1.waitForTimeout(3000);

    // Scroll to see results
    await page1.evaluate(() =>
      window.scrollTo({ top: 300, behavior: "smooth" })
    );
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
  console.log("🎥 2/6: Capturing Multiple Views (JSON, CSV)...");
  const { context: context2, page: page2 } =
    await createRecordingContextAndNavigate(
      browser,
      componentURL,
      storageState
    );

  try {
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
        const jsonView = document.querySelector(".json-content");
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
        const csvView = document.querySelector(".csv-content");
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
  console.log("🎥 3/6: Capturing Tree View with Child Relationships...");
  const { context: context3, page: page3 } =
    await createRecordingContextAndNavigate(
      browser,
      componentURL,
      storageState
    );

  try {
    // Select a config that has child relationships (Account usually has Contacts, Opportunities)
    await selectConfiguration(page3, "Customer 360");
    await page3.waitForTimeout(1500);

    // Execute query
    await executeQuery(page3);
    await page3.waitForTimeout(2500);

    // Try to expand first row with children (tree view)
    const expandButton = page3
      .locator(
        'lightning-button-icon[icon-name*="chevronright"], tbody lightning-button-icon'
      )
      .first();

    if (await expandButton.isVisible().catch(() => false)) {
      await expandButton.click();
      await page3.waitForTimeout(2500);

      // Scroll to see expanded content
      await page3.evaluate(() =>
        window.scrollTo({ top: 300, behavior: "smooth" })
      );
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
  console.log("🎥 4/6: Capturing Large Dataset with Cursors...");
  const { context: context4, page: page4 } =
    await createRecordingContextAndNavigate(
      browser,
      componentURL,
      storageState
    );

  try {
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
    const paginationInfo = page4
      .locator("text=/showing|results|records/i")
      .first();
    if (await paginationInfo.isVisible().catch(() => false)) {
      await page4.waitForTimeout(2000);
    }

    // Scroll through results
    await page4.evaluate(() =>
      window.scrollTo({ top: 400, behavior: "smooth" })
    );
    await page4.waitForTimeout(1500);
    await page4.evaluate(() => window.scrollTo({ top: 0, behavior: "smooth" }));
    await page4.waitForTimeout(1500);

    console.log("   ✅ Large Dataset captured");
  } finally {
    await context4.close();
  }

  // ==================================================================
  // GIF 5: Create Configuration (12 seconds)
  // Show: Click New Config → Fill form → Show validation
  // ==================================================================
  console.log("🎥 5/6: Capturing Create Configuration...");
  const { context: context5, page: page5 } =
    await createRecordingContextAndNavigate(
      browser,
      componentURL,
      storageState
    );

  try {
    // Click "New Configuration" button
    const newConfigButton = page5
      .locator('button:has-text("New Configuration")')
      .first();

    if (await newConfigButton.isVisible()) {
      await newConfigButton.click();
      await page5.waitForTimeout(1500);

      // Fill configuration name
      const nameInput = page5
        .locator('lightning-input[data-field="name"] input')
        .first();

      if (await nameInput.isVisible().catch(() => false)) {
        await nameInput.click();
        await page5.waitForTimeout(500);
        await nameInput.fill("My Custom Query");
        await page5.waitForTimeout(1200);

        // Fill object name
        const objectInput = page5
          .locator('lightning-input[data-field="object"] input')
          .first();

        if (await objectInput.isVisible().catch(() => false)) {
          await objectInput.click();
          await page5.waitForTimeout(500);
          await objectInput.fill("Account");
          await page5.waitForTimeout(1200);
        }

        // Show fields selection
        const fieldsTextarea = page5
          .locator('lightning-textarea[data-field="fields"] textarea')
          .first();

        if (await fieldsTextarea.isVisible().catch(() => false)) {
          await fieldsTextarea.click();
          await page5.waitForTimeout(500);
          await fieldsTextarea.fill("Id, Name, Type, Industry");
          await page5.waitForTimeout(1500);
        }
      }

      // Close modal (don't save - just demo)
      await page5.keyboard.press("Escape");
      await page5.waitForTimeout(1000);
    }

    console.log("   ✅ Create Configuration captured");
  } finally {
    await context5.close();
  }

  // ==================================================================
  // GIF 6: Run As User (15 seconds)
  // Show: Expand Run As accordion → Select user → Execute with System.runAs → Show results
  // ==================================================================
  console.log("🎥 6/6: Capturing Run As User...");
  const { context: context6, page: page6 } =
    await createRecordingContextAndNavigate(
      browser,
      componentURL,
      storageState
    );

  try {
    // Select a configuration first
    await selectConfiguration(page6, "Account By Name");
    await page6.waitForTimeout(1200);

    // Check if Run As section is available (user has permissions)
    const accordionSection = page6
      .locator('lightning-accordion-section[name="run-as"]')
      .first();
    const accordionExists = (await accordionSection.count()) > 0;

    if (accordionExists) {
      // Expand Run As accordion section if collapsed
      const isExpanded = await accordionSection
        .getAttribute("aria-expanded")
        .then((val) => val === "true")
        .catch(() => false);

      if (!isExpanded) {
        await accordionSection.click();
        await page6.waitForTimeout(1500);
      }

      // Wait for Run As section component to be visible
      const runAsComponent = page6.locator("c-jt-run-as-section").first();
      await runAsComponent.waitFor({ state: "visible", timeout: 5000 });
      await page6.waitForTimeout(1000);

      // Select a user from the combobox
      const userCombobox = page6.locator(
        'c-jt-run-as-section c-jt-searchable-combobox[data-testid="run-as-user-selector"]'
      );
      const userInput = userCombobox.locator("input").first();

      if (await userInput.isVisible({ timeout: 5000 }).catch(() => false)) {
        await userInput.click();
        await page6.waitForTimeout(1000);

        // Search for a user (try common names)
        await userInput.fill("Mariano");
        await page6.waitForTimeout(1500);

        // Select first option if available
        const userDropdown = userCombobox.locator(".slds-listbox").first();
        const userOptions = userDropdown.locator(".slds-listbox__item");
        const userCount = await userOptions.count();

        if (userCount > 0) {
          await userOptions.first().click();
          await page6.waitForTimeout(1500);

          // Fill parameter if needed (for Account By Name)
          const paramInput = page6
            .locator('lightning-input[data-testid*="parameter"] input')
            .first();
          if (
            await paramInput.isVisible({ timeout: 2000 }).catch(() => false)
          ) {
            await paramInput.fill("Dynamic");
            await page6.waitForTimeout(1000);
          }

          // Execute query with "Execute with System.runAs" button
          const executeRunAsButton = page6
            .locator('button:has-text("Execute with System.runAs")')
            .first();

          if (
            await executeRunAsButton
              .isVisible({ timeout: 5000 })
              .catch(() => false)
          ) {
            await executeRunAsButton.click();
            await page6.waitForTimeout(3000);

            // Wait for results or test execution status
            const resultsSection = page6.locator("c-jt-query-results").first();
            const testStatus = page6
              .locator("text=/Running|Completed|Failed/i")
              .first();

            // Wait for either results or status message
            await Promise.race([
              resultsSection
                .waitFor({ state: "visible", timeout: 10000 })
                .catch(() => null),
              testStatus
                .waitFor({ state: "visible", timeout: 10000 })
                .catch(() => null),
              page6.waitForTimeout(5000)
            ]);

            // Scroll to see results if available
            await page6.evaluate(() =>
              window.scrollTo({ top: 400, behavior: "smooth" })
            );
            await page6.waitForTimeout(2000);
          }
        } else {
          // If no users found, just show the search box
          await page6.waitForTimeout(1500);
        }
      }
    } else {
      // If Run As section is not available, show a message
      console.log(
        "   ⚠️  Run As section not available (user lacks permissions)"
      );
      await page6.waitForTimeout(2000);
    }

    console.log("   ✅ Run As User captured");
  } finally {
    await context6.close();
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

  if (videoFiles.length >= 6) {
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

    await convertToGif(
      path.join(VIDEOS_DIR, videoFiles[4]),
      path.join(GIFS_DIR, "05-create-config.gif"),
      6 // Slower to see form filling
    );

    await convertToGif(
      path.join(VIDEOS_DIR, videoFiles[5]),
      path.join(GIFS_DIR, "06-run-as-user.gif"),
      6 // Slower to see user selection
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
  console.log(
    "   4. 04-large-dataset.gif - Large datasets with cursors (>50k)"
  );
  console.log("   5. 05-create-config.gif - Create custom configuration");
  console.log("   6. 06-run-as-user.gif - Run queries as different users");
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
      console.error(
        "   Windows: Download from https://ffmpeg.org/download.html"
      );
      process.exit(1);
    }

    await captureHappyPaths();
    process.exit(0);
  } catch (error) {
    console.error("❌ Error capturing GIFs:", error);
    process.exit(1);
  }
})();
