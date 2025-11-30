/**
 * @description Controller for managing production editing settings
 * @author Jaime Terrats
 * @date 11-30-2025
 */
public with sharing class JT_ProductionSettingsController {

    /**
     * @description Inner class to handle audit log creation without sharing restrictions
     * Allows system to insert audit logs regardless of user permissions
     */
    private without sharing class AuditLogCreator {
        /**
         * @description Inserts an audit log record
         * @param log The audit log record to insert
         */
        public void insertLog(JT_SettingsAuditLog__c log) {
            insert log;
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
     */
    @AuraEnabled
    public static Boolean updateProductionEditingSetting(Boolean enabled) {
        try {
            JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();

            if (settings == null) {
                settings = new JT_DynamicQuerySettings__c();
            }

            settings.JT_AllowProductionEditing__c = enabled;
            upsert settings;

            // Create audit log entry
            createAuditLog(enabled);

            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating settings: ' + e.getMessage());
        }
    }

    /**
     * @description Creates an audit log entry for setting changes
     * Uses without sharing inner class to ensure audit logs are always created
     * @param enabled Whether production editing was enabled or disabled
     */
    private static void createAuditLog(Boolean enabled) {
        try {
            Organization org = [SELECT OrganizationType FROM Organization LIMIT 1];

            JT_SettingsAuditLog__c log = new JT_SettingsAuditLog__c(
                JT_Action__c = enabled ? 'Enabled' : 'Disabled',
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
            System.debug('Failed to create audit log: ' + e.getMessage());
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
            if (org.IsSandbox || org.TrialExpirationDate != null || org.OrganizationType == 'Developer Edition') {
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
