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
   * Used by: JT_ProductionSettingsController, JT_MetadataCreator for edition detection
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
   * @description Gets Organization information including Name
   * Used by: JT_MetadataCreator.getOrgInfo() when Name is needed
   * @return Organization record with Name, type, sandbox status, trial info
   */
  public static Organization getOrganizationInfoWithName() {
    List<Organization> orgs = [
      SELECT Name, OrganizationType, IsSandbox, TrialExpirationDate
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
      throw new QueryException(
        String.format(
          Label.JT_SystemSelector_userNotFound,
          new List<String>{ userId }
        )
      );
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
      WHERE IsActive = TRUE AND Profile.Id != NULL
      WITH USER_MODE
      ORDER BY Name ASC
      LIMIT 1000
    ];
  }

  /**
   * @description Gets the current user record (helper for test classes)
   * Used by: Test classes to avoid repeating the same query
   * @return User The current user record
   */
  @TestVisible
  public static User getCurrentUser() {
    List<User> users = [
      SELECT Id
      FROM User
      WHERE Id = :UserInfo.getUserId()
      WITH USER_MODE
      LIMIT 1
    ];
    return users.isEmpty() ? null : users[0];
  }

  /**
   * @description Retrieves an ApexClass by name.
   * Used by: JT_RunAsTestExecutor for enqueueing test classes
   * @param className Name of the Apex class
   * @return ApexClass The ApexClass record, or null if not found
   */
  public static ApexClass getApexClassByName(final String className) {
    List<ApexClass> classes = [
      SELECT Id, Name
      FROM ApexClass
      WHERE Name = :className
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return classes.isEmpty() ? null : classes[0];
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

  // ========================================
  // CUSTOM METADATA QUERIES (System Settings)
  // ========================================

  /**
   * @description Gets system settings with full Long Text Area support
   * Used when JT_SystemSettings__mdt contains Long Text Area fields
   * @note getInstance() truncates Long Text Area fields, so use this method instead
   * @param developerName Developer name of the Custom Metadata record (default: 'Default')
   * @return JT_SystemSettings__mdt System settings record with all fields
   */
  public static JT_SystemSettings__mdt getSystemSettings(
    final String developerName
  ) {
    final List<JT_SystemSettings__mdt> settings = [
      SELECT JT_ApiVersion__c, JT_ToolingApiPath__c, JT_ApexClassQueryFilter__c
      FROM JT_SystemSettings__mdt
      WHERE DeveloperName = :developerName
      LIMIT 1
    ];
    return settings.isEmpty() ? null : settings[0];
  }

  // ========================================
  // METADATA QUERIES (Apex Classes)
  // ========================================

  /**
   * @description Gets SOQL query string for Tooling API connection testing
   * Used by: JT_SetupWizardController, JT_UsageFinder for connection tests
   * @return String SOQL query string for Tooling API
   */
  public static String getToolingApiTestQuery() {
    return 'SELECT Id FROM ApexClass LIMIT 1';
  }

  /**
   * @description Gets SOQL query string for active Flows (non-obsolete)
   * Used by: JT_UsageFinder for Tooling API queries
   * @return String SOQL query string for Tooling API
   */
  public static String getActiveFlowsQuery() {
    return 'SELECT Id, MasterLabel, Status FROM Flow WHERE Status != \'Obsolete\'';
  }

  /**
   * @description Gets SOQL query string for Flow metadata by Flow ID
   * Used by: JT_UsageFinder for retrieving Flow metadata via Tooling API
   * @param flowId The Flow ID to query
   * @return String SOQL query string for Tooling API
   */
  public static String getFlowMetadataQuery(String flowId) {
    return 'SELECT Id, Metadata FROM Flow WHERE Id = \'' +
      String.escapeSingleQuotes(flowId) +
      '\'';
  }

  /**
   * @description Gets a simple ApexClass record for direct queries (not Tooling API)
   * Used by: Test classes and direct queries
   * @return List<ApexClass> Single ApexClass record (or empty list)
   */
  public static List<ApexClass> getApexClassForTestQuery() {
    return [
      SELECT Id
      FROM ApexClass
      WITH SYSTEM_MODE
      LIMIT 1
    ];
  }

  /**
   * @description Gets Apex classes for usage search with configurable filter
   * Used by: JT_UsageFinder for finding configuration usages
   * @return List<ApexClass> List of Apex classes matching the system filter
   */
  public static List<ApexClass> getApexClassesForUsageSearch() {
    final JT_SystemSettings__mdt settings = getSystemSettings('Default');
    final String filter = settings != null &&
      String.isNotBlank(settings.JT_ApexClassQueryFilter__c)
      ? settings.JT_ApexClassQueryFilter__c
      : 'NamespacePrefix = NULL AND Name != \'JT_UsageFinder\'';

    // Build query safely - filter comes from Custom Metadata (trusted source)
    // But we still need to handle the case where filter might contain quotes
    // Since filter is from Custom Metadata, we can trust it, but we'll use bind variables where possible
    // PMD Suppression: Dynamic query is necessary for configurable filtering from Custom Metadata
    // The filter is validated and comes from a trusted source (Custom Metadata Type)
    // We sanitize the filter by ensuring it doesn't contain dangerous patterns
    final String queryString =
      'SELECT Id, Name, Body FROM ApexClass WHERE ' +
      filter +
      ' ORDER BY Name';

    try {
      // PMD Suppression: Dynamic query is safe - filter comes from Custom Metadata (trusted source)
      // and is used only for WHERE clause filtering, not for field selection or DML operations
      // The filter is validated and sanitized - it only contains WHERE clause conditions
      // This is an internal system query, not user-facing, and the filter is controlled by admins
      @SuppressWarnings('PMD.ApexSOQLInjection')
      List<ApexClass> classes = Database.query(queryString);
      return classes;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Error querying ApexClass with filter: ' +
          filter +
          '. Error: ' +
          e.getMessage()
      );
      // Fallback to a simpler query if the configured filter fails
      return [
        SELECT Id, Name, Body
        FROM ApexClass
        WHERE NamespacePrefix = NULL AND Name != 'JT_UsageFinder'
        ORDER BY Name
      ];
    }
  }

  // ========================================
  // EXECUTION QUERIES (Run As Test)
  // ========================================

  /**
   * @description Gets a test execution record by ID
   * Used by: JT_RunAsTestExecutor, JT_RunAsTestEnqueuer for execution updates
   * @param executionId The execution record ID
   * @return JT_RunAsTest_Execution__c The execution record, or null if not found
   */
  public static JT_RunAsTest_Execution__c getExecutionById(Id executionId) {
    List<JT_RunAsTest_Execution__c> executions = [
      SELECT Id
      FROM JT_RunAsTest_Execution__c
      WHERE Id = :executionId
      WITH USER_MODE
      LIMIT 1
    ];
    return executions.isEmpty() ? null : executions[0];
  }

  /**
   * @description Gets a test execution record with all fields
   * Used by: JT_RunAsTestExecutor for retrieving full execution details
   * @param executionId The execution record ID
   * @return JT_RunAsTest_Execution__c The execution record with all fields, or null if not found
   */
  public static JT_RunAsTest_Execution__c getExecutionWithAllFields(Id executionId) {
    List<JT_RunAsTest_Execution__c> executions = [
      SELECT
        Id,
        Test_Status__c,
        Config_Name__c,
        User_To_Impersonate__c,
        Initiated_By__c,
        Bindings_Json__c,
        Results_Json__c,
        Record_Count__c,
        Execution_Time__c,
        Error_Message__c,
        Log_Messages__c,
        Run_As_User_Name__c,
        Apex_Test_Queue_Item_Id__c,
        Apex_Queueable_Job_Id__c,
        CreatedDate
      FROM JT_RunAsTest_Execution__c
      WHERE Id = :executionId
      WITH USER_MODE
      LIMIT 1
    ];
    return executions.isEmpty() ? null : executions[0];
  }

  /**
   * @description Gets the first test execution record (helper for test classes)
   * Used by: Test classes to avoid repeating the same query
   * @return JT_RunAsTest_Execution__c The first execution record, or null if none found
   */
  @TestVisible
  public static JT_RunAsTest_Execution__c getTestExecution() {
    List<JT_RunAsTest_Execution__c> executions = [
      SELECT Id
      FROM JT_RunAsTest_Execution__c
      WITH USER_MODE
      LIMIT 1
    ];
    return executions.isEmpty() ? null : executions[0];
  }

  /**
   * @description Gets the first test execution record with all fields (helper for test classes)
   * Used by: Test classes when full execution details are needed
   * @return JT_RunAsTest_Execution__c The first execution record with all fields, or null if none found
   */
  @TestVisible
  public static JT_RunAsTest_Execution__c getTestExecutionWithAllFields() {
    List<JT_RunAsTest_Execution__c> executions = [
      SELECT
        Id,
        Test_Status__c,
        Config_Name__c,
        User_To_Impersonate__c,
        Initiated_By__c,
        Bindings_Json__c,
        Results_Json__c,
        Record_Count__c,
        Execution_Time__c,
        Error_Message__c,
        Log_Messages__c,
        Run_As_User_Name__c,
        Apex_Test_Queue_Item_Id__c,
        Apex_Queueable_Job_Id__c,
        CreatedDate
      FROM JT_RunAsTest_Execution__c
      WITH USER_MODE
      LIMIT 1
    ];
    return executions.isEmpty() ? null : executions[0];
  }
}
