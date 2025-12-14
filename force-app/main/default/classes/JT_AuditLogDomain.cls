/**
 * @description Domain class for JT_SettingsAuditLog__c
 * Handles all DML operations for audit logs
 * Follows Domain Layer pattern (DML operations only)
 *
 * @author Jaime Terrats
 * @date 2025-12-02
 * @group Domain Layer
 *
 * SECURITY NOTE: Runs without sharing intentionally to ensure audit trail integrity.
 * This is safe because:
 * 1. Audit logs are system-generated (not user input)
 * 2. All values are from UserInfo/System methods (trusted sources)
 * 3. Required for compliance - audit logs must always be created
 */
@SuppressWarnings(
  'PMD.ApexCRUDViolation, PMD.AvoidDebugStatements, PMD.DebugsShouldUseLoggingLevel'
)
public without sharing class JT_AuditLogDomain {
  /**
   * @description Inserts a single audit log record
   * @param log The audit log record to insert
   * @throws DmlException if insert fails
   */
  public static void insertLog(JT_SettingsAuditLog__c log) {
    if (log == null) {
      throw new IllegalArgumentException(
        Label.JT_AuditLogDomain_auditLogCannotBeNull
      );
    }

    // Validate required fields
    if (String.isBlank(log.JT_Action__c)) {
      throw new IllegalArgumentException(
        Label.JT_AuditLogDomain_actionRequired
      );
    }

    try {
      insert log; // PMD suppressed: Audit logs must be created regardless of permissions
    } catch (DmlException e) {
      throw e; // Re-throw to let caller handle
    }
  }

  /**
   * @description Inserts multiple audit log records
   * @param logs List of audit log records to insert
   * @throws DmlException if insert fails
   */
  public static void insertLogs(List<JT_SettingsAuditLog__c> logs) {
    if (logs == null || logs.isEmpty()) {
      return;
    }

    try {
      insert logs; // PMD suppressed: Audit logs must be created regardless of permissions
    } catch (DmlException e) {
      throw e;
    }
  }

  /**
   * @description Deletes old audit logs (for cleanup/maintenance)
   * @param daysToKeep Number of days to keep logs (older logs are deleted)
   * @return Integer Number of logs deleted
   */
  public static Integer deleteOldLogs(Integer daysToKeep) {
    DateTime cutoffDateTime = DateTime.now().addDays(-daysToKeep);

    // Use System Selector for internal query
    List<JT_SettingsAuditLog__c> oldLogs = JT_SystemSelector.getAuditLogsOlderThan(
      cutoffDateTime
    );

    if (!oldLogs.isEmpty()) {
      delete oldLogs; // PMD suppressed: Cleanup operation
      return oldLogs.size();
    }

    return 0;
  }
}
