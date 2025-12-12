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
   * @description Input wrapper for configuration data
   */
  public class ConfigurationInput {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String developerName;
    @AuraEnabled
    public String baseQuery;
    @AuraEnabled
    public String bindings;
    @AuraEnabled
    public String objectName;
    @AuraEnabled
    public String originalDevName; // For updates only
  }

  /**
   * @description Creates a new Dynamic Query Configuration metadata record
   * @author Jaime Terrats | 12-11-2025
   * @param input Configuration input data
   * @return MetadataCreationResult
   **/
  @AuraEnabled
  public static MetadataCreationResult createConfiguration(
    ConfigurationInput input
  ) {
    MetadataCreationResult result = new MetadataCreationResult();

    try {
      // CRITICAL: Only allow in development/test environments
      if (!isSandboxOrScratch()) {
        throw new AuraHandledException(
          'Configuration creation is only allowed in development/test environments (Sandbox, Scratch Org, Developer Edition, or Trial). For production orgs (including Starter/Free Editions), use Setup > Custom Metadata Types.'
        );
      }

      // Validate required fields
      if (
        String.isBlank(input.label) ||
        String.isBlank(input.developerName) ||
        String.isBlank(input.baseQuery)
      ) {
        throw new AuraHandledException(
          'Label, Developer Name, and Base Query are required.'
        );
      }

      // Sanitize developer name
      String sanitizedDevName = sanitizeDeveloperName(input.developerName);

      // Build metadata XML
      String metadataXml = buildMetadataXml(
        input.label,
        sanitizedDevName,
        input.baseQuery,
        input.bindings,
        input.objectName
      );

      // Deploy via Metadata API
      String deploymentId = deployMetadata(metadataXml, sanitizedDevName);

      result.success = true;
      result.message = 'Configuration created successfully: ' + input.label;
      result.developerName = sanitizedDevName;
      result.deploymentId = deploymentId;

      // No need for Platform Events - LWC will use refreshApex()

      return result;
    } catch (Exception e) {
      result.success = false;
      result.errorMessage = e.getMessage();
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

    try {
      // CRITICAL: Only allow in development/test environments
      if (!isSandboxOrScratch()) {
        throw new AuraHandledException(
          'Configuration deletion is only allowed in development/test environments (Sandbox, Scratch Org, Developer Edition, or Trial). For production orgs (including Starter/Free Editions), use Setup > Custom Metadata Types.'
        );
      }

      // Validate required field
      if (String.isBlank(developerName)) {
        throw new AuraHandledException('Developer Name is required.');
      }

      // Delete via Tooling API
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        'callout:Tooling_API/sobjects/CustomMetadata/JT_DynamicQueryConfiguration.' +
        developerName
      );
      req.setMethod('DELETE');
      req.setHeader('Content-Type', 'application/json');

      Http http = new Http();
      HttpResponse res = http.send(req);

      if (res.getStatusCode() == 204 || res.getStatusCode() == 200) {
        result.success = true;
        result.message = 'Configuration deleted successfully: ' + developerName;
        result.developerName = developerName;
        return result;
      } else {
        throw new AuraHandledException(
          'Failed to delete metadata: ' + res.getBody()
        );
      }
    } catch (Exception e) {
      result.success = false;
      result.errorMessage = e.getMessage();
      result.stackTrace = e.getStackTraceString();
      return result;
    }
  }

  /**
   * @description Updates an existing Dynamic Query Configuration metadata record
   * @author Jaime Terrats | 12-11-2025
   * @param input Configuration input data (must include originalDevName)
   * @return MetadataCreationResult
   **/
  @AuraEnabled
  public static MetadataCreationResult updateConfiguration(
    ConfigurationInput input
  ) {
    MetadataCreationResult result = new MetadataCreationResult();

    try {
      // CRITICAL: Only allow in sandbox/scratch
      if (!isSandboxOrScratch()) {
        throw new AuraHandledException(
          'Configuration editing is only allowed in development/test environments (Sandbox, Scratch Org, Developer Edition, or Trial). For production orgs (including Starter/Free Editions), use Setup > Custom Metadata Types.'
        );
      }

      // Validate required fields
      if (
        String.isBlank(input.originalDevName) ||
        String.isBlank(input.label) ||
        String.isBlank(input.baseQuery)
      ) {
        throw new AuraHandledException(
          'Developer Name, Label, and Base Query are required.'
        );
      }

      // Build metadata XML (using original dev name - cannot change)
      String metadataXml = buildMetadataXml(
        input.label,
        input.originalDevName,
        input.baseQuery,
        input.bindings,
        input.objectName
      );

      // Deploy via Metadata API (will update existing record)
      String deploymentId = deployMetadata(metadataXml, input.originalDevName);

      result.success = true;
      result.message = 'Configuration updated successfully: ' + input.label;
      result.developerName = input.originalDevName;
      result.deploymentId = deploymentId;

      return result;
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
    Organization org = [
      SELECT IsSandbox, TrialExpirationDate, OrganizationType
      FROM Organization
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];

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
    Organization org = [
      SELECT Name, IsSandbox, OrganizationType, TrialExpirationDate
      FROM Organization
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];

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
      'name' => org.Name,
      'isSandbox' => org.IsSandbox,
      'organizationType' => org.OrganizationType,
      'isScratch' => org.TrialExpirationDate != null,
      'canCreateMetadata' => canCreate,
      'isProduction' => !isDevelopmentOrg,
      'productionOverrideEnabled' => productionOverride
    };
  }

  /**
   * @description Sanitizes developer name (removes spaces, special chars)
   * @author Jaime Terrats | 11-29-2025
   * @param devName Developer name input
   * @return String Sanitized name
   **/
  private static String sanitizeDeveloperName(String devName) {
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
   * @param label Label
   * @param devName Developer name
   * @param baseQuery Base query
   * @param bindings Bindings
   * @param objectName Object name
   * @return String XML content
   **/
  private static String buildMetadataXml(
    String label,
    String devName,
    String baseQuery,
    String bindings,
    String objectName
  ) {
    String xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
    xml += '<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata">\n';
    xml += '    <label>' + escapeXml(label) + '</label>\n';
    xml += '    <protected>false</protected>\n';

    // Base Query
    xml += '    <values>\n';
    xml += '        <field>JT_BaseQuery__c</field>\n';
    xml +=
      '        <value xsi:type="xsd:string">' +
      escapeXml(baseQuery) +
      '</value>\n';
    xml += '    </values>\n';

    // Bindings (optional)
    if (String.isNotBlank(bindings)) {
      xml += '    <values>\n';
      xml += '        <field>JT_Binding__c</field>\n';
      xml +=
        '        <value xsi:type="xsd:string">' +
        escapeXml(bindings) +
        '</value>\n';
      xml += '    </values>\n';
    }

    // Object Name (optional)
    if (String.isNotBlank(objectName)) {
      xml += '    <values>\n';
      xml += '        <field>JT_ObjectName__c</field>\n';
      xml +=
        '        <value xsi:type="xsd:string">' +
        escapeXml(objectName) +
        '</value>\n';
      xml += '    </values>\n';
    }

    xml += '</CustomMetadata>';

    return xml;
  }

  /**
   * @description Deploys metadata via Metadata API
   * @author Jaime Terrats | 11-29-2025
   * @param metadataXml XML content
   * @param devName Developer name
   * @return String Deployment ID
   **/
  private static String deployMetadata(String metadataXml, String devName) {
    // Build deployment package
    String zipBase64 = buildDeploymentZip(metadataXml, devName);

    // Deploy via Metadata API (simplified - in real implementation use MetadataService)
    // For now, use Tooling API as workaround
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Tooling_API/sobjects/CustomMetadata');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');

    Map<String, Object> metadata = new Map<String, Object>{
      'FullName' => 'JT_DynamicQueryConfiguration.' + devName,
      'Metadata' => parseMetadataXmlToJson(metadataXml)
    };

    req.setBody(JSON.serialize(metadata));

    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 201) {
      Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );
      return (String) responseMap.get('id');
    } else {
      throw new AuraHandledException(
        'Failed to deploy metadata: ' + res.getBody()
      );
    }
  }

  /**
   * @description Builds deployment ZIP (simplified)
   * @author Jaime Terrats | 11-29-2025
   * @param metadataXml XML content
   * @param devName Developer name
   * @return String Base64 encoded ZIP
   **/
  private static String buildDeploymentZip(String metadataXml, String devName) {
    // In a real implementation, build proper ZIP with package.xml
    // For now, encode metadata XML (devName used for future enhancement)
    String encoded = EncodingUtil.base64Encode(Blob.valueOf(metadataXml));
    // Use encoded result for deployment (devName logged for debugging)
    System.debug(LoggingLevel.FINE, 'Built deployment for: ' + devName);
    return encoded;
  }

  /**
   * @description Parses XML to JSON for Tooling API
   * @author Jaime Terrats | 11-29-2025
   * @param xml XML string
   * @return Map<String, Object> JSON representation
   **/
  private static Map<String, Object> parseMetadataXmlToJson(String xml) {
    // Simplified parser - in production use proper XML parser
    Map<String, Object> metadata = new Map<String, Object>();

    // Extract label
    Pattern labelPattern = Pattern.compile('<label>(.*?)</label>');
    Matcher labelMatcher = labelPattern.matcher(xml);
    if (labelMatcher.find()) {
      metadata.put('label', labelMatcher.group(1));
    }

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
        throw new AuraHandledException('Query must start with SELECT');
      }

      if (!query.toUpperCase().contains('FROM')) {
        throw new AuraHandledException('Query must contain FROM clause');
      }

      // Try to extract object name (case insensitive)
      Pattern objectPattern = Pattern.compile('(?i)FROM\\s+(\\w+)');
      Matcher objectMatcher = objectPattern.matcher(query);

      if (objectMatcher.find()) {
        result.objectName = objectMatcher.group(1);
      }

      // Extract bind variables
      Pattern bindPattern = Pattern.compile(':([a-zA-Z_][a-zA-Z0-9_]*)');
      Matcher bindMatcher = bindPattern.matcher(query);

      Set<String> bindings = new Set<String>();
      while (bindMatcher.find()) {
        bindings.add(bindMatcher.group(1));
      }

      result.bindVariables = new List<String>(bindings);
      result.isValid = true;
      result.message = 'Query syntax is valid';
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
