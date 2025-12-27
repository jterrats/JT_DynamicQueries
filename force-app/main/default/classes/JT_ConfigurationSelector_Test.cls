/**
 * @description Test class for JT_ConfigurationSelector
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @date 2025-12-14
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_ConfigurationSelector_Test {
  /**
   * @description Test getConfigurations returns all configurations sorted by label
   */
  @IsTest
  static void testGetConfigurations() {
    Test.startTest();
    List<JT_DynamicQueryConfiguration__mdt> configs = JT_ConfigurationSelector.getConfigurations();
    Test.stopTest();

    System.assertNotEquals(null, configs, 'Configurations should not be null');
    System.assert(configs.size() >= 0, 'Should return list (may be empty)');

    // Verify sorted by label
    if (configs.size() > 1) {
      for (Integer i = 0; i < configs.size() - 1; i++) {
        System.assert(
          configs[i].Label <= configs[i + 1].Label,
          'Configurations should be sorted by Label ASC'
        );
      }
    }
  }

  /**
   * @description Test getConfigurationByDevName with valid developer name
   */
  @IsTest
  static void testGetConfigurationByDevNameValid() {
    // Use existing test configuration
    String devName = 'Test_Record';

    Test.startTest();
    JT_DynamicQueryConfiguration__mdt config = JT_ConfigurationSelector.getConfigurationByDevName(
      devName
    );
    Test.stopTest();

    System.assertNotEquals(null, config, 'Configuration should not be null');
    System.assertEquals(
      devName,
      config.DeveloperName,
      'Developer name should match'
    );
    System.assertNotEquals(null, config.Label, 'Label should be populated');
  }

  /**
   * @description Test getConfigurationByDevName with invalid developer name (should throw exception)
   */
  @IsTest
  static void testGetConfigurationByDevNameInvalid() {
    String invalidDevName = 'NonExistent_Configuration_12345';

    Test.startTest();
    try {
      JT_ConfigurationSelector.getConfigurationByDevName(invalidDevName);
      System.assert(false, 'Should have thrown QueryException');
    } catch (QueryException e) {
      // Expected
      System.assert(
        e.getMessage().contains(invalidDevName),
        'Exception message should contain developer name'
      );
    }
    Test.stopTest();
  }

  /**
   * @description Test getConfigurationByDevName with null developer name
   */
  @IsTest
  static void testGetConfigurationByDevNameNull() {
    Test.startTest();
    try {
      JT_ConfigurationSelector.getConfigurationByDevName(null);
      System.assert(false, 'Should have thrown QueryException');
    } catch (QueryException e) {
      // Expected - null will not match any configuration
      System.assert(true, 'Exception thrown as expected');
    }
    Test.stopTest();
  }

  /**
   * @description Test getConfigurationsByObject with valid object name
   */
  @IsTest
  static void testGetConfigurationsByObjectValid() {
    String objectName = 'Account';

    Test.startTest();
    List<JT_DynamicQueryConfiguration__mdt> configs = JT_ConfigurationSelector.getConfigurationsByObject(
      objectName
    );
    Test.stopTest();

    System.assertNotEquals(null, configs, 'Configurations should not be null');
    System.assert(configs.size() >= 0, 'Should return list (may be empty)');

    // Verify all configs are for the specified object
    for (JT_DynamicQueryConfiguration__mdt config : configs) {
      System.assertEquals(
        objectName,
        config.JT_ObjectName__c,
        'All configurations should be for the specified object'
      );
    }

    // Verify sorted by label
    if (configs.size() > 1) {
      for (Integer i = 0; i < configs.size() - 1; i++) {
        System.assert(
          configs[i].Label <= configs[i + 1].Label,
          'Configurations should be sorted by Label ASC'
        );
      }
    }
  }

  /**
   * @description Test getConfigurationsByObject with non-existent object name
   */
  @IsTest
  static void testGetConfigurationsByObjectNonExistent() {
    String objectName = 'NonExistentObject__c';

    Test.startTest();
    List<JT_DynamicQueryConfiguration__mdt> configs = JT_ConfigurationSelector.getConfigurationsByObject(
      objectName
    );
    Test.stopTest();

    System.assertNotEquals(null, configs, 'Configurations should not be null');
    System.assertEquals(
      0,
      configs.size(),
      'Should return empty list for non-existent object'
    );
  }

  /**
   * @description Test getConfigurationsByObject with null object name
   */
  @IsTest
  static void testGetConfigurationsByObjectNull() {
    Test.startTest();
    List<JT_DynamicQueryConfiguration__mdt> configs = JT_ConfigurationSelector.getConfigurationsByObject(
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, configs, 'Configurations should not be null');
    System.assertEquals(
      0,
      configs.size(),
      'Should return empty list for null object'
    );
  }
}
