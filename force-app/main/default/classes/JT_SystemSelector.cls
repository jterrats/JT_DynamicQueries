/**
 * @description System Selector - Internal queries for framework infrastructure
 *
 * ⚠️ INTERNAL USE ONLY - NOT FOR END USER CONSUMPTION
 *
 * This class provides hardcoded queries for system objects (Organization, Audit Logs)
 * that are required by the framework's internal operations.
 *
 * Unlike JT_DataSelector (which handles configurable queries via Custom Metadata),
 * this class contains static SOQL queries for infrastructure needs.
 *
 * NOTE: This class is intentionally NOT included in the Permission Set.
 * Only the framework's internal components (Service, Domain layers) should use it.
 *
 * SECURITY NOTE: Runs without sharing intentionally to ensure system queries always work.
 * This is safe because:
 * 1. Not exposed to users (no @AuraEnabled methods)
 * 2. Only queries system objects (Organization, internal Audit Logs)
 * 3. Called by trusted internal components (Service/Domain layers)
 * 4. Required for framework reliability (must work regardless of user permissions)
 *
 * @author Jaime Terrats
 * @date 2025-12-02
 * @group Selector Layer (Internal)
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class JT_SystemSelector {
  // ========================================
  // ORGANIZATION QUERIES
  // ========================================

  /**
   * @description Gets Organization information with security enforced
   * Used by: JT_ProductionSettingsController for edition detection
   * @return Organization record with type, sandbox status, trial info
   */
  public static Organization getOrganizationInfo() {
    List<Organization> orgs = [
      SELECT OrganizationType, IsSandbox, TrialExpirationDate
      FROM Organization
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    return orgs.isEmpty() ? null : orgs[0];
  }

  /**
   * @description Gets Organization type only (for audit logs)
   * Used by: JT_SettingsService for audit log creation
   * @return Organization record with type only
   */
  public static Organization getOrganizationType() {
    List<Organization> orgs = [
      SELECT OrganizationType
      FROM Organization
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
    return orgs.isEmpty() ? null : orgs[0];
  }

  // ========================================
  // AUDIT LOG QUERIES
  // ========================================

  /**
   * @description Gets audit logs older than specified DateTime
   * Used by: JT_AuditLogDomain for cleanup operations
   * @param cutoffDateTime DateTime threshold (logs older than this will be returned)
   * @return List of audit logs to be deleted
   */
  public static List<JT_SettingsAuditLog__c> getAuditLogsOlderThan(
    DateTime cutoffDateTime
  ) {
    // PMD suppressed: Cleanup operation requires direct query
    return [
      SELECT Id
      FROM JT_SettingsAuditLog__c
      WHERE JT_Timestamp__c < :cutoffDateTime
      LIMIT 10000
    ];
  }

  /**
   * @description Gets audit logs by action pattern (for testing/verification)
   * Used by: Test classes for validation
   * @param actionPattern Action pattern to match (supports LIKE)
   * @return List of matching audit logs
   */
  @TestVisible
  private static List<JT_SettingsAuditLog__c> getAuditLogsByAction(
    String actionPattern
  ) {
    String likePattern = '%' + actionPattern + '%';
    // PMD suppressed: Test/verification query
    return [
      SELECT Id, JT_Action__c, JT_Timestamp__c, JT_ChangedByUsername__c
      FROM JT_SettingsAuditLog__c
      WHERE JT_Action__c LIKE :likePattern
      WITH USER_MODE
      LIMIT 1000
    ];
  }
}
