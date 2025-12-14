/**
 * @description Utility class for cleaning up old execution records and audit logs
 * Helps free up storage space by removing old, completed records
 * @author Jaime Terrats
 * @group Dynamic Queries
 */
public with sharing class JT_DataCleanupUtil {
  // Retention periods (in days)
  private static final Integer EXECUTION_RETENTION_DAYS = 30; // Keep execution records for 30 days
  private static final Integer AUDIT_LOG_RETENTION_DAYS = 90; // Keep audit logs for 90 days
  private static final Integer BATCH_SIZE = 200; // Process in batches to avoid governor limits

  /**
   * @description Cleans up old JT_RunAsTest_Execution__c records
   * Removes records that are:
   * - Completed or Failed AND older than retention period
   * - Queued or Running AND older than 7 days (stuck executions)
   * Preserves recent records and active executions
   * @param daysToKeep Optional: Number of days to keep records (default: 30)
   * @return Integer Number of records deleted
   */
  @AuraEnabled
  public static Integer cleanupExecutionRecords(Integer daysToKeep) {
    Integer retentionDays = daysToKeep != null && daysToKeep > 0
      ? daysToKeep
      : EXECUTION_RETENTION_DAYS;

    Datetime cutoffDate = Datetime.now().addDays(-retentionDays);
    Datetime stuckCutoffDate = Datetime.now().addDays(-7); // Clean up stuck executions after 7 days

    Integer deletedCount = 0;

    try {
      // Delete old completed/failed records
      List<JT_RunAsTest_Execution__c> oldCompletedRecords = [
        SELECT Id
        FROM JT_RunAsTest_Execution__c
        WHERE
          Test_Status__c IN ('Completed', 'Failed')
          AND CreatedDate < :cutoffDate
        WITH USER_MODE
        LIMIT 10000
      ];

      if (!oldCompletedRecords.isEmpty()) {
        // Delete in batches to avoid governor limits
        for (Integer i = 0; i < oldCompletedRecords.size(); i += BATCH_SIZE) {
          Integer endIndex = Math.min(i + BATCH_SIZE, oldCompletedRecords.size());
          List<JT_RunAsTest_Execution__c> batch = new List<JT_RunAsTest_Execution__c>();
          for (Integer j = i; j < endIndex; j++) {
            batch.add(oldCompletedRecords[j]);
          }
          delete batch;
          deletedCount += batch.size();
        }
      }

      // Delete stuck Queued/Running records (older than 7 days)
      List<JT_RunAsTest_Execution__c> stuckRecords = [
        SELECT Id
        FROM JT_RunAsTest_Execution__c
        WHERE
          Test_Status__c IN ('Queued', 'Running')
          AND CreatedDate < :stuckCutoffDate
        WITH USER_MODE
        LIMIT 1000
      ];

      if (!stuckRecords.isEmpty()) {
        // Delete in batches
        for (Integer i = 0; i < stuckRecords.size(); i += BATCH_SIZE) {
          Integer endIndex = Math.min(i + BATCH_SIZE, stuckRecords.size());
          List<JT_RunAsTest_Execution__c> batch = new List<JT_RunAsTest_Execution__c>();
          for (Integer j = i; j < endIndex; j++) {
            batch.add(stuckRecords[j]);
          }
          delete batch;
          deletedCount += batch.size();
        }
      }

      System.debug(
        '✅ Cleaned up ' +
        deletedCount +
        ' execution records older than ' +
        retentionDays +
        ' days'
      );
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ Error cleaning up execution records: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Failed to cleanup execution records: ' + e.getMessage()
      );
    }

    return deletedCount;
  }

  /**
   * @description Cleans up old JT_SettingsAuditLog__c records
   * Removes audit log entries older than retention period
   * @param daysToKeep Optional: Number of days to keep records (default: 90)
   * @return Integer Number of records deleted
   */
  @AuraEnabled
  public static Integer cleanupAuditLogs(Integer daysToKeep) {
    Integer retentionDays = daysToKeep != null && daysToKeep > 0
      ? daysToKeep
      : AUDIT_LOG_RETENTION_DAYS;

    Datetime cutoffDate = Datetime.now().addDays(-retentionDays);

    Integer deletedCount = 0;

    try {
      List<JT_SettingsAuditLog__c> oldAuditLogs = [
        SELECT Id
        FROM JT_SettingsAuditLog__c
        WHERE CreatedDate < :cutoffDate
        WITH USER_MODE
        LIMIT 10000
      ];

      if (!oldAuditLogs.isEmpty()) {
        // Delete in batches to avoid governor limits
        for (Integer i = 0; i < oldAuditLogs.size(); i += BATCH_SIZE) {
          Integer endIndex = Math.min(i + BATCH_SIZE, oldAuditLogs.size());
          List<JT_SettingsAuditLog__c> batch = new List<JT_SettingsAuditLog__c>();
          for (Integer j = i; j < endIndex; j++) {
            batch.add(oldAuditLogs[j]);
          }
          delete batch;
          deletedCount += batch.size();
        }
      }

      System.debug(
        '✅ Cleaned up ' +
        deletedCount +
        ' audit log records older than ' +
        retentionDays +
        ' days'
      );
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ Error cleaning up audit logs: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Failed to cleanup audit logs: ' + e.getMessage()
      );
    }

    return deletedCount;
  }

  /**
   * @description Gets statistics about data that can be cleaned up
   * @return Map<String, Object> Statistics about old records
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getCleanupStatistics() {
    Map<String, Object> stats = new Map<String, Object>();

    Datetime executionCutoff = Datetime.now().addDays(-EXECUTION_RETENTION_DAYS);
    Datetime auditCutoff = Datetime.now().addDays(-AUDIT_LOG_RETENTION_DAYS);
    Datetime stuckCutoff = Datetime.now().addDays(-7);

    try {
      // Count old execution records
      Integer oldCompletedExecutions = [
        SELECT COUNT()
        FROM JT_RunAsTest_Execution__c
        WHERE
          Test_Status__c IN ('Completed', 'Failed')
          AND CreatedDate < :executionCutoff
        WITH USER_MODE
      ];

      Integer stuckExecutions = [
        SELECT COUNT()
        FROM JT_RunAsTest_Execution__c
        WHERE
          Test_Status__c IN ('Queued', 'Running')
          AND CreatedDate < :stuckCutoff
        WITH USER_MODE
      ];

      // Count old audit logs
      Integer oldAuditLogs = [
        SELECT COUNT()
        FROM JT_SettingsAuditLog__c
        WHERE CreatedDate < :auditCutoff
        WITH USER_MODE
      ];

      stats.put('oldExecutionRecords', oldCompletedExecutions);
      stats.put('stuckExecutionRecords', stuckExecutions);
      stats.put('oldAuditLogs', oldAuditLogs);
      stats.put(
        'totalDeletableRecords',
        oldCompletedExecutions + stuckExecutions + oldAuditLogs
      );
      stats.put('executionRetentionDays', EXECUTION_RETENTION_DAYS);
      stats.put('auditLogRetentionDays', AUDIT_LOG_RETENTION_DAYS);
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ Error getting cleanup statistics: ' + e.getMessage()
      );
      stats.put('error', e.getMessage());
    }

    return stats;
  }

  /**
   * @description Performs a full cleanup of all old records
   * @param executionDaysToKeep Optional: Days to keep execution records (default: 30)
   * @param auditDaysToKeep Optional: Days to keep audit logs (default: 90)
   * @return Map<String, Object> Results with counts of deleted records
   */
  @AuraEnabled
  public static Map<String, Object> performFullCleanup(
    Integer executionDaysToKeep,
    Integer auditDaysToKeep
  ) {
    Map<String, Object> results = new Map<String, Object>();

    try {
      Integer executionDeleted = cleanupExecutionRecords(executionDaysToKeep);
      Integer auditDeleted = cleanupAuditLogs(auditDaysToKeep);

      results.put('executionRecordsDeleted', executionDeleted);
      results.put('auditLogsDeleted', auditDeleted);
      results.put('totalDeleted', executionDeleted + auditDeleted);
      results.put('success', true);
    } catch (Exception e) {
      results.put('success', false);
      results.put('error', e.getMessage());
    }

    return results;
  }
}

