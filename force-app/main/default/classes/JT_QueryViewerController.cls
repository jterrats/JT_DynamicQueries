/**
 * @description Controller for the Query Viewer LWC
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 11-28-2025
 * @last modified by Jaime Terrats
**/
public with sharing class JT_QueryViewerController {

    /**
    * @description Retrieves all available query configurations
    * @author Jaime Terrats | 11-28-2025
    * @return List<ConfigurationOption>
    **/
    @AuraEnabled(cacheable=true)
    public static List<ConfigurationOption> getConfigurations() {
        try {
            List<JT_DynamicQueryConfiguration__mdt> configs = [
                SELECT Id, DeveloperName, Label, JT_BaseQuery__c, JT_Binding__c, JT_ObjectName__c
                FROM JT_DynamicQueryConfiguration__mdt
                WITH USER_MODE
                ORDER BY Label ASC
                LIMIT 200
            ];

            List<ConfigurationOption> options = new List<ConfigurationOption>();
            for (JT_DynamicQueryConfiguration__mdt config : configs) {
                ConfigurationOption opt = new ConfigurationOption();
                opt.label = config.Label;
                opt.value = config.DeveloperName;
                opt.baseQuery = config.JT_BaseQuery__c;
                opt.bindings = config.JT_Binding__c;
                opt.objectName = config.JT_ObjectName__c;
                options.add(opt);
            }

            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving configurations: ' + e.getMessage());
        }
    }

    /**
    * @description Executes a query based on configuration and bindings
    * @author Jaime Terrats | 11-28-2025
    * @param devName Configuration developer name
    * @param bindingsJson JSON string with bindings
    * @param runAsUserId Optional User ID to validate permissions context
    * @return QueryResult
    **/
    @AuraEnabled
    public static QueryResult executeQuery(String devName, String bindingsJson, String runAsUserId) {
        try {
            // Validate Run As User feature
            if (String.isNotBlank(runAsUserId)) {
                validateRunAsPermission(runAsUserId);
            }

            Map<String, Object> bindings = String.isNotBlank(bindingsJson)
                ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
                : new Map<String, Object>();

            List<SObject> records = JT_DataSelector.getRecords(devName, true, bindings);

            QueryResult result = new QueryResult();
            result.records = records;
            result.recordCount = records.size();
            result.success = true;
            result.runAsUserName = String.isNotBlank(runAsUserId) ? getUserName(runAsUserId) : null;

            // Extract field names from first record if available
            if (!records.isEmpty()) {
                result.fields = getFieldNames(records[0]);
            }

            return result;
        } catch (Exception e) {
            QueryResult result = new QueryResult();
            result.success = false;
            result.errorMessage = e.getMessage();
            result.records = new List<SObject>();
            result.recordCount = 0;
            return result;
        }
    }

    /**
    * @description Extracts field names from an SObject record
    * @author Jaime Terrats | 11-28-2025
    * @param record SObject record
    * @return List<String> Field names
    **/
    private static List<String> getFieldNames(SObject record) {
        Map<String, Object> fieldMap = record.getPopulatedFieldsAsMap();
        List<String> fields = new List<String>(fieldMap.keySet());
        fields.sort();
        return fields;
    }

    /**
    * @description Extracts parameter names from a SOQL query
    * @author Jaime Terrats | 11-28-2025
    * @param query SOQL query string
    * @return List<String> Parameter names
    **/
    @AuraEnabled(cacheable=true)
    public static List<String> extractParameters(String query) {
        try {
            Set<String> params = new Set<String>();
            if (String.isBlank(query)) {
                return new List<String>();
            }

            // Normalize query: remove extra spaces around : for consistent parsing
            // Handles = :, =:, = : , etc.
            String normalizedQuery = query.replaceAll('\\s*:\\s*', ':');

            // Match patterns like :paramName (bind variables)
            // After normalization, all bind variables will be in format :paramName
            Pattern bindPattern = Pattern.compile(':([a-zA-Z_][a-zA-Z0-9_]*)');
            Matcher matcher = bindPattern.matcher(normalizedQuery);

            while (matcher.find()) {
                params.add(matcher.group(1));
            }

            List<String> paramList = new List<String>(params);
            paramList.sort();
            return paramList;
        } catch (Exception e) {
            throw new AuraHandledException('Error extracting parameters: ' + e.getMessage());
        }
    }

    /**
    * @description Checks if current user can use Run As feature
    * @author Jaime Terrats | 11-28-2025
    * @return Boolean True if user can use Run As
    **/
    @AuraEnabled(cacheable=true)
    public static Boolean canUseRunAs() {
        try {
            // Check if user has Modify All Data or View All Data permission
            List<PermissionSetAssignment> assignments = [
                SELECT PermissionSet.PermissionsModifyAllData, PermissionSet.PermissionsViewAllData
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId()
                AND (PermissionSet.PermissionsModifyAllData = true
                     OR PermissionSet.PermissionsViewAllData = true)
                WITH USER_MODE
                LIMIT 1
            ];

            return !assignments.isEmpty() || isSystemAdmin();
        } catch (Exception e) {
            return false;
        }
    }

    /**
    * @description Checks if current user is a System Administrator
    * @author Jaime Terrats | 11-28-2025
    * @return Boolean True if user is admin
    **/
    private static Boolean isSystemAdmin() {
        try {
            Profile userProfile = [
                SELECT Name
                FROM Profile
                WHERE Id = :UserInfo.getProfileId()
                WITH USER_MODE
                LIMIT 1
            ];
            return userProfile.Name.contains('System Administrator');
        } catch (Exception e) {
            return false;
        }
    }

    /**
    * @description Gets ALL active users (excludes current user) for dropdown with client-side filtering
    * @author Jaime Terrats | 11-29-2025
    * @return List<UserOption> List of user options
    **/
    @AuraEnabled(cacheable=true)
    public static List<UserOption> getAllActiveUsers() {
        try {
            if (!canUseRunAs()) {
                throw new AuraHandledException('Insufficient permissions to use Run As feature.');
            }

            Id currentUserId = UserInfo.getUserId();

            // Get ALL active users (excluding current) - client-side filtering in LWC
            List<User> users = [
                SELECT Id, Name, Username, Email, Profile.Name
                FROM User
                WHERE IsActive = true
                AND Id != :currentUserId
                WITH USER_MODE
                ORDER BY Name ASC
                LIMIT 200
            ];

            List<UserOption> options = new List<UserOption>();
            for (User u : users) {
                UserOption opt = new UserOption();
                opt.value = u.Id;
                opt.label = u.Name + ' (' + u.Profile.Name + ')';
                opt.username = u.Username;
                opt.email = u.Email;
                opt.profileName = u.Profile.Name;
                options.add(opt);
            }

            return options;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading users: ' + e.getMessage());
        }
    }

    /**
    * @description Validates Run As permission and user access
    * @author Jaime Terrats | 11-28-2025
    * @param userId User ID to validate
    **/
    private static void validateRunAsPermission(String userId) {
        if (!canUseRunAs()) {
            throw new AuraHandledException('You do not have permission to use the Run As feature.');
        }

        // Verify user exists and is active
        List<User> users = [
            SELECT Id, IsActive, Name
            FROM User
            WHERE Id = :userId
            WITH USER_MODE
            LIMIT 1
        ];

        if (users.isEmpty()) {
            throw new AuraHandledException('Selected user not found.');
        }

        if (!users[0].IsActive) {
            throw new AuraHandledException('Cannot run as inactive user: ' + users[0].Name);
        }
    }

    /**
    * @description Gets user name by ID
    * @author Jaime Terrats | 11-28-2025
    * @param userId User ID
    * @return String User name
    **/
    private static String getUserName(String userId) {
        try {
            User u = [SELECT Name FROM User WHERE Id = :userId WITH USER_MODE LIMIT 1];
            return u.Name;
        } catch (Exception e) {
            return null;
        }
    }

    /**
    * @description Wrapper class for configuration options
    **/
    public class ConfigurationOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String baseQuery;
        @AuraEnabled public String bindings;
        @AuraEnabled public String objectName;
    }

    /**
    * @description Wrapper class for query results
    **/
    public class QueryResult {
        @AuraEnabled public List<SObject> records;
        @AuraEnabled public Integer recordCount;
        @AuraEnabled public List<String> fields;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String runAsUserName;
    }

    /**
    * @description Wrapper class for user options
    **/
    public class UserOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String username;
        @AuraEnabled public String profileName;
        @AuraEnabled public String email;
    }
}

