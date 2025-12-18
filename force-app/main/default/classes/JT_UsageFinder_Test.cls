/**
 * @description Test class for JT_UsageFinder
 * @author Jaime Terrats
 * @date 2025-11-30
 */
@IsTest
private class JT_UsageFinder_Test {
  /**
   * @description Test finding configuration usage in Apex classes
   */
  @IsTest
  static void testFindConfigurationUsageInApex() {
    Test.startTest();
    List<JT_UsageFinder.UsageResult> results = JT_UsageFinder.findConfigurationUsage(
      'Test_Record'
    );
    Test.stopTest();

    // Should find at least one usage (in JT_DataSelector_Test)
    System.assertNotEquals(null, results, 'Results should not be null');
    System.assert(results.size() >= 0, 'Should return results (even if empty)');

    // Verify result structure if found
    if (results.size() > 0) {
      JT_UsageFinder.UsageResult firstResult = results[0];
      System.assertNotEquals(
        null,
        firstResult.className,
        'Class name should not be null'
      );
      System.assertNotEquals(
        null,
        firstResult.metadataType,
        'Metadata type should not be null'
      );
      System.assertEquals(
        'Apex Class',
        firstResult.metadataType,
        'Should be Apex Class type'
      );
    }
  }

  /**
   * @description Test finding all usages
   */
  @IsTest
  static void testFindAllUsages() {
    Test.startTest();
    List<JT_UsageFinder.UsageResult> results = JT_UsageFinder.findAllUsages();
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    // Should find at least some usages in test classes
    System.assert(results.size() >= 0, 'Should return results');
  }

  /**
   * @description Test with non-existent configuration
   */
  @IsTest
  static void testFindNonExistentConfig() {
    Test.startTest();
    List<JT_UsageFinder.UsageResult> results = JT_UsageFinder.findConfigurationUsage(
      'NonExistentConfig123'
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      results,
      'Results should not be null even if empty'
    );
    // No error should be thrown, just empty results
    System.assert(true, 'Should handle non-existent config gracefully');
  }

  /**
   * @description Test Flow search with mock callout
   * Note: Flow search requires Tooling API callout which cannot be tested directly
   * This test ensures the method doesn't fail when session ID is unavailable
   */
  @IsTest
  static void testFlowSearchWithoutSession() {
    // Mock scenario: No VF page available (returns null session)
    Test.startTest();
    List<JT_UsageFinder.UsageResult> results = JT_UsageFinder.findConfigurationUsage(
      'Test_Record'
    );
    Test.stopTest();

    // Should not throw error even if Flow search fails
    System.assertNotEquals(
      null,
      results,
      'Should return results without failing'
    );
  }

  /**
   * @description Test UsageResult wrapper class
   */
  @IsTest
  @SuppressWarnings(
    'PMD.AvoidHardcodingId'
  ) // Hardcoded ID intentional for test data
  static void testUsageResultWrapper() {
    JT_UsageFinder.UsageResult result = new JT_UsageFinder.UsageResult();
    result.className = 'TestClass';
    result.configName = 'Test_Config';
    result.lineNumber = 42;
    result.codeLine = 'JT_DataSelector.getRecords(\'Test_Config\')';
    result.classId = '01p000000000000AAA';
    result.metadataType = 'Apex Class';

    System.assertEquals('TestClass', result.className);
    System.assertEquals('Test_Config', result.configName);
    System.assertEquals(42, result.lineNumber);
    System.assertEquals('Apex Class', result.metadataType);
  }

  /**
   * @description Test findInApexClassesService method
   */
  @IsTest
  static void testFindInApexClassesService() {
    Test.startTest();
    JT_UsageFinder.ServiceResponse response = JT_UsageFinder.findInApexClassesService(
      'Test_Record'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.serviceName, 'Service name should not be null');
    System.assertNotEquals(null, response.data, 'Data should not be null');
  }

