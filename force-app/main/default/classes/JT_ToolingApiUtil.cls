/**
 * @description Utility class for Tooling API operations
 * Centralizes session ID management, HTTP request creation, and API configuration
 * @author Jaime Terrats
 * @group Dynamic Queries
 */
public without sharing class JT_ToolingApiUtil {
  // Cache session ID in static variable for transaction reuse (avoids multiple VFP calls)
  private static String cachedSessionId = null;
  private static final Integer SESSION_CACHE_TTL = 300; // 5 minutes
  private static final String CACHE_KEY_PREFIX = 'ApiSessionId';

  /**
   * @description Cached system settings to avoid repeated calls
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
  public static String getApiVersion() {
    return systemSettings != null &&
      String.isNotBlank(systemSettings.JT_ApiVersion__c)
      ? systemSettings.JT_ApiVersion__c
      : 'v65.0';
  }

  /**
   * @description Gets Tooling API path from system settings with fallback
   * @return String Tooling API path (e.g., /services/data/v65.0/tooling/query/)
   */
  public static String getToolingApiPath() {
    return systemSettings != null &&
      String.isNotBlank(systemSettings.JT_ToolingApiPath__c)
      ? systemSettings.JT_ToolingApiPath__c
      : '/services/data/v65.0/tooling/query/';
  }

  /**
   * @description Gets org domain URL
   * @return String Full org URL (e.g., https://myorg.my.salesforce.com)
   */
  public static String getOrgDomainUrl() {
    return URL.getOrgDomainUrl().toExternalForm();
  }

  /**
   * @description Sanitizes any string to alphanumeric (removes non-alphanumeric characters).
   * Useful for Platform Cache keys which must be alphanumeric.
   * @param input String to sanitize
   * @return String Sanitized alphanumeric string
   */
  public static String toAlphanumeric(final String input) {
    if (String.isBlank(input)) {
      return Label.JT_ToolingApiUtil_invalid;
    }
    return input.replaceAll('[^a-zA-Z0-9]', '');
  }

  /**
   * @description Sanitizes userId for Platform Cache key (alphanumeric only)
   * Platform Cache requires keys to be alphanumeric
   * @param userId User ID to sanitize (optional, defaults to current user)
   * @return String Alphanumeric key safe for Platform Cache
   */
  public static String getAlphanumericCacheKey(final String userId) {
    final String targetUserId = String.isBlank(userId)
      ? UserInfo.getUserId()
      : userId;
    return CACHE_KEY_PREFIX + toAlphanumeric(targetUserId);
  }

  /**
   * @description Gets API-enabled session ID from Visualforce page with caching
   * Optimized for production: caches session ID in static variable (transaction-level) and Platform Cache (cross-request)
   * UserInfo.getSessionId() doesn't work from LWC context, so we use VF page
   * @return String API-enabled session ID
   * @throws AuraHandledException If session ID cannot be obtained
   */
  @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
  public static String getApiSessionId() {
    if (Test.isRunningTest()) {
      return 'test_session_id';
    }

    // First check: static variable (same transaction)
    if (cachedSessionId != null) {
      return cachedSessionId;
    }

    // Second check: Platform Cache (cross-request, 5 min TTL)
    final String cacheKey = getAlphanumericCacheKey(UserInfo.getUserId());
    try {
      final Object cached = Cache.Org.get(cacheKey);
      if (cached != null) {
        cachedSessionId = (String) cached;
        return cachedSessionId;
      }
    } catch (Exception cacheEx) {
      // Platform Cache not available - continue to VFP call
      System.debug(
        LoggingLevel.FINE,
        'Platform Cache not available, fetching from VFP: ' +
        cacheEx.getMessage()
      );
    }

    // Third: Fetch from Visualforce page (only if not cached)
    try {
      final PageReference sessionPage = Page.JT_SessionIdPage;
      final String sessionId = sessionPage.getContent().toString().trim();

      if (String.isBlank(sessionId)) {
        throw new AuraHandledException(
          'Retrieved blank session ID from Visualforce page.'
        );
      }

      // Cache in static variable for transaction reuse
      cachedSessionId = sessionId;

      // Cache in Platform Cache for cross-request reuse (5 min TTL)
      try {
        Cache.Org.put(cacheKey, sessionId, SESSION_CACHE_TTL);
      } catch (Exception cacheEx) {
        // Platform Cache not available - that's okay, static cache still works
        System.debug(
          LoggingLevel.FINE,
          String.format(
            Label.JT_ToolingApiUtil_couldNotCacheSessionId,
            new List<String>{ cacheEx.getMessage() }
          )
        );
      }

      return sessionId;
    } catch (Exception e) {
      // Log Tooling API session error for support
      JT_ErrorLogger.logError(
        'Tooling API Session Failed',
        e.getMessage(),
        e,
        'JT_ToolingApiUtil.getApiSessionId',
        null,
        'High'
      );

      throw new AuraHandledException(
        Label.JT_ToolingApiUtil_unableToObtainApiSession
      );
    }
  }

  /**
   * @description Creates an HTTP request for Tooling API query calls
   * @param query The SOQL query string for Tooling API
   * @param timeout Timeout in milliseconds (default: 60000)
   * @return HttpRequest Configured HTTP request with API session ID authentication
   */
  @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
  public static HttpRequest createToolingApiQueryRequest(
    final String query,
    final Integer timeout
  ) {
    final String orgUrl = getOrgDomainUrl();
    final String sessionId = getApiSessionId();
    final String endpoint =
      orgUrl +
      getToolingApiPath() +
      '?q=' +
      EncodingUtil.urlEncode(query, 'UTF-8');

    final HttpRequest request = new HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod('GET');
    request.setHeader('Authorization', 'Bearer ' + sessionId);
    request.setHeader('Accept', 'application/json');
    // Validate timeout: must be between 1 and 120000 milliseconds
    Integer validTimeout = (timeout != null && timeout >= 1) ? timeout : 60000;
    request.setTimeout(validTimeout);

    return request;
  }

  /**
   * @description Creates an HTTP request for Tooling API query calls (default timeout)
   * @param query The SOQL query string for Tooling API
   * @return HttpRequest Configured HTTP request with API session ID authentication
   */
  public static HttpRequest createToolingApiQueryRequest(final String query) {
    return createToolingApiQueryRequest(query, 60000);
  }

  /**
   * @description Creates an HTTP request for Tooling API REST calls (non-query endpoints)
   * @param endpointPath Endpoint path (e.g., /services/data/v65.0/tooling/sobjects/CustomMetadata)
   * @param method HTTP method (GET, POST, DELETE, PATCH)
   * @param timeout Timeout in milliseconds (default: 30000)
   * @return HttpRequest Configured HTTP request with API session ID authentication
   */
  @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
  public static HttpRequest createToolingApiRestRequest(
    final String endpointPath,
    final String method,
    final Integer timeout
  ) {
    final String orgUrl = getOrgDomainUrl();
    final String sessionId = getApiSessionId();
    final String endpoint = orgUrl + endpointPath;

    final HttpRequest request = new HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod(method);
    request.setHeader('Authorization', 'Bearer ' + sessionId);
    request.setHeader('Accept', 'application/json');
    request.setHeader('Content-Type', 'application/json');
    // Validate timeout: must be between 1 and 120000 milliseconds
    Integer validTimeout = (timeout != null && timeout >= 1) ? timeout : 30000;
    request.setTimeout(validTimeout);

    return request;
  }

  /**
   * @description Creates an HTTP request for Tooling API REST calls (default timeout)
   * @param endpointPath Endpoint path
   * @param method HTTP method
   * @return HttpRequest Configured HTTP request with API session ID authentication
   */
  public static HttpRequest createToolingApiRestRequest(
    final String endpointPath,
    final String method
  ) {
    return createToolingApiRestRequest(endpointPath, method, 30000);
  }

  /**
   * @description Executes a Tooling API query and returns the response
   * @param query The SOQL query string for Tooling API
   * @param timeout Timeout in milliseconds (default: 60000)
   * @return HttpResponse HTTP response from Tooling API
   */
  public static HttpResponse executeToolingApiQuery(
    final String query,
    final Integer timeout
  ) {
    final HttpRequest request = createToolingApiQueryRequest(query, timeout);
    return new Http().send(request);
  }

  /**
   * @description Executes a Tooling API query (default timeout)
   * @param query The SOQL query string for Tooling API
   * @return HttpResponse HTTP response from Tooling API
   */
  public static HttpResponse executeToolingApiQuery(final String query) {
    return executeToolingApiQuery(query, 60000);
  }

  /**
   * @description Gets the content of an Apex Log using REST API
   * Note: This uses REST API (not Tooling API) to access ApexLog Body field
   * @param apexLogId The ID of the ApexLog record (e.g., 07LKW00000Uees82AB)
   * @return String The log content, or null if log cannot be retrieved
   */
  @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
  public static String getApexLogContent(final String apexLogId) {
    if (String.isBlank(apexLogId)) {
      System.debug(
        LoggingLevel.WARN,
        '⚠️ ApexLogId is blank, cannot retrieve log content'
      );
      return null;
    }

    try {
      final String apiVersion = getApiVersion();
      // REST API endpoint for ApexLog Body field
      final String endpointPath =
        '/services/data/' +
        apiVersion +
        '/sobjects/ApexLog/' +
        apexLogId +
        '/Body';

      final HttpRequest request = createToolingApiRestRequest(
        endpointPath,
        'GET',
        30000
      );
      // Override Accept header for plain text (log body is text, not JSON)
      request.setHeader('Accept', 'text/plain');

      final HttpResponse response = new Http().send(request);

      if (response.getStatusCode() == 200) {
        System.debug(
          '✅ Successfully retrieved Apex Log content (length: ' +
            response.getBody().length() +
            ')'
        );
        return response.getBody();
      } else {
        System.debug(
          LoggingLevel.ERROR,
          '❌ Failed to retrieve Apex Log content. Status: ' +
            response.getStatusCode() +
            ', Body: ' +
            response.getBody()
        );
        return null;
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ Error retrieving Apex Log content: ' + e.getMessage()
      );
      System.debug(
        LoggingLevel.ERROR,
        'Stack trace: ' + e.getStackTraceString()
      );
      return null;
    }
  }
}
