/**
 * @description Data Selector for dynamic SOQL queries with security enforcement
 * @author Jaime Terrats
 * @group Selector Layer
 * @last modified on 12-11-2025
 * @last modified by Jaime Terrats
 *
 * PMD Suppressions:
 * - CognitiveComplexity/CyclomaticComplexity: Inherent to bind variable processing and security checks
 * - AvoidBooleanMethodParameters: enforceSecurity flag is a common pattern for security-aware methods
 * - ExcessiveParameterList: All parameters are necessary for query execution flexibility
 * - AvoidDeeplyNestedIfStmts: Required for comprehensive bind variable validation
 **/
@SuppressWarnings(
  'PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity, PMD.AvoidBooleanMethodParameters, PMD.ExcessiveParameterList, PMD.AvoidDeeplyNestedIfStmts'
)
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
        Label.JT_DataSelector_insufficientPermissionsMetadata
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
      throw new AuraHandledException(
        String.format(
          Label.JT_DataSelector_configurationNotFound,
          new List<String>{ devName }
        )
      );
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

    // Check if query uses unsupported operators and throw descriptive error
    validateSupportedOperators(config.JT_BaseQuery__c);

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
   * @description Validates query doesn't use operators not supported by Salesforce SOQL
   * @param query SOQL query string to validate
   * @throws UnsupportedOperatorException If unsupported operators are detected
   */
  @TestVisible
  private static void validateSupportedOperators(String query) {
    if (String.isBlank(query)) {
      return;
    }

    String normalizedQuery = query.toLowerCase();

    // Check for BETWEEN operator
    if (normalizedQuery.contains(' between ')) {
      throw new UnsupportedOperatorException(
        System.Label.JT_Error_BetweenOperatorNotSupported
      );
    }

    // Check for NOT LIKE operator
    if (normalizedQuery.contains(' not like ')) {
      throw new UnsupportedOperatorException(
        System.Label.JT_Error_NotLikeOperatorNotSupported
      );
    }
  }

  /**
   * @description Custom exception for unsupported SOQL operators
   */
  public class UnsupportedOperatorException extends Exception {
  }

  /**
   * @description Validates and converts binding types by detecting operators in query
   * @param bindings Raw bindings from user input
   * @param query SOQL query string to analyze for operators
   * @return Map<String, Object> Validated and converted bindings
   */
  @TestVisible
  private static Map<String, Object> validateAndConvertBindings(
    Map<String, Object> bindings,
    String query
  ) {
    if (bindings == null || bindings.isEmpty()) {
      return bindings;
    }

    if (String.isBlank(query)) {
      return bindings;
    }

    Map<String, Object> validatedBindings = new Map<String, Object>();

    for (String key : bindings.keySet()) {
      Object value = bindings.get(key);

      // Auto-detect if this binding is used with IN operator
      String normalizedQuery = query.toLowerCase();
      String bindingPattern = ':' + key.toLowerCase();

      // Check if used with IN/INCLUDES/EXCLUDES (requires List)
      Boolean requiresList =
        normalizedQuery.contains('in ' + bindingPattern) ||
        normalizedQuery.contains('includes ' + bindingPattern) ||
        normalizedQuery.contains('excludes ' + bindingPattern);

      if (requiresList) {
        // Convert to List<String> if not already a list
        if (!(value instanceof List<Object>)) {
          validatedBindings.put(
            key,
            convertListToTypedList(new List<Object>{ value }, 'String')
          );
        } else {
          validatedBindings.put(
            key,
            convertListToTypedList((List<Object>) value, 'String')
          );
        }
      } else {
        // Pass through as-is for other operators
        validatedBindings.put(key, value);
      }
    }

    return validatedBindings;
  }

  /**
   * @description Converts List<Object> to properly typed list for Database.queryWithBinds
   * @param values List of values
   * @param innerType Type of elements (String, Id, Integer, etc.)
   * @return Object Typed list
   */
  @TestVisible
  private static Object convertListToTypedList(
    List<Object> values,
    String innerType
  ) {
    if (values == null || values.isEmpty()) {
      return values;
    }

    // Handle common types
    if (innerType == 'String') {
      List<String> typedList = new List<String>();
      for (Object val : values) {
        typedList.add(String.valueOf(val));
      }
      return typedList;
    }

    if (innerType == 'Id') {
      List<String> typedList = new List<String>();
      for (Object val : values) {
        typedList.add(String.valueOf(val));
      }
      return typedList;
    }

    if (innerType == 'Integer') {
      List<Integer> typedList = new List<Integer>();
      for (Object val : values) {
        typedList.add(
          val instanceof Integer
            ? (Integer) val
            : Integer.valueOf(String.valueOf(val))
        );
      }
      return typedList;
    }

    if (innerType == 'Decimal') {
      List<Decimal> typedList = new List<Decimal>();
      for (Object val : values) {
        typedList.add(
          val instanceof Decimal
            ? (Decimal) val
            : Decimal.valueOf(String.valueOf(val))
        );
      }
      return typedList;
    }

    if (innerType == 'Date') {
      List<Date> typedList = new List<Date>();
      for (Object val : values) {
        typedList.add(
          val instanceof Date ? (Date) val : Date.valueOf(String.valueOf(val))
        );
      }
      return typedList;
    }

    if (innerType == 'Datetime') {
      List<Datetime> typedList = new List<Datetime>();
      for (Object val : values) {
        typedList.add(
          val instanceof Datetime
            ? (Datetime) val
            : Datetime.valueOf(String.valueOf(val))
        );
      }
      return typedList;
    }

    // Default: return as List<String> (safest for most cases)
    List<String> defaultList = new List<String>();
    for (Object val : values) {
      defaultList.add(String.valueOf(val));
    }
    return defaultList;
  }

  /**
   * @description Process large query results using Apex Cursors (Beta)
   * Allows efficient processing of >50K records in batches
   * @param params CursorProcessingParams object containing all parameters
   * @return Integer Total number of records processed
   * @see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_SOQL_cursors.htm
   */
  public static Integer processRecordsWithCursor(
    CursorProcessingParams params
  ) {
    final JT_DataSelector selectorInstance = JT_DataSelector.getInstance();
    final JT_DynamicQueryConfiguration__mdt config = selectorInstance.getConfig(
      params.devName
    );

    Map<String, Object> configBindings = String.isNotBlank(config.JT_Binding__c)
      ? (Map<String, Object>) JSON.deserializeUntyped(config.JT_Binding__c)
      : new Map<String, Object>();
    Map<String, Object> mergedBindings = new Map<String, Object>(
      configBindings
    );
    if (params.bindings != null) {
      mergedBindings.putAll(params.bindings);
    }

    AccessLevel accessMode = params.enforceSecurity
      ? AccessLevel.USER_MODE
      : AccessLevel.SYSTEM_MODE;

    Integer effectiveBatchSize = params.batchSize != null &&
      params.batchSize > 0
      ? params.batchSize
      : 200;

    Integer totalProcessed = 0;

    List<SObject> allRecords = Database.queryWithBinds(
      config.JT_BaseQuery__c,
      mergedBindings,
      accessMode
    );

    for (Integer i = 0; i < allRecords.size(); i += effectiveBatchSize) {
      List<SObject> batch = new List<SObject>();
      for (
        Integer j = i;
        j < Math.min(i + effectiveBatchSize, allRecords.size());
        j++
      ) {
        batch.add(allRecords[j]);
      }
      params.processor.processBatch(batch);
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
   * @description Parameter object for processRecordsWithCursor method
   * Follows project rule: no many parameters, always use objects
   */
  public class CursorProcessingParams {
    @AuraEnabled
    public String devName;
    @AuraEnabled
    public Map<String, Object> bindings;
    @AuraEnabled
    public Boolean enforceSecurity;
    @AuraEnabled
    public Integer batchSize;
    public CursorProcessor processor; // Not @AuraEnabled - interface cannot be serialized

    /**
     * @description Constructor with all parameters
     */
    public CursorProcessingParams(
      String devName,
      Map<String, Object> bindings,
      Boolean enforceSecurity,
      Integer batchSize,
      CursorProcessor processor
    ) {
      this.devName = devName;
      this.bindings = bindings;
      this.enforceSecurity = enforceSecurity;
      this.batchSize = batchSize;
      this.processor = processor;
    }
  }

  /**
   * @description Parameter object for getRecordsWithAutoStrategy method
   * Follows project rule: no many parameters, always use objects
   */
  public class AutoStrategyParams {
    @AuraEnabled
    public String devName;
    @AuraEnabled
    public Boolean enforceSecurity;
    @AuraEnabled
    public Map<String, Object> bindings;
    @AuraEnabled
    public Integer threshold;
    public CursorProcessor processor; // Not @AuraEnabled - interface cannot be serialized

    /**
     * @description Default constructor
     */
    public AutoStrategyParams() {
    }

    /**
     * @description Constructor with all parameters
     */
    public AutoStrategyParams(
      String devName,
      Boolean enforceSecurity,
      Map<String, Object> bindings,
      Integer threshold,
      CursorProcessor processor
    ) {
      this.devName = devName;
      this.enforceSecurity = enforceSecurity;
      this.bindings = bindings;
      this.threshold = threshold;
      this.processor = processor;
    }
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

    // Check if query uses unsupported operators and throw descriptive error
    validateSupportedOperators(config.JT_BaseQuery__c);

    // Validate and convert bindings (auto-detect types from query patterns)
    Map<String, Object> validatedBindings = validateAndConvertBindings(
      bindings,
      config.JT_BaseQuery__c
    );

    // Use appropriate access level
    AccessLevel accessMode = enforceSecurity
      ? AccessLevel.USER_MODE
      : AccessLevel.SYSTEM_MODE;

    return Database.queryWithBinds(
      config.JT_BaseQuery__c,
      validatedBindings,
      accessMode
    );
  }

  /**
   * @description Count records for a given configuration
   * This method allows users to check record count BEFORE deciding execution strategy
   * Use this when you need to choose between standard query, cursor processing, or Batch/Queueable
   * @param devName Configuration name
   * @param bindings Custom bindings (merged with config bindings)
   * @param enforceSecurity Whether to use USER_MODE
   * @return Integer Number of records that would be returned
   * @example
   * // Check count first, then decide strategy
   * Integer count = JT_DataSelector.countRecordsForConfig('MyConfig', bindings, true);
   * if (count > 50000 && System.isBatch()) {
   *     // Use Batch Apex for async processing
   * } else if (count > 50000) {
   *     // Use cursor processing (sync only)
   *     JT_DataSelector.CursorProcessingParams params = new JT_DataSelector.CursorProcessingParams('MyConfig', bindings, true, 200, processor);
   *     JT_DataSelector.processRecordsWithCursor(params);
   * } else {
   *     // Use standard query
   *     List<SObject> records = JT_DataSelector.getRecords('MyConfig', true, bindings);
   * }
   */
  public static Integer countRecordsForConfig(
    String devName,
    Map<String, Object> bindings,
    Boolean enforceSecurity
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

    return countRecordsInternal(
      config.JT_BaseQuery__c,
      mergedBindings,
      enforceSecurity
    );
  }

  /**
   * @description Internal helper to count records for a given query
   * @param baseQuery The SOQL query to count
   * @param bindings Bind variables for the query
   * @param enforceSecurity Whether to use USER_MODE
   * @return Integer Number of records that would be returned
   */
  @TestVisible
  private static Integer countRecordsInternal(
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
   * WARNING: This method uses cursor processing for large datasets, which can ONLY be used
   * in synchronous contexts (NOT in @Future, Queueable, Batch, or Triggers).
   * For async contexts, use countRecordsForConfig() first, then decide your strategy.
   * @param params AutoStrategyParams object containing all parameters
   * @return List<SObject> Records if count <= threshold, empty list if cursor processing was used
   * @see countRecordsForConfig For checking count before deciding strategy in async contexts
   */
  public static List<SObject> getRecordsWithAutoStrategy(
    AutoStrategyParams params
  ) {
    String devName = params.devName;
    Boolean enforceSecurity = params.enforceSecurity;
    Map<String, Object> bindings = params.bindings;
    Integer threshold = params.threshold;
    CursorProcessor processor = params.processor;
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
      recordCount = countRecordsInternal(
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
          String.format(
            Label.JT_DataSelector_queryWouldReturnRecords,
            new List<String>{
              String.valueOf(recordCount),
              String.valueOf(effectiveThreshold)
            }
          )
        );
      }

      // Process with cursor and return empty list (data is handled by processor)
      JT_DataSelector.CursorProcessingParams cursorParams = new JT_DataSelector.CursorProcessingParams(
        devName,
        mergedBindings,
        enforceSecurity,
        200,
        processor
      );
      processRecordsWithCursor(cursorParams);
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
    AutoStrategyParams params = new AutoStrategyParams();
    params.devName = devName;
    params.enforceSecurity = enforceSecurity;
    params.bindings = bindings;
    params.threshold = 50000;
    params.processor = null;
    return getRecordsWithAutoStrategy(params);
  }
}
