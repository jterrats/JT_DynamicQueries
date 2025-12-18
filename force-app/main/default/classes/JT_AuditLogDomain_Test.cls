/**
 * @description Test class for JT_AuditLogDomain
 * @author Jaime Terrats
 * @date 2025-12-02
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class JT_AuditLogDomain_Test {
  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testInsertLogSuccess() {
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

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testInsertLogNullLog() {
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

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testInsertLogMissingRequiredField() {
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

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testInsertLogsBulk() {
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

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testInsertLogsEmptyList() {
    Test.startTest();
    JT_AuditLogDomain.insertLogs(new List<JT_SettingsAuditLog__c>());
    Test.stopTest();

    // Should not throw exception
    System.assert(true, 'Should handle empty list gracefully');
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
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

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testInsertLogsNullList() {
    Test.startTest();
    JT_AuditLogDomain.insertLogs(null);
    Test.stopTest();

    // Should not throw exception, should return early
    System.assert(true, 'Should handle null list gracefully');
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testDeleteOldLogsNoLogs() {
    // Ensure no old logs exist
    delete [SELECT Id FROM JT_SettingsAuditLog__c WHERE CreatedDate < :DateTime.now().addDays(-30)];

    Test.startTest();
    Integer deletedCount = JT_AuditLogDomain.deleteOldLogs(30);
    Test.stopTest();

    System.assertEquals(0, deletedCount, 'Should return 0 when no logs exist');
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testDeleteOldLogsWithRecentLogs() {
    // Create recent logs (should not be deleted)
    List<JT_SettingsAuditLog__c> recentLogs = new List<JT_SettingsAuditLog__c>();
    for (Integer i = 0; i < 2; i++) {
      recentLogs.add(
        new JT_SettingsAuditLog__c(
          JT_Action__c = 'Recent Log ' + i,
          JT_ChangedBy__c = UserInfo.getUserId(),
          JT_ChangedByUsername__c = UserInfo.getUserName(),
          JT_Timestamp__c = System.now().addDays(-10),
          JT_OrgType__c = 'Developer Edition'
        )
      );
    }
    insert recentLogs;

    Test.startTest();
    Integer deletedCount = JT_AuditLogDomain.deleteOldLogs(30);
    Test.stopTest();

    // Should not delete recent logs
    System.assertEquals(0, deletedCount, 'Should not delete recent logs');

    // Verify recent logs still exist
    List<JT_SettingsAuditLog__c> remainingLogs = [
      SELECT Id
      FROM JT_SettingsAuditLog__c
      WHERE JT_Action__c LIKE 'Recent Log%'
      WITH USER_MODE
    ];

    System.assertEquals(2, remainingLogs.size(), 'Recent logs should remain');
  }

  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testInsertLogBlankAction() {
    // Create log with blank action
    JT_SettingsAuditLog__c log = new JT_SettingsAuditLog__c(
      JT_Action__c = '   ', // Blank string
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
      'Should throw exception for blank action'
    );
  }
}
