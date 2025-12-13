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
  private static final Integer INITIAL_FLOWS_TO_CHECK = 30; // Process first 30 Flows in initial search (fast results)
  private static final Integer MAX_FLOWS_PER_BATCH = 30; // Process 30 Flows per batch when loading more
  private static final Integer MAX_FLOWS_WITHOUT_FILTER = 50; // If total Flows <= this, check all regardless of name match

  /**
   * @description Creates an HTTP request for Tooling API calls using API-enabled session ID
   * Delegates to JT_ToolingApiUtil for centralized session management
   * @param query The SOQL query string for Tooling API
   * @return HttpRequest Configured HTTP request with API session ID authentication
   */
  private static HttpRequest createToolingApiRequest(final String query) {
    return JT_ToolingApiUtil.createToolingApiQueryRequest(query);
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

    // Pagination metadata for Flows
    @AuraEnabled
    public Integer totalFlowsFound { get; set; }
    @AuraEnabled
    public Integer flowsProcessed { get; set; }
    @AuraEnabled
    public Boolean hasMoreFlows { get; set; }
    @AuraEnabled
    public List<String> pendingFlowIds { get; set; } // Flow IDs not yet processed

    public AggregatedUsageResponse() {
      this.allResults = new List<UsageResult>();
      this.totalFlowsFound = 0;
      this.flowsProcessed = 0;
      this.hasMoreFlows = false;
      this.pendingFlowIds = new List<String>();
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
  public static ServiceResponse findInFlowsService(final String configName) {
    final ServiceResponse response = new ServiceResponse();
    response.serviceName = 'Flows (Tooling API)';

    try {
      response.data = findInFlows(configName);
      response.success = true;
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
   * @description Finds all usages with fault isolation - each service runs independently
   * This method is designed for Queueable contexts where synchronous callouts are allowed
   * @param configName The configuration name to search for
   * @return AggregatedUsageResponse Aggregated results from all services with fault isolation
   */
  public static AggregatedUsageResponse findAllUsagesResilient(
    final String configName
  ) {
    final AggregatedUsageResponse aggregated = new AggregatedUsageResponse();

    // Run each service independently - failures in one don't affect others
    aggregated.apexService = findInApexClassesService(configName);
    aggregated.flowService = findInFlowsService(configName);

    // Aggregate results
    if (aggregated.apexService.success) {
      aggregated.allResults.addAll(aggregated.apexService.data);
    }
    if (aggregated.flowService.success) {
      aggregated.allResults.addAll(aggregated.flowService.data);
    }

    aggregated.totalResults = aggregated.allResults.size();

    // Determine if we have partial results (one service succeeded, one failed)
    final Boolean apexOk = aggregated.apexService.success;
    final Boolean flowOk = aggregated.flowService.success;
    aggregated.hasPartialResults = (apexOk && !flowOk) || (!apexOk && flowOk);

    return aggregated;
  }

  /**
   * @description Searches for configuration usage in Flows using Continuation
   * This uses Continuation to make async callout with API-enabled session
   * @param configName The configuration name to search for
   * @return Object Continuation or ServiceResponse
   */
  @AuraEnabled(continuation=true cacheable=false)
  public static Object findInFlowsWithContinuation(final String configName) {
    // Create continuation with 60 second timeout
    final Continuation cont = new Continuation(60);
    cont.continuationMethod = 'processFlowSearchCallback';
    cont.state = configName;

    // Create Tooling API request
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiQueryRequest(
      JT_SystemSelector.getActiveFlowsQuery()
    );

    // Add request to continuation
    final String requestLabel = cont.addHttpRequest(request);
    cont.state = JSON.serialize(
      new Map<String, String>{
        'configName' => configName,
        'requestLabel' => requestLabel
      }
    );

    return cont;
  }

  /**
   * @description Callback method for Flow search continuation
   * @param state State passed from continuation
   * @return ServiceResponse Service response with Flow search results
   */
  @AuraEnabled(cacheable=false)
  public static ServiceResponse processFlowSearchCallback(final Object state) {
    final ServiceResponse response = new ServiceResponse();
    response.serviceName = 'Flows (Tooling API)';

    try {
      // Parse state
      final Map<String, String> stateMap = (Map<String, String>) JSON.deserialize(
        (String) state,
        Map<String, String>.class
      );
      final String configName = stateMap.get('configName');
      final String requestLabel = stateMap.get('requestLabel');

      // Get response from continuation
      final HttpResponse httpResponse = Continuation.getResponse(requestLabel);

      if (httpResponse.getStatusCode() == 200) {
        // Parse and filter results
        final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
          httpResponse.getBody()
        );
        final List<Object> records = (List<Object>) responseMap.get('records');
        final List<UsageResult> results = new List<UsageResult>();

        for (Object record : records) {
          final Map<String, Object> flowData = (Map<String, Object>) record;
          final Map<String, Object> metadata = (Map<String, Object>) flowData.get(
            'Metadata'
          );

          if (metadata != null && searchFlowMetadata(metadata, configName)) {
            results.add(createFlowUsageResult(flowData, configName));
          }
        }

        response.data = results;
        response.success = true;
      } else {
        response.success = false;
        response.error =
          'Tooling API returned status ' +
          httpResponse.getStatusCode() +
          ': ' +
          httpResponse.getStatus();
        System.debug(
          LoggingLevel.ERROR,
          'Tooling API error: ' + httpResponse.getBody()
        );
      }
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
   * @description Finds all usages with fault isolation using Continuation for Flows
   * This is the main entry point called by LWC
   * @param configName The configuration name to search for
   * @return Object Continuation or AggregatedUsageResponse
   */
  @AuraEnabled(continuation=true cacheable=false)
  public static Object findAllUsagesWithContinuation(final String configName) {
    // First, get Apex class results synchronously (no callout needed)
    final ServiceResponse apexService = findInApexClassesService(configName);

    // Create continuation for Flow search
    final Continuation cont = new Continuation(60);
    cont.continuationMethod = 'processAllUsagesCallback';

    // Create Tooling API request for Flows with API-enabled session ID
    // Note: Can't query Metadata field with multiple records, so we get basic info first
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiQueryRequest(
      FLOW_LIST_QUERY
    );

    // Add request to continuation
    final String requestLabel = cont.addHttpRequest(request);

    // Store state - serialize apexService separately to avoid JSON serialization issues
    final Map<String, Object> stateMap = new Map<String, Object>{
      'configName' => configName,
      'requestLabel' => requestLabel,
      'apexServiceJson' => JSON.serialize(apexService)
    };
    cont.state = JSON.serialize(stateMap);

    return cont;
  }

  /**
   * @description Callback method for aggregated usage search
   * Returns JSON string to avoid Apex serialization issues
   * @param state State passed from continuation
   * @return String JSON serialized AggregatedUsageResponse
   */
  @AuraEnabled(cacheable=false)
  public static String processAllUsagesCallback(final Object state) {
    final AggregatedUsageResponse aggregated = new AggregatedUsageResponse();

    try {
      final Map<String, Object> stateMap = (Map<String, Object>) JSON.deserializeUntyped(
        (String) state
      );
      final String configName = (String) stateMap.get('configName');
      final String requestLabel = (String) stateMap.get('requestLabel');

      // Restore Apex results from state
      aggregated.apexService = (ServiceResponse) JSON.deserialize(
        (String) stateMap.get('apexServiceJson'),
        ServiceResponse.class
      );

      // Process Flow search response
      final HttpResponse httpResponse = Continuation.getResponse(requestLabel);
      aggregated.flowService = processFlowSearchResponse(
        httpResponse,
        configName,
        aggregated
      );

      // Aggregate results from both services
      aggregateAllResults(aggregated);
    } catch (Exception e) {
      handleCallbackError(e, aggregated);
    }

    return JSON.serialize(aggregated);
  }

  /**
   * @description Processes the Tooling API response for Flow search
   * @param httpResponse HTTP response from Tooling API
   * @param configName Configuration name to search for
   * @param aggregated Aggregated response to update with pagination metadata
   * @return ServiceResponse Flow service response
   */
  private static ServiceResponse processFlowSearchResponse(
    final HttpResponse httpResponse,
    final String configName,
    final AggregatedUsageResponse aggregated
  ) {
    final ServiceResponse flowService = new ServiceResponse();
    flowService.serviceName = 'Flows (Tooling API)';

    if (httpResponse.getStatusCode() != 200) {
      flowService.success = false;
      flowService.error =
        'Tooling API returned status ' + httpResponse.getStatusCode();
      System.debug(
        LoggingLevel.ERROR,
        'Tooling API error: ' + httpResponse.getBody()
      );
      return flowService;
    }

    try {
      final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
        httpResponse.getBody()
      );
      final List<Object> records = (List<Object>) responseMap.get('records');

      // Select candidate Flows based on org size and name matching
      final FlowCandidateResult candidateResult = selectCandidateFlows(
        records,
        configName
      );

      // Update pagination metadata
      updatePaginationMetadata(aggregated, candidateResult, records);

      // Process candidates to find actual usage
      flowService.data = processFlowCandidates(
        candidateResult.candidates,
        configName
      );
      flowService.success = true;
    } catch (Exception e) {
      flowService.success = false;
      flowService.error = 'Flow search failed: ' + e.getMessage();
      System.debug(
        LoggingLevel.ERROR,
        'Flow processing error: ' +
          e.getMessage() +
          '\n' +
          e.getStackTraceString()
      );
    }

    return flowService;
  }

  /**
   * @description Result wrapper for candidate Flow selection
   */
  private class FlowCandidateResult {
    List<Map<String, Object>> candidates;
    Set<String> candidateIds;
    Integer totalRecords;

    FlowCandidateResult(
      final List<Map<String, Object>> candidates,
      final Set<String> candidateIds,
      final Integer totalRecords
    ) {
      this.candidates = candidates;
      this.candidateIds = candidateIds;
      this.totalRecords = totalRecords;
    }
  }

  /**
   * @description Selects candidate Flows based on org size and name matching
   * @param records All Flow records from Tooling API
   * @param configName Configuration name to search for
   * @return FlowCandidateResult Candidate Flows and metadata
   */
  private static FlowCandidateResult selectCandidateFlows(
    final List<Object> records,
    final String configName
  ) {
    final List<Map<String, Object>> candidates = new List<Map<String, Object>>();
    final Set<String> candidateIds = new Set<String>();

    // Small org: check all Flows
    if (records.size() <= MAX_FLOWS_WITHOUT_FILTER) {
      System.debug(
        LoggingLevel.INFO,
        'Small org (' +
          records.size() +
          ' Flows): checking all for "' +
          configName +
          '"'
      );
      addAllValidFlows(records, candidates, candidateIds);
      return new FlowCandidateResult(candidates, candidateIds, records.size());
    }

    // Large org: filter by name first, then fallback to first N
    System.debug(
      LoggingLevel.INFO,
      'Large org (' + records.size() + ' Flows): filtering by name'
    );

    final String normalizedConfigName = configName.toLowerCase();
    addNameMatchedFlows(
      records,
      normalizedConfigName,
      candidates,
      candidateIds
    );

    // If no name matches, check first N Flows
    if (candidates.isEmpty()) {
      System.debug(
        LoggingLevel.INFO,
        'No name matches - checking first ' + INITIAL_FLOWS_TO_CHECK + ' Flows'
      );
      addFirstNFlows(records, INITIAL_FLOWS_TO_CHECK, candidates, candidateIds);
    }

    return new FlowCandidateResult(candidates, candidateIds, records.size());
  }

  /**
   * @description Adds all valid Flows (non-null with ID) to candidates
   */
  private static void addAllValidFlows(
    final List<Object> records,
    final List<Map<String, Object>> candidates,
    final Set<String> candidateIds
  ) {
    for (Object record : records) {
      final Map<String, Object> flowData = (Map<String, Object>) record;
      final String flowId = (String) flowData?.get('Id');
      if (flowId != null) {
        candidates.add(flowData);
        candidateIds.add(flowId);
      }
    }
    System.debug(
      LoggingLevel.INFO,
      'Added ' + candidates.size() + ' candidate Flows'
    );
  }

  /**
   * @description Adds Flows whose MasterLabel contains the config name
   */
  private static void addNameMatchedFlows(
    final List<Object> records,
    final String normalizedConfigName,
    final List<Map<String, Object>> candidates,
    final Set<String> candidateIds
  ) {
    for (Object record : records) {
      final Map<String, Object> flowData = (Map<String, Object>) record;
      final String masterLabel = (String) flowData?.get('MasterLabel');
      final String flowId = (String) flowData?.get('Id');

      if (
        masterLabel != null &&
        flowId != null &&
        masterLabel.toLowerCase().contains(normalizedConfigName)
      ) {
        candidates.add(flowData);
        candidateIds.add(flowId);
      }
    }
    if (!candidates.isEmpty()) {
      System.debug(
        LoggingLevel.INFO,
        'Found ' + candidates.size() + ' Flows with matching names'
      );
    }
  }

  /**
   * @description Adds first N Flows to candidates
   */
  private static void addFirstNFlows(
    final List<Object> records,
    final Integer maxFlows,
    final List<Map<String, Object>> candidates,
    final Set<String> candidateIds
  ) {
    final Integer flowsToCheck = Math.min(records.size(), maxFlows);
    for (Integer i = 0; i < flowsToCheck; i++) {
      final Map<String, Object> flowData = (Map<String, Object>) records[i];
      final String flowId = (String) flowData?.get('Id');
      if (flowId != null) {
        candidates.add(flowData);
        candidateIds.add(flowId);
      }
    }
  }

  /**
   * @description Updates pagination metadata in aggregated response
   */
  private static void updatePaginationMetadata(
    final AggregatedUsageResponse aggregated,
    final FlowCandidateResult candidateResult,
    final List<Object> allRecords
  ) {
    aggregated.totalFlowsFound = candidateResult.totalRecords;
    aggregated.flowsProcessed = candidateResult.candidates.size();

    // Store pending Flow IDs for pagination (Flows not yet checked)
    for (Object record : allRecords) {
      final Map<String, Object> flowData = (Map<String, Object>) record;
      final String flowId = (String) flowData?.get('Id');
      if (flowId != null && !candidateResult.candidateIds.contains(flowId)) {
        aggregated.pendingFlowIds.add(flowId);
      }
    }

    aggregated.hasMoreFlows = !aggregated.pendingFlowIds.isEmpty();

    System.debug(
      LoggingLevel.INFO,
      'Pagination: ' +
        aggregated.flowsProcessed +
        '/' +
        aggregated.totalFlowsFound +
        ' processed, ' +
        aggregated.pendingFlowIds.size() +
        ' pending'
    );
  }

  /**
   * @description Processes candidate Flows to find actual usage
   * @param candidates Candidate Flows to check
   * @param configName Configuration name to search for
   * @return List<UsageResult> Usage results
   */
  private static List<UsageResult> processFlowCandidates(
    final List<Map<String, Object>> candidates,
    final String configName
  ) {
    final List<UsageResult> results = new List<UsageResult>();
    final String sessionId = JT_ToolingApiUtil.getApiSessionId();

    System.debug(
      LoggingLevel.INFO,
      'Processing ' +
        candidates.size() +
        ' candidate Flows for config: ' +
        configName
    );

    Integer flowsChecked = 0;
    for (Map<String, Object> flowData : candidates) {
      final String flowId = (String) flowData.get('Id');
      final String flowName = (String) flowData.get('MasterLabel');
      flowsChecked++;

      try {
        System.debug(
          LoggingLevel.FINE,
          'Checking Flow [' +
            flowsChecked +
            '/' +
            candidates.size() +
            ']: ' +
            flowName +
            ' (ID: ' +
            flowId +
            ')'
        );

        if (checkFlowUsesConfig(flowId, configName, sessionId)) {
          results.add(createFlowUsageResult(flowData, configName));
          System.debug(
            LoggingLevel.INFO,
            '✓ Found usage in Flow: ' + flowName + ' (ID: ' + flowId + ')'
          );
        }
      } catch (Exception e) {
        System.debug(
          LoggingLevel.WARN,
          'Error checking Flow ' + flowName + ': ' + e.getMessage()
        );
      }
    }

    System.debug(
      LoggingLevel.INFO,
      'Flow search complete: Found ' + results.size() + ' Flows with usage'
    );

    return results;
  }

  /**
   * @description Aggregates results from all services
   */
  private static void aggregateAllResults(
    final AggregatedUsageResponse aggregated
  ) {
    if (aggregated.apexService?.success == true) {
      aggregated.allResults.addAll(aggregated.apexService.data);
    }
    if (aggregated.flowService?.success == true) {
      aggregated.allResults.addAll(aggregated.flowService.data);
    }

    aggregated.totalResults = aggregated.allResults.size();

    final Boolean apexOk = aggregated.apexService?.success == true;
    final Boolean flowOk = aggregated.flowService?.success == true;
    aggregated.hasPartialResults = (apexOk != flowOk);
  }

  /**
   * @description Handles errors in continuation callback
   */
  private static void handleCallbackError(
    final Exception e,
    final AggregatedUsageResponse aggregated
  ) {
    System.debug(
      LoggingLevel.ERROR,
      'Error in continuation callback: ' +
        e.getMessage() +
        '\n' +
        e.getStackTraceString()
    );

    if (aggregated.flowService == null) {
      aggregated.flowService = new ServiceResponse();
      aggregated.flowService.serviceName = 'Flows (Tooling API)';
    }
    aggregated.flowService.success = false;
    aggregated.flowService.error = 'Flow search failed: ' + e.getMessage();
    aggregated.hasPartialResults = true;
  }

  /**
   * @description Checks if Tooling API is available using direct session ID
   * @return Boolean True if Tooling API is accessible
   */
  private static Boolean isToolingAPIAvailable() {
    try {
      final HttpRequest request = createToolingApiRequest(
        JT_SystemSelector.getToolingApiTestQuery()
      );
      request.setTimeout(5000);
      final HttpResponse response = new Http().send(request);
      return response.getStatusCode() == 200;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.WARN,
        'Tooling API not available: ' + e.getMessage()
      );
      return false;
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
    final String normalizedConfig = configName.toLowerCase();

    for (ApexClass apexClass : apexClasses) {
      // Skip if class has no body or doesn't use JT_DataSelector
      if (
        String.isBlank(apexClass.Body) ||
        !apexClass.Body.contains('JT_DataSelector')
      ) {
        continue;
      }

      // Skip if config name not found in class
      if (!apexClass.Body.toLowerCase().contains(normalizedConfig)) {
        continue;
      }

      // Find specific lines containing the config
      results.addAll(
        findConfigInClassLines(apexClass, configName, normalizedConfig)
      );
    }

    return results;
  }

  /**
   * @description Finds specific lines in an Apex class that reference the config
   * @param apexClass Apex class to search
   * @param configName Original config name
   * @param normalizedConfig Lowercase config name
   * @return List<UsageResult> Usage results for this class
   */
  private static List<UsageResult> findConfigInClassLines(
    final ApexClass apexClass,
    final String configName,
    final String normalizedConfig
  ) {
    final List<UsageResult> results = new List<UsageResult>();
    final List<String> lines = apexClass.Body.split('\n');
    Integer lineNumber = 0;
    Boolean foundInClass = false;

    for (String line : lines) {
      lineNumber++;

      if (line.toLowerCase().contains(normalizedConfig)) {
        results.add(
          createApexUsageResult(apexClass, configName, lineNumber, line.trim())
        );
        foundInClass = true;
      }
    }

    // If config referenced but no specific line found, add generic result
    if (!foundInClass) {
      results.add(
        createApexUsageResult(
          apexClass,
          configName,
          0,
          'Configuration referenced in class'
        )
      );
    }

    return results;
  }

  /**
   * @description Creates a UsageResult for an Apex class
   */
  private static UsageResult createApexUsageResult(
    final ApexClass apexClass,
    final String configName,
    final Integer lineNumber,
    final String codeLine
  ) {
    final UsageResult result = new UsageResult();
    result.className = apexClass.Name;
    result.configName = configName;
    result.lineNumber = lineNumber;
    result.codeLine = codeLine;
    result.classId = apexClass.Id;
    result.metadataType = 'Apex Class';
    return result;
  }

  /**
   * @description Searches for configuration usage in Flows using Tooling API
   * @param configName The configuration name to search for
   * @return List<UsageResult> List of Flow usages
   */
  private static List<UsageResult> findInFlows(final String configName) {
    try {
      final HttpRequest request = createToolingApiRequest(FLOW_LIST_QUERY);
      final HttpResponse response = new Http().send(request);

      if (response.getStatusCode() != 200) {
        return new List<UsageResult>();
      }

      final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
        response.getBody()
      );
      final List<Object> records = (List<Object>) responseMap?.get('records');

      if (records == null) {
        return new List<UsageResult>();
      }

      return findFlowUsagesInRecords(records, configName);
    } catch (Exception e) {
      System.debug(
        LoggingLevel.WARN,
        'Could not search Flows: ' + e.getMessage()
      );
      return new List<UsageResult>();
    }
  }

  /**
   * @description Finds Flow usages within a list of Flow records
   */
  private static List<UsageResult> findFlowUsagesInRecords(
    final List<Object> records,
    final String configName
  ) {
    final List<UsageResult> results = new List<UsageResult>();

    for (Object record : records) {
      final Map<String, Object> flowData = (Map<String, Object>) record;
      final Map<String, Object> metadata = (Map<String, Object>) flowData
        ?.get('Metadata');

      if (metadata != null && searchFlowMetadata(metadata, configName)) {
        results.add(createFlowUsageResult(flowData, configName));
      }
    }

    return results;
  }

  /**
   * @description Checks if a single Flow uses the configuration
   * Queries individual Flow to get Metadata field
   * @param flowId Flow ID
   * @param configName Configuration name
   * @param sessionId API-enabled session ID
   * @return Boolean True if Flow uses the configuration
   */
  private static Boolean checkFlowUsesConfig(
    final String flowId,
    final String configName,
    final String sessionId
  ) {
    try {
      // Build query using SystemSelector pattern (but Tooling API requires string query)
      final String query =
        'SELECT Id, Metadata FROM Flow WHERE Id = \'' +
        String.escapeSingleQuotes(flowId) +
        '\'';
      final HttpRequest request = JT_ToolingApiUtil.createToolingApiQueryRequest(
        query,
        5000
      );

      final HttpResponse response = new Http().send(request);

      if (response.getStatusCode() != 200) {
        return false;
      }

      final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
        response.getBody()
      );
      final List<Object> records = (List<Object>) responseMap?.get('records');

      if (records == null || records.isEmpty()) {
        return false;
      }

      final Map<String, Object> flowData = (Map<String, Object>) records[0];
      final Map<String, Object> metadata = (Map<String, Object>) flowData
        ?.get('Metadata');

      return metadata != null && searchFlowMetadata(metadata, configName);
    } catch (Exception e) {
      System.debug(
        LoggingLevel.WARN,
        'Could not check Flow ' + flowId + ': ' + e.getMessage()
      );
      return false;
    }
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

    // Quick check: does Flow use JT_DataSelector at all?
    if (!metadataJson.contains('JT_DataSelector')) {
      return false;
    }

    final String normalizedJson = metadataJson.toLowerCase();
    final String normalizedConfig = configName.toLowerCase();

    // Check if config name appears in various JSON formats
    final Boolean foundConfig =
      normalizedJson.contains(normalizedConfig) ||
      normalizedJson.contains('"' + normalizedConfig + '"') ||
      normalizedJson.contains('\'' + normalizedConfig + '\'') ||
      normalizedJson.contains('\\"' + normalizedConfig + '\\"') ||
      normalizedJson.contains('stringvalue":"' + normalizedConfig + '"') ||
      normalizedJson.contains('stringvalue":"' + normalizedConfig + '\\"');

    // Debug logging only when needed
    if (foundConfig) {
      System.debug(
        LoggingLevel.INFO,
        '✓ Found Flow usage: configName="' + configName + '" in metadata'
      );
    } else {
      System.debug(
        LoggingLevel.FINE,
        'Config "' + configName + '" not found in Flow metadata'
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
   * Uses UserInfo.getSessionId() directly instead of Named Credential
   * because same-org Tooling API calls via OAuth Named Credential fail with proxy errors (500)
   * @return List<UsageResult> List of Flow usages
   */
  private static List<UsageResult> findAllFlowUsages() {
    final List<UsageResult> results = new List<UsageResult>();

    try {
      final HttpRequest request = createToolingApiRequest(FLOW_LIST_QUERY);
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
