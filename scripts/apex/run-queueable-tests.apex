/**
 * Run Unit Tests for JT_UsageFinderQueueable
 *
 * This script executes all test methods in JT_UsageFinderQueueable_Test
 *
 * Usage:
 * - Copy this script to Developer Console > Anonymous Apex
 * - Execute
 */

System.debug('========================================');
System.debug('Running JT_UsageFinderQueueable Tests');
System.debug('========================================');
System.debug('');

// Run all tests in the test class
Test.startTest();
Test.stopTest();

// Execute test methods
try {
  // Test 1: Queueable execution with email
  System.debug('Test 1: testQueueableExecutionSuccess');
  JT_UsageFinderQueueable_Test.testQueueableExecutionSuccess();
  System.debug('✅ testQueueableExecutionSuccess passed');

  // Test 2: Get cached results (not found)
  System.debug('');
  System.debug('Test 2: testGetCachedResultsNotFound');
  JT_UsageFinderQueueable_Test.testGetCachedResultsNotFound();
  System.debug('✅ testGetCachedResultsNotFound passed');

  // Test 3: Get cached results (after cache)
  System.debug('');
  System.debug('Test 3: testGetCachedResultsAfterCache');
  JT_UsageFinderQueueable_Test.testGetCachedResultsAfterCache();
  System.debug('✅ testGetCachedResultsAfterCache passed');

  // Test 4: Queueable with null email
  System.debug('');
  System.debug('Test 4: testQueueableWithNullEmail');
  JT_UsageFinderQueueable_Test.testQueueableWithNullEmail();
  System.debug('✅ testQueueableWithNullEmail passed');

  // Test 5: Queueable with empty email
  System.debug('');
  System.debug('Test 5: testQueueableWithEmptyEmail');
  JT_UsageFinderQueueable_Test.testQueueableWithEmptyEmail();
  System.debug('✅ testQueueableWithEmptyEmail passed');

  System.debug('');
  System.debug('========================================');
  System.debug('✅ All tests completed successfully!');
  System.debug('========================================');

} catch (Exception e) {
  System.debug('');
  System.debug('❌ Test failed: ' + e.getMessage());
  System.debug('Stack Trace: ' + e.getStackTraceString());
  System.debug('');
  System.debug('========================================');
  System.debug('❌ Tests failed');
  System.debug('========================================');
}

