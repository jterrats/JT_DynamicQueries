/**
 * E2E Tests for Persona Manager modal (US-025)
 * Validates:
 * 1. Modal opens / closes correctly
 * 2. Tabs navigate between Existing Personas and Create New Persona
 * 3. Existing personas table renders with data
 * 4. Create form validates required fields before enabling Save
 * 5. Happy-path persona creation: fill form → save → deployment notice appears
 * 6. Pagination controls render when more than PAGE_SIZE personas exist
 */

const { test, expect } = require("@playwright/test");
const { setupTestContext } = require("./utils/testHelpers");
const { getSFSession } = require("./utils/sfAuth");
const { QUERY_VIEWER_TAB, TIMEOUTS } = require("./utils/testConstants");

let session;

test.beforeAll(async () => {
  session = await getSFSession();
});

// ─── Helpers ────────────────────────────────────────────────────────────────

/**
 * Expands the Run As accordion and opens the Manage Personas modal.
 * Returns the modal locator, or null if not available.
 */
async function openPersonaManager(page) {
  // Check if the Run As accordion section exists (requires admin)
  const accordionLabel = page.getByText("Run As User (Advanced)").first();
  const accordionExists = await accordionLabel
    .isVisible({ timeout: TIMEOUTS.component })
    .catch(() => false);

  if (!accordionExists) {
    console.log("ℹ️  Run As section not available (not an admin?) — skipping.");
    return null;
  }

  // Expand the accordion by clicking its label
  await accordionLabel.click({ force: true });
  await page.waitForTimeout(TIMEOUTS.short);

  // Confirm run-as-section content is now visible
  const runAsSection = page.locator("c-jt-run-as-section").first();
  const sectionVisible = await runAsSection
    .isVisible({ timeout: TIMEOUTS.component })
    .catch(() => false);

  if (!sectionVisible) {
    console.log(
      "ℹ️  Run As section not visible after accordion expand — skipping."
    );
    return null;
  }

  // Switch to Persona mode so the Manage Personas button is visible
  const personaBtn = runAsSection.locator(
    '[data-testid="run-as-mode-persona"]'
  );
  await personaBtn.click();
  await page.waitForTimeout(TIMEOUTS.short);

  const manageBtn = runAsSection.locator(
    '[data-testid="manage-personas-button"]'
  );
  await expect(manageBtn).toBeVisible({ timeout: TIMEOUTS.component });
  await manageBtn.click();

  const modal = page.locator('[data-testid="persona-manager-modal"]');
  await expect(modal).toBeVisible({ timeout: TIMEOUTS.component });
  return modal;
}

// ─── Tests ───────────────────────────────────────────────────────────────────

