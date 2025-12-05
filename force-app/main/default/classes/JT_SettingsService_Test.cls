/**
 * @description Test class for JT_SettingsService
 * @author Jaime Terrats
 * @date 2025-12-02
 */
@isTest
private class JT_SettingsService_Test {
  @isTest
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

  @isTest
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

  @isTest
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

  @isTest
  static void testGetProductionEditingSetting_Default() {
    // No custom setting exists yet
    Test.startTest();
    Boolean result = JT_SettingsService.getProductionEditingSetting();
    Test.stopTest();

    System.assertEquals(false, result, 'Should default to false');
  }

  @isTest
  static void testGetUsageTrackingSetting_Default() {
    // No custom setting exists yet
    Test.startTest();
    Boolean result = JT_SettingsService.getUsageTrackingSetting();
    Test.stopTest();

    System.assertEquals(false, result, 'Should default to false');
  }

  @isTest
  static void testUpdateProductionEditingSetting_Toggle() {
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
}


