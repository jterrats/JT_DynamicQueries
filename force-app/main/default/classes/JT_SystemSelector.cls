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

  // ========================================
  // USER & PROFILE QUERIES (Added 2025-12-02)
  // ========================================

  /**
   * @description Retrieves a user by ID.
   * Used by: JT_QueryViewerController for Run As feature
   * @param userId The User ID to retrieve.
   * @return User The User record.
   * @throws QueryException if user not found.
   */
  public static User getUserById(Id userId) {
    List<User> users = [
      SELECT Id, Name, Email, Username, IsActive
      FROM User
      WHERE Id = :userId
      WITH USER_MODE
      LIMIT 1
    ];

    if (users.isEmpty()) {
      throw new QueryException('User not found: ' + userId);
    }

    return users[0];
  }

  /**
   * @description Retrieves all active users.
   * Used by: JT_QueryViewerController for Run As user selection
   * @return List<User> List of active users sorted by name.
   */
  public static List<User> getAllActiveUsers() {
    return [
      SELECT Id, Name, Email, Username, Profile.Name
      FROM User
      WHERE IsActive = TRUE
      WITH USER_MODE
      ORDER BY Name ASC
      LIMIT 1000
    ];
  }

  /**
   * @description Retrieves the current user's profile.
   * Used by: JT_QueryViewerController for permission checks
   * @return Profile The current user's Profile record.
   */
  public static Profile getUserProfile() {
    List<Profile> profiles = [
      SELECT Id, Name
      FROM Profile
      WHERE Id = :UserInfo.getProfileId()
      WITH USER_MODE
      LIMIT 1
    ];
    return profiles.isEmpty() ? null : profiles[0];
  }

  /**
   * @description Retrieves permission set assignments for a user.
   * Used by: JT_QueryViewerController for Run As permission checks
   * @param userId The User ID to retrieve assignments for.
   * @return List<PermissionSetAssignment> List of permission set assignments.
   */
  public static List<PermissionSetAssignment> getPermissionSetAssignments(
    Id userId
  ) {
    return [
      SELECT
        Id,
        PermissionSetId,
        PermissionSet.Name,
        PermissionSet.PermissionsModifyAllData,
        PermissionSet.PermissionsViewAllData
      FROM PermissionSetAssignment
      WHERE AssigneeId = :userId
      WITH USER_MODE
    ];
  }

  /**
   * @description Checks if a user has Modify All Data or View All Data permissions.
   * Used by: JT_QueryViewerController.canUseRunAs()
   * @param userId The User ID to check permissions for.
   * @return Boolean True if user has elevated permissions.
   */
  public static Boolean hasElevatedPermissions(Id userId) {
    List<PermissionSetAssignment> assignments = [
      SELECT
        PermissionSet.PermissionsModifyAllData,
        PermissionSet.PermissionsViewAllData
      FROM PermissionSetAssignment
      WHERE
        AssigneeId = :userId
        AND (PermissionSet.PermissionsModifyAllData = TRUE
        OR PermissionSet.PermissionsViewAllData = TRUE)
      WITH USER_MODE
      LIMIT 1
    ];

    return !assignments.isEmpty();
  }
}
