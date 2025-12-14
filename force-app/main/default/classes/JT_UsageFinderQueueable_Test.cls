/**
 * @description Test class for JT_UsageFinderQueueable
 * @author Jaime Terrats
 * @date 2025-12-11
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_UsageFinderQueueable_Test {
  @IsTest
  static void testQueueableExecutionSuccess() {
    // Create test configuration
    String configDevName =
      'Test_Config_' + String.valueOf(Math.random()).substring(2, 10);

    Test.startTest();

    // Execute queueable
    JT_UsageFinderQueueable job = new JT_UsageFinderQueueable(
      configDevName,
      'test@example.com',
      UserInfo.getUserId()
    );
    System.enqueueJob(job);

    Test.stopTest();

    // Verify cached results exist
    JT_UsageFinder.AggregatedUsageResponse cachedResult = JT_UsageFinderQueueable.getCachedResults(
      configDevName,
      UserInfo.getUserId()
    );

    System.assertNotEquals(
      null,
      cachedResult,
      'Results should be cached after execution'
    );
    System.assertNotEquals(
      null,
      cachedResult.allResults,
      'Results list should be initialized'
    );
    System.assertNotEquals(
      null,
      cachedResult.apexService,
      'Apex service response should be initialized'
    );
    System.assertNotEquals(
      null,
      cachedResult.flowService,
      'Flow service response should be initialized'
    );
  }

  @IsTest
  static void testGetCachedResultsNotFound() {
    // Try to get non-existent cached results
    JT_UsageFinder.AggregatedUsageResponse result = JT_UsageFinderQueueable.getCachedResults(
      'NonExistent_Config',
      UserInfo.getUserId()
    );

    System.assertEquals(
      null,
      result,
      'Should return null for non-cached results'
    );
  }

  @IsTest
  static void testGetCachedResultsAfterCache() {
    // Create and cache a mock result
    String configDevName = 'Test_Cached_Config';
    JT_UsageFinder.AggregatedUsageResponse mockResult = new JT_UsageFinder.AggregatedUsageResponse();
    mockResult.totalResults = 3;
    mockResult.hasPartialResults = false;

    JT_UsageFinder.UsageResult usage1 = new JT_UsageFinder.UsageResult();
    usage1.className = 'TestClass1';
    usage1.metadataType = 'Apex Class';

    JT_UsageFinder.UsageResult usage2 = new JT_UsageFinder.UsageResult();
    usage2.className = 'TestClass2';
    usage2.metadataType = 'Apex Class';

    JT_UsageFinder.UsageResult usage3 = new JT_UsageFinder.UsageResult();
    usage3.className = 'TestFlow1';
    usage3.metadataType = 'Flow';

    mockResult.allResults = new List<JT_UsageFinder.UsageResult>{
      usage1,
      usage2,
      usage3
    };

    // Use same sanitization logic as production code
    String sanitizedConfigName = configDevName != null
      ? configDevName.replaceAll('[^a-zA-Z0-9]', '')
      : '';
    String sanitizedUserId = UserInfo.getUserId() != null
      ? UserInfo.getUserId().replaceAll('[^a-zA-Z0-9]', '')
      : '';
    String cacheKey = 'UsageSearch' + sanitizedConfigName + sanitizedUserId;
    Cache.Org.put(cacheKey, JSON.serialize(mockResult), 172800); // 2 days (max allowed)

    Test.startTest();

    // Retrieve cached results
    JT_UsageFinder.AggregatedUsageResponse cachedResult = JT_UsageFinderQueueable.getCachedResults(
      configDevName,
      UserInfo.getUserId()
    );

    Test.stopTest();

    System.assertNotEquals(
      null,
      cachedResult,
      'Should retrieve cached results'
    );
    System.assertEquals(
      3,
      cachedResult.totalResults,
      'Should have 3 total results'
    );
    System.assertEquals(
      3,
      cachedResult.allResults.size(),
      'Should have 3 usage records'
    );
  }

  @IsTest
  static void testQueueableWithNullEmail() {
    // Test execution without email notification
    String configDevName = 'Test_Config_NoEmail';

    Test.startTest();

    JT_UsageFinderQueueable job = new JT_UsageFinderQueueable(
      configDevName,
      null, // No email
      UserInfo.getUserId()
    );
    System.enqueueJob(job);

    Test.stopTest();

    // Verify results are still cached even without email
    JT_UsageFinder.AggregatedUsageResponse cachedResult = JT_UsageFinderQueueable.getCachedResults(
      configDevName,
      UserInfo.getUserId()
    );

    System.assertNotEquals(
      null,
      cachedResult,
      'Results should be cached even without email notification'
    );
  }

  @IsTest
  static void testQueueableWithEmptyEmail() {
    // Test execution with empty email
    String configDevName = 'Test_Config_EmptyEmail';

    Test.startTest();

    JT_UsageFinderQueueable job = new JT_UsageFinderQueueable(
      configDevName,
      '', // Empty email
      UserInfo.getUserId()
    );
    System.enqueueJob(job);

    Test.stopTest();

    // Verify results are cached
    JT_UsageFinder.AggregatedUsageResponse cachedResult = JT_UsageFinderQueueable.getCachedResults(
      configDevName,
      UserInfo.getUserId()
    );

    System.assertNotEquals(
      null,
      cachedResult,
      'Results should be cached with empty email'
    );
  }
}
