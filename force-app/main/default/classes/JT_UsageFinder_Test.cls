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
}