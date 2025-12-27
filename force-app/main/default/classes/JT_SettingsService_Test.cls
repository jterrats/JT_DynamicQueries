/**
 * @description Test class for JT_SettingsService
 * @author Jaime Terrats
 * @date 2025-12-02
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class JT_SettingsService_Test {
  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testUpdateProductionEditingSetting() {
    Test.startTest();
    Boolean result = JT_SettingsService.updateProductionEditingSetting(true);
    Test.stopTest();

    System.assertEquals(true, result, 'Should return true');

    // Verify custom setting was updated
    JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();
    System.assertEquals(
      true,
      settings.JT_AllowProductionEditing__c,
      'Setting should be enabled'
    );

    // Verify audit log was created
    List<JT_SettingsAuditLog__c> logs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WHERE JT_Action__c LIKE '%Production Editing%'
      WITH USER_MODE
    ];

    System.assertEquals(1, logs.size(), 'Should create audit log');
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testUpdateUsageTrackingSetting() {
    Test.startTest();
    Boolean result = JT_SettingsService.updateUsageTrackingSetting(true);
    Test.stopTest();

    System.assertEquals(true, result, 'Should return true');

    // Verify custom setting was updated
    JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();
    System.assertEquals(
      true,
      settings.JT_EnableUsageTracking__c,
      'Setting should be enabled'
    );

    // Verify audit log was created
    List<JT_SettingsAuditLog__c> logs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WHERE JT_Action__c LIKE '%Usage Tracking%'
      WITH USER_MODE
    ];

    System.assertEquals(1, logs.size(), 'Should create audit log');
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testLogUsageSearch() {
    Test.startTest();
    JT_SettingsService.logUsageSearch('Test_Config', 10);
    Test.stopTest();

    // Verify audit log was created
    List<JT_SettingsAuditLog__c> logs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WHERE JT_Action__c LIKE 'Usage Search:%'
      WITH USER_MODE
    ];

    System.assertEquals(1, logs.size(), 'Should create usage search log');
    System.assert(
      logs[0].JT_Action__c.contains('Test_Config'),
      'Should contain config name'
    );
    System.assert(
      logs[0].JT_Action__c.contains('10'),
      'Should contain result count'
    );
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testGetProductionEditingSettingDefault() {
    // No custom setting exists yet
    Test.startTest();
    Boolean result = JT_SettingsService.getProductionEditingSetting();
    Test.stopTest();

    System.assertEquals(false, result, 'Should default to false');
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testGetUsageTrackingSettingDefault() {
    // No custom setting exists yet
    Test.startTest();
    Boolean result = JT_SettingsService.getUsageTrackingSetting();
    Test.stopTest();

    System.assertEquals(false, result, 'Should default to false');
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testUpdateProductionEditingSettingToggle() {
    // Enable
    JT_SettingsService.updateProductionEditingSetting(true);
    System.assertEquals(
      true,
      JT_SettingsService.getProductionEditingSetting(),
      'Should be enabled'
    );

    Test.startTest();
    // Disable
    JT_SettingsService.updateProductionEditingSetting(false);
    Test.stopTest();

    System.assertEquals(
      false,
      JT_SettingsService.getProductionEditingSetting(),
      'Should be disabled'
    );

    // Should have 2 audit logs
    List<JT_SettingsAuditLog__c> logs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WITH USER_MODE
    ];

    System.assert(
      logs.size() >= 2,
      'Should create logs for both enable and disable'
    );
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testUpdateUsageTrackingSettingToggle() {
    // Enable
    JT_SettingsService.updateUsageTrackingSetting(true);
    System.assertEquals(
      true,
      JT_SettingsService.getUsageTrackingSetting(),
      'Should be enabled'
    );

    Test.startTest();
    // Disable
    JT_SettingsService.updateUsageTrackingSetting(false);
    Test.stopTest();

    System.assertEquals(
      false,
      JT_SettingsService.getUsageTrackingSetting(),
      'Should be disabled'
    );
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testGetProductionEditingSettingWhenEnabled() {
    // Enable setting first
    JT_SettingsService.updateProductionEditingSetting(true);

    Test.startTest();
    Boolean result = JT_SettingsService.getProductionEditingSetting();
    Test.stopTest();

    System.assertEquals(true, result, 'Should return true when enabled');
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testGetUsageTrackingSettingWhenEnabled() {
    // Enable setting first
    JT_SettingsService.updateUsageTrackingSetting(true);

    Test.startTest();
    Boolean result = JT_SettingsService.getUsageTrackingSetting();
    Test.stopTest();

    System.assertEquals(true, result, 'Should return true when enabled');
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testLogUsageSearchWithZeroResults() {
    Test.startTest();
    JT_SettingsService.logUsageSearch('Test_Config_Zero', 0);
    Test.stopTest();

    // Verify audit log was created
    List<JT_SettingsAuditLog__c> logs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WHERE JT_Action__c LIKE 'Usage Search: Test_Config_Zero%'
      WITH USER_MODE
    ];

    System.assertEquals(1, logs.size(), 'Should create usage search log');
    System.assert(
      logs[0].JT_Action__c.contains('0'),
      'Should contain zero result count'
    );
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testLogUsageSearchWithLargeResultCount() {
    Test.startTest();
    JT_SettingsService.logUsageSearch('Test_Config_Large', 9999);
    Test.stopTest();

    // Verify audit log was created
    List<JT_SettingsAuditLog__c> logs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WHERE JT_Action__c LIKE 'Usage Search: Test_Config_Large%'
      WITH USER_MODE
    ];

    System.assertEquals(1, logs.size(), 'Should create usage search log');
    System.assert(
      logs[0].JT_Action__c.contains('9999'),
      'Should contain large result count'
    );
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testUpdateProductionEditingSettingWhenNull() {
    // Delete existing setting if any
    List<JT_DynamicQuerySettings__c> existingSettings = [
      SELECT Id
      FROM JT_DynamicQuerySettings__c
      WITH USER_MODE
    ];
    if (!existingSettings.isEmpty()) {
      delete existingSettings;
    }

    Test.startTest();
    Boolean result = JT_SettingsService.updateProductionEditingSetting(true);
    Test.stopTest();

    System.assertEquals(true, result, 'Should return true');
    // Verify setting was created
    JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();
    System.assertNotEquals(null, settings, 'Setting should be created');
    System.assertEquals(
      true,
      settings.JT_AllowProductionEditing__c,
      'Setting should be enabled'
    );
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testUpdateUsageTrackingSettingWhenNull() {
    // Delete existing setting if any
    List<JT_DynamicQuerySettings__c> existingSettings = [
      SELECT Id
      FROM JT_DynamicQuerySettings__c
      WITH USER_MODE
    ];
    if (!existingSettings.isEmpty()) {
      delete existingSettings;
    }

    Test.startTest();
    Boolean result = JT_SettingsService.updateUsageTrackingSetting(true);
    Test.stopTest();

    System.assertEquals(true, result, 'Should return true');
    // Verify setting was created
    JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();
    System.assertNotEquals(null, settings, 'Setting should be created');
    System.assertEquals(
      true,
      settings.JT_EnableUsageTracking__c,
      'Setting should be enabled'
    );
  }
}
