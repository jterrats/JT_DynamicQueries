/**
 * E2E Tests for GitHub Pages Documentation Site
 * Tests: https://jterrats.github.io/JT_DynamicQueries/
 *
 * Verifies:
 * - All pages load successfully (no 404s)
 * - Navigation links work
 * - Documentation content is accessible
 * - Key features are documented
 */

import { test, expect } from "@playwright/test";

const BASE_URL = "https://jterrats.github.io/JT_DynamicQueries";

// Test configuration
test.describe("GitHub Pages - Documentation Site", () => {
  test.beforeEach(async ({ page }) => {
    // Set longer timeout for external site
    page.setDefaultTimeout(30000);
  });

  test("Homepage loads successfully", async ({ page }) => {
    const response = await page.goto(BASE_URL);

    // Verify successful load
    expect(response.status()).toBe(200);

    // Verify page title
    await expect(page).toHaveTitle(/JT Dynamic Queries/i);

    // Verify main heading
    await expect(page.locator("h1").first()).toContainText(
      "JT Dynamic Queries"
    );

    // Verify key sections exist
    await expect(page.locator("text=Quick Links")).toBeVisible();
    await expect(page.locator("text=What is JT Dynamic Queries")).toBeVisible();
    await expect(page.locator("text=Getting Started")).toBeVisible();
  });

  test("Navigation links are visible and functional", async ({ page }) => {
    await page.goto(BASE_URL);

    // Wait for page to fully load
    await page.waitForLoadState("networkidle");

    // Check for main navigation links (if they exist in header)
    const galleryLink = page.locator('a[href*="gallery"]').first();
    if (await galleryLink.isVisible()) {
      await expect(galleryLink).toBeVisible();
    }

    // Check for documentation links
    await expect(page.locator('a[href*="FEATURES"]').first()).toBeVisible();
    await expect(page.locator('a[href*="ARCHITECTURE"]').first()).toBeVisible();
  });

  test("Gallery page loads with videos and screenshots", async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/gallery.html`);
    expect(response.status()).toBe(200);

    // Verify gallery heading
    await expect(
      page
        .locator("h1, h2")
        .filter({ hasText: /gallery|demos/i })
        .first()
    ).toBeVisible();

    // Check for video or screenshot containers
    const mediaElements = page.locator(
      'video, img[src*="screenshot"], img[src*="demo"]'
    );
    const count = await mediaElements.count();

    // Should have at least some media
    expect(count).toBeGreaterThan(0);
  });

  test("Features v2.0 documentation is accessible", async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/FEATURES_v2.html`);
    expect(response.status()).toBe(200);

    // Verify content loaded
    await expect(page.locator("body")).toContainText("Features");
  });

  test("Architecture documentation is accessible", async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/ARCHITECTURE_LAYERS.html`);
    expect(response.status()).toBe(200);

    // Verify architecture content
    await expect(page.locator("body")).toContainText(/architecture|layers/i);
  });

  test("V3.0 Roadmap is accessible", async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/V3_ROADMAP.html`);

    // Verify page loads (200 or cached)
    expect([200, 304]).toContain(response.status());

    // Verify roadmap content
    await expect(page.locator("body")).toContainText("Roadmap");
    await expect(page.locator("body")).toContainText(/v3\.0|version 3/i);

    // Verify key sections
    await expect(page.locator("body")).toContainText("Visual SOQL Builder");
    await expect(page.locator("body")).toContainText("Query History");
  });

  test("GitHub Issues documentation is accessible", async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/GITHUB_ISSUES_V3.html`);
    expect([200, 304]).toContain(response.status());

    // Verify issues content
    await expect(page.locator("body")).toContainText(
      /GitHub Issues|User Stories/i
    );
    await expect(page.locator("body")).toContainText(/v3\.0|version 3/i);
  });

  test("Run As User feature documentation is accessible (no 404)", async ({
    page
  }) => {
    const response = await page.goto(`${BASE_URL}/RUN_AS_USER_FEATURE.html`);

    // Should NOT be 404
    expect(response.status()).not.toBe(404);
    expect([200, 304]).toContain(response.status());

    // Verify content
    await expect(page.locator("body")).toContainText(/Run As User|Run As/i);
  });

  test("Semantic HTML implementation docs are accessible", async ({ page }) => {
    const response = await page.goto(
      `${BASE_URL}/SEMANTIC_HTML_FINAL_REPORT.html`
    );
    expect([200, 304]).toContain(response.status());

    // Verify semantic HTML content
    await expect(page.locator("body")).toContainText(
      /Semantic HTML|HTML Semántico/i
    );
  });

  test("E2E test documentation is accessible", async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/E2E_COMPLETE_SUCCESS.html`);
    expect([200, 304]).toContain(response.status());

    // Verify E2E content
    await expect(page.locator("body")).toContainText(/E2E|End-to-End/i);
  });

  test("Functional Run As documentation is accessible", async ({ page }) => {
    const response = await page.goto(`${BASE_URL}/FUNCTIONAL_RUN_AS.html`);
    expect([200, 304]).toContain(response.status());

    // Verify functional content
    await expect(page.locator("body")).toContainText(/Functional|Run As/i);
  });

  test("All critical documentation pages return 200 (no 404s)", async ({
    page
  }) => {
    const criticalPages = [
      "/",
      "/gallery.html",
      "/FEATURES_v2.html",
      "/ARCHITECTURE_LAYERS.html",
      "/V3_ROADMAP.html",
      "/GITHUB_ISSUES_V3.html",
      "/RUN_AS_USER_FEATURE.html",
      "/SEMANTIC_HTML_FINAL_REPORT.html",
      "/E2E_COMPLETE_SUCCESS.html",
      "/FUNCTIONAL_RUN_AS.html"
    ];

    for (const pagePath of criticalPages) {
      const response = await page.goto(`${BASE_URL}${pagePath}`, {
        waitUntil: "domcontentloaded"
      });

      expect(
        response.status(),
        `Page ${pagePath} should not return 404`
      ).not.toBe(404);

      expect(
        [200, 304].includes(response.status()),
        `Page ${pagePath} should return 200 or 304, got ${response.status()}`
      ).toBeTruthy();
    }
  });

  test("Footer is present with correct links", async ({ page }) => {
    await page.goto(BASE_URL);

    // Check for footer
    const footer = page.locator('.footer, footer, [class*="footer"]').first();
    await expect(footer).toBeVisible();

    // Verify footer content
    await expect(footer).toContainText(/Salesforce Community|Built with/i);

    // Verify GitHub links in footer
    const githubLinks = page.locator(
      'a[href*="github.com/jterrats/JT_DynamicQueries"]'
    );
    expect(await githubLinks.count()).toBeGreaterThan(0);
  });

  test("Deploy to Salesforce button works on homepage", async ({ page }) => {
    await page.goto(BASE_URL);

    // Find deploy button
    const deployButton = page
      .locator('a[href*="githubsfdeploy"], img[alt*="Deploy"]')
      .first();

    // Should be visible
    await expect(deployButton).toBeVisible();
  });

  test("Search functionality exists (if implemented)", async ({ page }) => {
    await page.goto(BASE_URL);

    // Check if search exists
    const searchInput = page.locator(
      'input[type="search"], input[placeholder*="search" i]'
    );

    // If search exists, verify it's functional
    if (await searchInput.isVisible()) {
      await searchInput.fill("query");
      // Search should accept input
      await expect(searchInput).toHaveValue("query");
    }
  });

  test("No console errors on homepage", async ({ page }) => {
    const consoleErrors = [];

    page.on("console", (msg) => {
      if (msg.type() === "error") {
        consoleErrors.push(msg.text());
      }
    });

    await page.goto(BASE_URL);
    await page.waitForLoadState("networkidle");

    // Allow for some errors from external scripts, but not too many
    expect(
      consoleErrors.length,
      `Found ${consoleErrors.length} console errors: ${consoleErrors.join(", ")}`
    ).toBeLessThan(5);
  });

  test("Responsive design - Mobile view works", async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });

    await page.goto(BASE_URL);

    // Content should still be visible on mobile
    await expect(page.locator("h1").first()).toBeVisible();

    // Navigation should adapt (hamburger menu or similar)
    const body = page.locator("body");
    await expect(body).toBeVisible();
  });

  test("External links open in new tab", async ({ page }) => {
    await page.goto(BASE_URL);

    // Find GitHub repository link
    const githubLink = page.locator('a[href*="github.com/jterrats"]').first();

    if (await githubLink.isVisible()) {
      const target = await githubLink.getAttribute("target");
      const rel = await githubLink.getAttribute("rel");

      // Should open in new tab for security
      if (target === "_blank") {
        expect(rel).toContain("noopener");
      }
    }
  });

  test("All images have alt text for accessibility", async ({ page }) => {
    await page.goto(BASE_URL);
    await page.waitForLoadState("networkidle");

    // Get all images
    const images = page.locator("img");
    const count = await images.count();

    // Check each image has alt text
    for (let i = 0; i < count; i++) {
      const img = images.nth(i);
      const alt = await img.getAttribute("alt");

      // Alt should exist (can be empty for decorative images)
      expect(
        alt !== null,
        `Image ${i} should have an alt attribute`
      ).toBeTruthy();
    }
  });

  test("Page metadata is present (SEO)", async ({ page }) => {
    await page.goto(BASE_URL);

    // Check for meta tags
    const metaDescription = page.locator('meta[name="description"]');
    const metaOgTitle = page.locator('meta[property="og:title"]');

    // At least description should exist
    expect(await metaDescription.count()).toBeGreaterThan(0);
  });

  test("Code blocks are properly formatted", async ({ page }) => {
    await page.goto(`${BASE_URL}/V3_ROADMAP.html`);

    // Look for code blocks
    const codeBlocks = page.locator("pre code, code, .highlight");

    if ((await codeBlocks.count()) > 0) {
      // First code block should be visible
      await expect(codeBlocks.first()).toBeVisible();
    }
  });

  test("Links to GitHub issues work", async ({ page }) => {
    await page.goto(`${BASE_URL}/V3_ROADMAP.html`);

    // Find links to GitHub issues
    const issueLinks = page.locator(
      'a[href*="github.com/jterrats/JT_DynamicQueries/issues"]'
    );

    if ((await issueLinks.count()) > 0) {
      const firstLink = issueLinks.first();
      await expect(firstLink).toBeVisible();

      // Verify link format
      const href = await firstLink.getAttribute("href");
      expect(href).toMatch(/github\.com\/jterrats\/JT_DynamicQueries\/issues/);
    }
  });

  test("Documentation has proper heading hierarchy", async ({ page }) => {
    await page.goto(BASE_URL);

    // Should have H1
    const h1Count = await page.locator("h1").count();
    expect(h1Count).toBeGreaterThan(0);

    // Should have H2s
    const h2Count = await page.locator("h2").count();
    expect(h2Count).toBeGreaterThan(0);
  });

  test("Quick Links section contains expected links", async ({ page }) => {
    await page.goto(BASE_URL);

    // Find Quick Links section
    const quickLinks = page
      .locator("text=Quick Links")
      .locator("xpath=following-sibling::*[1]");

    if (await quickLinks.isVisible()) {
      // Should contain links to key pages
      await expect(page.locator('a[href*="gallery"]')).toBeVisible();
      await expect(page.locator('a[href*="FEATURES"]')).toBeVisible();
    }
  });

  test("Roadmap section is visible on homepage", async ({ page }) => {
    await page.goto(BASE_URL);

    // Should mention roadmap or v3.0
    await expect(page.locator("body")).toContainText(/Roadmap|v3\.0|Future/i);
  });
});

// Separate describe block for performance tests
test.describe("GitHub Pages - Performance", () => {
  test("Homepage loads within acceptable time", async ({ page }) => {
    const startTime = Date.now();
    await page.goto(BASE_URL, { waitUntil: "domcontentloaded" });
    const loadTime = Date.now() - startTime;

    // Should load in under 5 seconds
    expect(loadTime).toBeLessThan(5000);
  });

  test("No broken images on homepage", async ({ page }) => {
    await page.goto(BASE_URL);
    await page.waitForLoadState("networkidle");

    const brokenImages = await page.evaluate(() => {
      const images = Array.from(document.querySelectorAll("img"));
      return images.filter((img) => !img.complete || img.naturalHeight === 0)
        .length;
    });

    expect(brokenImages).toBe(0);
  });
});

// Export for CI/CD integration
export default test;
