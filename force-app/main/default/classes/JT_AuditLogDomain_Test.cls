/**
 * @description Test class for JT_AuditLogDomain
 * @author Jaime Terrats
 * @date 2025-12-02
 */
@isTest
private class JT_AuditLogDomain_Test {
  @isTest
  static void testInsertLog_Success() {
    // Create audit log
    JT_SettingsAuditLog__c log = new JT_SettingsAuditLog__c(
      JT_Action__c = 'Test Action',
      JT_ChangedBy__c = UserInfo.getUserId(),
      JT_ChangedByUsername__c = UserInfo.getUserName(),
      JT_Timestamp__c = System.now(),
      JT_OrgType__c = 'Developer Edition'
    );

    Test.startTest();
    JT_AuditLogDomain.insertLog(log);
    Test.stopTest();

    // Verify log was created
    List<JT_SettingsAuditLog__c> logs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WHERE JT_Action__c = 'Test Action'
      WITH USER_MODE
    ];

    System.assertEquals(1, logs.size(), 'Should create 1 audit log');
    System.assertNotEquals(null, log.Id, 'Log should have Id after insert');
  }

  @isTest
  static void testInsertLog_NullLog() {
    Boolean exceptionThrown = false;

    Test.startTest();
    try {
      JT_AuditLogDomain.insertLog(null);
    } catch (IllegalArgumentException e) {
      exceptionThrown = true;
      System.assert(
        e.getMessage().contains('cannot be null'),
        'Should mention null'
      );
    }
    Test.stopTest();

    System.assertEquals(
      true,
      exceptionThrown,
      'Should throw exception for null log'
    );
  }

  @isTest
  static void testInsertLog_MissingRequiredField() {
    // Create log without required JT_Action__c field
    JT_SettingsAuditLog__c log = new JT_SettingsAuditLog__c(
      JT_ChangedBy__c = UserInfo.getUserId()
    );

    Boolean exceptionThrown = false;

    Test.startTest();
    try {
      JT_AuditLogDomain.insertLog(log);
    } catch (IllegalArgumentException e) {
      exceptionThrown = true;
      System.assert(
        e.getMessage().contains('required'),
        'Should mention required field'
      );
    }
    Test.stopTest();

    System.assertEquals(
      true,
      exceptionThrown,
      'Should throw exception for missing required field'
    );
  }

  @isTest
  static void testInsertLogs_Bulk() {
    List<JT_SettingsAuditLog__c> logs = new List<JT_SettingsAuditLog__c>();

    for (Integer i = 0; i < 5; i++) {
      logs.add(
        new JT_SettingsAuditLog__c(
          JT_Action__c = 'Bulk Test Action ' + i,
          JT_ChangedBy__c = UserInfo.getUserId(),
          JT_ChangedByUsername__c = UserInfo.getUserName(),
          JT_Timestamp__c = System.now(),
          JT_OrgType__c = 'Developer Edition'
        )
      );
    }

    Test.startTest();
    JT_AuditLogDomain.insertLogs(logs);
    Test.stopTest();

    // Verify all logs were created
    List<JT_SettingsAuditLog__c> insertedLogs = [
      SELECT Id, JT_Action__c
      FROM JT_SettingsAuditLog__c
      WHERE JT_Action__c LIKE 'Bulk Test Action%'
      WITH USER_MODE
    ];

    System.assertEquals(5, insertedLogs.size(), 'Should create 5 audit logs');
  }

  @isTest
  static void testInsertLogs_EmptyList() {
    Test.startTest();
    JT_AuditLogDomain.insertLogs(new List<JT_SettingsAuditLog__c>());
    Test.stopTest();

    // Should not throw exception
    System.assert(true, 'Should handle empty list gracefully');
  }

  @isTest
  static void testDeleteOldLogs() {
    // Create old logs (simulate 31 days ago)
    List<JT_SettingsAuditLog__c> oldLogs = new List<JT_SettingsAuditLog__c>();

    for (Integer i = 0; i < 3; i++) {
      oldLogs.add(
        new JT_SettingsAuditLog__c(
          JT_Action__c = 'Old Log ' + i,
          JT_ChangedBy__c = UserInfo.getUserId(),
          JT_ChangedByUsername__c = UserInfo.getUserName(),
          JT_Timestamp__c = System.now().addDays(-31),
          JT_OrgType__c = 'Developer Edition'
        )
      );
    }

    insert oldLogs;

    Test.startTest();
    Integer deletedCount = JT_AuditLogDomain.deleteOldLogs(30);
    Test.stopTest();

    System.assertEquals(3, deletedCount, 'Should delete 3 old logs');

    // Verify logs were deleted
    List<JT_SettingsAuditLog__c> remainingLogs = [
      SELECT Id
      FROM JT_SettingsAuditLog__c
      WHERE JT_Action__c LIKE 'Old Log%'
      WITH USER_MODE
    ];

    System.assertEquals(0, remainingLogs.size(), 'Old logs should be deleted');
  }
}
