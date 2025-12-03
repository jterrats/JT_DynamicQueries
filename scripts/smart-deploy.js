#!/usr/bin/env node
/**
 * Smart Deploy - Cross-platform (Windows, Linux, macOS)
 * Auto-detects changes in target-org and updates Named Credential
 */

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UTILITIES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function log(emoji, message) {
  console.log(`${emoji} ${message}`);
}

function header(title) {
  console.log("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log(`🚀 ${title}`);
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
}

function execCommand(command, errorMsg) {
  try {
    return execSync(command, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"]
    }).trim();
  } catch (error) {
    console.error(`❌ ${errorMsg}`);
    console.error(error.message);
    process.exit(1);
  }
}

function loadEnv(envPath) {
  if (!fs.existsSync(envPath)) {
    return {};
  }

  const envContent = fs.readFileSync(envPath, "utf-8");
  const env = {};

  envContent.split("\n").forEach((line) => {
    const match = line.match(/^([^=]+)=(.*)$/);
    if (match) {
      const key = match[1].trim();
      const value = match[2].trim().replace(/^["']|["']$/g, ""); // Remove quotes
      env[key] = value;
    }
  });

  return env;
}

function saveEnv(envPath, data) {
  const content = Object.entries(data)
    .map(([key, value]) => `${key}=${value}`)
    .join("\n");

  fs.writeFileSync(envPath, content + "\n", "utf-8");
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MAIN LOGIC
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async function main() {
  header("Smart Deploy - Named Credentials");

  // Step 1: Get current target org
  const targetOrg =
    process.argv[2] ||
    (() => {
      const result = execCommand(
        "sf config get target-org --json",
        "Failed to get target org"
      );
      const json = JSON.parse(result);
      return json.result?.[0]?.value;
    })();

  if (!targetOrg || targetOrg === "null") {
    log("❌", "No target org found");
    process.exit(1);
  }

  log("📍", `Current Target Org: ${targetOrg}`);

  // Step 2: Get org URL
  const orgDisplayResult = execCommand(
    `sf org display --target-org "${targetOrg}" --json`,
    "Failed to get org URL"
  );

  const orgData = JSON.parse(orgDisplayResult);
  const currentUrl = orgData.result?.instanceUrl;

  if (!currentUrl || currentUrl === "null") {
    log("❌", "Failed to get org URL");
    process.exit(1);
  }

  log("🌐", `Current Org URL: ${currentUrl}`);

  // Step 3: Check cached URL
  const envPath = path.join(process.cwd(), ".env");
  const env = loadEnv(envPath);
  const cachedUrl = env.SF_ORG_SQF || "";

  log("💾", `Cached URL: ${cachedUrl || "<not set>"}`);

  console.log("");

  // Step 4: Compare URLs
  if (currentUrl !== cachedUrl) {
    log("⚠️", "Org URL mismatch detected!");
    console.log("");
    console.log(`   Cached:  ${cachedUrl || "<none>"}`);
    console.log(`   Current: ${currentUrl}`);
    console.log("");
    log("🔄", "Updating environment...");

    // Update .env
    env.SF_ORG_SQF = currentUrl;
    env.SF_TARGET_ORG = targetOrg;
    saveEnv(envPath, env);

    console.log("");
    log("✅", "Environment updated!");
  } else {
    log("✅", "Org URL matches cached value");
    log("  ", "No update needed");
  }

  console.log("");
  header("📦 Deploying Named Credential...");

  // Step 5: Deploy with replacement
  const ncPath = path.join(
    process.cwd(),
    "force-app/main/default/namedCredentials/JT_Tooling_API.namedCredential-meta.xml"
  );

  if (!fs.existsSync(ncPath)) {
    log("❌", `Named Credential file not found: ${ncPath}`);
    process.exit(1);
  }

  // Read original NC file (always has placeholder in repo)
  const originalContent = fs.readFileSync(ncPath, "utf-8");

  // Replace placeholder with actual URL (temporary, only for deploy)
  const updatedContent = originalContent.replace(
    /{!\$Credential\.JT_Tooling_API}/g,
    currentUrl
  );

  try {
    // Write modified content to file
    log("📝", "Updating Named Credential with org URL...");
    fs.writeFileSync(ncPath, updatedContent, "utf-8");

    // Deploy
    log("📤", "Deploying Named Credential...");
    execCommand(
      `sf project deploy start --source-dir force-app/main/default/namedCredentials --target-org "${targetOrg}"`,
      "Deployment failed"
    );

    log("✅", "Named Credential deployed successfully");
  } finally {
    // ALWAYS restore original file with placeholder
    log("🔄", "Restoring original file with placeholder...");
    fs.writeFileSync(ncPath, originalContent, "utf-8");
    log("✅", "Original file restored");
  }

  console.log("");
  header("✅ Smart Deploy Complete!");
  log("💡", `Named Credential configured for: ${targetOrg}`);
  log("  ", `URL: ${currentUrl}`);
  console.log("");
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RUN
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main().catch((error) => {
  console.error("❌ Fatal error:", error.message);
  process.exit(1);
});

