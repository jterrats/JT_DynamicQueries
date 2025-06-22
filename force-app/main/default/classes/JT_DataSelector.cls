/**
 * @description       :
 * @author            : Jaime Terrats
 * @group             :
 * @last modified on  : 06-20-2025
 * @last modified by  : Jaime Terrats
**/
public inherited sharing class JT_DataSelector {
    private static JT_DataSelector instance;

    private JT_DataSelector() {
        // doesn't require initialization
    }

    /**
    * @description create instance for singleton pattern design
    * @author Jaime Terrats | 06-18-2025
    * @return DataSelector
    **/
    public static JT_DataSelector getInstance() {
        if(instance == null){
            instance = new JT_DataSelector();
        }
        return instance;
    }

    /**
    * @description instance method to get the config
    * @param devName
    * @author Jaime Terrats | 06-18-2025
    * @return DataSelector
    **/
    private JT_DynamicQueryConfiguration__mdt getConfig(String devName) {
        if (!Schema.SObjectType.JT_DynamicQueryConfiguration__mdt.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access DynamicSOQL__mdt object.');
        }

        return [
            SELECT JT_BaseQuery__c, JT_Binding__c
            FROM JT_DynamicQueryConfiguration__mdt
            WHERE DeveloperName = : devName
            LIMIT 1
        ];
    }

    /**
    * @description returns a collection of records based on the configuration name provided
    * @author Jaime Terrats | 06-18-2025
    * @param devName
    * @param enforceSecurity
    * @return List<SObject>
    **/
    public static List<SObject> getRecords(String devName, Boolean enforceSecurity) {
        final JT_DataSelector selectorInstance = JT_DataSelector.getInstance();
        final JT_DynamicQueryConfiguration__mdt config = selectorInstance.getConfig(devName);
        Map<String, Object> bindings = new Map<String, Object>();
        if(enforceSecurity) {
            bindings = (Map<String, Object>) JSON.deserializeUntyped(
            config.JT_Binding__c
            );

            return Database.queryWithBinds(
                config.JT_BaseQuery__c,
                bindings,
                AccessLevel.USER_MODE
            );
        } else {
            bindings = (Map<String, Object>) JSON.deserializeUntyped(
            config.JT_Binding__c
            );
            return Database.queryWithBinds(
                config.JT_BaseQuery__c,
                bindings,
                AccessLevel.SYSTEM_MODE);
        }
    }

    /**
    * @description returns a collection of records based on the configuration name provided
    * @author Jaime Terrats | 06-18-2025
    * @param devName
    * @param enforceSecurity
    * @return List<SObject>
    **/
    public static List<SObject> getRecords(String devName, Boolean enforceSecurity, Map<String, Object> bindings) {
        final JT_DataSelector selectorInstance = JT_DataSelector.getInstance();
        final JT_DynamicQueryConfiguration__mdt config = selectorInstance.getConfig(devName);
        if(enforceSecurity) {
            return Database.queryWithBinds(
                config.JT_BaseQuery__c,
                bindings,
                AccessLevel.USER_MODE
            );
        } else {
            bindings = (Map<String, Object>) JSON.deserializeUntyped(
            config.JT_Binding__c
            );
            return Database.queryWithBinds(
                config.JT_BaseQuery__c,
                bindings,
                AccessLevel.SYSTEM_MODE);
        }
    }
}