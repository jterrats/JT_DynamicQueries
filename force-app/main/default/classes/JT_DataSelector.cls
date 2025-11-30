/**
 * @description       :
 * @author            : Jaime Terrats
 * @group             :
 * @last modified on  : 11-28-2025
 * @last modified by  : Jaime Terrats
**/
public inherited sharing class JT_DataSelector {
    /** Cache to store configurations and avoid repeated queries */
    private static Map<String, JT_DynamicQueryConfiguration__mdt> configCache = new Map<String, JT_DynamicQueryConfiguration__mdt>();

    /** used to validate if there's already an instance of the class */
    private static JT_DataSelector instance;

    @SuppressWarnings('PMD.EmptyStatementBlock')
    /**
    * @description class consturctor
    * @author Jaime Terrats | 06-18-2025
    **/
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
     * @description Invocable method wrapper for Flow and Agentforce integration
     */
    public class InvocableRequest {
        @InvocableVariable(label='Configuration Name' description='The developer name of the query configuration' required=true)
        public String configName;
        
        @InvocableVariable(label='Binding Parameters (JSON)' description='Optional JSON string with bind variable values' required=false)
        public String bindingsJson;
    }

    /**
     * @description Invocable method result wrapper
     */
    public class InvocableResult {
        @InvocableVariable(label='Records' description='List of records returned by the query')
        public List<SObject> records;
        
        @InvocableVariable(label='Record Count' description='Number of records returned')
        public Integer recordCount;
        
        @InvocableVariable(label='Success' description='Whether the query executed successfully')
        public Boolean success;
        
        @InvocableVariable(label='Error Message' description='Error message if query failed')
        public String errorMessage;
    }

    /**
     * @description Invocable method for Flow and Agentforce integration
     * @param requests List of invocable requests
     * @return List<InvocableResult> Results for each request
     */
    @InvocableMethod(
        label='Execute Dynamic Query' 
        description='Execute a pre-configured SOQL query with optional bind parameters'
        category='Data'
        iconName='slds:standard:record_lookup'
    )
    public static List<InvocableResult> executeQuery(List<InvocableRequest> requests) {
        List<InvocableResult> results = new List<InvocableResult>();
        
        for (InvocableRequest request : requests) {
            InvocableResult result = new InvocableResult();
            result.success = false;
            
            try {
                List<SObject> records;
                
                if (String.isNotBlank(request.bindingsJson)) {
                    // Execute with bindings
                    Map<String, Object> bindings = (Map<String, Object>) JSON.deserializeUntyped(request.bindingsJson);
                    records = getRecords(request.configName, true, bindings);
                } else {
                    // Execute without bindings
                    records = getRecords(request.configName, true);
                }
                
                result.records = records;
                result.recordCount = records != null ? records.size() : 0;
                result.success = true;
                
            } catch (Exception e) {
                result.errorMessage = e.getMessage();
                result.records = new List<SObject>();
                result.recordCount = 0;
            }
            
            results.add(result);
        }
        
        return results;
    }

    /**
    * @description instance method to get the config with caching optimization
    * @param devName
    * @author Jaime Terrats | 06-18-2025
    * @return JT_DynamicQueryConfiguration__mdt
    **/
    private JT_DynamicQueryConfiguration__mdt getConfig(String devName) {
        // Check cache first to avoid unnecessary queries
        if (configCache.containsKey(devName)) {
            return configCache.get(devName);
        }

        if (!Schema.SObjectType.JT_DynamicQueryConfiguration__mdt.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to access DynamicSOQL__mdt object.');
        }

        List<JT_DynamicQueryConfiguration__mdt> configs = [
            SELECT JT_BaseQuery__c, JT_Binding__c
            FROM JT_DynamicQueryConfiguration__mdt
            WHERE DeveloperName = :devName
            WITH USER_MODE LIMIT 1
        ];

        if (configs.isEmpty()) {
            throw new AuraHandledException('Configuration not found: ' + devName);
        }

        // Store in cache for future use
        JT_DynamicQueryConfiguration__mdt config = configs[0];
        configCache.put(devName, config);

        return config;
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

        // Deserialize bindings only once
        Map<String, Object> bindings = String.isNotBlank(config.JT_Binding__c)
            ? (Map<String, Object>) JSON.deserializeUntyped(config.JT_Binding__c)
            : new Map<String, Object>();

        // Use appropriate access level
        AccessLevel accessMode = enforceSecurity ? AccessLevel.USER_MODE : AccessLevel.SYSTEM_MODE;

        return Database.queryWithBinds(
            config.JT_BaseQuery__c,
            bindings,
            accessMode
        );
    }

    /**
    * @description returns a collection of records based on the configuration name provided
    * @author Jaime Terrats | 06-18-2025
    * @param devName
    * @param enforceSecurity
    * @param bindings
    * @return List<SObject>
    **/
    public static List<SObject> getRecords(String devName, Boolean enforceSecurity, Map<String, Object> bindings) {
        final JT_DataSelector selectorInstance = JT_DataSelector.getInstance();
        final JT_DynamicQueryConfiguration__mdt config = selectorInstance.getConfig(devName);

        // Use appropriate access level
        AccessLevel accessMode = enforceSecurity ? AccessLevel.USER_MODE : AccessLevel.SYSTEM_MODE;

        return Database.queryWithBinds(
            config.JT_BaseQuery__c,
            bindings,
            accessMode
        );
    }
}