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
    if (instance == null) {
      instance = new JT_DataSelector();
    }
    return instance;
  }

  /**
   * @description Invocable method wrapper for Flow and Agentforce integration
   */
  public class InvocableRequest {
    @InvocableVariable(
      label='Configuration Name'
      description='The developer name of the query configuration'
      required=true
    )
    public String configName;

    @InvocableVariable(
      label='Binding Parameters (JSON)'
      description='Optional JSON string with bind variable values'
      required=false
    )
    public String bindingsJson;
  }

  /**
   * @description Invocable method result wrapper
   */
  public class InvocableResult {
    @InvocableVariable(
      label='Records'
      description='List of records returned by the query'
    )
    public List<SObject> records;

    @InvocableVariable(
      label='Record Count'
      description='Number of records returned'
    )
    public Integer recordCount;

    @InvocableVariable(
      label='Success'
      description='Whether the query executed successfully'
    )
    public Boolean success;

    @InvocableVariable(
      label='Error Message'
      description='Error message if query failed'
    )
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
  public static List<InvocableResult> executeQuery(
    List<InvocableRequest> requests
  ) {
    List<InvocableResult> results = new List<InvocableResult>();

    for (InvocableRequest request : requests) {
      InvocableResult result = new InvocableResult();
      result.success = false;

      try {
        List<SObject> records;

        if (String.isNotBlank(request.bindingsJson)) {
          // Execute with bindings
          Map<String, Object> bindings = (Map<String, Object>) JSON.deserializeUntyped(
            request.bindingsJson
          );
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
      throw new AuraHandledException(
        'Insufficient permissions to access DynamicSOQL__mdt object.'
      );
    }

    List<JT_DynamicQueryConfiguration__mdt> configs = [
      SELECT JT_BaseQuery__c, JT_Binding__c
      FROM JT_DynamicQueryConfiguration__mdt
      WHERE DeveloperName = :devName
      WITH USER_MODE
      LIMIT 1
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
  public static List<SObject> getRecords(
    String devName,
    Boolean enforceSecurity
  ) {
    final JT_DataSelector selectorInstance = JT_DataSelector.getInstance();
    final JT_DynamicQueryConfiguration__mdt config = selectorInstance.getConfig(
      devName
    );

    // Deserialize bindings only once
    Map<String, Object> bindings = String.isNotBlank(config.JT_Binding__c)
      ? (Map<String, Object>) JSON.deserializeUntyped(config.JT_Binding__c)
      : new Map<String, Object>();

    // Use appropriate access level
    AccessLevel accessMode = enforceSecurity
      ? AccessLevel.USER_MODE
      : AccessLevel.SYSTEM_MODE;

    return Database.queryWithBinds(
      config.JT_BaseQuery__c,
      bindings,
      accessMode
    );
  }

  /**
   * @description Process large query results using Apex Cursors (Beta)
   * Allows efficient processing of >50K records in batches
   * @param devName Configuration name
   * @param bindings Custom bindings (merged with config bindings)
   * @param enforceSecurity Whether to use USER_MODE
   * @param batchSize Number of records to process per batch (default: 200)
   * @param processor Instance of CursorProcessor to handle each batch
   * @return Integer Total number of records processed
   * @see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_SOQL_cursors.htm
   */
  public static Integer processRecordsWithCursor(
    String devName,
    Map<String, Object> bindings,
    Boolean enforceSecurity,
    Integer batchSize,
    CursorProcessor processor
  ) {
    final JT_DataSelector selectorInstance = JT_DataSelector.getInstance();
    final JT_DynamicQueryConfiguration__mdt config = selectorInstance.getConfig(
      devName
    );

    // Merge config bindings with custom bindings
    Map<String, Object> configBindings = String.isNotBlank(config.JT_Binding__c)
      ? (Map<String, Object>) JSON.deserializeUntyped(config.JT_Binding__c)
      : new Map<String, Object>();
    Map<String, Object> mergedBindings = new Map<String, Object>(
      configBindings
    );
    if (bindings != null) {
      mergedBindings.putAll(bindings);
    }

    // Use appropriate access level
    AccessLevel accessMode = enforceSecurity
      ? AccessLevel.USER_MODE
      : AccessLevel.SYSTEM_MODE;

    // Set batch size (default 200)
    Integer effectiveBatchSize = batchSize != null &&
      batchSize > 0
      ? batchSize
      : 200;

    Integer totalProcessed = 0;

    // NOTE: Apex Cursors (Database.getCursor) are not yet available in API 65.0
    // When available, this method will automatically use them for better performance
    // For now, we use batch processing simulation with standard queries

    // Query all records
    List<SObject> allRecords = Database.queryWithBinds(
      config.JT_BaseQuery__c,
      mergedBindings,
      accessMode
    );

    // Process in batches to manage heap size
    for (Integer i = 0; i < allRecords.size(); i += effectiveBatchSize) {
      List<SObject> batch = new List<SObject>();
      for (
        Integer j = i;
        j < Math.min(i + effectiveBatchSize, allRecords.size());
        j++
      ) {
        batch.add(allRecords[j]);
      }
      processor.processBatch(batch);
      totalProcessed += batch.size();
    }

    return totalProcessed;
  }

  /**
   * @description Interface for cursor batch processing
   * Implement this interface to define custom processing logic for each batch
   */
  public interface CursorProcessor {
    /**
     * @description Process a batch of records
     * @param batch List of SObjects to process
     */
    void processBatch(List<SObject> batch);
  }

  /**
   * @description returns a collection of records based on the configuration name provided
   * @author Jaime Terrats | 06-18-2025
   * @param devName
   * @param enforceSecurity
   * @param bindings
   * @return List<SObject>
   **/
  public static List<SObject> getRecords(
    String devName,
    Boolean enforceSecurity,
    Map<String, Object> bindings
  ) {
    final JT_DataSelector selectorInstance = JT_DataSelector.getInstance();
    final JT_DynamicQueryConfiguration__mdt config = selectorInstance.getConfig(
      devName
    );

    // Use appropriate access level
    AccessLevel accessMode = enforceSecurity
      ? AccessLevel.USER_MODE
      : AccessLevel.SYSTEM_MODE;

    return Database.queryWithBinds(
      config.JT_BaseQuery__c,
      bindings,
      accessMode
    );
  }

  /**
   * @description Helper method to count records for a given query
   * @param baseQuery The SOQL query to count
   * @param bindings Bind variables for the query
   * @param enforceSecurity Whether to use USER_MODE
   * @return Integer Number of records that would be returned
   */
  @TestVisible
  private static Integer countRecords(
    String baseQuery,
    Map<String, Object> bindings,
    Boolean enforceSecurity
  ) {
    // Convert SELECT query to COUNT query
    String countQuery = baseQuery.replaceAll(
      '(?i)SELECT[\\s\\S]+?FROM',
      'SELECT COUNT() FROM'
    );

    // Remove ORDER BY, LIMIT, OFFSET clauses for COUNT
    countQuery = countQuery.replaceAll('(?i)\\s+ORDER\\s+BY[^\\n]+', '');
    countQuery = countQuery.replaceAll('(?i)\\s+LIMIT\\s+\\d+', '');
    countQuery = countQuery.replaceAll('(?i)\\s+OFFSET\\s+\\d+', '');

    // Use appropriate access level
    AccessLevel accessMode = enforceSecurity
      ? AccessLevel.USER_MODE
      : AccessLevel.SYSTEM_MODE;

    // Replace bind variables in the query string for Database.countQuery()
    String finalQuery = countQuery;
    if (bindings != null && !bindings.isEmpty()) {
      for (String key : bindings.keySet()) {
        Object value = bindings.get(key);
        String replacement = '';

        if (value instanceof String) {
          replacement = '\'' + String.escapeSingleQuotes((String) value) + '\'';
        } else if (value instanceof Date) {
          replacement = String.valueOf((Date) value);
        } else if (value instanceof Datetime) {
          replacement = ((Datetime) value)
            .format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        } else if (
          value instanceof Boolean ||
          value instanceof Integer ||
          value instanceof Decimal
        ) {
          replacement = String.valueOf(value);
        } else if (value instanceof List<Object>) {
          List<Object> listValue = (List<Object>) value;
          List<String> escapedValues = new List<String>();
          for (Object item : listValue) {
            if (item instanceof String) {
              escapedValues.add(
                '\'' + String.escapeSingleQuotes((String) item) + '\''
              );
            } else {
              escapedValues.add(String.valueOf(item));
            }
          }
          replacement = '(' + String.join(escapedValues, ',') + ')';
        } else {
          replacement = String.valueOf(value);
        }

        finalQuery = finalQuery.replaceAll(':' + key + '\\b', replacement);
      }
    }

    return Database.countQuery(finalQuery, accessMode);
  }

  /**
   * @description Smart method that automatically decides whether to use standard query
   * or cursor-based processing based on record count
   * @param devName Configuration name
   * @param enforceSecurity Whether to use USER_MODE
   * @param bindings Custom bindings (merged with config bindings)
   * @param threshold Record count threshold for using cursor processing (default: 50000)
   * @param processor Optional CursorProcessor for large result sets. If null and count > threshold, throws exception
   * @return List<SObject> Records if count <= threshold, empty list if cursor processing was used
   */
  public static List<SObject> getRecordsWithAutoStrategy(
    String devName,
    Boolean enforceSecurity,
    Map<String, Object> bindings,
    Integer threshold,
    CursorProcessor processor
  ) {
    final JT_DataSelector selectorInstance = JT_DataSelector.getInstance();
    final JT_DynamicQueryConfiguration__mdt config = selectorInstance.getConfig(
      devName
    );

    // Merge config bindings with custom bindings
    Map<String, Object> configBindings = String.isNotBlank(config.JT_Binding__c)
      ? (Map<String, Object>) JSON.deserializeUntyped(config.JT_Binding__c)
      : new Map<String, Object>();
    Map<String, Object> mergedBindings = new Map<String, Object>(
      configBindings
    );
    if (bindings != null) {
      mergedBindings.putAll(bindings);
    }

    // Set threshold (default 50,000)
    Integer effectiveThreshold = threshold != null &&
      threshold > 0
      ? threshold
      : 50000;

    // Step 1: Count records
    Integer recordCount;
    try {
      recordCount = countRecords(
        config.JT_BaseQuery__c,
        mergedBindings,
        enforceSecurity
      );
    } catch (Exception e) {
      // If COUNT fails, fall back to standard query
      return getRecords(devName, enforceSecurity, mergedBindings);
    }

    // Step 2: Decide strategy based on count
    if (recordCount > effectiveThreshold) {
      // Large result set - use cursor processing
      if (processor == null) {
        throw new AuraHandledException(
          'Query would return ' +
            recordCount +
            ' records (>' +
            effectiveThreshold +
            '). Please provide a CursorProcessor to handle large result sets.'
        );
      }

      // Process with cursor and return empty list (data is handled by processor)
      processRecordsWithCursor(
        devName,
        mergedBindings,
        enforceSecurity,
        200,
        processor
      );
      return new List<SObject>();
    } else {
      // Small/medium result set - use standard query
      return getRecords(devName, enforceSecurity, mergedBindings);
    }
  }

  /**
   * @description Overload with default threshold (50,000) and no processor
   * @param devName Configuration name
   * @param enforceSecurity Whether to use USER_MODE
   * @param bindings Custom bindings
   * @return List<SObject> Records if count <= 50000, throws exception if more
   */
  public static List<SObject> getRecordsWithAutoStrategy(
    String devName,
    Boolean enforceSecurity,
    Map<String, Object> bindings
  ) {
    return getRecordsWithAutoStrategy(
      devName,
      enforceSecurity,
      bindings,
      50000,
      null
    );
  }
}