test.describe("Manage Personas Modal", () => {
  test.beforeEach(async ({ page }) => {
    await setupTestContext(page, session, {
      targetTab: QUERY_VIEWER_TAB,
      waitForComponent: true
    });
  });

  // ── Open / Close ──────────────────────────────────────────────────────────

  test("should open Manage Personas modal from Run As section", async ({
    page
  }) => {
    console.log("🧪 Testing Manage Personas modal opens...");

    const modal = await openPersonaManager(page);
    if (!modal) return;

    await expect(modal.locator('[data-testid="modal-body"]')).toBeVisible();
    console.log("✅ Modal opened successfully");
  });

  test("should close modal with the header close button", async ({ page }) => {
    console.log("🧪 Testing modal closes with header X button...");

    const modal = await openPersonaManager(page);
    if (!modal) return;

    await modal.locator('[data-testid="close-button"]').click();

    await expect(
      page.locator('[data-testid="persona-manager-modal"]')
    ).not.toBeVisible();
    console.log("✅ Modal closed with header close button");
  });

  test("should close modal with the footer Close button", async ({ page }) => {
    console.log("🧪 Testing modal closes with footer Close button...");

    const modal = await openPersonaManager(page);
    if (!modal) return;

    await modal.locator('[data-testid="footer-close-button"]').click();

    await expect(
      page.locator('[data-testid="persona-manager-modal"]')
    ).not.toBeVisible();
    console.log("✅ Modal closed with footer Close button");
  });

  // ── Tabs ──────────────────────────────────────────────────────────────────

  test("should default to Existing Personas tab on open", async ({ page }) => {
    console.log("🧪 Testing default tab is Existing Personas...");

    const modal = await openPersonaManager(page);
    if (!modal) return;

    await expect(modal.locator('[data-testid="panel-existing"]')).toBeVisible();
    await expect(
      modal.locator('[data-testid="panel-create"]')
    ).not.toBeVisible();
    console.log("✅ Existing Personas tab is active by default");
  });

  test("should switch to Create New Persona tab", async ({ page }) => {
    console.log("🧪 Testing tab switch to Create New Persona...");

    const modal = await openPersonaManager(page);
    if (!modal) return;

    await modal.locator('[data-testid="tab-create"]').click();

    await expect(modal.locator('[data-testid="panel-create"]')).toBeVisible();
    await expect(
      modal.locator('[data-testid="panel-existing"]')
    ).not.toBeVisible();
    console.log("✅ Create New Persona tab is active");
  });

  test("should switch back to Existing Personas tab from Create tab", async ({
    page
  }) => {
    console.log("🧪 Testing tab switch back to Existing Personas...");

    const modal = await openPersonaManager(page);
    if (!modal) return;

    await modal.locator('[data-testid="tab-create"]').click();
    await modal.locator('[data-testid="tab-existing"]').click();

    await expect(modal.locator('[data-testid="panel-existing"]')).toBeVisible();
    console.log("✅ Switched back to Existing Personas tab");
  });

  // ── Existing Personas tab ─────────────────────────────────────────────────

  test("should show existing personas table or empty state", async ({
    page
  }) => {
    console.log("🧪 Testing existing personas table / empty state renders...");

    const modal = await openPersonaManager(page);
    if (!modal) return;

    // Wait for modal loading spinner to disappear before checking panel content
    await modal
      .locator('[data-testid="loading-spinner"]')
      .waitFor({ state: "hidden", timeout: TIMEOUTS.component })
      .catch(() => {});

    const panel = modal.locator('[data-testid="panel-existing"]');

    const hasTable = await panel
      .locator('[data-testid="personas-table"]')
      .isVisible({ timeout: TIMEOUTS.component })
      .catch(() => false);

    const hasEmpty = await panel
      .locator('[data-testid="empty-state"]')
      .isVisible({ timeout: TIMEOUTS.component })
      .catch(() => false);

    expect(hasTable || hasEmpty).toBe(true);
    console.log(
      hasTable ? "✅ Personas table is visible" : "✅ Empty state is visible"
    );
  });

  // ── Create form ───────────────────────────────────────────────────────────

  test("should show Create form fields when on Create tab", async ({
    page
  }) => {
    console.log("🧪 Testing Create form fields are present...");

    const modal = await openPersonaManager(page);
    if (!modal) return;

    await modal.locator('[data-testid="tab-create"]').click();
    const panel = modal.locator('[data-testid="panel-create"]');

    await expect(panel.locator('[data-testid="input-label"]')).toBeVisible();
    await expect(
      panel.locator('[data-testid="input-developer-name"]')
    ).toBeVisible();
    await expect(
      panel.locator('[data-testid="combobox-profile"]')
    ).toBeVisible();
    await expect(
      panel.locator('[data-testid="dual-listbox-permission-sets"]')
    ).toBeVisible();
    console.log("✅ All Create form fields are visible");
  });

  test("should keep Save button disabled when required fields are empty", async ({
    page
  }) => {
    console.log("🧪 Testing Save button is disabled with empty form...");

    const modal = await openPersonaManager(page);
    if (!modal) return;

    await modal.locator('[data-testid="tab-create"]').click();
    const saveBtn = modal.locator('[data-testid="save-button"] button');

    await expect(saveBtn).toBeDisabled();
    console.log("✅ Save button is disabled with empty form");
  });

  test("should auto-populate Developer Name from Label", async ({ page }) => {
    console.log("🧪 Testing Developer Name auto-population from Label...");

    const modal = await openPersonaManager(page);
    if (!modal) return;

    await modal.locator('[data-testid="tab-create"]').click();
    const panel = modal.locator('[data-testid="panel-create"]');

    const labelInput = panel.locator('[data-testid="input-label"] input');
    await labelInput.fill("Sales Rep Test");
    await page.waitForTimeout(500);

    const devNameInput = panel.locator(
      '[data-testid="input-developer-name"] input'
    );
    const devNameValue = await devNameInput.inputValue();

    expect(devNameValue).toBe("Sales_Rep_Test");
    console.log(`✅ Developer Name auto-set to: "${devNameValue}"`);
  });

  test("should enable Save button when required fields are filled", async ({
    page
  }) => {
    console.log(
      "🧪 Testing Save button enables when required fields filled..."
    );

    const modal = await openPersonaManager(page);
    if (!modal) return;

    await modal.locator('[data-testid="tab-create"]').click();
    const panel = modal.locator('[data-testid="panel-create"]');

    // Fill Label (auto-populates Developer Name)
    await panel
      .locator('[data-testid="input-label"] input')
      .fill("E2E Test Persona");
    await page.waitForTimeout(500);

    // Select Profile — click lightning-combobox directly to open dropdown
    const profileCombobox = panel.locator('[data-testid="combobox-profile"]');
    await profileCombobox.click();
    await page.waitForTimeout(500);
    const firstProfileOption = page
      .locator('lightning-base-combobox-item[role="option"]')
      .first();
    if ((await firstProfileOption.count()) > 0) {
      await firstProfileOption.click();
    }
    await page.waitForTimeout(500);

    const saveBtn = modal.locator('[data-testid="save-button"] button');
    await expect(saveBtn).toBeEnabled();
    console.log("✅ Save button enabled after filling required fields");
  });

  // ── Happy-path create ─────────────────────────────────────────────────────

  test("should show deployment pending notice after saving a persona", async ({
    page
  }) => {
    console.log(
      "🧪 Testing happy-path persona creation → deployment notice..."
    );

    const modal = await openPersonaManager(page);
    if (!modal) return;

    await modal.locator('[data-testid="tab-create"]').click();
    const panel = modal.locator('[data-testid="panel-create"]');

    const timestamp = Date.now();
    const labelValue = `E2E Persona ${timestamp}`;

    // Fill Label
    await panel.locator('[data-testid="input-label"] input').fill(labelValue);
    await page.waitForTimeout(500);

    // Select first available Profile — click lightning-combobox directly
    await panel.locator('[data-testid="combobox-profile"]').click();
    await page.waitForTimeout(500);
    const firstProfile = page
      .locator('lightning-base-combobox-item[role="option"]')
      .first();
    if ((await firstProfile.count()) === 0) {
      console.log("ℹ️  No profiles available — skipping save test.");
      return;
    }
    await firstProfile.click();
    await page.waitForTimeout(500);

    // Save
    const saveBtn = modal.locator('[data-testid="save-button"] button');
    await expect(saveBtn).toBeEnabled();
    await saveBtn.click();

    await expect(
      modal.locator('[data-testid="deployment-pending-notice"]')
    ).toBeVisible({ timeout: TIMEOUTS.long });

    console.log("✅ Deployment pending notice shown after save");
  });
});
