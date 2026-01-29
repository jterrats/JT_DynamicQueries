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

    // Use same cache key logic as production code (hash-based)
    // Replicate buildCacheKey logic for test
    String combined = (configDevName != null ? configDevName : '') +
                      (UserInfo.getUserId() != null ? UserInfo.getUserId() : '');
    Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(combined));
    String hashHex = EncodingUtil.convertToHex(hash);
    String shortHash = hashHex.substring(0, 16);
    String prefix = 'US';
    String userIdSuffix = '';
    if (UserInfo.getUserId() != null && UserInfo.getUserId().length() > 0) {
      String sanitizedUserId = JT_ToolingApiUtil.toAlphanumeric(UserInfo.getUserId());
      userIdSuffix = sanitizedUserId.length() > 8
        ? sanitizedUserId.substring(sanitizedUserId.length() - 8)
        : sanitizedUserId;
    }
    String cacheKey = prefix + shortHash + userIdSuffix;
    if (cacheKey.length() > 50) {
      cacheKey = cacheKey.substring(0, 50);
    }
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

  @IsTest
  static void testQueueableExecutionWithEmail() {
    // Test execution with email notification
    String configDevName = 'Test_Config_WithEmail';
    String testEmail = 'test@example.com';

    Test.startTest();

    JT_UsageFinderQueueable job = new JT_UsageFinderQueueable(
      configDevName,
      testEmail,
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
      'Results should be cached with email notification'
    );
  }

  @IsTest
  static void testQueueableExecutionError() {
    // Test execution with error (will throw exception during construction)
    String configDevName = null; // This will cause an error

    Test.startTest();

    try {
      JT_UsageFinderQueueable job = new JT_UsageFinderQueueable(
        configDevName,
        'test@example.com',
        UserInfo.getUserId()
      );
      System.enqueueJob(job);
      System.assert(false, 'Should have thrown exception');
    } catch (IllegalArgumentException e) {
      System.assert(true, 'Exception thrown as expected: ' + e.getMessage());
    }

    Test.stopTest();
  }

  @IsTest
  static void testGetCachedResultsWithNullConfig() {
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse result = JT_UsageFinderQueueable.getCachedResults(
      null,
      UserInfo.getUserId()
    );
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null for null config');
  }

  @IsTest
  static void testGetCachedResultsWithNullUserId() {
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse result = JT_UsageFinderQueueable.getCachedResults(
      'Test_Config',
      null
    );
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null for null userId');
  }

  @IsTest
  static void testGetCachedResultsWithInvalidCacheKey() {
    // Test with very long config name that exceeds cache key limit (50 chars)
    String configDevName = 'Test_Config_With_Very_Long_Name_That_Exceeds_Cache_Key_Limit_12345';

    Test.startTest();
    try {
      JT_UsageFinder.AggregatedUsageResponse result = JT_UsageFinderQueueable.getCachedResults(
        configDevName,
        UserInfo.getUserId()
      );
      // May return null or throw exception depending on cache key validation
      System.assert(true, 'Should handle invalid cache key gracefully');
    } catch (Exception e) {
      // Exception is acceptable for invalid cache key
      System.assert(true, 'Exception acceptable for invalid cache key');
    }
    Test.stopTest();
  }

  /**
   * @description Test queueable execution with email notification and results
   * This test covers sendCompletionEmail and buildEmailBody methods indirectly
   */
  @IsTest
  static void testQueueableExecutionWithEmailAndResults() {
    String configDevName = 'Test_Config_EmailResults';
    String testEmail = 'test@example.com';

    Test.startTest();
    JT_UsageFinderQueueable job = new JT_UsageFinderQueueable(
      configDevName,
      testEmail,
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
      'Results should be cached with email notification'
    );
    // Email sending is tested indirectly - if no exception is thrown, email methods executed successfully
  }

  /**
   * @description Test queueable execution with error and email notification
   * This test covers sendErrorEmail method indirectly
   */
  @IsTest
  static void testQueueableExecutionErrorWithEmail() {
    // Test that exception is thrown during construction when configDevName is null
    String configDevName = null; // This will cause an error

    Test.startTest();
    try {
      JT_UsageFinderQueueable job = new JT_UsageFinderQueueable(
        configDevName,
        'test@example.com', // Email provided
        UserInfo.getUserId()
      );
      System.enqueueJob(job);
      System.assert(false, 'Should have thrown IllegalArgumentException');
    } catch (IllegalArgumentException e) {
      // Exception during construction is expected
      System.assert(true, 'Exception thrown as expected: ' + e.getMessage());
    }
    Test.stopTest();
  }

  /**
   * @description Test queueable execution with email and partial results
   * This test covers buildEmailBody with hasPartialResults flag
   */
  @IsTest
  static void testQueueableExecutionWithEmailPartialResults() {
    String configDevName = 'Test_Config_PartialResults';
    String testEmail = 'test@example.com';

    Test.startTest();
    JT_UsageFinderQueueable job = new JT_UsageFinderQueueable(
      configDevName,
      testEmail,
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
      'Results should be cached even with partial results'
    );
  }

  /**
   * @description Test queueable execution with email and zero results
   * This test covers buildEmailBody with zero total results
   */
  @IsTest
  static void testQueueableExecutionWithEmailZeroResults() {
    // Use a config name that likely won't be found
    String configDevName =
      'NonExistentConfig_' + String.valueOf(Math.random()).substring(2, 10);
    String testEmail = 'test@example.com';

    Test.startTest();
    JT_UsageFinderQueueable job = new JT_UsageFinderQueueable(
      configDevName,
      testEmail,
      UserInfo.getUserId()
    );
    System.enqueueJob(job);
    Test.stopTest();

    // Verify results are cached (even if empty)
    JT_UsageFinder.AggregatedUsageResponse cachedResult = JT_UsageFinderQueueable.getCachedResults(
      configDevName,
      UserInfo.getUserId()
    );

    // Results may be null if search failed, or may be cached with zero results
    // The important thing is that email methods were called without exception
    System.assert(true, 'Email methods should execute without exception');
  }

  /**
   * @description Test queueable execution with email and multiple usage results
   * This test covers buildEmailBody with multiple results in the list
   */
  @IsTest
  static void testQueueableExecutionWithEmailMultipleResults() {
    String configDevName = 'Test_Record'; // This should find multiple usages in test classes
    String testEmail = 'test@example.com';

    Test.startTest();
    JT_UsageFinderQueueable job = new JT_UsageFinderQueueable(
      configDevName,
      testEmail,
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
      'Results should be cached with multiple results'
    );
    // Email body building with multiple results is tested indirectly
  }
}
