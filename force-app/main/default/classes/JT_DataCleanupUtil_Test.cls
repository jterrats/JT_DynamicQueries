/**
 * @description Test class for JT_DataCleanupUtil
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @date 2025-12-14
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_DataCleanupUtil_Test {
  @testSetup
  static void setupTestData() {
    // Create old execution records
    List<JT_RunAsTest_Execution__c> oldExecutions = new List<JT_RunAsTest_Execution__c>();
    for (Integer i = 0; i < 5; i++) {
      oldExecutions.add(
        new JT_RunAsTest_Execution__c(
          Test_Status__c = 'Completed',
          Config_Name__c = 'Test_Record',
          User_To_Impersonate__c = UserInfo.getUserId(),
          Initiated_By__c = UserInfo.getUserId()
        )
      );
    }
    insert oldExecutions;
    // Set created date to 35 days ago
    for (JT_RunAsTest_Execution__c exec : oldExecutions) {
      Test.setCreatedDate(exec.Id, DateTime.now().addDays(-35));
    }

    // Create recent execution records (should not be deleted)
    List<JT_RunAsTest_Execution__c> recentExecutions = new List<JT_RunAsTest_Execution__c>();
    for (Integer i = 0; i < 3; i++) {
      recentExecutions.add(
        new JT_RunAsTest_Execution__c(
          Test_Status__c = 'Completed',
          Config_Name__c = 'Test_Record',
          User_To_Impersonate__c = UserInfo.getUserId(),
          Initiated_By__c = UserInfo.getUserId()
        )
      );
    }
    insert recentExecutions;
    // Set created date to 10 days ago
    for (JT_RunAsTest_Execution__c exec : recentExecutions) {
      Test.setCreatedDate(exec.Id, DateTime.now().addDays(-10));
    }

    // Create stuck execution records (Queued/Running older than 7 days)
    List<JT_RunAsTest_Execution__c> stuckExecutions = new List<JT_RunAsTest_Execution__c>();
    for (Integer i = 0; i < 2; i++) {
      stuckExecutions.add(
        new JT_RunAsTest_Execution__c(
          Test_Status__c = i == 0 ? 'Queued' : 'Running',
          Config_Name__c = 'Test_Record',
          User_To_Impersonate__c = UserInfo.getUserId(),
          Initiated_By__c = UserInfo.getUserId()
        )
      );
    }
    insert stuckExecutions;
    // Set created date to 10 days ago
    for (JT_RunAsTest_Execution__c exec : stuckExecutions) {
      Test.setCreatedDate(exec.Id, DateTime.now().addDays(-10));
    }

    // Create old audit logs
    List<JT_SettingsAuditLog__c> oldAuditLogs = new List<JT_SettingsAuditLog__c>();
    for (Integer i = 0; i < 4; i++) {
      oldAuditLogs.add(
        new JT_SettingsAuditLog__c(
          JT_Action__c = 'Test Action',
          JT_ChangedBy__c = UserInfo.getUserId()
        )
      );
    }
    insert oldAuditLogs;
    // Set created date to 100 days ago
    for (JT_SettingsAuditLog__c log : oldAuditLogs) {
      Test.setCreatedDate(log.Id, DateTime.now().addDays(-100));
    }

    // Create recent audit logs (should not be deleted)
    List<JT_SettingsAuditLog__c> recentAuditLogs = new List<JT_SettingsAuditLog__c>();
    for (Integer i = 0; i < 2; i++) {
      recentAuditLogs.add(
        new JT_SettingsAuditLog__c(
          JT_Action__c = 'Test Action',
          JT_ChangedBy__c = UserInfo.getUserId()
        )
      );
    }
    insert recentAuditLogs;
    // Set created date to 30 days ago
    for (JT_SettingsAuditLog__c log : recentAuditLogs) {
      Test.setCreatedDate(log.Id, DateTime.now().addDays(-30));
    }
  }

  /**
   * @description Test cleanupExecutionRecords with default retention period
   */
  @IsTest
  static void testCleanupExecutionRecordsDefault() {
    Test.startTest();
    Integer deletedCount = JT_DataCleanupUtil.cleanupExecutionRecords(null);
    Test.stopTest();

    System.assert(deletedCount >= 0, 'Should return count of deleted records');
    // Should delete old completed records (5) and stuck records (2) = 7 total
    System.assert(
      deletedCount >= 7,
      'Should delete old completed and stuck execution records'
    );

    // Verify recent records still exist
    List<JT_RunAsTest_Execution__c> remainingExecutions = [
      SELECT Id
      FROM JT_RunAsTest_Execution__c
      WHERE Test_Status__c = 'Completed'
    ];

    System.assert(
      remainingExecutions.size() >= 3,
      'Recent records should remain'
    );
  }

  /**
   * @description Test cleanupExecutionRecords with custom retention period
   */
  @IsTest
  static void testCleanupExecutionRecordsCustom() {
    Integer customDays = 5; // Very short retention

    Test.startTest();
    Integer deletedCount = JT_DataCleanupUtil.cleanupExecutionRecords(
      customDays
    );
    Test.stopTest();

    System.assert(deletedCount >= 0, 'Should return count of deleted records');
    // Should delete more records with shorter retention
    System.assert(
      deletedCount >= 7,
      'Should delete records older than custom retention period'
    );
  }

  /**
   * @description Test cleanupExecutionRecords with zero days (should use default)
   */
  @IsTest
  static void testCleanupExecutionRecordsZeroDays() {
    Test.startTest();
    Integer deletedCount = JT_DataCleanupUtil.cleanupExecutionRecords(0);
    Test.stopTest();

    System.assert(deletedCount >= 0, 'Should return count of deleted records');
    // Should use default retention when zero or negative
    System.assert(deletedCount >= 7, 'Should use default retention period');
  }

  /**
   * @description Test cleanupAuditLogs with default retention period
   */
  @IsTest
  static void testCleanupAuditLogsDefault() {
    Test.startTest();
    Integer deletedCount = JT_DataCleanupUtil.cleanupAuditLogs(null);
    Test.stopTest();

    System.assert(deletedCount >= 0, 'Should return count of deleted records');
    // Should delete old audit logs (4)
    System.assert(deletedCount >= 4, 'Should delete old audit logs');

    // Verify recent audit logs still exist
    List<JT_SettingsAuditLog__c> remainingLogs = [
      SELECT Id
      FROM JT_SettingsAuditLog__c
    ];

    System.assert(remainingLogs.size() >= 2, 'Recent audit logs should remain');
  }

  /**
   * @description Test cleanupAuditLogs with custom retention period
   */
  @IsTest
  static void testCleanupAuditLogsCustom() {
    Integer customDays = 50; // Custom retention

    Test.startTest();
    Integer deletedCount = JT_DataCleanupUtil.cleanupAuditLogs(customDays);
    Test.stopTest();

    System.assert(deletedCount >= 0, 'Should return count of deleted records');
    // Should delete records older than custom retention
    System.assert(deletedCount >= 4, 'Should delete old audit logs');
  }

  /**
   * @description Test getCleanupStatistics returns correct counts
   */
  @IsTest
  static void testGetCleanupStatistics() {
    Test.startTest();
    Map<String, Object> stats = JT_DataCleanupUtil.getCleanupStatistics();
    Test.stopTest();

    System.assertNotEquals(null, stats, 'Statistics should not be null');
    System.assert(
      stats.containsKey('oldExecutionRecords'),
      'Should contain oldExecutionRecords'
    );
    System.assert(
      stats.containsKey('stuckExecutionRecords'),
      'Should contain stuckExecutionRecords'
    );
    System.assert(
      stats.containsKey('oldAuditLogs'),
      'Should contain oldAuditLogs'
    );
    System.assert(
      stats.containsKey('totalDeletableRecords'),
      'Should contain totalDeletableRecords'
    );
    System.assert(
      stats.containsKey('executionRetentionDays'),
      'Should contain executionRetentionDays'
    );
    System.assert(
      stats.containsKey('auditLogRetentionDays'),
      'Should contain auditLogRetentionDays'
    );

    Integer oldExecutions = (Integer) stats.get('oldExecutionRecords');
    Integer stuckExecutions = (Integer) stats.get('stuckExecutionRecords');
    Integer oldAuditLogs = (Integer) stats.get('oldAuditLogs');

    System.assert(oldExecutions >= 5, 'Should count old execution records');
    System.assert(stuckExecutions >= 2, 'Should count stuck execution records');
    System.assert(oldAuditLogs >= 4, 'Should count old audit logs');
  }

  /**
   * @description Test performFullCleanup deletes both execution records and audit logs
   */
  @IsTest
  static void testPerformFullCleanup() {
    Test.startTest();
    Map<String, Object> results = JT_DataCleanupUtil.performFullCleanup(
      null,
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    System.assertEquals(true, results.get('success'), 'Should succeed');
    System.assert(
      results.containsKey('executionRecordsDeleted'),
      'Should contain executionRecordsDeleted'
    );
    System.assert(
      results.containsKey('auditLogsDeleted'),
      'Should contain auditLogsDeleted'
    );
    System.assert(
      results.containsKey('totalDeleted'),
      'Should contain totalDeleted'
    );

    Integer executionDeleted = (Integer) results.get('executionRecordsDeleted');
    Integer auditDeleted = (Integer) results.get('auditLogsDeleted');
    Integer totalDeleted = (Integer) results.get('totalDeleted');

    System.assert(executionDeleted >= 7, 'Should delete execution records');
    System.assert(auditDeleted >= 4, 'Should delete audit logs');
    System.assertEquals(
      executionDeleted + auditDeleted,
      totalDeleted,
      'Total should be sum of both'
    );
  }

  /**
   * @description Test performFullCleanup with custom retention periods
   */
  @IsTest
  static void testPerformFullCleanupCustom() {
    Test.startTest();
    Map<String, Object> results = JT_DataCleanupUtil.performFullCleanup(10, 50);
    Test.stopTest();

    System.assertEquals(true, results.get('success'), 'Should succeed');
    System.assert(
      results.containsKey('executionRecordsDeleted'),
      'Should contain executionRecordsDeleted'
    );
    System.assert(
      results.containsKey('auditLogsDeleted'),
      'Should contain auditLogsDeleted'
    );
  }

  /**
   * @description Test cleanupExecutionRecords with negative days (should use default)
   */
  @IsTest
  static void testCleanupExecutionRecordsNegativeDays() {
    Test.startTest();
    Integer deletedCount = JT_DataCleanupUtil.cleanupExecutionRecords(-5);
    Test.stopTest();

    System.assert(deletedCount >= 0, 'Should return count of deleted records');
    // Should use default retention when negative
    System.assert(deletedCount >= 7, 'Should use default retention period');
  }

  /**
   * @description Test cleanupAuditLogs with zero days (should use default)
   */
  @IsTest
  static void testCleanupAuditLogsZeroDays() {
    Test.startTest();
    Integer deletedCount = JT_DataCleanupUtil.cleanupAuditLogs(0);
    Test.stopTest();

    System.assert(deletedCount >= 0, 'Should return count of deleted records');
    // Should use default retention when zero or negative
    System.assert(deletedCount >= 4, 'Should use default retention period');
  }

  /**
   * @description Test cleanupAuditLogs with negative days (should use default)
   */
  @IsTest
  static void testCleanupAuditLogsNegativeDays() {
    Test.startTest();
    Integer deletedCount = JT_DataCleanupUtil.cleanupAuditLogs(-10);
    Test.stopTest();

    System.assert(deletedCount >= 0, 'Should return count of deleted records');
    // Should use default retention when negative
    System.assert(deletedCount >= 4, 'Should use default retention period');
  }

  /**
   * @description Test cleanupExecutionRecords when no records exist
   */
  @IsTest
  static void testCleanupExecutionRecordsNoRecords() {
    // Delete all test data first
    delete [SELECT Id FROM JT_RunAsTest_Execution__c];

    Test.startTest();
    Integer deletedCount = JT_DataCleanupUtil.cleanupExecutionRecords(null);
    Test.stopTest();

    System.assertEquals(0, deletedCount, 'Should return 0 when no records exist');
  }

  /**
   * @description Test cleanupAuditLogs when no records exist
   */
  @IsTest
  static void testCleanupAuditLogsNoRecords() {
    // Delete all test data first
    delete [SELECT Id FROM JT_SettingsAuditLog__c];

    Test.startTest();
    Integer deletedCount = JT_DataCleanupUtil.cleanupAuditLogs(null);
    Test.stopTest();

    System.assertEquals(0, deletedCount, 'Should return 0 when no records exist');
  }

  /**
   * @description Test getCleanupStatistics when no records exist
   */
  @IsTest
  static void testGetCleanupStatisticsNoRecords() {
    // Delete all test data first
    delete [SELECT Id FROM JT_RunAsTest_Execution__c];
    delete [SELECT Id FROM JT_SettingsAuditLog__c];

    Test.startTest();
    Map<String, Object> stats = JT_DataCleanupUtil.getCleanupStatistics();
    Test.stopTest();

    System.assertNotEquals(null, stats, 'Statistics should not be null');
    System.assertEquals(0, stats.get('oldExecutionRecords'), 'Should return 0');
    System.assertEquals(0, stats.get('stuckExecutionRecords'), 'Should return 0');
    System.assertEquals(0, stats.get('oldAuditLogs'), 'Should return 0');
    System.assertEquals(0, stats.get('totalDeletableRecords'), 'Should return 0');
  }

  /**
   * @description Test performFullCleanup with zero days for both parameters
   */
  @IsTest
  static void testPerformFullCleanupZeroDays() {
    Test.startTest();
    Map<String, Object> results = JT_DataCleanupUtil.performFullCleanup(0, 0);
    Test.stopTest();

    System.assertEquals(true, results.get('success'), 'Should succeed');
    System.assert(
      results.containsKey('executionRecordsDeleted'),
      'Should contain executionRecordsDeleted'
    );
    System.assert(
      results.containsKey('auditLogsDeleted'),
      'Should contain auditLogsDeleted'
    );
  }

  /**
   * @description Test performFullCleanup with negative days (should use defaults)
   */
  @IsTest
  static void testPerformFullCleanupNegativeDays() {
    Test.startTest();
    Map<String, Object> results = JT_DataCleanupUtil.performFullCleanup(-5, -10);
    Test.stopTest();

    System.assertEquals(true, results.get('success'), 'Should succeed');
    System.assert(
      results.containsKey('executionRecordsDeleted'),
      'Should contain executionRecordsDeleted'
    );
    System.assert(
      results.containsKey('auditLogsDeleted'),
      'Should contain auditLogsDeleted'
    );
  }

  /**
   * @description Test cleanupExecutionRecords with Failed status records
   */
  @IsTest
  static void testCleanupExecutionRecordsFailedStatus() {
    // Create old failed execution records
    List<JT_RunAsTest_Execution__c> failedExecutions = new List<JT_RunAsTest_Execution__c>();
    for (Integer i = 0; i < 3; i++) {
      failedExecutions.add(
        new JT_RunAsTest_Execution__c(
          Test_Status__c = 'Failed',
          Config_Name__c = 'Test_Record',
          User_To_Impersonate__c = UserInfo.getUserId(),
          Initiated_By__c = UserInfo.getUserId()
        )
      );
    }
    insert failedExecutions;
    // Set created date to 35 days ago
    for (JT_RunAsTest_Execution__c exec : failedExecutions) {
      Test.setCreatedDate(exec.Id, DateTime.now().addDays(-35));
    }

    Test.startTest();
    Integer deletedCount = JT_DataCleanupUtil.cleanupExecutionRecords(null);
    Test.stopTest();

    System.assert(deletedCount >= 3, 'Should delete failed execution records');
  }
}
