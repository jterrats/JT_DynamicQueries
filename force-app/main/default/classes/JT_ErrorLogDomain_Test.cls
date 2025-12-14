/**
 * @description Test class for JT_ErrorLogDomain
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @date 2025-12-14
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_ErrorLogDomain_Test {
  /**
   * @description Test insertLog with valid error log
   */
  @IsTest
  static void testInsertLogValid() {
    JT_ErrorLog__c errorLog = new JT_ErrorLog__c(
      JT_ErrorType__c = 'TestError',
      JT_ErrorMessage__c = 'Test error message',
      JT_Context__c = 'TestContext',
      JT_Timestamp__c = System.now(),
      JT_Severity__c = 'Medium'
    );

    Test.startTest();
    JT_ErrorLogDomain.insertLog(errorLog);
    Test.stopTest();

    System.assertNotEquals(
      null,
      errorLog.Id,
      'Error log should have ID after insert'
    );

    List<JT_ErrorLog__c> logs = [
      SELECT Id, JT_ErrorType__c, JT_ErrorMessage__c
      FROM JT_ErrorLog__c
      WHERE Id = :errorLog.Id
    ];

    System.assertEquals(1, logs.size(), 'One log should be created');
    System.assertEquals(
      'TestError',
      logs[0].JT_ErrorType__c,
      'Error type should match'
    );
    System.assertEquals(
      'Test error message',
      logs[0].JT_ErrorMessage__c,
      'Error message should match'
    );
  }

  /**
   * @description Test insertLog with null log (should throw exception)
   */
  @IsTest
  static void testInsertLogNull() {
    Test.startTest();
    try {
      JT_ErrorLogDomain.insertLog(null);
      System.assert(false, 'Should have thrown IllegalArgumentException');
    } catch (IllegalArgumentException e) {
      // Expected
      System.assert(
        e.getMessage().contains(Label.JT_ErrorLogDomain_errorLogCannotBeNull),
        'Exception message should reference Custom Label'
      );
    }
    Test.stopTest();
  }

  /**
   * @description Test insertLog with missing error type (should throw exception)
   */
  @IsTest
  static void testInsertLogMissingErrorType() {
    JT_ErrorLog__c errorLog = new JT_ErrorLog__c(
      JT_ErrorMessage__c = 'Test error message',
      JT_Timestamp__c = System.now()
    );

    Test.startTest();
    try {
      JT_ErrorLogDomain.insertLog(errorLog);
      System.assert(false, 'Should have thrown IllegalArgumentException');
    } catch (IllegalArgumentException e) {
      // Expected
      System.assert(
        e.getMessage().contains(Label.JT_ErrorLogDomain_errorTypeRequired),
        'Exception message should reference Custom Label'
      );
    }
    Test.stopTest();
  }

  /**
   * @description Test insertLog with missing error message (should throw exception)
   */
  @IsTest
  static void testInsertLogMissingErrorMessage() {
    JT_ErrorLog__c errorLog = new JT_ErrorLog__c(
      JT_ErrorType__c = 'TestError',
      JT_Timestamp__c = System.now()
    );

    Test.startTest();
    try {
      JT_ErrorLogDomain.insertLog(errorLog);
      System.assert(false, 'Should have thrown IllegalArgumentException');
    } catch (IllegalArgumentException e) {
      // Expected
      System.assert(
        e.getMessage().contains(Label.JT_ErrorLogDomain_errorMessageRequired),
        'Exception message should reference Custom Label'
      );
    }
    Test.stopTest();
  }

  /**
   * @description Test insertLogs with valid list
   */
  @IsTest
  static void testInsertLogsValid() {
    List<JT_ErrorLog__c> logs = new List<JT_ErrorLog__c>{
      new JT_ErrorLog__c(
        JT_ErrorType__c = 'Error1',
        JT_ErrorMessage__c = 'Message 1',
        JT_Timestamp__c = System.now()
      ),
      new JT_ErrorLog__c(
        JT_ErrorType__c = 'Error2',
        JT_ErrorMessage__c = 'Message 2',
        JT_Timestamp__c = System.now()
      )
    };

    Test.startTest();
    JT_ErrorLogDomain.insertLogs(logs);
    Test.stopTest();

    System.assertNotEquals(null, logs[0].Id, 'First log should have ID');
    System.assertNotEquals(null, logs[1].Id, 'Second log should have ID');

    List<JT_ErrorLog__c> insertedLogs = [
      SELECT Id, JT_ErrorType__c
      FROM JT_ErrorLog__c
      WHERE Id IN :new List<Id>{ logs[0].Id, logs[1].Id }
    ];

    System.assertEquals(2, insertedLogs.size(), 'Two logs should be created');
  }

  /**
   * @description Test insertLogs with null list (should return gracefully)
   */
  @IsTest
  static void testInsertLogsNull() {
    Test.startTest();
    JT_ErrorLogDomain.insertLogs(null);
    Test.stopTest();

    // Should complete without error
    System.assert(true, 'Should handle null list gracefully');
  }

  /**
   * @description Test insertLogs with empty list (should return gracefully)
   */
  @IsTest
  static void testInsertLogsEmpty() {
    Test.startTest();
    JT_ErrorLogDomain.insertLogs(new List<JT_ErrorLog__c>());
    Test.stopTest();

    // Should complete without error
    System.assert(true, 'Should handle empty list gracefully');
  }

  /**
   * @description Test deleteOldLogs with logs older than cutoff
   */
  @IsTest
  static void testDeleteOldLogs() {
    // Create old logs
    List<JT_ErrorLog__c> oldLogs = new List<JT_ErrorLog__c>();
    for (Integer i = 0; i < 5; i++) {
      oldLogs.add(
        new JT_ErrorLog__c(
          JT_ErrorType__c = 'OldError',
          JT_ErrorMessage__c = 'Old message ' + i,
          JT_Timestamp__c = DateTime.now().addDays(-10) // 10 days ago
        )
      );
    }
    insert oldLogs;

    // Create recent logs
    List<JT_ErrorLog__c> recentLogs = new List<JT_ErrorLog__c>();
    for (Integer i = 0; i < 3; i++) {
      recentLogs.add(
        new JT_ErrorLog__c(
          JT_ErrorType__c = 'RecentError',
          JT_ErrorMessage__c = 'Recent message ' + i,
          JT_Timestamp__c = DateTime.now().addDays(-1) // 1 day ago
        )
      );
    }
    insert recentLogs;

    Test.startTest();
    Integer deletedCount = JT_ErrorLogDomain.deleteOldLogs(7); // Keep logs from last 7 days
    Test.stopTest();

    System.assertEquals(5, deletedCount, 'Should delete 5 old logs');

    List<JT_ErrorLog__c> remainingLogs = [
      SELECT Id
      FROM JT_ErrorLog__c
      WHERE
        Id IN :new List<Id>(new Map<Id, JT_ErrorLog__c>(recentLogs).keySet())
    ];

    System.assertEquals(3, remainingLogs.size(), 'Recent logs should remain');
  }

  /**
   * @description Test deleteOldLogs with no old logs
   */
  @IsTest
  static void testDeleteOldLogsNoOldLogs() {
    // Create only recent logs
    List<JT_ErrorLog__c> recentLogs = new List<JT_ErrorLog__c>{
      new JT_ErrorLog__c(
        JT_ErrorType__c = 'RecentError',
        JT_ErrorMessage__c = 'Recent message',
        JT_Timestamp__c = DateTime.now().addDays(-1)
      )
    };
    insert recentLogs;

    Test.startTest();
    Integer deletedCount = JT_ErrorLogDomain.deleteOldLogs(7);
    Test.stopTest();

    System.assertEquals(0, deletedCount, 'Should delete 0 logs');

    List<JT_ErrorLog__c> remainingLogs = [
      SELECT Id
      FROM JT_ErrorLog__c
      WHERE Id = :recentLogs[0].Id
    ];

    System.assertEquals(1, remainingLogs.size(), 'Recent log should remain');
  }

  /**
   * @description Test deleteOldLogs respects limit (10000)
   */
  @IsTest
  static void testDeleteOldLogsRespectsLimit() {
    // Create many old logs (more than limit)
    List<JT_ErrorLog__c> oldLogs = new List<JT_ErrorLog__c>();
    for (Integer i = 0; i < 10005; i++) {
      oldLogs.add(
        new JT_ErrorLog__c(
          JT_ErrorType__c = 'OldError',
          JT_ErrorMessage__c = 'Old message ' + i,
          JT_Timestamp__c = DateTime.now().addDays(-10)
        )
      );
    }
    insert oldLogs;

    Test.startTest();
    Integer deletedCount = JT_ErrorLogDomain.deleteOldLogs(7);
    Test.stopTest();

    // Should delete up to 10000 (the limit)
    System.assertEquals(10000, deletedCount, 'Should delete up to limit');
  }
}
