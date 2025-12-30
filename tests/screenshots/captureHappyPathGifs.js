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
const { SELECTORS } = require("../e2e/utils/testConstants");
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
 * Get component URL once (without recording) - starts directly in Query Viewer tab
 */
async function getComponentURL(browser, session) {
  console.log("   📍 Getting component URL (not recorded)...");
  const tempContext = await browser.newContext({
    viewport: VIEWPORT
  });
  const tempPage = await tempContext.newPage();

  // Navigate to app and Query Viewer tab
  await setupTestContext(tempPage, session, {
    targetTab: "Query Viewer",
    waitForComponent: true
  });
  await tempPage.waitForTimeout(2000);

  // Get the current URL (should be the Query Viewer component page)
  const componentURL = tempPage.url();

  // Save storage state (cookies)
  const storageState = await tempContext.storageState();
  await tempContext.close();

  console.log("   ✅ Component URL:", componentURL);
  return { componentURL, storageState };
}

/**
 * Create recording context and navigate directly to component URL
 * This starts directly in Query Viewer tab without showing App Launcher
 * @param {string} videoName - Name for the video file (without extension)
 */
async function createRecordingContextAndNavigate(
  browser,
  componentURL,
  storageState,
  videoName
) {
  const context = await browser.newContext({
    viewport: VIEWPORT,
    storageState: storageState,
    recordVideo: {
      dir: VIDEOS_DIR,
      size: VIEWPORT,
      path: path.join(VIDEOS_DIR, `${videoName}.webm`) // Explicit video filename
    }
  });

  const page = await context.newPage();

  // Go directly to component URL (skips App Launcher, starts in Query Viewer)
  await page.goto(componentURL, {
    waitUntil: "domcontentloaded",
    timeout: 30000
  });
  await page.waitForSelector("c-jt-query-viewer", { timeout: 30000 });
  await page.waitForTimeout(2000); // Wait for component to stabilize

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

  // Get component URL once (starts directly in Query Viewer tab)
  const { componentURL, storageState } = await getComponentURL(
    browser,
    session
  );
  console.log("");

  // Array to store video file paths mapped to their intended names
  const videoFilesMap = new Map();

  // ==================================================================
  // GIF 1: Basic Query Execution (10 seconds)
  // Show: Select config → Execute → View results (NO view switching)
  // ==================================================================
  console.log("🎥 1/6: Capturing Basic Query Execution...");
  const { context: context1, page: page1 } =
    await createRecordingContextAndNavigate(
      browser,
      componentURL,
      storageState,
      "01-query-execution"
    );

  try {
    // Select configuration (use label that matches Custom Metadata)
    await selectConfiguration(page1, "Customer 360 View");
    await page1.waitForTimeout(2000);

    // Wait for any parameters to appear and fill them if needed
    const paramInput = page1
      .locator('lightning-input[data-testid*="parameter"] input')
      .first();
    if (await paramInput.isVisible({ timeout: 3000 }).catch(() => false)) {
      await paramInput.fill("Customer");
      await page1.waitForTimeout(1000);
    }

    // Execute query
    await executeQuery(page1);
    await page1.waitForTimeout(5000); // Wait longer for results

    // Wait for results to appear
    const resultsSection = page1.locator("c-jt-query-results").first();
    await resultsSection
      .waitFor({ state: "visible", timeout: 15000 })
      .catch(() => {
        console.log("   ⚠️  Results may not have appeared");
      });

    // Scroll to see results (NO clicking on table/json/csv buttons)
    await page1.waitForTimeout(2000); // Show results in table view
    await page1.evaluate(() =>
      window.scrollTo({ top: 400, behavior: "smooth" })
    );
    await page1.waitForTimeout(2000);
    await page1.evaluate(() => window.scrollTo({ top: 0, behavior: "smooth" }));
    await page1.waitForTimeout(1500);

    console.log("   ✅ Basic Query Execution captured");
  } catch (error) {
    console.error("   ❌ Error capturing Query Execution:", error.message);
    throw error;
  } finally {
    // Get video path before closing
    const video = page1.video();
    const videoPath = video ? await video.path() : null;
    await context1.close();
    // Wait for video to be saved and map it to intended name
    if (videoPath) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      videoFilesMap.set("01-query-execution.webm", videoPath);
      console.log(`   📹 Video saved: ${path.basename(videoPath)}`);
    }
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
      storageState,
      "02-multiple-views"
    );

  try {
    // Select configuration
    await selectConfiguration(page2, "Customer 360 View");
    await page2.waitForTimeout(2000);

    // Wait for any parameters to appear and fill them if needed
    const paramInput = page2
      .locator('lightning-input[data-testid*="parameter"] input')
      .first();
    if (await paramInput.isVisible({ timeout: 3000 }).catch(() => false)) {
      await paramInput.fill("Customer");
      await page2.waitForTimeout(1000);
    }

    // Execute query
    await executeQuery(page2);
    await page2.waitForTimeout(5000); // Wait longer for results to appear

    // Wait for results component to be visible
    const resultsComponent = page2.locator("c-jt-query-results").first();
    await resultsComponent.waitFor({ state: "visible", timeout: 15000 });

    // Switch to JSON view - use more specific selector
    const jsonButton = page2
      .locator("c-jt-query-results")
      .locator('button:has-text("JSON"), button[title*="JSON"]')
      .first();
    if (await jsonButton.isVisible({ timeout: 5000 }).catch(() => false)) {
      await jsonButton.click();
      await page2.waitForTimeout(2000); // Wait for JSON view to render

      // Wait for JSON content to be visible
      await page2.waitForSelector("c-jt-query-results .json-content, c-jt-query-results pre", {
        state: "visible",
        timeout: 5000
      }).catch(() => {});

      // Scroll down the page to show JSON content
      await page2.evaluate(() => {
        window.scrollTo({ top: 500, behavior: "smooth" });
      });
      await page2.waitForTimeout(2000);

      // Also scroll within the JSON content element if it exists
      await page2.evaluate(() => {
        const jsonView = document.querySelector("c-jt-query-results .json-content, c-jt-query-results pre");
        if (jsonView) {
          jsonView.scrollTop = 200;
        }
      });
      await page2.waitForTimeout(2000);
    } else {
      console.log("   ⚠️  JSON button not found");
    }

    // Switch to CSV view - use more specific selector
    const csvButton = page2
      .locator("c-jt-query-results")
      .locator('button:has-text("CSV"), button[title*="CSV"]')
      .first();
    if (await csvButton.isVisible({ timeout: 5000 }).catch(() => false)) {
      await csvButton.click();
      await page2.waitForTimeout(2000); // Wait for CSV view to render

      // Wait for CSV content to be visible
      await page2.waitForSelector("c-jt-query-results .csv-content, c-jt-query-results pre", {
        state: "visible",
        timeout: 5000
      }).catch(() => {});

      // Scroll down the page to show CSV content
      await page2.evaluate(() => {
        window.scrollTo({ top: 500, behavior: "smooth" });
      });
      await page2.waitForTimeout(2000);

      // Also scroll within the CSV content element if it exists
      await page2.evaluate(() => {
        const csvView = document.querySelector("c-jt-query-results .csv-content, c-jt-query-results pre");
        if (csvView) {
          csvView.scrollTop = 150;
        }
      });
      await page2.waitForTimeout(2000);
    } else {
      console.log("   ⚠️  CSV button not found");
    }

    // Back to Table view - use more specific selector
    const tableButton = page2
      .locator("c-jt-query-results")
      .locator('button:has-text("Table"), button[title*="Table"]')
      .first();
    if (await tableButton.isVisible({ timeout: 5000 }).catch(() => false)) {
      await tableButton.click();
      await page2.waitForTimeout(2000);
    } else {
      console.log("   ⚠️  Table button not found");
    }

    console.log("   ✅ Multiple Views captured");
  } finally {
    const video = page2.video();
    const videoPath = video ? await video.path() : null;
    await context2.close();
    if (videoPath) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      videoFilesMap.set("02-multiple-views.webm", videoPath);
      console.log(`   📹 Video saved: ${path.basename(videoPath)}`);
    }
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
      storageState,
      "03-tree-view"
    );

  try {
    // Select a config that has child relationships (Account usually has Contacts, Opportunities)
    await selectConfiguration(page3, "Customer 360 View");
    await page3.waitForTimeout(2000);

    // Wait for any parameters to appear and fill them if needed
    const paramInput = page3
      .locator('lightning-input[data-testid*="parameter"] input')
      .first();
    if (await paramInput.isVisible({ timeout: 3000 }).catch(() => false)) {
      await paramInput.fill("Customer");
      await page3.waitForTimeout(1000);
    }

    // Execute query
    await executeQuery(page3);
    await page3.waitForTimeout(3000); // Wait longer for results

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
    const video = page3.video();
    const videoPath = video ? await video.path() : null;
    await context3.close();
    if (videoPath) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      videoFilesMap.set("03-tree-view.webm", videoPath);
      console.log(`   📹 Video saved: ${path.basename(videoPath)}`);
    }
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
      storageState,
      "04-large-dataset"
    );

  try {
    // Select configuration that returns many records
    // Use "Account By Name" which should return multiple accounts
    await selectConfiguration(page4, "Account By Name");
    await page4.waitForTimeout(2000);

    // Fill parameter with wildcard to get many records
    const paramInput = page4
      .locator('lightning-input[data-testid*="parameter"] input')
      .first();
    if (await paramInput.isVisible({ timeout: 3000 }).catch(() => false)) {
      await paramInput.fill("%");
      await page4.waitForTimeout(1000);
    }

    // Execute query
    await executeQuery(page4);
    await page4.waitForTimeout(4000); // Wait longer for results

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
    const video = page4.video();
    const videoPath = video ? await video.path() : null;
    await context4.close();
    if (videoPath) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      videoFilesMap.set("04-large-dataset.webm", videoPath);
      console.log(`   📹 Video saved: ${path.basename(videoPath)}`);
    }
  }

  // ==================================================================
  // GIF 5: Create Configuration (15 seconds)
  // Show: Click New Config → Fill form → Save → Show success message
  // ==================================================================
  console.log("🎥 5/6: Capturing Create Configuration...");
  const { context: context5, page: page5 } =
    await createRecordingContextAndNavigate(
      browser,
      componentURL,
      storageState,
      "05-create-config"
    );

  try {
    // Wait for component to be fully loaded and stable
    await page5.waitForSelector("c-jt-query-viewer", { timeout: 30000 });
    await page5.waitForTimeout(2000); // Wait for any initial loading to complete

    // Make sure no configuration is selected (clear any selection)
    // Use same selector as E2E tests
    const configInput = page5.locator(SELECTORS.configSelectorInput).first();
    if (await configInput.isVisible({ timeout: 3000 }).catch(() => false)) {
      // Clear any existing selection by clicking and clearing
      await configInput.click();
      await page5.waitForTimeout(500);
      await configInput.fill("");
      await page5.waitForTimeout(1000);
      // Press Escape to close dropdown if open
      await page5.keyboard.press("Escape");
      await page5.waitForTimeout(1000);
    }

    // Click "Create Configuration" button (same selector as E2E tests)
    const createButton = page5
      .locator("lightning-button")
      .filter({ hasText: /Create.*Configuration/i })
      .first();

    if (await createButton.isVisible({ timeout: 10000 })) {
      await createButton.click();
      await page5.waitForTimeout(1000); // Wait longer for modal to open

      // Wait for modal to be visible (same selector as E2E tests)
      const modal = page5.locator('section[role="dialog"]').first();
      await modal.waitFor({ state: "visible", timeout: 5000 });

      // Fill Label (same as E2E tests - uses "label" field, not "name")
      const labelInput = modal
        .locator('lightning-input[data-field="label"]')
        .first();
      if (await labelInput.isVisible({ timeout: 5000 }).catch(() => false)) {
        await labelInput.locator("input").click();
        await page5.waitForTimeout(300);
        await labelInput.locator("input").fill("Demo Query Configuration");
        await page5.waitForTimeout(1000); // Wait for auto-generation of Developer Name

        // Fill base query (same field name as E2E tests)
        const queryTextarea = modal
          .locator('lightning-textarea[data-field="baseQuery"]')
          .first();

        if (
          await queryTextarea.isVisible({ timeout: 3000 }).catch(() => false)
        ) {
          await queryTextarea.locator("textarea").click();
          await page5.waitForTimeout(300);
          await queryTextarea
            .locator("textarea")
            .fill("SELECT Id, Name, Type, Industry FROM Account LIMIT 10");
          await page5.waitForTimeout(1500);
        }

        // Fill object name (same as E2E tests)
        const objectInput = modal
          .locator('lightning-input[data-field="object"]')
          .first();
        if (await objectInput.isVisible({ timeout: 3000 }).catch(() => false)) {
          await objectInput.locator("input").click();
          await page5.waitForTimeout(300);
          await objectInput.locator("input").fill("Account");
          await page5.waitForTimeout(1000);
        }

        // Show the form filled out for a moment
        await page5.waitForTimeout(2000);

        // Click Save button (not Cancel - show the save process)
        const saveButton = modal
          .locator("lightning-button")
          .filter({ hasText: /Save/i })
          .first();
        if (
          await saveButton.isVisible({ timeout: 3000 }).catch(() => false)
        ) {
          await saveButton.click();
          await page5.waitForTimeout(3000); // Wait for save to complete

          // Wait for success toast or modal to close
          const toast = page5.locator("lightning-toast").first();
          await toast
            .waitFor({ state: "visible", timeout: 5000 })
            .catch(() => {});
          await page5.waitForTimeout(2000); // Show success message

          // Modal should close automatically, but wait a bit
          await page5.waitForTimeout(1500);
        } else {
          console.log("   ⚠️  Save button not found");
        }
      }
    } else {
      console.log(
        "   ⚠️  New Configuration button not found (may be in production org)"
      );
      await page5.waitForTimeout(2000);
    }

    console.log("   ✅ Create Configuration captured");
  } catch (error) {
    console.error("   ❌ Error capturing Create Configuration:", error.message);
    // Don't throw - continue with other GIFs
  } finally {
    const video = page5.video();
    const videoPath = video ? await video.path() : null;
    await context5.close();
    if (videoPath) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      videoFilesMap.set("05-create-config.webm", videoPath);
      console.log(`   📹 Video saved: ${path.basename(videoPath)}`);
    }
  }

  // ==================================================================
  // GIF 6: Run As User (20 seconds)
  // Show: Expand Run As accordion → Select user → Execute with System.runAs → Show results
  // ==================================================================
  console.log("🎥 6/6: Capturing Run As User...");
  const { context: context6, page: page6 } =
    await createRecordingContextAndNavigate(
      browser,
      componentURL,
      storageState,
      "06-run-as-user"
    );

  try {
    // Wait for component to be fully loaded and stable
    await page6.waitForSelector("c-jt-query-viewer", { timeout: 30000 });
    await page6.waitForTimeout(2000); // Wait for any initial loading to complete

    // Select a configuration first (use one that works well)
    await selectConfiguration(page6, "Account By Name");
    await page6.waitForTimeout(3000); // Wait longer for configuration to load and stabilize

    // Fill parameter first (before opening Run As)
    const paramInput = page6
      .locator('lightning-input[data-testid*="parameter"] input')
      .first();
    if (await paramInput.isVisible({ timeout: 3000 }).catch(() => false)) {
      await paramInput.fill("%");
      await page6.waitForTimeout(1000);
    }

    // Scroll to top to ensure accordion is visible
    await page6.evaluate(() => window.scrollTo({ top: 0, behavior: "smooth" }));
    await page6.waitForTimeout(1000);

    // Try multiple selectors to find the Run As accordion section
    let accordionSection = page6
      .locator('lightning-accordion-section[name="run-as"]')
      .first();

    // If not found, try alternative selector
    if ((await accordionSection.count()) === 0) {
      accordionSection = page6
        .locator('lightning-accordion-section')
        .filter({ hasText: /Run As|run as/i })
        .first();
    }

    const accordionExists = (await accordionSection.count()) > 0;

    if (accordionExists) {
      // Scroll to accordion to make it visible
      await accordionSection.scrollIntoViewIfNeeded();
      await page6.waitForTimeout(1000);

      // Expand Run As accordion section if collapsed
      const isExpanded = await accordionSection
        .getAttribute("aria-expanded")
        .then((val) => val === "true")
        .catch(() => false);

      if (!isExpanded) {
        console.log("   📂 Expanding Run As accordion...");
        // Click on the accordion header/button
        const accordionButton = accordionSection.locator("button").first();
        if (await accordionButton.isVisible({ timeout: 5000 }).catch(() => false)) {
          await accordionButton.click();
        } else {
          await accordionSection.click();
        }
        await page6.waitForTimeout(4000); // Wait longer for accordion to expand and show content
      } else {
        console.log("   ✅ Run As accordion already expanded");
        await page6.waitForTimeout(2000);
      }

      // Scroll down a bit to show the expanded content
      await page6.evaluate(() => window.scrollTo({ top: 300, behavior: "smooth" }));
      await page6.waitForTimeout(2000);

      // Wait for Run As section component to be visible (if permissions allow)
      const runAsComponent = page6.locator("c-jt-run-as-section").first();
      const componentVisible = await runAsComponent
        .isVisible({ timeout: 5000 })
        .catch(() => false);

      if (componentVisible) {
        await page6.waitForTimeout(2000); // Wait for component to fully load

        // Select a user from the combobox
        const userCombobox = page6.locator(
          'c-jt-run-as-section c-jt-searchable-combobox[data-testid="run-as-user-selector"]'
        );
        const userInput = userCombobox.locator("input").first();

        if (await userInput.isVisible({ timeout: 10000 }).catch(() => false)) {
          console.log("   👤 Clicking user selector...");
          await userInput.scrollIntoViewIfNeeded();
          await page6.waitForTimeout(1000);
          await userInput.click();
          await page6.waitForTimeout(3000); // Wait longer for dropdown to open

          // Clear any existing text and wait for dropdown
          await userInput.fill("");
          await page6.waitForTimeout(2000);

          // Try to get users from dropdown
          const userDropdown = userCombobox.locator(".slds-listbox").first();
          let dropdownVisible = await userDropdown
            .isVisible({ timeout: 5000 })
            .then(() => true)
            .catch(() => false);

          if (!dropdownVisible) {
            console.log("   ⚠️  User dropdown not visible, trying to type...");
            // Try typing to trigger dropdown
            await userInput.fill("a");
            await page6.waitForTimeout(2000);
            // Try waiting again after typing
            dropdownVisible = await userDropdown
              .isVisible({ timeout: 5000 })
              .then(() => true)
              .catch(() => false);
          }

          await page6.waitForTimeout(2000);

          const userOptions = userDropdown.locator(".slds-listbox__item");
          const userCount = await userOptions.count();

          console.log(`   📋 Found ${userCount} user(s) in dropdown`);

          if (userCount > 0) {
            // Select the first available user
            console.log("   ✅ Selecting first user...");
            await userOptions.first().scrollIntoViewIfNeeded();
            await page6.waitForTimeout(500);
            await userOptions.first().click();
            await page6.waitForTimeout(5000); // Wait longer for selection to register

            // Scroll to show the execute button area
            await page6.evaluate(() => window.scrollTo({ top: 300, behavior: "smooth" }));
            await page6.waitForTimeout(2000);

            // The execute button label changes when a user is selected
            // Try multiple selectors for the execute button
            const executeButton = page6
              .locator('c-jt-execute-button lightning-button, lightning-button[data-testid="execute-query-button"], lightning-button:has-text("Execute"), lightning-button[label*="Execute"]')
              .first();

            if (
              await executeButton
                .isVisible({ timeout: 10000 })
                .catch(() => false)
            ) {
              console.log("   ▶️  Clicking Execute button (will use System.runAs)...");
              await executeButton.scrollIntoViewIfNeeded();
              await page6.waitForTimeout(1000);
              await executeButton.click();
              await page6.waitForTimeout(12000); // Wait longer for test execution

              // Wait for results or test execution status
              const resultsSection = page6.locator("c-jt-query-results").first();
              const testStatus = page6
                .locator("text=/Running|Completed|Failed|Test execution|executing/i")
                .first();
              const spinnerOverlay = page6.locator(".run-as-spinner-overlay").first();

              // Wait longer for either results, status message, or spinner
              console.log("   ⏳ Waiting for execution results...");
              await Promise.race([
                resultsSection
                  .waitFor({ state: "visible", timeout: 25000 })
                  .catch(() => null),
                testStatus
                  .waitFor({ state: "visible", timeout: 25000 })
                  .catch(() => null),
                spinnerOverlay
                  .waitFor({ state: "visible", timeout: 5000 })
                  .then(() => {
                    console.log("   ⏳ Test execution spinner visible...");
                    return spinnerOverlay.waitFor({ state: "hidden", timeout: 20000 }).catch(() => null);
                  })
                  .catch(() => null),
                page6.waitForTimeout(15000) // Wait at least 15 seconds
              ]);

              // Wait a bit for any error/access messages to appear
              await page6.waitForTimeout(2000);

              // Scroll up to show the access denied message or error message
              console.log("   📜 Scrolling up to show access message...");
              await page6.evaluate(() =>
                window.scrollTo({ top: 0, behavior: "smooth" })
              );
              await page6.waitForTimeout(3000); // Show the message at the top

              // Also check for error messages or test assertion messages
              const errorMessage = page6.locator("text=/access|permission|denied|insufficient/i").first();
              const testAssertMessage = page6.locator("text=/Test Assertion|assertion/i").first();

              if (await errorMessage.isVisible({ timeout: 3000 }).catch(() => false)) {
                await errorMessage.scrollIntoViewIfNeeded();
                await page6.waitForTimeout(2000);
              } else if (await testAssertMessage.isVisible({ timeout: 3000 }).catch(() => false)) {
                await testAssertMessage.scrollIntoViewIfNeeded();
                await page6.waitForTimeout(2000);
              }

              // Scroll down a bit to show results if available
              await page6.evaluate(() =>
                window.scrollTo({ top: 300, behavior: "smooth" })
              );
              await page6.waitForTimeout(3000); // Show results area
              console.log("   ✅ Run As execution completed");
            } else {
              console.log("   ⚠️  Execute button not found");
              // Still show the accordion expanded with user selected
              await page6.waitForTimeout(3000);
            }
          } else {
            // If no users found, show the search box open
            console.log("   ⚠️  No users found in dropdown");
            await page6.waitForTimeout(3000);
          }
        } else {
          console.log("   ⚠️  User input not found - showing accordion expanded");
          // Still show the accordion expanded
          await page6.waitForTimeout(3000);
        }
      } else {
        console.log("   ⚠️  Run As component not visible (user lacks permissions) - showing accordion expanded");
        // Still show the accordion expanded even without permissions
        await page6.waitForTimeout(3000);
      }
    } else {
      // If Run As section is not available, try to find it anyway
      console.log("   ⚠️  Run As accordion not found with standard selector, trying alternatives...");
      // Try to find any accordion and show it
      const anyAccordion = page6.locator("lightning-accordion").first();
      if (await anyAccordion.isVisible({ timeout: 5000 }).catch(() => false)) {
        await anyAccordion.scrollIntoViewIfNeeded();
        await page6.waitForTimeout(2000);
      }
      await page6.waitForTimeout(2000);
    }

    console.log("   ✅ Run As User captured");
  } catch (error) {
    console.error("   ❌ Error capturing Run As User:", error.message);
    // Don't throw - continue with GIF conversion
  } finally {
    const video = page6.video();
    const videoPath = video ? await video.path() : null;
    await context6.close();
    if (videoPath) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      videoFilesMap.set("06-run-as-user.webm", videoPath);
      console.log(`   📹 Video saved: ${path.basename(videoPath)}`);
    }
  }

  await browser.close();

  // ==================================================================
  // Convert videos to GIFs
  // ==================================================================
  console.log("");
  console.log("🎨 Converting videos to GIFs...");

  // Wait a bit for all videos to be fully written
  await new Promise((resolve) => setTimeout(resolve, 3000));

  // Use the video files map we created during capture
  const videoMappings = [
    { video: "01-query-execution.webm", gif: "01-query-execution.gif" },
    { video: "02-multiple-views.webm", gif: "02-multiple-views.gif" },
    { video: "03-tree-view.webm", gif: "03-tree-view.gif" },
    { video: "04-large-dataset.webm", gif: "04-large-dataset.gif" },
    { video: "05-create-config.webm", gif: "05-create-config.gif" },
    { video: "06-run-as-user.webm", gif: "06-run-as-user.gif" }
  ];

  for (const mapping of videoMappings) {
    const actualVideoPath = videoFilesMap.get(mapping.video);
    const gifPath = path.join(GIFS_DIR, mapping.gif);

    if (actualVideoPath && fs.existsSync(actualVideoPath)) {
      console.log(`   ✅ Converting: ${mapping.video} → ${mapping.gif}`);
      await convertToGif(actualVideoPath, gifPath, 6);
    } else {
      console.error(`   ❌ Video not found: ${mapping.video} (mapped path: ${actualVideoPath})`);
    }
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
