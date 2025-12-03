const { getSFSession } = require("./utils/sfAuth");

/**
 * Global setup for Playwright tests
 * Sets SF_INSTANCE_URL from active SF CLI session
 */
module.exports = async () => {
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("🔧 Global Setup: Configuring E2E Tests");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  try {
    // Only get SF session if SF_INSTANCE_URL is not already set (CI scenario)
    if (!process.env.SF_INSTANCE_URL) {
      console.log("🔑 SF_INSTANCE_URL not found, loading from SF CLI session...");
      const session = getSFSession();

      // Set env var for all tests
      process.env.SF_INSTANCE_URL = session.instanceUrl;
      process.env.SF_USERNAME = session.username;
      process.env.SF_ORG_ID = session.orgId;

      console.log("✅ Environment configured from SF CLI:");
      console.log(`   📍 Instance: ${session.instanceUrl}`);
      console.log(`   👤 Username: ${session.username}`);
      console.log(`   🆔 Org ID: ${session.orgId}`);
    } else {
      console.log("✅ SF_INSTANCE_URL already set (CI mode):");
      console.log(`   📍 Instance: ${process.env.SF_INSTANCE_URL}`);
    }

    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    console.log("✅ Global Setup Complete");
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
  } catch (error) {
    console.error("❌ Global Setup Failed:", error.message);
    console.error("💡 Make sure you have an active SF CLI session");
    console.error("   Run: sf org login web");
    throw error;
  }
};

