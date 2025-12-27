/**
 * Test Script for JT_UsageFinderQueueable
 *
 * This script demonstrates how to:
 * 1. Execute the Queueable job
 * 2. Retrieve cached results
 * 3. Display results
 *
 * Usage:
 * - Copy this script to Developer Console > Anonymous Apex
 * - Update configDevName to match an existing configuration
 * - Update email to your email address
 * - Execute
 */

// Configuration to search for (use an existing Custom Metadata Developer Name)
String configDevName = 'Test_Record'; // Change this to match your configuration

// Your email address (optional - set to null if you don't want email notifications)
String userEmail = UserInfo.getUserEmail(); // Uses current user's email
String userId = UserInfo.getUserId();

System.debug('========================================');
System.debug('Testing JT_UsageFinderQueueable');
System.debug('========================================');
System.debug('Configuration: ' + configDevName);
System.debug('User Email: ' + userEmail);
System.debug('User ID: ' + userId);
System.debug('');

// Step 1: Check if results are already cached
JT_UsageFinder.AggregatedUsageResponse cachedResult = JT_UsageFinderQueueable.getCachedResults(
  configDevName,
  userId
);

if (cachedResult != null) {
  System.debug('✅ Found cached results!');
  System.debug('Total Results: ' + cachedResult.totalResults);
  System.debug('Apex Service Success: ' + cachedResult.apexService.success);
  System.debug('Flow Service Success: ' + cachedResult.flowService.success);
  System.debug('Has Partial Results: ' + cachedResult.hasPartialResults);
  System.debug('');
  System.debug('Apex Results: ' + cachedResult.apexService.data.size());
  System.debug('Flow Results: ' + cachedResult.flowService.data.size());

  if (cachedResult.allResults.size() > 0) {
    System.debug('');
    System.debug('Usage Details:');
    for (JT_UsageFinder.UsageResult usage : cachedResult.allResults) {
      System.debug('  - ' + usage.className + ' (' + usage.metadataType + ')');
      if (usage.lineNumber != null) {
        System.debug('    Line: ' + usage.lineNumber);
      }
    }
  }
} else {
  System.debug('ℹ️  No cached results found. Executing Queueable job...');
  System.debug('');

  // Step 2: Execute the Queueable job
  JT_UsageFinderQueueable job = new JT_UsageFinderQueueable(
    configDevName,
    userEmail,
    userId
  );

  Id jobId = System.enqueueJob(job);
  System.debug('✅ Queueable job enqueued!');
  System.debug('Job ID: ' + jobId);
  System.debug('');
  System.debug('⏳ Waiting for job to complete...');
  System.debug('(Note: In production, the job runs asynchronously. Check cache after a few seconds.)');
  System.debug('');
  System.debug('To retrieve results later, use:');
  System.debug('JT_UsageFinderQueueable.getCachedResults(\'' + configDevName + '\', \'' + userId + '\');');
}

System.debug('');
System.debug('========================================');
System.debug('Test Complete');
System.debug('========================================');

