const { execSync } = require("child_process");
const path = require("path");

/**
 * Assigns the JT_Dynamic_Queries permission set to the current user
 * This ensures E2E tests have proper access
 */
function assignPermissionSet() {
  try {
    console.log("🔐 Checking Permission Set assignment...");

    const apexScript = path.join(
      __dirname,
      "../../../scripts/apex/assign-permset.apex"
    );

    // Execute apex anonymous script
    const result = execSync(`sf apex run --file "${apexScript}"`, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"]
    });

    // Check if it was successful
    if (
      result.includes("Permission Set") &&
      !result.toLowerCase().includes("error")
    ) {
      console.log("✅ Permission Set verified/assigned successfully");
      return true;
    } else if (result.toLowerCase().includes("error")) {
      console.error("❌ Error assigning Permission Set:", result);
      return false;
    }

    return true;
  } catch (error) {
    console.error(
      "❌ Error executing Permission Set assignment:",
      error.message
    );
    // Don't fail the tests, just warn
    console.log("⚠️  Continuing without Permission Set verification...");
    return false;
  }
}

module.exports = {
  assignPermissionSet
};
