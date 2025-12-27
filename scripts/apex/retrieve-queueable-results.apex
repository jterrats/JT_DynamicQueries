/**
 * Retrieve Cached Results from JT_UsageFinderQueueable
 *
 * Use this script to check cached results after a Queueable job has completed.
 *
 * Usage:
 * - Copy this script to Developer Console > Anonymous Apex
 * - Update configDevName to match the configuration you searched for
 * - Execute
 */

// Configuration Developer Name (change this to match your search)
String configDevName = 'Test_Record'; // Change this
String userId = UserInfo.getUserId();

System.debug('========================================');
System.debug('Retrieving Cached Results');
System.debug('========================================');
System.debug('Configuration: ' + configDevName);
System.debug('User ID: ' + userId);
System.debug('');

// Retrieve cached results
JT_UsageFinder.AggregatedUsageResponse result = JT_UsageFinderQueueable.getCachedResults(
  configDevName,
  userId
);

if (result == null) {
  System.debug('❌ No cached results found.');
  System.debug('');
  System.debug('Possible reasons:');
  System.debug('1. Queueable job has not completed yet');
  System.debug('2. Cache expired (7 days TTL)');
  System.debug('3. Configuration name is incorrect');
  System.debug('4. Queueable job failed');
} else {
  System.debug('✅ Results Found!');
  System.debug('');
  System.debug('=== Summary ===');
  System.debug('Total Results: ' + result.totalResults);
  System.debug('Has Partial Results: ' + result.hasPartialResults);
  System.debug('');

  System.debug('=== Apex Service ===');
  System.debug('Success: ' + result.apexService.success);
  System.debug('Service Name: ' + result.apexService.serviceName);
  System.debug('Results Count: ' + result.apexService.data.size());
  if (!result.apexService.success && String.isNotBlank(result.apexService.error)) {
    System.debug('Error: ' + result.apexService.error);
  }
  System.debug('');

  System.debug('=== Flow Service ===');
  System.debug('Success: ' + result.flowService.success);
  System.debug('Service Name: ' + result.flowService.serviceName);
  System.debug('Results Count: ' + result.flowService.data.size());
  if (!result.flowService.success && String.isNotBlank(result.flowService.error)) {
    System.debug('Error: ' + result.flowService.error);
  }
  System.debug('');

  if (result.allResults.size() > 0) {
    System.debug('=== Usage Details ===');
    Integer index = 1;
    for (JT_UsageFinder.UsageResult usage : result.allResults) {
      System.debug(index + '. ' + usage.className);
      System.debug('   Type: ' + usage.metadataType);
      System.debug('   Config: ' + usage.configName);
      if (usage.lineNumber != null) {
        System.debug('   Line: ' + usage.lineNumber);
      }
      if (String.isNotBlank(usage.codeLine)) {
        System.debug('   Code: ' + usage.codeLine);
      }
      System.debug('');
      index++;
    }
  } else {
    System.debug('ℹ️  No usages found for this configuration.');
  }

  // Serialize full result for inspection
  System.debug('=== Full JSON Result ===');
  System.debug(JSON.serializePretty(result));
}

System.debug('');
System.debug('========================================');

