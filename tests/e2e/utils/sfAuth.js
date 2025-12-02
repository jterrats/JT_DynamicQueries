const { execSync } = require("child_process");

/**
 * Gets the active Salesforce org session from SF CLI
 * Uses the already authenticated session - NO LOGIN REQUIRED
 * @returns {Object} Object containing instanceUrl, accessToken, and username
 */
function getSFSession() {
  try {
    console.log("🔑 Using SF CLI active session (no login needed)...");

    // Get org info from SF CLI - uses active session
    // Force plain JSON output (no colors) with SF_USE_PROGRESS_BAR=false
    const orgInfoJson = execSync("sf org display --json", {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
      env: { ...process.env, SF_USE_PROGRESS_BAR: "false", SF_AUTOUPDATE_DISABLE: "true" }
    });

    const orgInfo = JSON.parse(orgInfoJson);

    if (orgInfo.status !== 0) {
      throw new Error(
        "❌ No default org found. Run: sf config set target-org <username>"
      );
    }

    const result = orgInfo.result;

    console.log("✅ Using active session:", result.username);
    console.log("📍 Instance:", result.instanceUrl);

    return {
      instanceUrl: result.instanceUrl,
      accessToken: result.accessToken,
      username: result.username,
      orgId: result.id
    };
  } catch (error) {
    console.error("❌ Error getting SF session:", error.message);
    console.error("💡 Make sure you have an active SF CLI session");
    throw error;
  }
}

/**
 * Creates an authenticated context for Playwright using SF CLI session
 * @param {import('@playwright/test').Browser} browser
 * @returns {Promise<import('@playwright/test').BrowserContext>}
 */
async function createAuthenticatedContext(browser) {
  const session = getSFSession();

  // Create a new context with the SF session
  const context = await browser.newContext({
    storageState: {
      cookies: [
        {
          name: "sid",
          value: session.accessToken,
          domain: new URL(session.instanceUrl).hostname,
          path: "/",
          httpOnly: true,
          secure: true,
          sameSite: "None"
        }
      ],
      origins: []
    }
  });

  return { context, session };
}

/**
 * Injects the SF session directly into the page using CLI session
 * No login required - uses active SF CLI authentication
 * @param {import('@playwright/test').Page} page
 * @param {Object} session - Session object from getSFSession()
 */
async function injectSFSession(page, session) {
  const url = new URL(session.instanceUrl);

  // CRITICAL: Add cookies BEFORE navigating to avoid login redirect
  await page.context().addCookies([
    {
      name: "sid",
      value: session.accessToken,
      domain: url.hostname,
      path: "/",
      httpOnly: false, // Changed to false for Lightning
      secure: true,
      sameSite: "None" // Required for cross-site cookies
    },
    {
      name: "sid_Client",
      value: session.accessToken,
      domain: url.hostname,
      path: "/",
      httpOnly: false,
      secure: true,
      sameSite: "None"
    }
  ]);

  console.log("🔐 Cookies injected, navigating to org...");

  // Navigate with authenticated session (no login page)
  await page.goto(session.instanceUrl + "/lightning/page/home", {
    waitUntil: "domcontentloaded",
    timeout: 30000
  });

  // Verify we're authenticated (no login form)
  const isLoginPage = await page
    .locator('input[type="password"]')
    .isVisible({ timeout: 2000 })
    .catch(() => false);

  if (isLoginPage) {
    throw new Error(
      "❌ Authentication failed - still on login page. Make sure your SF CLI session is active."
    );
  }

  console.log("✅ Authenticated successfully - no login required");

  // Wait for Lightning to load
  await page.waitForSelector("one-appnav", { timeout: 15000 }).catch(() => {
    console.log("⚠️  Lightning navigation not found, continuing...");
  });
}

/**
 * Navigates to a specific Lightning app using App Launcher
 * @param {import('@playwright/test').Page} page
 * @param {string} appName - The name of the app to navigate to
 */
async function navigateToApp(page, appName) {
  try {
    console.log(`🚀 Opening App Launcher to find "${appName}"...`);

    // Step 1: Click the App Launcher (waffle icon)
    const appLauncher = page
      .locator(
        [
          "button.slds-icon-waffle_container",
          'button[title="App Launcher"]',
          "div.appLauncher button",
          "button:has(div.slds-icon-waffle)"
        ].join(", ")
      )
      .first();

    await appLauncher.click({ timeout: 10000 });
    console.log(`✅ App Launcher opened`);

    // Wait for the modal to fully load
    await page.waitForTimeout(2000);

    // Step 2: Force focus on the search input (it might be hidden initially)
    console.log(`🔍 Activating search box...`);

    // Force the input to be visible by executing JS
    await page.evaluate(() => {
      const input = document.querySelector('input[type="search"]');
      if (input) {
        input.tabIndex = 0; // Make it focusable
        input.style.visibility = "visible";
        input.style.display = "block";
      }
    });

    const searchInput = page.locator('input[type="search"]').first();

    // Step 3: Type in the search box (force it even if not fully visible)
    console.log(`⌨️  Typing "${appName}" in search...`);
    await searchInput.focus();
    await page.keyboard.type(appName, { delay: 100 });

    // Alternative: use fill with force option
    // await searchInput.fill(appName, { force: true });

    // Wait for search results
    await page.waitForTimeout(2000);
    console.log(`🔍 Waiting for search results...`);

    // Step 4: Find and click the app in results
    console.log(`🎯 Looking for "${appName}" in results...`);

    // Try multiple selectors for the app tile/link
    const appTile = page
      .locator(
        [
          `one-app-launcher-app-tile:has-text("${appName}")`,
          `a[title="${appName}"]`,
          `a:has-text("${appName}")`,
          `div.slds-app-launcher__tile:has-text("${appName}")`,
          `[data-name="${appName}"]`
        ].join(", ")
      )
      .first();

    // Wait for the app to appear in results
    await appTile.waitFor({ state: "visible", timeout: 5000 });

    console.log(`✅ Found "${appName}" - clicking...`);
    await appTile.click();

    // Step 5: Wait for app to load
    console.log(`⏳ Waiting for app to load...`);
    await page.waitForLoadState("domcontentloaded");
    await page.waitForTimeout(2000); // Extra time for Lightning to settle

    console.log(`✅ Successfully navigated to "${appName}" app`);

    return true;
  } catch (error) {
    console.log(`❌ Error navigating to app: ${error.message}`);
    console.log(`📸 Taking screenshot for debugging...`);

    // Take screenshot for debugging
    try {
      await page.screenshot({
        path: `test-results/app-launcher-error-${Date.now()}.png`,
        fullPage: true
      });
    } catch (e) {
      // Ignore screenshot errors
    }

    console.log(`⚠️  Will try to continue anyway...`);
    return false;
  }
}

/**
 * Gets the current app name from the page
 * @param {import('@playwright/test').Page} page
 * @returns {Promise<string>}
 */
async function getCurrentApp(page) {
  try {
    const appName = await page
      .locator("one-appnav-brand-logo-text")
      .textContent({ timeout: 5000 });
    return appName.trim();
  } catch {
    return "";
  }
}

module.exports = {
  getSFSession,
  createAuthenticatedContext,
  injectSFSession,
  navigateToApp,
  getCurrentApp
};
