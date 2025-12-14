/**
 * @description Utility class for processing query bindings
 * Centralizes logic for adding wildcards to LIKE bindings and other binding transformations
 * @author Jaime Terrats
 * @group Dynamic Queries
 */
public class JT_QueryBindingUtil {
  /**
   * @description Adds wildcards to bind parameters used in LIKE clauses
   * This ensures queries like "WHERE Name LIKE :searchName" work correctly
   * by automatically wrapping string values with % wildcards
   * @param query The SOQL query string
   * @param bindings The map of bind variables (will be modified in place)
   * @example
   * Map<String, Object> bindings = new Map<String, Object>{ 'searchName' => 'test' };
   * JT_QueryBindingUtil.addWildcardsForLikeBindings('SELECT Id FROM Account WHERE Name LIKE :searchName', bindings);
   * // bindings now contains: 'searchName' => '%test%'
   */
  public static void addWildcardsForLikeBindings(
    String query,
    Map<String, Object> bindings
  ) {
    if (String.isBlank(query) || bindings == null || bindings.isEmpty()) {
      return;
    }

    System.debug(LoggingLevel.FINE, '🔍 Adding wildcards for LIKE bindings...');

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
              '✅ Added wildcards: "' + strValue + '" → "' + newValue + '"'
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
   * @description Processes bindings JSON string by deserializing and adding wildcards for LIKE queries
   * This is a convenience method that combines JSON deserialization with wildcard processing
   * @param query The SOQL query string
   * @param bindingsJson JSON string with bind variables
   * @return Map<String, Object> Processed bindings map with wildcards added
   * @example
   * String bindingsJson = '{"searchName": "test"}';
   * Map<String, Object> bindings = JT_QueryBindingUtil.processBindings(
   *   'SELECT Id FROM Account WHERE Name LIKE :searchName',
   *   bindingsJson
   * );
   * // bindings now contains: 'searchName' => '%test%'
   */
  public static Map<String, Object> processBindings(
    String query,
    String bindingsJson
  ) {
    Map<String, Object> bindings = String.isNotBlank(bindingsJson)
      ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
      : new Map<String, Object>();

    // Add wildcards for LIKE queries
    addWildcardsForLikeBindings(query, bindings);

    return bindings;
  }
}