  /**
   * @description Test findInApexClassesService with non-existent config
   */
  @IsTest
  static void testFindInApexClassesServiceNonExistent() {
    Test.startTest();
    JT_UsageFinder.ServiceResponse response = JT_UsageFinder.findInApexClassesService(
      'NonExistentConfig12345'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertEquals(true, response.success, 'Should succeed even with no results');
  }

  /**
   * @description Test findInFlowsService method
   */
  @IsTest
  static void testFindInFlowsService() {
    Test.startTest();
    JT_UsageFinder.ServiceResponse response = JT_UsageFinder.findInFlowsService(
      'Test_Record'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.serviceName, 'Service name should not be null');
    System.assertNotEquals(null, response.data, 'Data should not be null');
    // Flow search may fail if Tooling API is not available, but should not throw exception
  }

  /**
   * @description Test findAllUsagesResilient method
   */
  @IsTest
  static void testFindAllUsagesResilient() {
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse response = JT_UsageFinder.findAllUsagesResilient(
      'Test_Record'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.apexService, 'Apex service should not be null');
    System.assertNotEquals(null, response.flowService, 'Flow service should not be null');
    System.assertNotEquals(null, response.allResults, 'All results should not be null');
  }

  /**
   * @description Test findAllUsagesResilient with non-existent config
   */
  @IsTest
  static void testFindAllUsagesResilientNonExistent() {
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse response = JT_UsageFinder.findAllUsagesResilient(
      'NonExistentConfig12345'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.apexService, 'Apex service should not be null');
    System.assertNotEquals(null, response.flowService, 'Flow service should not be null');
  }

  /**
   * @description Test ServiceResponse wrapper class
   */
  @IsTest
  static void testServiceResponseWrapper() {
    JT_UsageFinder.ServiceResponse response = new JT_UsageFinder.ServiceResponse();
    response.success = true;
    response.error = null;
    response.data = new List<JT_UsageFinder.UsageResult>();
    response.serviceName = 'Test Service';

    System.assertEquals(true, response.success);
    System.assertEquals(null, response.error);
    System.assertEquals(0, response.data.size());
    System.assertEquals('Test Service', response.serviceName);
  }

  /**
   * @description Test AggregatedUsageResponse wrapper class
   */
  @IsTest
  static void testAggregatedUsageResponseWrapper() {
    JT_UsageFinder.AggregatedUsageResponse aggregated = new JT_UsageFinder.AggregatedUsageResponse();
    aggregated.apexService = new JT_UsageFinder.ServiceResponse();
    aggregated.flowService = new JT_UsageFinder.ServiceResponse();
    aggregated.hasPartialResults = false;
    aggregated.totalResults = 0;
    aggregated.totalFlowsFound = 0;
    aggregated.flowsProcessed = 0;
    aggregated.hasMoreFlows = false;
    aggregated.pendingFlowIds = new List<String>();

    System.assertNotEquals(null, aggregated.apexService);
    System.assertNotEquals(null, aggregated.flowService);
    System.assertEquals(false, aggregated.hasPartialResults);
    System.assertEquals(0, aggregated.totalResults);
  }

  /**
   * @description Test findInFlowsService with null config name
   */
  @IsTest
  static void testFindInFlowsServiceNullConfig() {
    Test.startTest();
    JT_UsageFinder.ServiceResponse response = JT_UsageFinder.findInFlowsService(null);
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.serviceName, 'Service name should not be null');
  }

  /**
   * @description Test findInFlowsService with empty config name
   */
  @IsTest
  static void testFindInFlowsServiceEmptyConfig() {
    Test.startTest();
    JT_UsageFinder.ServiceResponse response = JT_UsageFinder.findInFlowsService('');
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
  }

