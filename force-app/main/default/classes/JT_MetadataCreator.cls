/**
 * @description Creates Custom Metadata records via Tooling API
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 11-30-2025
 * @last modified by Jaime Terrats
 * @warning Use only in Sandbox, Scratch Org, Developer Edition, or Trial - Blocked in Production
 **/
@SuppressWarnings(
  'PMD.AvoidDebugStatements, PMD.UnusedLocalVariable, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity'
)
public with sharing class JT_MetadataCreator {
  /**
   * @description Internal wrapper for metadata parameters
   * Used to reduce parameter count in buildMetadataXml
   */
  private class MetadataParams {
    String label;
    String devName;
    String baseQuery;
    String bindings;
    String objectName;
  }

  /**
   * @description Internal wrapper for extracted configuration values
   */
  private class ConfigValues {
    String label;
    String developerName;
    String baseQuery;
    String bindings;
    String objectName;
    String originalDevName; // For updates only
  }

  /**
   * @description Creates a new Dynamic Query Configuration metadata record
   * @author Jaime Terrats | 12-11-2025
   * @param configJson JSON string containing configuration data (label, developerName, baseQuery, bindings, objectName)
   * @return MetadataCreationResult
   **/
  @AuraEnabled
  public static MetadataCreationResult createConfiguration(String configJson) {
    MetadataCreationResult result = new MetadataCreationResult();
    // Initialize all fields to ensure proper serialization
    result.success = false;
    result.message = null;
    result.errorMessage = null;
    result.stackTrace = null;
    result.developerName = null;
    result.deploymentId = null;

    try {
      // Deserialize and extract configuration values
      ConfigValues config = extractConfigValues(configJson);
      if (config == null) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_configJsonRequired;
        return result;
      }

      // CRITICAL: Only allow in development/test environments
      if (!isSandboxOrScratch()) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_creationNotAllowed;
        return result;
      }

      // Validate required fields
      if (
        String.isBlank(config.label) ||
        String.isBlank(config.developerName) ||
        String.isBlank(config.baseQuery)
      ) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_requiredFieldsMissing;
        return result;
      }

      // Sanitize developer name (with null check)
      if (String.isBlank(config.developerName)) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_developerNameBlank;
        return result;
      }
      String sanitizedDevName = sanitizeDeveloperName(config.developerName);

      // Build metadata XML (handle null values for optional fields)
      MetadataParams params = new MetadataParams();
      params.label = config.label;
      params.devName = sanitizedDevName;
      params.baseQuery = config.baseQuery;
      params.bindings = String.isBlank(config.bindings) ? null : config.bindings;
      params.objectName = String.isBlank(config.objectName) ? null : config.objectName;

      // Build XML - catch any exceptions here to prevent serialization issues
      String metadataXml;
      try {
        metadataXml = buildMetadataXml(params);
      } catch (IllegalArgumentException iae) {
        result.success = false;
        String iaeMsg = iae.getMessage();
        result.errorMessage = String.isNotBlank(iaeMsg) ? iaeMsg : Label.JT_MetadataCreator_invalidMetadataParams;
        return result;
      } catch (Exception xmlEx) {
        result.success = false;
        String xmlMsg = xmlEx.getMessage();
        String xmlErrorMsg = String.isNotBlank(xmlMsg) ? xmlMsg : xmlEx.getTypeName();
        result.errorMessage = String.format(Label.JT_MetadataCreator_errorBuildingXml, new List<String>{ xmlErrorMsg });
        return result;
      }

      // Deploy via Metadata API
      DeploymentResult deployResult = deployMetadata(metadataXml, sanitizedDevName);

      if (!deployResult.success) {
        result.success = false;
        result.errorMessage = deployResult.errorMessage;
        return result;
      }

      result.success = true;
      result.message = String.format(Label.JT_MetadataCreator_configCreatedSuccess, new List<String>{ config.label });
      result.developerName = sanitizedDevName;
      result.deploymentId = deployResult.deploymentId;

      // No need for Platform Events - LWC will use refreshApex()

      return result;
    } catch (Exception e) {
      result.success = false;
      // Ensure errorMessage is never null - use fallback if needed
      String errorMsg = e.getMessage();
      if (String.isBlank(errorMsg)) {
        errorMsg = String.format(Label.JT_MetadataCreator_unexpectedError, new List<String>{ e.getTypeName() });
      }
      result.errorMessage = errorMsg;
      result.stackTrace = e.getStackTraceString();
      return result;
    }
  }

  /**
   * @description Deletes a Dynamic Query Configuration metadata record
   * @author Jaime Terrats | 12-11-2025
   * @param developerName Developer name of configuration to delete
   * @return MetadataCreationResult
   **/
  @AuraEnabled
  public static MetadataCreationResult deleteConfiguration(
    String developerName
  ) {
    MetadataCreationResult result = new MetadataCreationResult();
    // Initialize all fields to ensure proper serialization
    result.success = false;
    result.message = null;
    result.errorMessage = null;
    result.stackTrace = null;
    result.developerName = null;
    result.deploymentId = null;

    try {
      // CRITICAL: Only allow in development/test environments
      if (!isSandboxOrScratch()) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_deletionNotAllowed;
        return result;
      }

      // Validate required field
      if (String.isBlank(developerName)) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_developerNameRequired;
        return result;
      }

      // Delete via Tooling API using API-enabled session ID
      final String endpointPath =
        '/services/data/' +
        JT_ToolingApiUtil.getApiVersion() +
        '/tooling/sobjects/CustomMetadata/JT_DynamicQueryConfiguration.' +
        EncodingUtil.urlEncode(developerName, 'UTF-8');

      final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
        endpointPath,
        'DELETE',
        30000
      );

      final Http httpClient = new Http();
      final HttpResponse response = httpClient.send(request);

      if (response.getStatusCode() == 204 || response.getStatusCode() == 200) {
        result.success = true;
        result.message = String.format(Label.JT_MetadataCreator_configDeletedSuccess, new List<String>{ developerName });
        result.developerName = developerName;
        return result;
      } else {
        result.success = false;
        result.errorMessage = String.format(Label.JT_MetadataCreator_failedDeleteMetadata, new List<String>{ response.getBody() });
        return result;
      }
    } catch (Exception e) {
      result.success = false;
      String errorMsg = e.getMessage();
      if (String.isBlank(errorMsg)) {
        errorMsg = String.format(Label.JT_MetadataCreator_unexpectedError, new List<String>{ e.getTypeName() });
      }
      result.errorMessage = errorMsg;
      result.stackTrace = e.getStackTraceString();
      return result;
    }
  }

  /**
   * @description Updates an existing Dynamic Query Configuration metadata record
   * @author Jaime Terrats | 12-11-2025
   * @param configJson JSON string containing configuration data (originalDevName, label, developerName, baseQuery, bindings, objectName)
   * @return MetadataCreationResult
   **/
  @AuraEnabled
  public static MetadataCreationResult updateConfiguration(String configJson) {
    MetadataCreationResult result = new MetadataCreationResult();
    // Initialize all fields to ensure proper serialization
    result.success = false;
    result.message = null;
    result.errorMessage = null;
    result.stackTrace = null;
    result.developerName = null;
    result.deploymentId = null;

    try {
      // Deserialize and extract configuration values
      ConfigValues config = extractConfigValues(configJson);
      if (config == null) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_configJsonRequired;
        return result;
      }

      // CRITICAL: Only allow in sandbox/scratch
      if (!isSandboxOrScratch()) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_editingNotAllowed;
        return result;
      }

      // Validate required fields
      if (
        String.isBlank(config.originalDevName) ||
        String.isBlank(config.label) ||
        String.isBlank(config.baseQuery)
      ) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_updateRequiredFieldsMissing;
        return result;
      }

      // Sanitize developer name (with null check)
      String sanitizedDevName = String.isNotBlank(config.developerName)
        ? sanitizeDeveloperName(config.developerName)
        : config.originalDevName;

      // Check if Developer Name changed (renaming scenario)
      Boolean isRenaming =
        String.isNotBlank(sanitizedDevName) &&
        sanitizedDevName != config.originalDevName;

      if (isRenaming) {
        // Rename: Delete old record and create new one
        MetadataCreationResult renameResult = handleRename(config, sanitizedDevName);
        return renameResult;
      } else {
        // Normal update: Use original dev name
        MetadataParams params = new MetadataParams();
        params.label = config.label;
        params.devName = config.originalDevName;
        params.baseQuery = config.baseQuery;
        params.bindings = String.isBlank(config.bindings) ? null : config.bindings;
        params.objectName = String.isBlank(config.objectName) ? null : config.objectName;

        // Build XML - catch any exceptions here to prevent serialization issues
        String metadataXml;
        try {
          metadataXml = buildMetadataXml(params);
        } catch (IllegalArgumentException iae) {
          result.success = false;
          String iaeMsg = iae.getMessage();
          result.errorMessage = String.isNotBlank(iaeMsg) ? iaeMsg : Label.JT_MetadataCreator_invalidMetadataParams;
          return result;
        } catch (Exception xmlEx) {
          result.success = false;
          String xmlMsg = xmlEx.getMessage();
          String xmlErrorMsg = String.isNotBlank(xmlMsg) ? xmlMsg : xmlEx.getTypeName();
          result.errorMessage = String.format(Label.JT_MetadataCreator_errorBuildingXml, new List<String>{ xmlErrorMsg });
          return result;
        }

        // Deploy via Metadata API (will update existing record)
        DeploymentResult deployResult = deployMetadata(
          metadataXml,
          config.originalDevName
        );

        if (!deployResult.success) {
          result.success = false;
          result.errorMessage = deployResult.errorMessage;
          return result;
        }

        result.success = true;
        result.message = String.format(Label.JT_MetadataCreator_configUpdatedSuccess, new List<String>{ config.label });
        result.developerName = config.originalDevName;
        result.deploymentId = deployResult.deploymentId;

        return result;
      }
    } catch (Exception e) {
      result.success = false;
      result.errorMessage = e.getMessage();
      result.stackTrace = e.getStackTraceString();
      return result;
    }
  }

  /**
   * @description Checks if current org is sandbox or scratch
   * @author Jaime Terrats | 11-29-2025
   * @return Boolean True if sandbox/scratch
   **/
  @AuraEnabled(cacheable=true)
  public static Boolean isSandboxOrScratch() {
    // ✅ REFACTORED: Use SystemSelector pattern
    Organization org = JT_SystemSelector.getOrganizationInfo();
    if (org == null) {
      return false;
    }

    // Check if it's a development/test environment
    Boolean isDevelopmentOrg =
      org.IsSandbox ||
      org.TrialExpirationDate != null ||
      org.OrganizationType == 'Developer Edition';

    // If not a dev org, check custom setting override
    if (!isDevelopmentOrg) {
      JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();
      if (settings != null && settings.JT_AllowProductionEditing__c == true) {
        // User explicitly enabled production editing (Starter/Free Editions)
        return true;
      }
    }

    return isDevelopmentOrg;
  }

  /**
   * @description Gets org type information
   * @author Jaime Terrats | 11-29-2025
   * @return Map<String, Object> Org info
   **/
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getOrgInfo() {
    try {
      // ✅ REFACTORED: Use SystemSelector pattern - single query with Name
      Organization org = JT_SystemSelector.getOrganizationInfoWithName();

      if (org == null) {
        return new Map<String, Object>{
          'name' => 'Unknown',
          'isSandbox' => false,
          'organizationType' => 'Unknown',
          'isScratch' => false,
          'canCreateMetadata' => false,
          'isProduction' => true,
          'productionOverrideEnabled' => false
        };
      }

      Boolean isDevelopmentOrg =
        org.IsSandbox ||
        org.TrialExpirationDate != null ||
        org.OrganizationType == 'Developer Edition';

      // Check custom setting override for production orgs
      JT_DynamicQuerySettings__c settings = JT_DynamicQuerySettings__c.getInstance();
      Boolean productionOverride = (settings != null &&
      settings.JT_AllowProductionEditing__c == true);

      Boolean canCreate = isDevelopmentOrg || productionOverride;

      return new Map<String, Object>{
        'name' => org.Name != null ? org.Name : 'Unknown',
        'isSandbox' => org.IsSandbox != null ? org.IsSandbox : false,
        'organizationType' => org.OrganizationType != null ? org.OrganizationType : 'Unknown',
        'isScratch' => org.TrialExpirationDate != null,
        'canCreateMetadata' => canCreate,
        'isProduction' => !isDevelopmentOrg,
        'productionOverrideEnabled' => productionOverride
      };
    } catch (Exception e) {
      // Ensure we always return a valid Map, never a String
      System.debug(LoggingLevel.ERROR, 'Error in getOrgInfo: ' + e.getMessage() + '\n' + e.getStackTraceString());
      // Return default values to maintain consistent Map structure
      return new Map<String, Object>{
        'name' => 'Unknown',
        'isSandbox' => false,
        'organizationType' => 'Unknown',
        'isScratch' => false,
        'canCreateMetadata' => false,
        'isProduction' => true,
        'productionOverrideEnabled' => false
      };
    }
  }

  /**
   * @description Sanitizes developer name (removes spaces, special chars)
   * @author Jaime Terrats | 11-29-2025
   * @param devName Developer name input
   * @return String Sanitized name
   **/
  private static String sanitizeDeveloperName(String devName) {
    if (String.isBlank(devName)) {
      return devName;
    }
    // Remove spaces and special characters
    String sanitized = devName.replaceAll('[^a-zA-Z0-9_]', '_');

    // Ensure starts with letter
    if (!Pattern.matches('^[a-zA-Z].*', sanitized)) {
      sanitized = 'Config_' + sanitized;
    }

    // Max length 40 characters
    if (sanitized.length() > 40) {
      sanitized = sanitized.substring(0, 40);
    }

    return sanitized;
  }

  /**
   * @description Builds Custom Metadata XML
   * @author Jaime Terrats | 11-29-2025
   * @param params MetadataParams wrapper containing all metadata fields
   * @return String XML content
   **/
  private static String buildMetadataXml(MetadataParams params) {
    // Validate required parameters
    if (
      params == null ||
      String.isBlank(params.label) ||
      String.isBlank(params.devName) ||
      String.isBlank(params.baseQuery)
    ) {
      throw new IllegalArgumentException(Label.JT_MetadataCreator_xmlGenerationRequiredFields);
    }

    String xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
    xml += '<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata">\n';
    xml += '    <label>' + escapeXml(params.label) + '</label>\n';
    xml += '    <protected>false</protected>\n';

    // Base Query
    xml += '    <values>\n';
    xml += '        <field>JT_BaseQuery__c</field>\n';
    xml +=
      '        <value xsi:type="xsd:string">' +
      escapeXml(params.baseQuery) +
      '</value>\n';
    xml += '    </values>\n';

    // Bindings (optional)
    if (String.isNotBlank(params.bindings)) {
      xml += '    <values>\n';
      xml += '        <field>JT_Binding__c</field>\n';
      xml +=
        '        <value xsi:type="xsd:string">' +
        escapeXml(params.bindings) +
        '</value>\n';
      xml += '    </values>\n';
    }

    // Object Name (optional)
    if (String.isNotBlank(params.objectName)) {
      xml += '    <values>\n';
      xml += '        <field>JT_ObjectName__c</field>\n';
      xml +=
        '        <value xsi:type="xsd:string">' +
        escapeXml(params.objectName) +
        '</value>\n';
      xml += '    </values>\n';
    }

    xml += '</CustomMetadata>';

    return xml;
  }

  /**
   * @description Result wrapper for deployment operation
   */
  private class DeploymentResult {
    Boolean success;
    String deploymentId;
    String errorMessage;
  }

  /**
   * @description Deploys metadata via Metadata API
   * @author Jaime Terrats | 11-29-2025
   * @param metadataXml XML content
   * @param devName Developer name
   * @return DeploymentResult with success status, deploymentId, and errorMessage
   **/
  private static DeploymentResult deployMetadata(String metadataXml, String devName) {
    DeploymentResult result = new DeploymentResult();
    result.success = false;

    try {
      // Deploy via Tooling API using API-enabled session ID
      final String endpointPath =
        '/services/data/' +
        JT_ToolingApiUtil.getApiVersion() +
        '/tooling/sobjects/CustomMetadata';

      // Parse XML to JSON format required by Tooling API
      Map<String, Object> metadataJson = parseMetadataXmlToJson(metadataXml);

      final Map<String, Object> metadata = new Map<String, Object>{
        'FullName' => 'JT_DynamicQueryConfiguration.' + devName,
        'Metadata' => metadataJson
      };

      String requestBody = JSON.serialize(metadata);
      System.debug(
        LoggingLevel.FINE,
        'Deploying Custom Metadata for: ' + devName
      );
      System.debug(LoggingLevel.FINE, 'Request body: ' + requestBody);

      final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
        endpointPath,
        'POST',
        30000
      );
      request.setBody(requestBody);

      final Http httpClient = new Http();
      final HttpResponse response = httpClient.send(request);

      System.debug(
        LoggingLevel.FINE,
        'Response status: ' + response.getStatusCode()
      );
      System.debug(LoggingLevel.FINE, 'Response body: ' + response.getBody());

      if (response.getStatusCode() == 201) {
        final Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
          response.getBody()
        );
        result.success = true;
        result.deploymentId = (String) responseMap.get('id');
        return result;
      } else {
        // Parse error response for better error message
        String errorDetail = '';
        try {
          Map<String, Object> errorMap = (Map<String, Object>) JSON.deserializeUntyped(
            response.getBody()
          );
          List<Object> errors = (List<Object>) errorMap.get('errors');
          if (errors != null && !errors.isEmpty()) {
            Map<String, Object> firstError = (Map<String, Object>) errors[0];
            String message = (String) firstError.get('message');
            if (String.isNotBlank(message)) {
              errorDetail = ': ' + message;
            }
          } else {
            errorDetail = ': ' + response.getBody();
          }
        } catch (Exception e) {
          errorDetail = ': ' + response.getBody();
        }
        result.errorMessage = String.format(
          Label.JT_MetadataCreator_failedDeployMetadata,
          new List<String>{ String.valueOf(response.getStatusCode()), errorDetail }
        );
        return result;
      }
    } catch (Exception e) {
      String errorMsg = e.getMessage();
      if (String.isBlank(errorMsg)) {
        errorMsg = String.format(Label.JT_MetadataCreator_unexpectedErrorDeployment, new List<String>{ e.getTypeName() });
      }
      result.errorMessage = String.format(Label.JT_MetadataCreator_errorDeployingMetadata, new List<String>{ errorMsg });
      return result;
    }
  }

  /**
   * @description Helper method to extract configuration values from JSON string
   * @param configJson JSON string containing configuration data
   * @return ConfigValues object with extracted values, or null if invalid
   **/
  private static ConfigValues extractConfigValues(String configJson) {
    if (String.isBlank(configJson)) {
      return null;
    }

    try {
      // Deserialize JSON input
      Object deserialized = JSON.deserializeUntyped(configJson);

      // Ensure we have a Map, not a List
      if (!(deserialized instanceof Map<String, Object>)) {
        System.debug(
          LoggingLevel.ERROR,
          String.format(Label.JT_MetadataCreator_invalidJsonFormat, new List<String>{ String.valueOf(deserialized) })
        );
        return null;
      }

      Map<String, Object> configMap = (Map<String, Object>) deserialized;

      System.debug(
        LoggingLevel.ERROR,
        '🔍 Extracted configMap: ' + JSON.serialize(configMap)
      );

      // Extract values from map (handle null values safely)
      ConfigValues config = new ConfigValues();
      config.label = configMap.get('label') != null ? String.valueOf(configMap.get('label')) : null;
      config.developerName = configMap.get('developerName') != null ? String.valueOf(configMap.get('developerName')) : null;
      config.baseQuery = configMap.get('baseQuery') != null ? String.valueOf(configMap.get('baseQuery')) : null;
      config.bindings = configMap.get('bindings') != null ? String.valueOf(configMap.get('bindings')) : null;
      config.objectName = configMap.get('objectName') != null ? String.valueOf(configMap.get('objectName')) : null;
      config.originalDevName = configMap.get('originalDevName') != null ? String.valueOf(configMap.get('originalDevName')) : null;

      return config;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        String.format(Label.JT_MetadataCreator_errorDeserializingJson, new List<String>{ e.getMessage() })
      );
      return null;
    }
  }

  /**
   * @description Handles renaming scenario (delete old + create new)
   * @param config ConfigValues object containing all configuration data
   * @param sanitizedDevName New sanitized developer name
   * @return MetadataCreationResult
   **/
  @SuppressWarnings('PMD.ExcessiveParameterList')
  private static MetadataCreationResult handleRename(
    ConfigValues config,
    String sanitizedDevName
  ) {
    MetadataCreationResult result = new MetadataCreationResult();
    // Initialize all fields to ensure proper serialization
    result.success = false;
    result.message = null;
    result.errorMessage = null;
    result.stackTrace = null;
    result.developerName = null;
    result.deploymentId = null;

    // Step 1: Delete old record
    MetadataCreationResult deleteResult = deleteConfiguration(config.originalDevName);

    if (!deleteResult.success) {
      result.success = false;
      result.errorMessage = String.format(
        Label.JT_MetadataCreator_failedDeleteRename,
        new List<String>{ deleteResult.errorMessage }
      );
      return result;
    }

    // Step 2: Create new record with new Developer Name
    Map<String, Object> createConfigMap = new Map<String, Object>{
      'label' => config.label,
      'developerName' => sanitizedDevName,
      'baseQuery' => config.baseQuery,
      'bindings' => config.bindings,
      'objectName' => config.objectName
    };
    String createConfigJson = JSON.serialize(createConfigMap);

    MetadataCreationResult createResult = createConfiguration(createConfigJson);

    if (!createResult.success) {
      result.success = false;
      result.errorMessage = String.format(
        Label.JT_MetadataCreator_failedCreateRename,
        new List<String>{ createResult.errorMessage }
      );
      return result;
    }

    result.success = true;
    result.message = String.format(
      Label.JT_MetadataCreator_configRenamedSuccess,
      new List<String>{ config.originalDevName, sanitizedDevName }
    );
    result.developerName = sanitizedDevName;
    result.deploymentId = createResult.deploymentId;

    return result;
  }

  /**
   * @description Parses XML to JSON for Tooling API
   * Tooling API expects: { "label": "...", "values": [{ "field": "...", "value": "..." }] }
   * @author Jaime Terrats | 11-29-2025
   * @param xml XML string
   * @return Map<String, Object> JSON representation
   **/
  private static Map<String, Object> parseMetadataXmlToJson(String xml) {
    Map<String, Object> metadata = new Map<String, Object>();
    List<Map<String, Object>> values = new List<Map<String, Object>>();

    // Extract label
    final Pattern labelPattern = Pattern.compile('<label>(.*?)</label>');
    final Matcher labelMatcher = labelPattern.matcher(xml);
    if (labelMatcher.find()) {
      metadata.put('label', labelMatcher.group(1));
    }

    // Extract all field values
    // Pattern matches: <field>FieldName__c</field><value xsi:type="xsd:string">Value</value>
    // Using (?i) flag for case-insensitive matching
    final Pattern valuePattern = Pattern.compile(
      '(?i)<field>(.*?)</field>\\s*<value[^>]*>(.*?)</value>'
    );
    final Matcher valueMatcher = valuePattern.matcher(xml);

    while (valueMatcher.find()) {
      String fieldName = valueMatcher.group(1);
      String fieldValue = valueMatcher.group(2);

      Map<String, Object> valueEntry = new Map<String, Object>{
        'field' => fieldName,
        'value' => fieldValue
      };
      values.add(valueEntry);
    }

    // Add values array to metadata (required by Tooling API)
    metadata.put('values', values);

    return metadata;
  }

  /**
   * @description Escapes XML special characters
   * @author Jaime Terrats | 11-29-2025
   * @param value Value to escape
   * @return String Escaped value
   **/
  private static String escapeXml(String value) {
    if (String.isBlank(value)) {
      return '';
    }

    return value
      .replace('&', '&amp;')
      .replace('<', '&lt;')
      .replace('>', '&gt;')
      .replace('"', '&quot;')
      .replace('\'', '&apos;');
  }

  /**
   * @description Validates SOQL query syntax
   * @author Jaime Terrats | 11-29-2025
   * @param query SOQL query
   * @return ValidationResult
   **/
  @AuraEnabled
  public static ValidationResult validateQuery(String query) {
    ValidationResult result = new ValidationResult();

    try {
      // Basic validation
      if (!query.trim().toUpperCase().startsWith('SELECT')) {
        throw new AuraHandledException(Label.JT_MetadataCreator_queryMustStartWithSelect);
      }

      if (!query.toUpperCase().contains('FROM')) {
        throw new AuraHandledException(Label.JT_MetadataCreator_queryMustContainFrom);
      }

      // Try to extract object name (case insensitive)
      final Pattern objectPattern = Pattern.compile('(?i)FROM\\s+(\\w+)');
      final Matcher objectMatcher = objectPattern.matcher(query);

      if (objectMatcher.find()) {
        result.objectName = objectMatcher.group(1);
      }

      // Extract bind variables
      final Pattern bindVariablePattern = Pattern.compile(
        ':([a-zA-Z_][a-zA-Z0-9_]*)'
      );
      final Matcher bindVariableMatcher = bindVariablePattern.matcher(query);

      final Set<String> bindings = new Set<String>();
      while (bindVariableMatcher.find()) {
        bindings.add(bindVariableMatcher.group(1));
      }

      result.bindVariables = new List<String>(bindings);
      result.isValid = true;
      result.message = Label.JT_MetadataCreator_querySyntaxValid;
    } catch (Exception e) {
      result.isValid = false;
      result.message = e.getMessage();
    }

    return result;
  }

  /**
   * @description Result wrapper for metadata creation
   **/
  public class MetadataCreationResult {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String errorMessage;
    @AuraEnabled
    public String stackTrace;
    @AuraEnabled
    public String developerName;
    @AuraEnabled
    public String deploymentId;
  }

  /**
   * @description Result wrapper for query validation
   **/
  public class ValidationResult {
    @AuraEnabled
    public Boolean isValid;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String objectName;
    @AuraEnabled
    public List<String> bindVariables;
  }
}
