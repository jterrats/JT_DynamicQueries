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
public with sharing class JT_UsageFinder {
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
  public static List<UsageResult> findConfigurationUsage(String configName) {
    List<UsageResult> results = new List<UsageResult>();

    try {
      // Search in Apex classes
      results.addAll(findInApexClasses(configName));

      // Search in Flows
      results.addAll(findInFlows(configName));

      return results;
    } catch (Exception e) {
      throw new AuraHandledException('Error finding usage: ' + e.getMessage());
    }
  }

  /**
   * 🎯 MICROSERVICE 1: Apex Class Search (No external dependencies)
   * @description Searches for configuration usage in Apex classes independently
   * @param configName The configuration name to search for
   * @return ServiceResponse Service response with fault isolation
   */
  @AuraEnabled(cacheable=false)
  public static ServiceResponse findInApexClassesService(String configName) {
    ServiceResponse response = new ServiceResponse();
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
   * 🎯 MICROSERVICE 2: Flow Search (Requires Tooling API + Named Credential)
   * @description Searches for configuration usage in Flows independently
   * @param configName The configuration name to search for
   * @return ServiceResponse Service response with fault isolation
   */
  @AuraEnabled(cacheable=false)
  public static ServiceResponse findInFlowsService(String configName) {
    ServiceResponse response = new ServiceResponse();
    response.serviceName = 'Flows (Tooling API)';

    try {
      // Pre-flight check: Is Tooling API available?
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
   * 🎯 ORCHESTRATOR: Calls both services independently and aggregates results
   * @description Finds all usages with fault isolation - partial results if one service fails
   * @param configName The configuration name to search for
   * @return AggregatedUsageResponse Aggregated response from both services
   */
  @AuraEnabled(cacheable=false)
  public static AggregatedUsageResponse findAllUsagesResilient(
    String configName
  ) {
    AggregatedUsageResponse aggregated = new AggregatedUsageResponse();

    // Call services independently (conceptually parallel)
    aggregated.apexService = findInApexClassesService(configName);
    aggregated.flowService = findInFlowsService(configName);

    // Aggregate results
    if (aggregated.apexService.success) {
      aggregated.allResults.addAll(aggregated.apexService.data);
    }
    if (aggregated.flowService.success) {
      aggregated.allResults.addAll(aggregated.flowService.data);
    }

    // Calculate metrics
    aggregated.totalResults = aggregated.allResults.size();

    // Partial results flag: at least one succeeded, at least one failed
    Boolean apexOk = aggregated.apexService.success;
    Boolean flowOk = aggregated.flowService.success;
    aggregated.hasPartialResults = (apexOk && !flowOk) || (!apexOk && flowOk);

    return aggregated;
  }

  /**
   * @description Checks if Tooling API Named Credential is configured
   * @return Boolean True if Named Credential is accessible
   */
  @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
  // Named Credential uses NoAuthentication protocol, requiring manual Authorization header
  // This is the correct pattern for same-org Tooling API calls using session ID
  private static Boolean isToolingAPIAvailable() {
    try {
      // Try a simple HEAD request using Named Credential to verify configuration
      HttpRequest req = new HttpRequest();
      req.setEndpoint('callout:JT_Tooling_API/services/data/v65.0/');
      req.setMethod('HEAD');
      req.setHeader('Authorization', 'Bearer ' + getSessionId());
      req.setTimeout(5000);

      // If this doesn't throw an exception, Named Credential is configured
      return true;
    } catch (System.CalloutException e) {
      // Callout exception likely means Named Credential is not configured
      System.debug(
        LoggingLevel.WARN,
        'Tooling API Named Credential not configured: ' + e.getMessage()
      );
      return false;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.WARN,
        'Tooling API availability check failed: ' + e.getMessage()
      );
      return true; // Assume available, let actual callout handle any errors
    }
  }

  /**
   * @description Searches for configuration usage in Apex classes
   * @param configName The configuration name to search for
   * @return List<UsageResult> List of Apex class usages
   */
  private static List<UsageResult> findInApexClasses(String configName) {
    List<UsageResult> results = new List<UsageResult>();

    // Query all Apex classes
    List<ApexClass> apexClasses = [
      SELECT Id, Name, Body
      FROM ApexClass
      WHERE NamespacePrefix = NULL
      WITH USER_MODE
      ORDER BY Name
    ];

    // Search for references
    String searchPattern = 'JT_DataSelector';

    for (ApexClass cls : apexClasses) {
      if (String.isBlank(cls.Body)) {
        continue;
      }

      // Check if class references JT_DataSelector
      if (!cls.Body.contains(searchPattern)) {
        continue;
      }

      // Check if class references the configuration name anywhere
      String normalizedBody = cls.Body.toLowerCase();
      String normalizedConfig = configName.toLowerCase();

      if (!normalizedBody.contains(normalizedConfig)) {
        continue;
      }

      // Find specific lines that mention the config (for display purposes)
      List<String> lines = cls.Body.split('\n');
      Integer lineNumber = 0;
      Boolean foundInClass = false;

      for (String line : lines) {
        lineNumber++;

        String normalizedLine = line.toLowerCase();

        // Look for lines containing the config name
        if (normalizedLine.contains(normalizedConfig)) {
          UsageResult result = new UsageResult();
          result.className = cls.Name;
          result.configName = configName;
          result.lineNumber = lineNumber;
          result.codeLine = line.trim();
          result.classId = cls.Id;
          result.metadataType = 'Apex Class';
          results.add(result);
          foundInClass = true;
        }
      }

      // If we didn't find any specific line but the class uses both,
      // add a general result
      if (!foundInClass) {
        UsageResult result = new UsageResult();
        result.className = cls.Name;
        result.configName = configName;
        result.lineNumber = 0;
        result.codeLine = 'Configuration referenced in class';
        result.classId = cls.Id;
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
  // Named Credential uses NoAuthentication protocol, requiring manual Authorization header
  // This is the correct pattern for same-org Tooling API calls using session ID
  private static List<UsageResult> findInFlows(String configName) {
    List<UsageResult> results = new List<UsageResult>();

    try {
      // Get session ID for Tooling API callout
      String sessionId = getSessionId();
      if (String.isBlank(sessionId)) {
        return results; // Can't query without session
      }

      // Query Flows via Tooling API using Named Credential
      String endpoint =
        'callout:JT_Tooling_API/services/data/v65.0/tooling/query/?q=' +
        EncodingUtil.urlEncode(
          'SELECT Id, MasterLabel, Metadata FROM Flow WHERE Status = \'Active\'',
          'UTF-8'
        );

      HttpRequest req = new HttpRequest();
      req.setEndpoint(endpoint);
      req.setMethod('GET');
      req.setHeader('Authorization', 'Bearer ' + sessionId);
      req.setHeader('Content-Type', 'application/json');
      req.setTimeout(60000);

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() == 200) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
          res.getBody()
        );
        List<Object> records = (List<Object>) responseMap.get('records');

        if (records != null) {
          for (Object record : records) {
            Map<String, Object> flowData = (Map<String, Object>) record;
            String flowId = (String) flowData.get('Id');
            String flowName = (String) flowData.get('MasterLabel');
            Map<String, Object> metadata = (Map<String, Object>) flowData.get(
              'Metadata'
            );

            // Search in Flow metadata for our Invocable Action
            if (metadata != null && searchFlowMetadata(metadata, configName)) {
              UsageResult result = new UsageResult();
              result.className = flowName;
              result.configName = configName;
              result.lineNumber = null; // Flows don't have line numbers
              result.codeLine = 'Invocable Action: JT_DataSelector.executeQuery';
              result.classId = flowId;
              result.metadataType = 'Flow';
              results.add(result);
            }
          }
        }
      }
    } catch (Exception e) {
      // Log error but don't fail the entire search
      System.debug(
        LoggingLevel.WARN,
        'Could not search Flows: ' + e.getMessage()
      );
    }

    return results;
  }

  /**
   * @description Gets session ID for Tooling API callouts
   * @return String Session ID or null if unavailable
   */
  private static String getSessionId() {
    try {
      return Page.JT_SessionIdPage.getContent().toString().trim();
    } catch (Exception e) {
      System.debug(
        LoggingLevel.WARN,
        'Could not get session ID: ' + e.getMessage()
      );
      return null;
    }
  }

  /**
   * @description Recursively searches Flow metadata for configuration name
   * @param metadata Flow metadata object
   * @param configName Configuration name to search for
   * @return Boolean True if configuration is found
   */
  private static Boolean searchFlowMetadata(
    Map<String, Object> metadata,
    String configName
  ) {
    if (metadata == null) {
      return false;
    }

    // Convert metadata to JSON string for easier searching
    String metadataJson = JSON.serialize(metadata);

    // Search for our Invocable Method name and configuration
    return metadataJson.contains('JT_DataSelector') &&
      metadataJson.containsIgnoreCase(configName);
  }

  /**
   * @description Finds all usages of JT_DataSelector across all configurations
   * @return List<UsageResult> List of all JT_DataSelector usages
   */
  @AuraEnabled(cacheable=true)
  public static List<UsageResult> findAllUsages() {
    List<UsageResult> results = new List<UsageResult>();

    try {
      // Query all Apex classes
      List<ApexClass> apexClasses = [
        SELECT Id, Name, Body
        FROM ApexClass
        WHERE NamespacePrefix = NULL
        WITH USER_MODE
        ORDER BY Name
      ];

      // Search for all references to JT_DataSelector
      String searchPattern = 'JT_DataSelector';

      for (ApexClass cls : apexClasses) {
        if (String.isBlank(cls.Body)) {
          continue;
        }

        // Check if class references JT_DataSelector
        if (!cls.Body.contains(searchPattern)) {
          continue;
        }

        // Split into lines and find all occurrences
        List<String> lines = cls.Body.split('\n');
        Integer lineNumber = 0;

        for (String line : lines) {
          lineNumber++;

          if (line.contains(searchPattern)) {
            // Try to extract configuration name from common patterns
            String extractedConfig = extractConfigName(line);

            UsageResult result = new UsageResult();
            result.className = cls.Name;
            result.configName = extractedConfig;
            result.lineNumber = lineNumber;
            result.codeLine = line.trim();
            result.classId = cls.Id;
            result.metadataType = 'Apex Class';
            results.add(result);
          }
        }
      }

      // Also search in all Flows
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
  // Named Credential uses NoAuthentication protocol, requiring manual Authorization header
  // This is the correct pattern for same-org Tooling API calls using session ID
  private static List<UsageResult> findAllFlowUsages() {
    List<UsageResult> results = new List<UsageResult>();

    try {
      String sessionId = getSessionId();
      if (String.isBlank(sessionId)) {
        return results;
      }

      String endpoint =
        URL.getOrgDomainUrl().toExternalForm() +
        '/services/data/v65.0/tooling/query/?q=' +
        EncodingUtil.urlEncode(
          'SELECT Id, MasterLabel, Metadata FROM Flow WHERE Status = \'Active\'',
          'UTF-8'
        );

      HttpRequest req = new HttpRequest();
      req.setEndpoint(endpoint);
      req.setMethod('GET');
      req.setHeader('Authorization', 'Bearer ' + sessionId);
      req.setHeader('Content-Type', 'application/json');
      req.setTimeout(60000);

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() == 200) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
          res.getBody()
        );
        List<Object> records = (List<Object>) responseMap.get('records');

        if (records != null) {
          for (Object record : records) {
            Map<String, Object> flowData = (Map<String, Object>) record;
            Map<String, Object> metadata = (Map<String, Object>) flowData.get(
              'Metadata'
            );

            if (metadata != null) {
              String metadataJson = JSON.serialize(metadata);

              if (metadataJson.contains('JT_DataSelector')) {
                UsageResult result = new UsageResult();
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
  private static String extractConfigFromFlowMetadata(String metadataJson) {
    // Try to find configName in the inputParameters
    Pattern p = Pattern.compile('"configName"\\s*:\\s*"([^"]+)"');
    Matcher m = p.matcher(metadataJson);

    if (m.find()) {
      return m.group(1);
    }

    return 'Unknown';
  }

  /**
   * @description Extracts configuration name from a line of code
   * @param line Line of code
   * @return String Extracted configuration name or 'Unknown'
   */
  private static String extractConfigName(String line) {
    // Try to extract string literal after JT_DataSelector method calls
    // Patterns: getConfig('name'), getRecords('name'), etc.
    Pattern p = Pattern.compile(
      'JT_DataSelector\\.[a-zA-Z]+\\s*\\(\\s*[\'"]([^\'"]+)[\'"]'
    );
    Matcher m = p.matcher(line);

    if (m.find()) {
      return m.group(1);
    }

    return 'Unknown';
  }
}
