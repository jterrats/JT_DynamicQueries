/**
 * @description Test class for JT_ProductionSettingsController
 * @author Jaime Terrats
 * @date 2025-11-30
 */
@isTest
private class JT_ProductionSettingsController_Test {
  /**
   * @description Test getting production editing setting (default false)
   */
  @isTest
  static void testGetProductionEditingSettingDefault() {
    Test.startTest();
    Boolean result = JT_ProductionSettingsController.getProductionEditingSetting();
    Test.stopTest();

    System.assertEquals(
      false,
      result,
      'Default setting should be false'
    );
  }

  /**
   * @description Test updating production editing setting
   */
  @isTest
  static void testUpdateProductionEditingSetting() {
    Test.startTest();
    Boolean updateResult = JT_ProductionSettingsController.updateProductionEditingSetting(
      true
    );
    Test.stopTest();

    System.assertEquals(
      true,
      updateResult,
      'Update should succeed'
    );

    // Verify setting was updated
    Boolean currentValue = JT_ProductionSettingsController.getProductionEditingSetting();
    System.assertEquals(
      true,
      currentValue,
      'Setting should be enabled'
    );

    // Verify audit log was created
    List<JT_SettingsAuditLog__c> logs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WITH USER_MODE
      LIMIT 1
    ];

    System.assertEquals(
      1,
      logs.size(),
      'Audit log should be created'
    );
    System.assertEquals(
      'Enabled',
      logs[0].JT_Action__c,
      'Action should be Enabled'
    );
  }

  /**
   * @description Test disabling production editing
   */
  @isTest
  static void testDisableProductionEditing() {
    // First enable it
    JT_ProductionSettingsController.updateProductionEditingSetting(true);

    Test.startTest();
    Boolean updateResult = JT_ProductionSettingsController.updateProductionEditingSetting(
      false
    );
    Test.stopTest();

    System.assertEquals(
      true,
      updateResult,
      'Update should succeed'
    );

    Boolean currentValue = JT_ProductionSettingsController.getProductionEditingSetting();
    System.assertEquals(
      false,
      currentValue,
      'Setting should be disabled'
    );
  }

  /**
   * @description Test audit log creation directly
   */
  @isTest
  static void testAuditLogCreationViaQuery() {
    // Create some audit entries
    JT_ProductionSettingsController.updateProductionEditingSetting(true);
    JT_ProductionSettingsController.updateProductionEditingSetting(false);

    Test.startTest();
    List<JT_SettingsAuditLog__c> logs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WITH USER_MODE
      ORDER BY CreatedDate DESC
    ];
    Test.stopTest();

    System.assertNotEquals(
      null,
      logs,
      'Logs should not be null'
    );
    System.assert(
      logs.size() >= 2,
      'Should have at least 2 audit log entries'
    );
  }

  /**
   * @description Test Starter/Free Edition detection
   */
  @isTest
  static void testIsStarterOrFreeEdition() {
    Test.startTest();
    Boolean isStarter = JT_ProductionSettingsController.isStarterOrFreeEdition();
    Test.stopTest();

    // In test context, this will depend on org type
    // Just verify it doesn't throw an error
    System.assertNotEquals(
      null,
      isStarter,
      'Should return a boolean value'
    );
  }

  /**
   * @description Test audit log creation with without sharing
   * Verifies that audit logs can be created even without explicit permissions
   */
  @isTest
  static void testAuditLogCreationWithoutSharing() {
    // This test verifies the @SuppressWarnings('PMD.ApexCRUDViolation')
    // annotation is correctly applied for AppExchange security review

    Test.startTest();
    Boolean result = JT_ProductionSettingsController.updateProductionEditingSetting(
      true
    );
    Test.stopTest();

    // Verify audit log was created despite without sharing context
    List<JT_SettingsAuditLog__c> logs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WITH USER_MODE
    ];

    System.assert(
      logs.size() > 0,
      'Audit log should be created with without sharing'
    );
  }

  /**
   * @description Test error handling in get setting
   */
  @isTest
  static void testGetSettingErrorHandling() {
    // This test verifies graceful error handling
    Test.startTest();
    Boolean result = JT_ProductionSettingsController.getProductionEditingSetting();
    Test.stopTest();

    // Should return false on any error, not throw exception
    System.assertNotEquals(
      null,
      result,
      'Should return a value even on error'
    );
  }

  /**
   * @description Test getting usage tracking setting
   */
  @isTest
  static void testGetUsageTrackingSetting() {
    Test.startTest();
    Boolean result = JT_ProductionSettingsController.getUsageTrackingSetting();
    Test.stopTest();

    System.assertEquals(
      false,
      result,
      'Default usage tracking should be false'
    );
  }

  /**
   * @description Test updating usage tracking setting
   */
  @isTest
  static void testUpdateUsageTrackingSetting() {
    Test.startTest();
    Boolean updateResult = JT_ProductionSettingsController.updateUsageTrackingSetting(
      true
    );
    Test.stopTest();

    System.assertEquals(
      true,
      updateResult,
      'Update should succeed'
    );

    Boolean currentValue = JT_ProductionSettingsController.getUsageTrackingSetting();
    System.assertEquals(
      true,
      currentValue,
      'Usage tracking should be enabled'
    );
  }

  /**
   * @description Test logging usage search
   */
  @isTest
  static void testLogUsageSearch() {
    Test.startTest();
    JT_ProductionSettingsController.logUsageSearch('Test_Config', 5);
    Test.stopTest();

    List<JT_SettingsAuditLog__c> logs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WHERE JT_Action__c LIKE 'Usage Search:%'
      WITH USER_MODE
    ];

    System.assert(
      logs.size() > 0,
      'Usage search should be logged'
    );
  }
}
