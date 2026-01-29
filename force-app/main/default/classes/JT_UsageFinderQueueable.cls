/**
 * @description Queueable implementation for large-scale "Where is this used?" searches
 * @author Jaime Terrats
 * @date 2025-12-11
 *
 * Handles asynchronous searches for configuration usage across:
 * - Apex Classes (100+ classes auto-triggers Queueable)
 * - Flows (processed asynchronously)
 * - Reports (processed asynchronously)
 *
 * Results are stored in Platform Cache for 7 days and optionally emailed.
 */
@SuppressWarnings('PMD.AvoidDebugStatements')
public with sharing class JT_UsageFinderQueueable implements Queueable {
  private String configurationDevName;
  private String userEmail;
  private String userId;

  /**
   * @description Constructor for queueable search
   * @param configurationDevName Developer name of the configuration to search for
   * @param userEmail Email address to notify when search completes
   * @param userId User ID who initiated the search
   * @throws IllegalArgumentException if configurationDevName is null or blank
   */
  public JT_UsageFinderQueueable(
    String configurationDevName,
    String userEmail,
    String userId
  ) {
    // Validate required parameters at construction time
    if (String.isBlank(configurationDevName)) {
      throw new IllegalArgumentException(
        'Configuration developer name cannot be null or blank'
      );
    }
    this.configurationDevName = configurationDevName;
    this.userEmail = userEmail;
    this.userId = userId;
  }

  /**
   * @description Executes the asynchronous usage search
   * @param context Queueable context
   */
  public void execute(QueueableContext context) {
    try {
      System.debug('Starting async usage search for: ' + configurationDevName);

      // Perform comprehensive usage search
      JT_UsageFinder.AggregatedUsageResponse result = JT_UsageFinder.findAllUsagesResilient(
        configurationDevName
      );

      // Store results in Platform Cache (2 days TTL - max allowed)
      // Use alphanumeric cache key to avoid invalid characters (underscores, etc.)
      String cacheKey = buildCacheKey(configurationDevName, userId);
      Cache.Org.put(cacheKey, JSON.serialize(result), 172800); // 2 days in seconds (max allowed)

      System.debug('Usage search completed. Found:');
      System.debug('- Total Results: ' + result.totalResults);
      System.debug(
        '- Apex Service: ' + (result.apexService.success ? 'Success' : 'Failed')
      );
      System.debug(
        '- Flow Service: ' + (result.flowService.success ? 'Success' : 'Failed')
      );

      // Send email notification
      if (String.isNotBlank(userEmail)) {
        sendCompletionEmail(result);
      }
    } catch (Exception e) {
      System.debug(
        'Error in async usage search: ' +
          e.getMessage() +
          '\n' +
          e.getStackTraceString()
      );

      // Send error email
      if (String.isNotBlank(userEmail)) {
        sendErrorEmail(e);
      }

      // Re-throw to mark job as failed
      throw e;
    }
  }

  /**
   * @description Sends completion email with search results
   * @param result Usage search results
   */
  private void sendCompletionEmail(
    JT_UsageFinder.AggregatedUsageResponse result
  ) {
    String subject =
      'Dynamic Queries - Usage Search Complete: ' + configurationDevName;
    String body = buildEmailBody(result);
    sendEmail(subject, body);
  }

  /**
   * @description Builds HTML email body with search results
   * @param result Usage search results
   * @return HTML formatted email body
   */
  private String buildEmailBody(JT_UsageFinder.AggregatedUsageResponse result) {
    Integer totalUsages = result.totalResults;

    String body = '<html><body style="font-family: Arial, sans-serif;">';
    body += '<h2>Usage Search Complete</h2>';
    body +=
      '<p>Your search for configuration <strong>' +
      configurationDevName +
      '</strong> has completed.</p>';
    body += '<h3>Results Summary:</h3>';
    body += '<ul>';
    body +=
      '<li><strong>Apex Classes:</strong> ' +
      (result.apexService.success
        ? String.valueOf(result.apexService.data.size())
        : 'Failed') +
      '</li>';
    body +=
      '<li><strong>Flows:</strong> ' +
      (result.flowService.success
        ? String.valueOf(result.flowService.data.size())
        : 'Failed') +
      '</li>';
    body += '</ul>';
    body += '<p><strong>Total Usages:</strong> ' + totalUsages + '</p>';

    if (result.hasPartialResults) {
      body += '<p style="color: orange;"><strong>Note:</strong> Partial results - one or more services failed.</p>';
    }

    if (totalUsages > 0) {
      body += '<h3>Details:</h3>';

      for (JT_UsageFinder.UsageResult usage : result.allResults) {
        body +=
          '<li><strong>' +
          usage.className +
          '</strong> (' +
          usage.metadataType +
          ')';
        if (usage.lineNumber != null) {
          body += ' - Line ' + usage.lineNumber;
        }
        body += '</li>';
      }
    } else {
      body += '<p><em>No usages found for this configuration. It may be unused or only referenced in code comments.</em></p>';
    }

    body +=
      '<hr><p style="font-size: 12px; color: #666;">This search was initiated by user ID: ' +
      userId +
      '</p>';
    body += '<p style="font-size: 12px; color: #666;">Results are cached for 7 days in your org.</p>';
    body += '</body></html>';

    return body;
  }

  /**
   * @description Sends error email when search fails
   * @param e Exception that occurred
   */
  private void sendErrorEmail(Exception e) {
    String subject =
      'Dynamic Queries - Usage Search Failed: ' + configurationDevName;
    String body = '<html><body style="font-family: Arial, sans-serif;">';
    body += '<h2>Usage Search Failed</h2>';
    body +=
      '<p>Your search for configuration <strong>' +
      configurationDevName +
      '</strong> encountered an error.</p>';
    body += '<h3>Error Details:</h3>';
    body += '<p><strong>Type:</strong> ' + e.getTypeName() + '</p>';
    body += '<p><strong>Message:</strong> ' + e.getMessage() + '</p>';
    body += '<p><strong>Line Number:</strong> ' + e.getLineNumber() + '</p>';
    body += '<p>Please contact your Salesforce administrator for assistance.</p>';
    body += '</body></html>';
    sendEmail(subject, body);
  }

  /**
   * @description Sends an email with the given subject and HTML body
   * Centralizes email sending logic to avoid duplication
   * @param subject Email subject
   * @param htmlBody HTML email body
   */
  private void sendEmail(String subject, String htmlBody) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setToAddresses(new List<String>{ userEmail });
    email.setSubject(subject);
    email.setHtmlBody(htmlBody);
    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
  }

  /**
   * @description Builds cache key for storing/retrieving usage search results
   * Centralizes cache key construction logic to avoid duplication
   * Cache keys must be <= 50 characters, so we use a hash-based approach
   * @param configurationDevName Developer name of the configuration
   * @param userId User ID who initiated the search
   * @return String Cache key for Platform Cache (max 50 chars)
   */
  private static String buildCacheKey(
    String configurationDevName,
    String userId
  ) {
    // Create a combined string for hashing
    String combined = (configurationDevName != null ? configurationDevName : '') +
                      (userId != null ? userId : '');

    // Generate a short hash (first 16 chars of hex digest)
    Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(combined));
    String hashHex = EncodingUtil.convertToHex(hash);
    String shortHash = hashHex.substring(0, 16);

    // Return key with prefix (max 50 chars: "US" + 16 char hash + last 32 chars of userId if needed)
    String prefix = 'US';
    String userIdSuffix = '';
    if (userId != null && userId.length() > 0) {
      // Use last 8 chars of userId to ensure uniqueness while staying under limit
      String sanitizedUserId = JT_ToolingApiUtil.toAlphanumeric(userId);
      userIdSuffix = sanitizedUserId.length() > 8
        ? sanitizedUserId.substring(sanitizedUserId.length() - 8)
        : sanitizedUserId;
    }

    // Ensure total length <= 50: prefix (2) + hash (16) + userIdSuffix (max 8) = max 26 chars
    String cacheKey = prefix + shortHash + userIdSuffix;

    // Truncate if still too long (shouldn't happen, but safety check)
    if (cacheKey.length() > 50) {
      cacheKey = cacheKey.substring(0, 50);
    }

    return cacheKey;
  }

  /**
   * @description Retrieves cached search results
   * @param configurationDevName Developer name of the configuration
   * @param userId User ID who initiated the search
   * @return Cached usage result or null if not found
   */
  public static JT_UsageFinder.AggregatedUsageResponse getCachedResults(
    String configurationDevName,
    String userId
  ) {
    // Use alphanumeric cache key to match the key used in execute()
    String cacheKey = buildCacheKey(configurationDevName, userId);
    String cachedJson = (String) Cache.Org.get(cacheKey);

    if (String.isNotBlank(cachedJson)) {
      return (JT_UsageFinder.AggregatedUsageResponse) JSON.deserialize(
        cachedJson,
        JT_UsageFinder.AggregatedUsageResponse.class
      );
    }

    return null;
  }
}
