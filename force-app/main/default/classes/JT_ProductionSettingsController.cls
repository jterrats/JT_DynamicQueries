/**
 * @description Controller for managing production editing settings
 * @author Jaime Terrats
 * @date 11-30-2025
 */
public with sharing class JT_ProductionSettingsController {
  /**
   * @description Inner class to handle audit log creation without sharing restrictions
   * Allows system to insert audit logs regardless of user permissions
   * SECURITY NOTE: Runs without sharing intentionally to ensure audit trail integrity.
   * This is safe because:
   * 1. Audit logs are system-generated (not user input)
   * 2. All values are from UserInfo/System methods (trusted sources)
   * 3. Required for compliance - audit logs must always be created
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  private without sharing class AuditLogCreator {
    /**
     * @description Inserts an audit log record
     * @param log The audit log record to insert
     */
    public void insertLog(JT_SettingsAuditLog__c log) {
      insert log; // PMD suppressed: Audit logs must be created regardless of user permissions
    }
  }

  /**
   * @description Gets current production editing setting
   * @return Boolean Current setting value
   */
  @AuraEnabled(cacheable=true)
  public static Boolean getProductionEditingSetting() {
    try {
      JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();
      return settings != null && settings.JT_AllowProductionEditing__c == true;
    } catch (Exception e) {
      return false;
    }
  }

  /**
   * @description Updates production editing setting
   * @param enabled Whether to enable production editing
   * @return Boolean Success status
   * SECURITY NOTE: Custom Settings are upserted with sharing context (user must have modify all data or similar).
   * This is safe because only privileged users can call this method.
   */
  @AuraEnabled
  @SuppressWarnings('PMD.ApexCRUDViolation')
  public static Boolean updateProductionEditingSetting(Boolean enabled) {
    try {
      // Verify user has appropriate permissions (Custom Settings require system admin or similar)
      if (
        !Schema.sObjectType.JT_DynamicQuerySettings__c.isCreateable() ||
        !Schema.sObjectType.JT_DynamicQuerySettings__c.isUpdateable()
      ) {
        throw new AuraHandledException(
          'Insufficient permissions to modify settings'
        );
      }

      JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();

      if (settings == null) {
        settings = new JT_DynamicQuerySettings__c();
      }

      settings.JT_AllowProductionEditing__c = enabled;
      upsert settings; // PMD suppressed: Permissions verified above

      // Create audit log entry
      createAuditLog(enabled);

      return true;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error updating settings: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Creates an audit log entry for setting changes
   * Uses without sharing inner class to ensure audit logs are always created
   * @param enabled Whether production editing was enabled or disabled
   * SECURITY NOTE: Organization query uses WITH SECURITY_ENFORCED.
   * Audit log insertion uses without sharing to ensure compliance.
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static void createAuditLog(Boolean enabled) {
    String action = enabled ? 'Enabled' : 'Disabled';
    createAuditLog(action);
  }

  /**
   * @description Creates an audit log entry with custom action message
   * Uses without sharing inner class to ensure audit logs are always created
   * @param action The action description to log
   * SECURITY NOTE: Organization query uses WITH SECURITY_ENFORCED.
   * Audit log insertion uses without sharing to ensure compliance.
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static void createAuditLog(String action) {
    try {
      Organization org = [
        SELECT OrganizationType
        FROM Organization
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];

      JT_SettingsAuditLog__c log = new JT_SettingsAuditLog__c(
        JT_Action__c = action,
        JT_ChangedBy__c = UserInfo.getUserId(),
        JT_ChangedByUsername__c = UserInfo.getUserName(),
        JT_Timestamp__c = System.now(),
        JT_OrgType__c = org.OrganizationType
      );

      // Use without sharing to ensure audit log is created
      AuditLogCreator creator = new AuditLogCreator();
      creator.insertLog(log);
    } catch (Exception e) {
      // Don't fail the setting update if audit log fails
      System.debug(
        LoggingLevel.ERROR,
        'Failed to create audit log: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Gets usage tracking setting (Where is this used?)
   * @return Boolean Current setting value
   */
  @AuraEnabled(cacheable=true)
  public static Boolean getUsageTrackingSetting() {
    try {
      JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();
      return settings != null && settings.JT_EnableUsageTracking__c == true;
    } catch (Exception e) {
      return false;
    }
  }

  /**
   * @description Updates usage tracking setting with audit log
   * @param enabled Whether to enable usage tracking
   * @return Boolean Success status
   */
  @AuraEnabled
  public static Boolean updateUsageTrackingSetting(Boolean enabled) {
    try {
      if (
        !Schema.sObjectType.JT_DynamicQuerySettings__c.isCreateable() ||
        !Schema.sObjectType.JT_DynamicQuerySettings__c.isUpdateable()
      ) {
        throw new AuraHandledException(
          'Insufficient permissions to modify settings'
        );
      }

      JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();

      if (settings == null) {
        settings = new JT_DynamicQuerySettings__c();
        settings.SetupOwnerId = UserInfo.getUserId();
      }

      settings.JT_EnableUsageTracking__c = enabled;
      upsert settings;

      createAuditLog(
        enabled ? 'Usage Tracking Enabled' : 'Usage Tracking Disabled'
      );

      return true;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Failed to update setting: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Logs usage tracking search (for API limit awareness)
   * @param configName Configuration that was searched
   * @param resultCount Number of results found
   */
  @AuraEnabled
  public static void logUsageSearch(String configName, Integer resultCount) {
    try {
      String action =
        'Usage Search: ' +
        configName +
        ' (' +
        resultCount +
        ' results)';
      createAuditLog(action);
    } catch (Exception e) {
      // Don't fail if logging fails
      System.debug(
        LoggingLevel.ERROR,
        'Failed to log usage search: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Checks if current org is Starter/Free Edition (should show override option)
   * @return Boolean True if Starter/Free Edition
   */
  @AuraEnabled(cacheable=true)
  public static Boolean isStarterOrFreeEdition() {
    try {
      Organization org = [
        SELECT OrganizationType, IsSandbox, TrialExpirationDate
        FROM Organization
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];

      // Don't show override for dev/test orgs (already have access)
      if (
        org.IsSandbox ||
        org.TrialExpirationDate != null ||
        org.OrganizationType == 'Developer Edition'
      ) {
        return false;
      }

      // Show override for Starter/Free (small production orgs without sandbox)
      String orgType = org.OrganizationType.toLowerCase();
      return orgType.contains('starter') || orgType.contains('free');
    } catch (Exception e) {
      return false;
    }
  }
}
