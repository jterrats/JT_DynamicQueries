/**
 * @description Domain class for JT_ErrorLog__c
 * Handles all DML operations for error logs
 * Follows Domain Layer pattern (DML operations only)
 *
 * @author Jaime Terrats
 * @date 2025-12-14
 * @group Domain Layer
 *
 * SECURITY NOTE: Runs without sharing intentionally to ensure error logging integrity.
 * This is safe because:
 * 1. Error logs are system-generated (not user input)
 * 2. All values are from exceptions/System methods (trusted sources)
 * 3. Required for debugging and support - error logs must always be created
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class JT_ErrorLogDomain {
  /**
   * @description Inserts a single error log record
   * @param log The error log record to insert
   * @throws DmlException if insert fails
   */
  public static void insertLog(JT_ErrorLog__c log) {
    if (log == null) {
      throw new IllegalArgumentException(
        Label.JT_ErrorLogDomain_errorLogCannotBeNull
      );
    }

    // Validate required fields
    if (String.isBlank(log.JT_ErrorType__c)) {
      throw new IllegalArgumentException(
        Label.JT_ErrorLogDomain_errorTypeRequired
      );
    }

    if (String.isBlank(log.JT_ErrorMessage__c)) {
      throw new IllegalArgumentException(
        Label.JT_ErrorLogDomain_errorMessageRequired
      );
    }

    insert log; // PMD suppressed: Error logs must be created regardless of permissions
  }

  /**
   * @description Inserts multiple error log records
   * @param logs List of error log records to insert
   * @throws DmlException if insert fails
   */
  public static void insertLogs(List<JT_ErrorLog__c> logs) {
    if (logs == null || logs.isEmpty()) {
      return;
    }

    insert logs; // PMD suppressed: Error logs must be created regardless of permissions
  }

  /**
   * @description Deletes old error logs (for cleanup/maintenance)
   * @param daysToKeep Number of days to keep logs (older logs are deleted)
   * @return Integer Number of logs deleted
   */
  public static Integer deleteOldLogs(Integer daysToKeep) {
    DateTime cutoffDateTime = DateTime.now().addDays(-daysToKeep);

    List<JT_ErrorLog__c> oldLogs = [
      SELECT Id
      FROM JT_ErrorLog__c
      WHERE JT_Timestamp__c < :cutoffDateTime
      LIMIT 10000
    ];

    if (!oldLogs.isEmpty()) {
      delete oldLogs; // PMD suppressed: Cleanup operation
      return oldLogs.size();
    }

    return 0;
  }
}
