const { execSync } = require('child_process');
const path = require('path');

/**
 * Executes the Apex script to set up test data and assign permission set
 */
function setupTestData() {
    try {
        console.log('🔧 Setting up test data and permissions...');

        const scriptPath = path.join(__dirname, '../../../scripts/setup-test-data.apex');
        const command = `sf apex run --file "${scriptPath}"`;

        const result = execSync(command, {
            encoding: 'utf-8',
            stdio: 'pipe'
        });

        if (result.includes('✅')) {
            console.log('✅ Test data setup complete');
            return true;
        } else {
            console.log('⚠️  Test data setup completed with warnings');
            console.log(result);
            return true;
        }
    } catch (error) {
        console.error('❌ Error setting up test data:', error.message);
        if (error.stdout) {
            console.log('Output:', error.stdout.toString());
        }
        if (error.stderr) {
            console.error('Error details:', error.stderr.toString());
        }
        return false;
    }
}

module.exports = { setupTestData };

