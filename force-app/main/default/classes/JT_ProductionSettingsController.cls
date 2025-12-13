/**
 * @description Thin controller layer for settings management
 * Delegates all business logic to JT_SettingsService
 * Follows Controller pattern (thin @AuraEnabled layer only)
 *
 * @author Jaime Terrats
 * @date 2025-12-11
 * @refactored 2025-12-02 - Extracted to Service Layer
 *
 * PMD: AvoidBooleanMethodParameters suppressed - enabled/disabled flags are self-documenting
 */
@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
public with sharing class JT_ProductionSettingsController {
  /**
   * @description Gets current production editing setting
   * @return Boolean Current setting value
   */
  @AuraEnabled(cacheable=true)
  public static Boolean getProductionEditingSetting() {
    return JT_SettingsService.getProductionEditingSetting();
  }

  /**
   * @description Updates production editing setting
   * @param enabled Whether to enable production editing
   * @return Boolean Success status
   */
  @AuraEnabled
  public static Boolean updateProductionEditingSetting(Boolean enabled) {
    try {
      return JT_SettingsService.updateProductionEditingSetting(enabled);
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error updating settings: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Gets usage tracking setting (Where is this used?)
   * @return Boolean Current setting value
   */
  @AuraEnabled(cacheable=true)
  public static Boolean getUsageTrackingSetting() {
    return JT_SettingsService.getUsageTrackingSetting();
  }

  /**
   * @description Updates usage tracking setting with audit log
   * @param enabled Whether to enable usage tracking
   * @return Boolean Success status
   */
  @AuraEnabled
  public static Boolean updateUsageTrackingSetting(Boolean enabled) {
    try {
      return JT_SettingsService.updateUsageTrackingSetting(enabled);
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
    JT_SettingsService.logUsageSearch(configName, resultCount);
  }

  /**
   * @description Checks if current org is Starter/Free Edition (should show override option)
   * @return Boolean True if Starter/Free Edition
   */
  @AuraEnabled(cacheable=true)
  public static Boolean isStarterOrFreeEdition() {
    try {
      // Use System Selector for internal query
      Organization org = JT_SystemSelector.getOrganizationInfo();

      if (org == null) {
        return false;
      }

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