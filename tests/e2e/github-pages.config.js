/**
 * Playwright Configuration for GitHub Pages E2E Tests
 * Specific config for testing the published documentation site
 */

import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./",
  testMatch: "github-pages.spec.js",

  // Longer timeout for external site
  timeout: 60000,

  // Test configuration
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1,
  workers: process.env.CI ? 1 : undefined,

  // Reporter configuration
  reporter: [
    ["list"],
    ["html", { outputFolder: "playwright-report-github-pages" }],
    ["json", { outputFile: "test-results/github-pages-results.json" }]
  ],

  // Shared settings for all tests
  use: {
    // Base URL for all tests
    baseURL: "https://jterrats.github.io/JT_DynamicQueries",

    // Collect trace on failure
    trace: "on-first-retry",

    // Screenshot on failure
    screenshot: "only-on-failure",

    // Video on failure
    video: "retain-on-failure",

    // Browser context options
    viewport: { width: 1280, height: 720 },

    // Longer navigation timeout for external site
    navigationTimeout: 30000,
    actionTimeout: 15000
  },

  // Configure projects for major browsers
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] }
    },

    {
      name: "firefox",
      use: { ...devices["Desktop Firefox"] }
    },

    {
      name: "webkit",
      use: { ...devices["Desktop Safari"] }
    },

    // Mobile tests
    {
      name: "Mobile Chrome",
      use: { ...devices["Pixel 5"] }
    },

    {
      name: "Mobile Safari",
      use: { ...devices["iPhone 12"] }
    }
  ],

  // Output folder
  outputDir: "test-results/github-pages"
});
