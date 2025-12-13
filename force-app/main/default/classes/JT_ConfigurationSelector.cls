/**
 * @description Selector class for JT_DynamicQueryConfiguration__mdt queries
 * This class centralizes all SOQL queries related to query configurations
 * Follows Selector Layer pattern for clean architecture
 *
 * @author Jaime Terrats
 * @date 2025-12-02
 * @group Selector Layer
 */
public with sharing class JT_ConfigurationSelector {
  /**
   * @description Retrieves all available query configurations
   * @return List<JT_DynamicQueryConfiguration__mdt> All configurations sorted by label
   */
  public static List<JT_DynamicQueryConfiguration__mdt> getConfigurations() {
    return [
      SELECT
        Id,
        DeveloperName,
        Label,
        JT_BaseQuery__c,
        JT_Binding__c,
        JT_ObjectName__c
      FROM JT_DynamicQueryConfiguration__mdt
      WITH USER_MODE
      ORDER BY Label ASC
      LIMIT 200
    ];
  }

  /**
   * @description Retrieves a single configuration by developer name
   * @param devName The developer name of the configuration
   * @return JT_DynamicQueryConfiguration__mdt The configuration record
   * @throws QueryException if configuration not found
   */
  public static JT_DynamicQueryConfiguration__mdt getConfigurationByDevName(
    String devName
  ) {
    List<JT_DynamicQueryConfiguration__mdt> configs = [
      SELECT
        Id,
        DeveloperName,
        Label,
        JT_BaseQuery__c,
        JT_Binding__c,
        JT_ObjectName__c
      FROM JT_DynamicQueryConfiguration__mdt
      WHERE DeveloperName = :devName
      WITH USER_MODE
      LIMIT 1
    ];

    if (configs.isEmpty()) {
      throw new QueryException('Configuration not found: ' + devName);
    }

    return configs[0];
  }

  /**
   * @description Retrieves configurations by object name
   * @param objectName The object API name to filter by
   * @return List<JT_DynamicQueryConfiguration__mdt> Configurations for the specified object
   */
  public static List<JT_DynamicQueryConfiguration__mdt> getConfigurationsByObject(
    String objectName
  ) {
    return [
      SELECT
        Id,
        DeveloperName,
        Label,
        JT_BaseQuery__c,
        JT_Binding__c,
        JT_ObjectName__c
      FROM JT_DynamicQueryConfiguration__mdt
      WHERE JT_ObjectName__c = :objectName
      WITH USER_MODE
      ORDER BY Label ASC
    ];
  }
}