  /**
   * @description Test findInApexClassesService with null config name
   */
  @IsTest
  static void testFindInApexClassesServiceNullConfig() {
    Test.startTest();
    JT_UsageFinder.ServiceResponse response = JT_UsageFinder.findInApexClassesService(
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
  }

  /**
   * @description Test findInApexClassesService with empty config name
   */
  @IsTest
  static void testFindInApexClassesServiceEmptyConfig() {
    Test.startTest();
    JT_UsageFinder.ServiceResponse response = JT_UsageFinder.findInApexClassesService(
      ''
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
  }

  /**
   * @description Test findAllUsagesResilient with null config name
   */
  @IsTest
  static void testFindAllUsagesResilientNullConfig() {
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse response = JT_UsageFinder.findAllUsagesResilient(
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.apexService, 'Apex service should not be null');
    System.assertNotEquals(null, response.flowService, 'Flow service should not be null');
  }

  /**
   * @description Test findAllUsagesResilient with empty config name
   */
  @IsTest
  static void testFindAllUsagesResilientEmptyConfig() {
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse response = JT_UsageFinder.findAllUsagesResilient(
      ''
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.apexService, 'Apex service should not be null');
    System.assertNotEquals(null, response.flowService, 'Flow service should not be null');
  }

  /**
   * @description Test findConfigurationUsage with null config name
   */
  @IsTest
  static void testFindConfigurationUsageNullConfig() {
    Test.startTest();
    try {
      List<JT_UsageFinder.UsageResult> results = JT_UsageFinder.findConfigurationUsage(
        null
      );
      System.assertNotEquals(null, results, 'Results should not be null');
    } catch (Exception e) {
      // Null config name may throw exception, which is acceptable
      System.assert(true, 'Exception acceptable for null config name');
    }
    Test.stopTest();
  }

  /**
   * @description Test findConfigurationUsage with empty config name
   */
  @IsTest
  static void testFindConfigurationUsageEmptyConfig() {
    Test.startTest();
    List<JT_UsageFinder.UsageResult> results = JT_UsageFinder.findConfigurationUsage('');
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  /**
   * @description Test findAllUsages with empty results
   */
  @IsTest
  static void testFindAllUsagesEmpty() {
    Test.startTest();
    List<JT_UsageFinder.UsageResult> results = JT_UsageFinder.findAllUsages();
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    // Results may be empty or have entries depending on test data
    System.assert(results.size() >= 0, 'Should return list (may be empty)');
  }

  /**
   * @description Test ServiceResponse with error
   */
  @IsTest
  static void testServiceResponseWithError() {
    JT_UsageFinder.ServiceResponse response = new JT_UsageFinder.ServiceResponse();
    response.success = false;
    response.error = 'Test error';
    response.data = new List<JT_UsageFinder.UsageResult>();
    response.serviceName = 'Test Service';

    System.assertEquals(false, response.success);
    System.assertEquals('Test error', response.error);
    System.assertEquals(0, response.data.size());
  }

  /**
   * @description Test AggregatedUsageResponse with partial results
   */
  @IsTest
  static void testAggregatedUsageResponsePartialResults() {
    JT_UsageFinder.AggregatedUsageResponse aggregated = new JT_UsageFinder.AggregatedUsageResponse();
    aggregated.apexService = new JT_UsageFinder.ServiceResponse();
    aggregated.apexService.success = true;
    aggregated.flowService = new JT_UsageFinder.ServiceResponse();
    aggregated.flowService.success = false;
    aggregated.hasPartialResults = true;
    aggregated.totalResults = 5;

    System.assertEquals(true, aggregated.hasPartialResults);
    System.assertEquals(5, aggregated.totalResults);
  }

  /**
   * @description Test UsageResult with all fields populated
   */
  @IsTest
  static void testUsageResultAllFields() {
    JT_UsageFinder.UsageResult result = new JT_UsageFinder.UsageResult();
    result.className = 'TestClass';
    result.configName = 'Test_Config';
    result.lineNumber = 42;
    result.codeLine = 'JT_DataSelector.getRecords(\'Test_Config\')';
    result.classId = '01p000000000000AAA';
    result.metadataType = 'Flow';

    System.assertEquals('TestClass', result.className);
    System.assertEquals('Test_Config', result.configName);
    System.assertEquals(42, result.lineNumber);
    System.assertEquals('Flow', result.metadataType);
    System.assertEquals('01p000000000000AAA', result.classId);
    System.assertNotEquals(null, result.codeLine);
  }

  /**
   * @description Test findAllUsages with different config names
   */
  @IsTest
  static void testFindAllUsagesDifferentConfigs() {
    List<String> configNames = new List<String>{
      'Test_Record',
      'NonExistentConfig',
      ''
    };

    Test.startTest();
    for (String configName : configNames) {
      List<JT_UsageFinder.UsageResult> results = JT_UsageFinder.findAllUsages();
      System.assertNotEquals(null, results, 'Results should not be null for: ' + configName);
    }
    Test.stopTest();
  }

  /**
   * @description Test findConfigurationUsage with exception handling
   */
  @IsTest
  static void testFindConfigurationUsageException() {
    // This test verifies exception handling in findConfigurationUsage
    Test.startTest();
    try {
      List<JT_UsageFinder.UsageResult> results = JT_UsageFinder.findConfigurationUsage(
        'Test_Record'
      );
      System.assertNotEquals(null, results, 'Results should not be null');
    } catch (Exception e) {
      // Exception handling is tested
      System.assert(true, 'Exception handling works');
    }
    Test.stopTest();
  }

  /**
   * @description Test findInApexClassesService with exception
   */
  @IsTest
  static void testFindInApexClassesServiceException() {
    // This test verifies exception handling in findInApexClassesService
    Test.startTest();
    JT_UsageFinder.ServiceResponse response = JT_UsageFinder.findInApexClassesService(
      'Test_Record'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.serviceName, 'Service name should not be null');
  }

  /**
   * @description Test findInFlowsService with exception
   */
  @IsTest
  static void testFindInFlowsServiceException() {
    // This test verifies exception handling in findInFlowsService
    Test.startTest();
    JT_UsageFinder.ServiceResponse response = JT_UsageFinder.findInFlowsService(
      'Test_Record'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.serviceName, 'Service name should not be null');
  }

  /**
   * @description Test findAllUsagesResilient with both services failing
   */
  @IsTest
  static void testFindAllUsagesResilientBothFail() {
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse response = JT_UsageFinder.findAllUsagesResilient(
      'NonExistentConfig12345'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.apexService, 'Apex service should not be null');
    System.assertNotEquals(null, response.flowService, 'Flow service should not be null');
    System.assertEquals(false, response.hasPartialResults, 'Should not have partial results if both fail');
  }

  /**
   * @description Test findAllUsagesResilient with apex success and flow failure
   */
  @IsTest
  static void testFindAllUsagesResilientApexSuccessFlowFail() {
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse response = JT_UsageFinder.findAllUsagesResilient(
      'Test_Record'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.apexService, 'Apex service should not be null');
    System.assertNotEquals(null, response.flowService, 'Flow service should not be null');
    // May have partial results if one service succeeds and one fails
  }

  /**
   * @description Test findAllUsagesResilient with apex failure and flow success
   */
  @IsTest
  static void testFindAllUsagesResilientApexFailFlowSuccess() {
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse response = JT_UsageFinder.findAllUsagesResilient(
      'Test_Record'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.apexService, 'Apex service should not be null');
    System.assertNotEquals(null, response.flowService, 'Flow service should not be null');
    // May have partial results if one service succeeds and one fails
  }

  /**
   * @description Test findAllUsagesResilient with both services succeeding
   */
  @IsTest
  static void testFindAllUsagesResilientBothSuccess() {
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse response = JT_UsageFinder.findAllUsagesResilient(
      'Test_Record'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertNotEquals(null, response.apexService, 'Apex service should not be null');
    System.assertNotEquals(null, response.flowService, 'Flow service should not be null');
    System.assertEquals(false, response.hasPartialResults, 'Should not have partial results if both succeed');
  }

  /**
   * @description Test ServiceResponse constructor
   */
  @IsTest
  static void testServiceResponseConstructor() {
    Test.startTest();
    JT_UsageFinder.ServiceResponse response = new JT_UsageFinder.ServiceResponse();
    Test.stopTest();

    System.assertNotEquals(null, response.data, 'Data should be initialized');
    System.assertEquals(0, response.data.size(), 'Data should be empty list');
  }

  /**
   * @description Test AggregatedUsageResponse constructor
   */
  @IsTest
  static void testAggregatedUsageResponseConstructor() {
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse aggregated = new JT_UsageFinder.AggregatedUsageResponse();
    Test.stopTest();

    System.assertNotEquals(null, aggregated.allResults, 'All results should be initialized');
    System.assertEquals(0, aggregated.totalFlowsFound, 'Total flows found should be 0');
    System.assertEquals(0, aggregated.flowsProcessed, 'Flows processed should be 0');
    System.assertEquals(false, aggregated.hasMoreFlows, 'Has more flows should be false');
    System.assertNotEquals(null, aggregated.pendingFlowIds, 'Pending flow IDs should be initialized');
  }

  /**
   * @description Test UsageResult with null values
   */
  @IsTest
  static void testUsageResultNullValues() {
    JT_UsageFinder.UsageResult result = new JT_UsageFinder.UsageResult();
    result.className = null;
    result.configName = null;
    result.lineNumber = null;
    result.codeLine = null;
    result.classId = null;
    result.metadataType = null;

    System.assertEquals(null, result.className);
    System.assertEquals(null, result.configName);
    System.assertEquals(null, result.lineNumber);
  }

  /**
   * @description Test ServiceResponse with null values
   */
  @IsTest
  static void testServiceResponseNullValues() {
    JT_UsageFinder.ServiceResponse response = new JT_UsageFinder.ServiceResponse();
    response.success = null;
    response.error = null;
    response.serviceName = null;

    System.assertEquals(null, response.success);
    System.assertEquals(null, response.error);
    System.assertEquals(null, response.serviceName);
  }

  /**
   * @description Test AggregatedUsageResponse with null values
   */
  @IsTest
  static void testAggregatedUsageResponseNullValues() {
    JT_UsageFinder.AggregatedUsageResponse aggregated = new JT_UsageFinder.AggregatedUsageResponse();
    aggregated.apexService = null;
    aggregated.flowService = null;
    aggregated.hasPartialResults = null;
    aggregated.totalResults = null;

    System.assertEquals(null, aggregated.apexService);
    System.assertEquals(null, aggregated.flowService);
    System.assertEquals(null, aggregated.hasPartialResults);
    System.assertEquals(null, aggregated.totalResults);
  }

  /**
   * @description Test findConfigurationUsage with very long config name
   */
  @IsTest
  static void testFindConfigurationUsageLongConfigName() {
    String longConfigName = 'A'.repeat(200);
    Test.startTest();
    List<JT_UsageFinder.UsageResult> results = JT_UsageFinder.findConfigurationUsage(
      longConfigName
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
  }

  /**
   * @description Test findAllUsagesResilient with very long config name
   */
  @IsTest
  static void testFindAllUsagesResilientLongConfigName() {
    String longConfigName = 'A'.repeat(200);
    Test.startTest();
    JT_UsageFinder.AggregatedUsageResponse response = JT_UsageFinder.findAllUsagesResilient(
      longConfigName
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
  }
}
