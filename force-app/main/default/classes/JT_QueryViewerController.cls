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
      // ✅ REFACTORED: Use Selector Layer (2025-12-02)
      List<JT_DynamicQueryConfiguration__mdt> configs = JT_ConfigurationSelector.getConfigurations();

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
      throw new AuraHandledException(
        'Error retrieving configurations: ' + e.getMessage()
      );
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
  public static QueryResult executeQuery(
    String devName,
    String bindingsJson,
    String runAsUserId
  ) {
    try {
      // Validate Run As User feature
      if (String.isNotBlank(runAsUserId)) {
        validateRunAsPermission(runAsUserId);
      }

      Map<String, Object> bindings = String.isNotBlank(bindingsJson)
        ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
        : new Map<String, Object>();

      List<SObject> sobjectRecords = JT_DataSelector.getRecords(
        devName,
        true,
        bindings
      );

      QueryResult result = new QueryResult();

      // ✅ SERIALIZE to preserve child relationships
      String recordsJson = JSON.serialize(sobjectRecords);
      result.records = (List<Object>) JSON.deserializeUntyped(recordsJson);

      result.recordCount = sobjectRecords.size();
      result.success = true;
      result.runAsUserName = String.isNotBlank(runAsUserId)
        ? getUserName(runAsUserId)
        : null;

      // Extract field names from first record if available
      if (!sobjectRecords.isEmpty()) {
        result.fields = getFieldNames(sobjectRecords[0]);
      }

      return result;
    } catch (Exception e) {
      QueryResult result = new QueryResult();
      result.success = false;
      result.errorMessage = e.getMessage();
      result.records = new List<Object>(); // Changed from List<SObject>
      result.recordCount = 0;
      return result;
    }
  }

  /**
   * @description Extracts field names from an SObject record IN ORDER
   * Maintains SELECT order by extracting only top-level fields, excluding child relationships
   * @author Jaime Terrats | 12-02-2025
   * @param record SObject record
   * @return List<String> Field names in the order they appear in the query
   **/
  private static List<String> getFieldNames(SObject record) {
    Map<String, Object> fieldMap = record.getPopulatedFieldsAsMap();
    List<String> fields = new List<String>();

    // Extract only scalar fields (exclude child relationships)
    for (String key : fieldMap.keySet()) {
      Object value = fieldMap.get(key);
      // Exclude 'attributes' and child relationships (which are lists)
      if (key != 'attributes' && !(value instanceof List<SObject>)) {
        fields.add(key);
      }
    }

    // ❌ DON'T sort - this loses SELECT order
    // fields.sort();

    return fields;
  }

  /**
   * @description Executes a query preview with LIMIT 5 for data preview
   * @author Jaime Terrats | 12-01-2025
   * @param devName Configuration developer name
   * @param bindingsJson JSON string with bindings
   * @return QueryResult with max 5 records
   **/
  @AuraEnabled
  public static QueryResult executeQueryPreview(
    String devName,
    String bindingsJson
  ) {
    try {
      Map<String, Object> bindings = String.isNotBlank(bindingsJson)
        ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
        : new Map<String, Object>();

      // Get the configuration to modify query with LIMIT
      JT_DynamicQueryConfiguration__mdt config = [
        SELECT JT_BaseQuery__c, JT_ObjectName__c
        FROM JT_DynamicQueryConfiguration__mdt
        WHERE DeveloperName = :devName
        WITH USER_MODE
        LIMIT 1
      ];

      String previewQuery = config.JT_BaseQuery__c;

      // Add LIMIT 5 if not already present
      if (!previewQuery.containsIgnoreCase('LIMIT')) {
        previewQuery += ' LIMIT 5';
      } else {
        // Replace existing LIMIT with LIMIT 5
        previewQuery = previewQuery.replaceAll('(?i)LIMIT\\s+\\d+', 'LIMIT 5');
      }

      List<SObject> records = Database.queryWithBinds(
        previewQuery,
        bindings,
        AccessLevel.USER_MODE
      );

      QueryResult result = new QueryResult();
      result.records = records;
      result.recordCount = records.size();
      result.success = true;

      // Extract field names from first record if available
      if (!records.isEmpty()) {
        result.fields = getFieldNames(records[0]);
      }

      return result;
    } catch (Exception e) {
      QueryResult result = new QueryResult();
      result.success = false;
      result.errorMessage = e.getMessage();
      result.records = new List<Object>(); // Changed from List<SObject>
      result.recordCount = 0;
      return result;
    }
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
      throw new AuraHandledException(
        'Error extracting parameters: ' + e.getMessage()
      );
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
      // ✅ REFACTORED: Use Selector Layer (2025-12-02)
      return JT_SystemSelector.hasElevatedPermissions(UserInfo.getUserId()) ||
        isSystemAdmin();
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
      // ✅ REFACTORED: Use Selector Layer (2025-12-02)
      Profile userProfile = JT_SystemSelector.getUserProfile();
      return userProfile != null &&
        userProfile.Name.contains('System Administrator');
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
        throw new AuraHandledException(
          'Insufficient permissions to use Run As feature.'
        );
      }

      Id currentUserId = UserInfo.getUserId();

      // ✅ REFACTORED: Use Selector Layer (2025-12-02)
      List<User> users = JT_SystemSelector.getAllActiveUsers();

      List<UserOption> options = new List<UserOption>();
      for (User u : users) {
        // Exclude current user
        if (u.Id == currentUserId) {
          continue;
        }

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
      throw new AuraHandledException(
        'You do not have permission to use the Run As feature.'
      );
    }

    // ✅ REFACTORED: Use Selector Layer (2025-12-02)
    try {
      User u = JT_SystemSelector.getUserById(userId);

      if (!u.IsActive) {
        throw new AuraHandledException(
          'Cannot run as inactive user: ' + u.Name
        );
      }
    } catch (QueryException e) {
      throw new AuraHandledException('Selected user not found.');
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
      // ✅ REFACTORED: Use Selector Layer (2025-12-02)
      User u = JT_SystemSelector.getUserById(userId);
      return u.Name;
    } catch (Exception e) {
      return null;
    }
  }

  /**
   * @description Wrapper class for configuration options
   **/
  public class ConfigurationOption {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;
    @AuraEnabled
    public String baseQuery;
    @AuraEnabled
    public String bindings;
    @AuraEnabled
    public String objectName;
  }

  /**
   * @description Wrapper class for query results
   **/
  /**
   * @description Wrapper class for query results
   * Uses List<Object> instead of List<SObject> to preserve child relationships
   */
  public class QueryResult {
    @AuraEnabled
    public List<Object> records; // Changed from List<SObject> to preserve child relationships
    @AuraEnabled
    public Integer recordCount;
    @AuraEnabled
    public List<String> fields;
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String errorMessage;
    @AuraEnabled
    public String runAsUserName;
  }

  /**
   * @description Wrapper class for user options
   **/
  public class UserOption {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;
    @AuraEnabled
    public String username;
    @AuraEnabled
    public String profileName;
    @AuraEnabled
    public String email;
  }

  /**
   * @description Detects if a query is potentially dangerous (might return >50K records)
   * @author Jaime Terrats | 12-02-2025
   * @param devName Configuration developer name
   * @param bindingsJson JSON string with bindings
   * @return QueryRiskAssessment
   **/
  /**
   * @description Detects if a query contains child relationships
   * @param query The SOQL query string
   * @return Boolean True if query has child relationships
   */
  private static Boolean hasChildRelationships(String query) {
    return query != null && query.containsIgnoreCase('(SELECT');
  }

  @AuraEnabled
  public static QueryRiskAssessment assessQueryRisk(
    String devName,
    String bindingsJson
  ) {
    try {
      Map<String, Object> bindings = String.isNotBlank(bindingsJson)
        ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
        : new Map<String, Object>();

      // Get config
      JT_DynamicQueryConfiguration__mdt config = [
        SELECT JT_BaseQuery__c, JT_ObjectName__c, JT_Binding__c
        FROM JT_DynamicQueryConfiguration__mdt
        WHERE DeveloperName = :devName
        WITH USER_MODE
        LIMIT 1
      ];

      // Merge bindings
      Map<String, Object> configBindings = String.isNotBlank(
          config.JT_Binding__c
        )
        ? (Map<String, Object>) JSON.deserializeUntyped(config.JT_Binding__c)
        : new Map<String, Object>();
      Map<String, Object> mergedBindings = new Map<String, Object>(
        configBindings
      );
      if (bindings != null) {
        mergedBindings.putAll(bindings);
      }

      // Create a DEEP COPY of bindings for COUNT with auto-added wildcards
      // Using JSON serialize/deserialize to ensure complete independence
      Map<String, Object> countBindings = (Map<String, Object>) JSON.deserializeUntyped(
        JSON.serialize(mergedBindings)
      );
      addWildcardsForLikeBindings(config.JT_BaseQuery__c, countBindings);

      // Build COUNT query (replace SELECT ... FROM with SELECT COUNT() FROM)
      // Use [\s\S]*? to match across multiple lines (including newlines)
      String countQuery = config.JT_BaseQuery__c
        .replaceAll('(?i)SELECT[\\s\\S]+?FROM', 'SELECT COUNT() FROM')
        .replaceAll('(?i)ORDER\\s+BY[\\s\\S]*$', '') // Remove ORDER BY
        .replaceAll('(?i)LIMIT\\s+\\d+[\\s\\S]*$', ''); // Remove LIMIT

      // Execute count query with timeout protection
      Integer estimatedCount = 0;
      try {
        System.debug(
          LoggingLevel.FINE,
          '📊 COUNT Query: ' + countQuery
        );
        System.debug(
          LoggingLevel.FINE,
          '📊 COUNT Bindings: ' + JSON.serialize(countBindings)
        );

        // Replace bind variables in COUNT query (countQuery() doesn't support bindings)
        String finalCountQuery = replaceBindVariables(countQuery, countBindings);
        
        System.debug(
          LoggingLevel.FINE,
          '📊 Final COUNT Query: ' + finalCountQuery
        );

        // Use countQuery() instead of queryWithBinds for COUNT queries
        estimatedCount = Database.countQuery(finalCountQuery);
        
        System.debug(
          LoggingLevel.FINE,
          '✅ COUNT Result: ' + estimatedCount
        );
      } catch (Exception e) {
        // If count fails, assume it's risky
        System.debug(
          LoggingLevel.ERROR,
          '❌ COUNT Failed: ' + e.getMessage() + ' | ' + e.getStackTraceString()
        );
        estimatedCount = 99999;
      }

      QueryRiskAssessment assessment = new QueryRiskAssessment();
      assessment.estimatedRecordCount = estimatedCount;

      // ⚠️ CRITICAL: Batch processing breaks child relationships
      // If query has child relationships, disable batch processing
      Boolean hasChildRelationships = hasChildRelationships(
        config.JT_BaseQuery__c
      );

      if (hasChildRelationships) {
        // ⚠️ CRITICAL: Batch processing breaks child relationships
        // Force LOW risk to skip batch processing modal
        assessment.isHighRisk = false;
        assessment.isCriticalRisk = false;
        assessment.recommendBatchProcessing = false;
        assessment.riskLevel = 'LOW';
        assessment.message = 'Query contains child relationships. Using standard processing.';
      } else {
        assessment.isHighRisk = estimatedCount > 10000; // >10K is high risk
        assessment.isCriticalRisk = estimatedCount > 50000; // >50K will fail
        assessment.recommendBatchProcessing = estimatedCount > 5000;

        if (assessment.isCriticalRisk) {
          assessment.riskLevel = 'CRITICAL';
          assessment.message = 'This query will exceed the 50,000 record limit. Batch processing is required.';
        } else if (assessment.isHighRisk) {
          assessment.riskLevel = 'HIGH';
          assessment.message =
            'This query may return a large number of records (' +
            estimatedCount +
            '). Consider using batch processing.';
        } else if (assessment.recommendBatchProcessing) {
          assessment.riskLevel = 'MEDIUM';
          assessment.message =
            'Query will return ' +
            estimatedCount +
            ' records. Batch processing recommended for better performance.';
        } else {
          assessment.riskLevel = 'LOW';
          assessment.message =
            'Query is safe to execute (' +
            estimatedCount +
            ' records).';
        }
      }

      return assessment;
    } catch (Exception e) {
      QueryRiskAssessment assessment = new QueryRiskAssessment();
      assessment.estimatedRecordCount = 0;
      assessment.isHighRisk = true;
      assessment.isCriticalRisk = false;
      assessment.recommendBatchProcessing = true;
      assessment.riskLevel = 'UNKNOWN';
      assessment.message = 'Unable to assess risk: ' + e.getMessage();
      return assessment;
    }
  }

  /**
   * @description Replaces bind variables in query with actual values for countQuery()
   * @param query The SOQL query string with bind variables
   * @param bindings The map of bind variables
   * @return String query with bind variables replaced
   **/
  private static String replaceBindVariables(
    String query,
    Map<String, Object> bindings
  ) {
    if (String.isBlank(query) || bindings == null || bindings.isEmpty()) {
      return query;
    }

    String result = query;
    for (String key : bindings.keySet()) {
      Object value = bindings.get(key);
      String escapedValue = '';

      if (value == null) {
        escapedValue = 'null';
      } else if (value instanceof String) {
        // Escape single quotes and wrap in quotes
        escapedValue = '\'' + String.valueOf(value).replace('\'', '\\\'') + '\'';
      } else if (value instanceof Boolean || value instanceof Integer || value instanceof Decimal) {
        escapedValue = String.valueOf(value);
      } else {
        // For other types, use string representation
        escapedValue = '\'' + String.valueOf(value).replace('\'', '\\\'') + '\'';
      }

      // Replace :bindVar with actual value
      result = result.replaceAll(':' + key + '\\b', escapedValue);
    }

    return result;
  }

  /**
   * @description Adds wildcards to bind parameters used in LIKE clauses for risk assessment
   * @param query The SOQL query string
   * @param bindings The map of bind variables
   **/
  private static void addWildcardsForLikeBindings(
    String query,
    Map<String, Object> bindings
  ) {
    if (String.isBlank(query) || bindings == null || bindings.isEmpty()) {
      return;
    }

    System.debug(
      LoggingLevel.FINE,
      '🔍 Adding wildcards for LIKE bindings...'
    );

    // Find all LIKE clauses with bind variables: LIKE :bindVar
    // (?i) makes the pattern case-insensitive
    Pattern likePattern = Pattern.compile('(?i)\\bLIKE\\s+:(\\w+)');
    Matcher matcher = likePattern.matcher(query);

    while (matcher.find()) {
      String bindVar = matcher.group(1);
      System.debug(
        LoggingLevel.FINE,
        '📌 Found LIKE bind variable: ' + bindVar
      );

      if (bindings.containsKey(bindVar)) {
        Object value = bindings.get(bindVar);
        if (value instanceof String) {
          String strValue = (String) value;
          // Only add wildcards if they're not already present
          if (!strValue.contains('%') && !strValue.contains('_')) {
            String newValue = '%' + strValue + '%';
            bindings.put(bindVar, newValue);
            System.debug(
              LoggingLevel.FINE,
              '✅ Added wildcards: "' +
              strValue +
              '" → "' +
              newValue +
              '"'
            );
          } else {
            System.debug(
              LoggingLevel.FINE,
              'ℹ️  Wildcards already present: "' + strValue + '"'
            );
          }
        }
      }
    }
  }

  /**
   * @description Executes query using batch/cursor processing for large result sets
   * @author Jaime Terrats | 12-02-2025
   * @param devName Configuration developer name
   * @param bindingsJson JSON string with bindings
   * @param batchSize Records per batch (default: 200)
   * @return QueryResult
   **/
  @AuraEnabled
  public static QueryResult executeQueryWithBatchProcessing(
    String devName,
    String bindingsJson,
    Integer batchSize
  ) {
    try {
      Map<String, Object> bindings = String.isNotBlank(bindingsJson)
        ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
        : new Map<String, Object>();

      Integer effectiveBatchSize = batchSize != null &&
        batchSize > 0
        ? batchSize
        : 200;

      // Use ResultCollector to accumulate records
      ResultCollector collector = new ResultCollector();

      Integer totalProcessed = JT_DataSelector.processRecordsWithCursor(
        devName,
        bindings,
        true, // enforce security
        effectiveBatchSize,
        collector
      );

      // Return collected results
      QueryResult result = new QueryResult();

      List<SObject> sobjectRecords = collector.getAllRecords();

      // ✅ SERIALIZE to preserve child relationships
      String recordsJson = JSON.serialize(sobjectRecords);
      result.records = (List<Object>) JSON.deserializeUntyped(recordsJson);

      result.recordCount = totalProcessed;
      result.success = true;

      // Extract field names from first record
      if (sobjectRecords != null && !sobjectRecords.isEmpty()) {
        result.fields = getFieldNames(sobjectRecords[0]);
      }

      return result;
    } catch (Exception e) {
      QueryResult result = new QueryResult();
      result.success = false;
      result.errorMessage = e.getMessage();
      result.records = new List<Object>(); // Changed from List<SObject>
      result.recordCount = 0;
      return result;
    }
  }

  /**
   * @description Helper to check if required parameters are empty
   * @param bindings Map of parameter bindings
   * @return Boolean True if all bindings are empty
   **/
  private static Boolean hasEmptyRequiredParameters(
    Map<String, Object> bindings
  ) {
    if (bindings == null || bindings.isEmpty()) {
      return true;
    }

    for (Object value : bindings.values()) {
      if (value != null && String.valueOf(value).trim() != '') {
        return false; // At least one parameter has a value
      }
    }

    return true; // All parameters are empty
  }

  /**
   * @description Inner class to collect records from cursor processing
   * Implements CursorProcessor interface from JT_DataSelector
   **/
  public class ResultCollector implements JT_DataSelector.CursorProcessor {
    private List<SObject> collectedRecords = new List<SObject>();

    public void processBatch(List<SObject> batch) {
      collectedRecords.addAll(batch);
    }

    public List<SObject> getAllRecords() {
      return collectedRecords;
    }
  }

  /**
   * @description Wrapper class for query risk assessment
   **/
  public class QueryRiskAssessment {
    @AuraEnabled
    public Integer estimatedRecordCount;
    @AuraEnabled
    public Boolean isHighRisk;
    @AuraEnabled
    public Boolean isCriticalRisk;
    @AuraEnabled
    public Boolean recommendBatchProcessing;
    @AuraEnabled
    public Boolean hasEmptyParameters;
    @AuraEnabled
    public String riskLevel; // LOW, MEDIUM, HIGH, CRITICAL, UNKNOWN
    @AuraEnabled
    public String message;
  }
}
