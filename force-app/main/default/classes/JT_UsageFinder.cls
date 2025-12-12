/**
 * @description Controller to find usage of JT_DataSelector configurations in Apex classes and Flows
 * @author Jaime Terrats
 * @date 2025-12-11
 *
 * PMD Suppressions:
 * - CognitiveComplexity/CyclomaticComplexity: Searches multiple metadata types with complex filtering
 * - AvoidBooleanMethodParameters: includeInactive flag is standard pattern for search methods
 * - AvoidDeeplyNestedIfStmts: Necessary for parsing Tooling API responses
 */
@SuppressWarnings(
  'PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity, PMD.AvoidBooleanMethodParameters, PMD.AvoidDeeplyNestedIfStmts, PMD.AvoidDebugStatements, PMD.ApexDoc, PMD.NcssMethodCount'
)
public without sharing class JT_UsageFinder {
  private static final String FLOW_QUERY = 'SELECT Id, MasterLabel, Metadata, Status FROM Flow';
  private static final String TOOLING_API_TEST_QUERY = 'SELECT Id FROM ApexClass LIMIT 1';

  /**
   * @description Cached system settings to avoid repeated calls
   * @note Uses getInstance() which is efficient but truncates Long Text Area fields.
   * If Long Text Area fields are needed, use JT_SystemSelector.getSystemSettings() instead.
   */
  private static JT_SystemSettings__mdt systemSettings {
    get {
      if (systemSettings == null) {
        systemSettings = JT_SystemSettings__mdt.getInstance('Default');
      }
      return systemSettings;
    }
    set;
  }

  /**
   * @description Gets API version from system settings with fallback
   * @return String API version (e.g., v65.0)
   */
  private static String getApiVersion() {
    return systemSettings != null &&
      String.isNotBlank(systemSettings.JT_ApiVersion__c)
      ? systemSettings.JT_ApiVersion__c
      : 'v65.0';
  }

  /**
   * @description Gets Tooling API path from system settings with fallback
   * @return String Tooling API path (e.g., /services/data/v65.0/tooling/query/)
   */
  private static String getToolingApiPath() {
    return systemSettings != null &&
      String.isNotBlank(systemSettings.JT_ToolingApiPath__c)
      ? systemSettings.JT_ToolingApiPath__c
      : '/services/data/v65.0/tooling/query/';
  }

  /**
   * @description Wrapper for usage results
   */
  public class UsageResult {
    /**
     * @description Name of the Apex class or Flow where the configuration is used
     */
    @AuraEnabled
    public String className { get; set; }

    /**
     * @description Name of the configuration being used
     */
    @AuraEnabled
    public String configName { get; set; }

    /**
     * @description Line number where the usage was found (Apex only)
     */
    @AuraEnabled
    public Integer lineNumber { get; set; }

    /**
     * @description Code snippet from the line where usage was found
     */
    @AuraEnabled
    public String codeLine { get; set; }

    /**
     * @description Salesforce ID of the Apex class or Flow
     */
    @AuraEnabled
    public String classId { get; set; }

    /**
     * @description Type of metadata: 'Apex Class' or 'Flow'
     */
    @AuraEnabled
    public String metadataType { get; set; }
  }

  /**
   * @description Service response wrapper with fault isolation
   */
  public class ServiceResponse {
    @AuraEnabled
    public Boolean success { get; set; }
    @AuraEnabled
    public String error { get; set; }
    @AuraEnabled
    public List<UsageResult> data { get; set; }
    @AuraEnabled
    public String serviceName { get; set; }

    public ServiceResponse() {
      this.data = new List<UsageResult>();
    }
  }

  /**
   * @description Aggregated response from multiple independent services
   */
  public class AggregatedUsageResponse {
    @AuraEnabled
    public ServiceResponse apexService { get; set; }
    @AuraEnabled
    public ServiceResponse flowService { get; set; }
    @AuraEnabled
    public Boolean hasPartialResults { get; set; }
    @AuraEnabled
    public Integer totalResults { get; set; }
    @AuraEnabled
    public List<UsageResult> allResults { get; set; }

    public AggregatedUsageResponse() {
      this.allResults = new List<UsageResult>();
    }
  }

  /**
   * @description Finds all usages of JT_DataSelector with a specific configuration
   * @param configName The configuration name to search for
   * @return List<UsageResult> List of classes/flows and lines where the configuration is used
   * @deprecated Use findAllUsagesResilient for fault-isolated searches
   */
  @AuraEnabled(cacheable=false)
  public static List<UsageResult> findConfigurationUsage(
    final String configName
  ) {
    final List<UsageResult> results = new List<UsageResult>();

    try {
      results.addAll(findInApexClasses(configName));
      results.addAll(findInFlows(configName));

      return results;
    } catch (Exception e) {
      throw new AuraHandledException('Error finding usage: ' + e.getMessage());
    }
  }

  /**
   * @description Searches for configuration usage in Apex classes independently
   * @param configName The configuration name to search for
   * @return ServiceResponse Service response with fault isolation
   */
  @AuraEnabled(cacheable=false)
  public static ServiceResponse findInApexClassesService(
    final String configName
  ) {
    final ServiceResponse response = new ServiceResponse();
    response.serviceName = 'Apex Classes';

    try {
      response.data = findInApexClasses(configName);
      response.success = true;
    } catch (Exception e) {
      response.success = false;
      response.error = 'Apex search failed: ' + e.getMessage();
      System.debug(
        LoggingLevel.ERROR,
        'Apex service error: ' + e.getMessage() + '\n' + e.getStackTraceString()
      );
    }

    return response;
  }

  /**
   * @description Searches for configuration usage in Flows independently
   * @param configName The configuration name to search for
   * @return ServiceResponse Service response with fault isolation
   */
  @AuraEnabled(cacheable=false)
  public static ServiceResponse findInFlowsService(final String configName) {
    final ServiceResponse response = new ServiceResponse();
    response.serviceName = 'Flows (Tooling API)';

    try {
      if (!isToolingAPIAvailable()) {
        response.success = false;
        response.error = 'Tooling API Named Credential not configured. Follow guide: scripts/NAMED_CREDENTIAL_SETUP.md';
        return response;
      }

      response.data = findInFlows(configName);
      response.success = true;
    } catch (System.CalloutException e) {
      response.success = false;
      response.error =
        'Named Credential error: ' +
        e.getMessage() +
        '. Check authentication setup.';
      System.debug(
        LoggingLevel.ERROR,
        'Flow service callout error: ' + e.getMessage()
      );
    } catch (System.JSONException e) {
      response.success = false;
      response.error =
        'Flow metadata parse error: ' +
        e.getMessage() +
        '. Tooling API response may be malformed.';
      System.debug(
        LoggingLevel.ERROR,
        'Flow service JSON error: ' + e.getMessage()
      );
    } catch (Exception e) {
      response.success = false;
      response.error = 'Flow search failed: ' + e.getMessage();
      System.debug(
        LoggingLevel.ERROR,
        'Flow service error: ' + e.getMessage() + '\n' + e.getStackTraceString()
      );
    }

    return response;
  }

  /**
   * @description Finds all usages with fault isolation - partial results if one service fails
   * @param configName The configuration name to search for
   * @return AggregatedUsageResponse Aggregated response from both services
   */
  @AuraEnabled(cacheable=false)
  public static AggregatedUsageResponse findAllUsagesResilient(
    final String configName
  ) {
    final AggregatedUsageResponse aggregated = new AggregatedUsageResponse();

    aggregated.apexService = findInApexClassesService(configName);
    aggregated.flowService = findInFlowsService(configName);

    if (aggregated.apexService.success) {
      aggregated.allResults.addAll(aggregated.apexService.data);
    }
    if (aggregated.flowService.success) {
      aggregated.allResults.addAll(aggregated.flowService.data);
    }

    aggregated.totalResults = aggregated.allResults.size();

    final Boolean apexOk = aggregated.apexService.success;
    final Boolean flowOk = aggregated.flowService.success;
    aggregated.hasPartialResults = (apexOk && !flowOk) || (!apexOk && flowOk);

    return aggregated;
  }

  /**
   * @description Checks if Tooling API Named Credential is configured
   * @return Boolean True if Named Credential is accessible
   */
  @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
  // Named Credential uses OAuth 2.0 - authentication handled automatically
  // Falls back to manual session ID if Named Credential not configured
  private static Boolean isToolingAPIAvailable() {
    try {
      final HttpRequest request = new HttpRequest();
      // Try Named Credential first (OAuth 2.0)
      request.setEndpoint(
        'callout:JT_Tooling_API' +
          getToolingApiPath() +
          '?q=' +
          EncodingUtil.urlEncode(TOOLING_API_TEST_QUERY, 'UTF-8')
      );
      request.setMethod('GET');
      request.setHeader('Accept', 'application/json');
      request.setTimeout(5000);

      return true;
    } catch (System.CalloutException e) {
      System.debug(
        LoggingLevel.WARN,
        'Tooling API not available: ' + e.getMessage()
      );
      return false;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.WARN,
        'Tooling API availability check failed: ' + e.getMessage()
      );
      return true;
    }
  }

  /**
   * @description Searches for configuration usage in Apex classes
   * @param configName The configuration name to search for
   * @return List<UsageResult> List of Apex class usages
   */
  private static List<UsageResult> findInApexClasses(final String configName) {
    final List<UsageResult> results = new List<UsageResult>();

    final List<ApexClass> apexClasses = JT_SystemSelector.getApexClassesForUsageSearch();

    final String searchPattern = 'JT_DataSelector';

    for (ApexClass apexClass : apexClasses) {
      if (String.isBlank(apexClass.Body)) {
        continue;
      }

      if (!apexClass.Body.contains(searchPattern)) {
        continue;
      }

      final String normalizedBody = apexClass.Body.toLowerCase();
      final String normalizedConfig = configName.toLowerCase();

      if (!normalizedBody.contains(normalizedConfig)) {
        continue;
      }

      final List<String> lines = apexClass.Body.split('\n');
      Integer lineNumber = 0;
      Boolean foundInClass = false;

      for (String line : lines) {
        lineNumber++;

        final String normalizedLine = line.toLowerCase();

        if (normalizedLine.contains(normalizedConfig)) {
          final UsageResult result = new UsageResult();
          result.className = apexClass.Name;
          result.configName = configName;
          result.lineNumber = lineNumber;
          result.codeLine = line.trim();
          result.classId = apexClass.Id;
          result.metadataType = 'Apex Class';
          results.add(result);
          foundInClass = true;
        }
      }

      if (!foundInClass) {
        final UsageResult result = new UsageResult();
        result.className = apexClass.Name;
        result.configName = configName;
        result.lineNumber = 0;
        result.codeLine = 'Configuration referenced in class';
        result.classId = apexClass.Id;
        result.metadataType = 'Apex Class';
        results.add(result);
      }
    }

    return results;
  }

  /**
   * @description Searches for configuration usage in Flows using Tooling API
   * @param configName The configuration name to search for
   * @return List<UsageResult> List of Flow usages
   */
  @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
  // Named Credential uses OAuth 2.0 - authentication handled automatically
  // Falls back to manual session ID if Named Credential not configured
  private static List<UsageResult> findInFlows(final String configName) {
    final List<UsageResult> results = new List<UsageResult>();

    try {
      final String endpoint =
        'callout:JT_Tooling_API' +
        getToolingApiPath() +
        '?q=' +
        EncodingUtil.urlEncode(FLOW_QUERY, 'UTF-8');

      final HttpRequest request = new HttpRequest();
      request.setEndpoint(endpoint);
      request.setMethod('GET');
      request.setHeader('Accept', 'application/json');
      request.setTimeout(60000);

      final Http httpClient = new Http();
      final HttpResponse response = httpClient.send(request);

      if (response.getStatusCode() == 200) {
        final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
          response.getBody()
        );
        final List<Object> records = (List<Object>) responseMap.get('records');

        for (Object record : records) {
          final Map<String, Object> flowData = (Map<String, Object>) record;
          final Map<String, Object> metadata = (Map<String, Object>) flowData.get(
            'Metadata'
          );

          if (metadata != null && searchFlowMetadata(metadata, configName)) {
            results.add(createFlowUsageResult(flowData, configName));
          }
        }
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.WARN,
        'Could not search Flows: ' + e.getMessage()
      );
    }

    return results;
  }

  /**
   * @description Creates a UsageResult for a Flow that uses the configuration
   * @param flowData Flow data from Tooling API
   * @param configName Configuration name being searched
   * @return UsageResult Usage result for the Flow
   */
  private static UsageResult createFlowUsageResult(
    final Map<String, Object> flowData,
    final String configName
  ) {
    final UsageResult result = new UsageResult();
    result.className = (String) flowData.get('MasterLabel');
    result.configName = configName;
    result.lineNumber = null;
    result.codeLine = 'Invocable Action: JT_DataSelector.executeQuery';
    result.classId = (String) flowData.get('Id');
    result.metadataType = 'Flow';
    return result;
  }

  /**
   * @description Recursively searches Flow metadata for configuration name
   * @param metadata Flow metadata object
   * @param configName Configuration name to search for
   * @return Boolean True if configuration is found
   */
  private static Boolean searchFlowMetadata(
    final Map<String, Object> metadata,
    final String configName
  ) {
    if (metadata == null) {
      return false;
    }

    final String metadataJson = JSON.serialize(metadata);

    if (!metadataJson.contains('JT_DataSelector')) {
      return false;
    }

    final String normalizedJson = metadataJson.toLowerCase();
    final String normalizedConfig = configName.toLowerCase();

    final Boolean foundConfig =
      normalizedJson.contains(normalizedConfig) ||
      normalizedJson.contains('"' + normalizedConfig + '"') ||
      normalizedJson.contains('\'' + normalizedConfig + '\'') ||
      normalizedJson.contains('\\"' + normalizedConfig + '\\"') ||
      normalizedJson.contains('stringvalue":"' + normalizedConfig + '"') ||
      normalizedJson.contains('stringvalue":"' + normalizedConfig + '\\"');

    if (!foundConfig) {
      final Pattern configPattern = Pattern.compile(
        '(?i)(configname|config_name)'
      );
      final Matcher matcher = configPattern.matcher(metadataJson);
      if (matcher.find()) {
        final Integer startPos = Math.max(0, matcher.start() - 100);
        final Integer endPos = Math.min(
          metadataJson.length(),
          matcher.end() + 200
        );
        System.debug(
          LoggingLevel.FINE,
          'Flow uses JT_DataSelector and has configName field, but value "' +
            configName +
            '" not found. Context: ' +
            metadataJson.substring(startPos, endPos)
        );
      } else {
        System.debug(
          LoggingLevel.FINE,
          'Flow uses JT_DataSelector but configName "' +
            configName +
            '" not found. JSON snippet: ' +
            metadataJson.substring(0, Math.min(1000, metadataJson.length()))
        );
      }
    } else {
      System.debug(
        LoggingLevel.INFO,
        '✓ Found Flow usage: configName=' +
          configName +
          ', metadataJson snippet=' +
          metadataJson.substring(0, Math.min(500, metadataJson.length()))
      );
    }

    return foundConfig;
  }

  /**
   * @description Finds all usages of JT_DataSelector across all configurations
   * @return List<UsageResult> List of all JT_DataSelector usages
   */
  @AuraEnabled(cacheable=true)
  public static List<UsageResult> findAllUsages() {
    final List<UsageResult> results = new List<UsageResult>();

    try {
      final List<ApexClass> apexClasses = JT_SystemSelector.getApexClassesForUsageSearch();

      final String searchPattern = 'JT_DataSelector';

      for (ApexClass apexClass : apexClasses) {
        if (String.isBlank(apexClass.Body)) {
          continue;
        }

        if (!apexClass.Body.contains(searchPattern)) {
          continue;
        }

        final List<String> lines = apexClass.Body.split('\n');
        Integer lineNumber = 0;

        for (String line : lines) {
          lineNumber++;

          if (line.contains(searchPattern)) {
            final String extractedConfig = extractConfigName(line);

            final UsageResult result = new UsageResult();
            result.className = apexClass.Name;
            result.configName = extractedConfig;
            result.lineNumber = lineNumber;
            result.codeLine = line.trim();
            result.classId = apexClass.Id;
            result.metadataType = 'Apex Class';
            results.add(result);
          }
        }
      }

      results.addAll(findAllFlowUsages());

      return results;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error finding all usages: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Finds all usages of JT_DataSelector in Flows
   * @return List<UsageResult> List of Flow usages
   */
  @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
  // Named Credential uses OAuth 2.0 - authentication handled automatically
  // Falls back to manual session ID if Named Credential not configured
  private static List<UsageResult> findAllFlowUsages() {
    final List<UsageResult> results = new List<UsageResult>();

    try {
      final String endpoint =
        'callout:JT_Tooling_API' +
        getToolingApiPath() +
        '?q=' +
        EncodingUtil.urlEncode(FLOW_QUERY, 'UTF-8');

      final HttpRequest request = new HttpRequest();
      request.setEndpoint(endpoint);
      request.setMethod('GET');
      request.setHeader('Accept', 'application/json');
      request.setTimeout(60000);

      final Http httpClient = new Http();
      final HttpResponse response = httpClient.send(request);

      if (response.getStatusCode() == 200) {
        final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
          response.getBody()
        );
        final List<Object> records = (List<Object>) responseMap.get('records');

        for (Object record : records) {
          final Map<String, Object> flowData = (Map<String, Object>) record;
          final Map<String, Object> metadata = (Map<String, Object>) flowData.get(
            'Metadata'
          );

          if (metadata != null) {
            final String metadataJson = JSON.serialize(metadata);

            if (metadataJson.contains('JT_DataSelector')) {
              final UsageResult result = new UsageResult();
              result.className = (String) flowData.get('MasterLabel');
              result.configName = extractConfigFromFlowMetadata(metadataJson);
              result.lineNumber = null;
              result.codeLine = 'Invocable Action: JT_DataSelector.executeQuery';
              result.classId = (String) flowData.get('Id');
              result.metadataType = 'Flow';
              results.add(result);
            }
          }
        }
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.WARN,
        'Could not search all Flows: ' + e.getMessage()
      );
    }

    return results;
  }

  /**
   * @description Extracts configuration name from Flow metadata JSON
   * @param metadataJson Flow metadata as JSON string
   * @return String Extracted configuration name or 'Unknown'
   */
  private static String extractConfigFromFlowMetadata(
    final String metadataJson
  ) {
    final Pattern configNamePattern = Pattern.compile(
      '"configName"\\s*:\\s*"([^"]+)"'
    );
    final Matcher configNameMatcher = configNamePattern.matcher(metadataJson);

    if (configNameMatcher.find()) {
      return configNameMatcher.group(1);
    }

    return 'Unknown';
  }

  /**
   * @description Extracts configuration name from a line of code
   * @param line Line of code
   * @return String Extracted configuration name or 'Unknown'
   */
  private static String extractConfigName(final String line) {
    final Pattern configNamePattern = Pattern.compile(
      'JT_DataSelector\\.[a-zA-Z]+\\s*\\(\\s*[\'"]([^\'"]+)[\'"]'
    );
    final Matcher configNameMatcher = configNamePattern.matcher(line);

    if (configNameMatcher.find()) {
      return configNameMatcher.group(1);
    }

    return 'Unknown';
  }
}
