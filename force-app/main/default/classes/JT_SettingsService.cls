/**
 * @description Service class for settings management
 * Orchestrates business logic for Custom Settings and Audit Logs
 * Follows Service Layer pattern (business logic + orchestration)
 *
 * @author Jaime Terrats
 * @date 2025-12-11
 * @group Service Layer
 *
 * PMD: AvoidBooleanMethodParameters suppressed - enabled/disabled flags are self-documenting
 */
@SuppressWarnings('PMD.AvoidBooleanMethodParameters, PMD.ApexDoc')
public with sharing class JT_SettingsService {
  /**
   * @description Updates production editing setting with audit log
   * @param enabled Whether to enable production editing
   * @return Boolean Success status
   * @throws AuraHandledException if update fails
   */
  public static Boolean updateProductionEditingSetting(Boolean enabled) {
    // Verify user has appropriate permissions
    if (
      !Schema.sObjectType.JT_DynamicQuerySettings__c.isCreateable() ||
      !Schema.sObjectType.JT_DynamicQuerySettings__c.isUpdateable()
    ) {
      throw new AuraHandledException(
        Label.JT_SettingsService_insufficientPermissions
      );
    }

    JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();

    if (settings == null) {
      settings = new JT_DynamicQuerySettings__c();
    }

    settings.JT_AllowProductionEditing__c = enabled;
    upsert settings;

    // Create audit log entry
    String action = enabled
      ? Label.JT_SettingsService_productionEditingEnabled
      : Label.JT_SettingsService_productionEditingDisabled;

    createAuditLogSafe(action);

    return true;
  }

  /**
   * @description Updates usage tracking setting with audit log
   * @param enabled Whether to enable usage tracking
   * @return Boolean Success status
   * @throws AuraHandledException if update fails
   */
  public static Boolean updateUsageTrackingSetting(Boolean enabled) {
    // Verify permissions
    if (
      !Schema.sObjectType.JT_DynamicQuerySettings__c.isCreateable() ||
      !Schema.sObjectType.JT_DynamicQuerySettings__c.isUpdateable()
    ) {
      throw new AuraHandledException(
        Label.JT_SettingsService_insufficientPermissions
      );
    }

    JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();

    if (settings == null) {
      settings = new JT_DynamicQuerySettings__c();
      settings.SetupOwnerId = UserInfo.getUserId();
    }

    settings.JT_EnableUsageTracking__c = enabled;
    upsert settings;

    // Create audit log entry
    String action = enabled
      ? Label.JT_SettingsService_usageTrackingEnabled
      : Label.JT_SettingsService_usageTrackingDisabled;

    createAuditLogSafe(action);

    return true;
  }

  /**
   * @description Logs usage tracking search (for API limit awareness)
   * @param configName Configuration that was searched
   * @param resultCount Number of results found
   */
  public static void logUsageSearch(String configName, Integer resultCount) {
    String action =
      'Usage Search: ' +
      configName +
      ' (' +
      resultCount +
      ' results)';
    createAuditLogSafe(action);
  }

  /**
   * @description Creates an audit log entry (safe - catches exceptions)
   * @param action The action description to log
   */
  private static void createAuditLogSafe(String action) {
    try {
      // Get org info via System Selector (internal)
      Organization org = JT_SystemSelector.getOrganizationType();

      if (org == null) {
        return;
      }

      // Build audit log record
      JT_SettingsAuditLog__c log = new JT_SettingsAuditLog__c(
        JT_Action__c = action,
        JT_ChangedBy__c = UserInfo.getUserId(),
        JT_ChangedByUsername__c = UserInfo.getUserName(),
        JT_Timestamp__c = System.now(),
        JT_OrgType__c = org.OrganizationType
      );

      // Insert via Domain layer (without sharing)
      JT_AuditLogDomain.insertLog(log);
    } catch (Exception e) {
      // Don't fail the setting update if audit log fails
      // Audit logging is non-critical - settings update should succeed even if logging fails
      System.debug(
        LoggingLevel.WARN,
        'Audit log insertion failed: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Gets current production editing setting
   * @return Boolean Current setting value
   */
  public static Boolean getProductionEditingSetting() {
    try {
      JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();
      return settings != null && settings.JT_AllowProductionEditing__c == true;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Error getting production setting: ' + e.getMessage()
      );
      return false;
    }
  }

  /**
   * @description Gets usage tracking setting
   * @return Boolean Current setting value
   */
  public static Boolean getUsageTrackingSetting() {
    try {
      JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();
      return settings != null && settings.JT_EnableUsageTracking__c == true;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Error getting usage tracking setting: ' + e.getMessage()
      );
      return false;
    }
  }
}
