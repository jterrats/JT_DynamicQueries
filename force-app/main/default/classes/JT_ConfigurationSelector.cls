/**
 * @description Selector class for JT_DynamicQueryConfiguration__mdt queries
 * @author Jaime Terrats
 * @date 2025-12-02
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
      String errorMessage = String.format(
        Label.JT_ConfigurationSelector_configurationNotFound,
        new List<String>{ devName }
      );
      throw new QueryException(errorMessage);
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
    // Return empty list if objectName is null or blank
    if (String.isBlank(objectName)) {
      return new List<JT_DynamicQueryConfiguration__mdt>();
    }

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
