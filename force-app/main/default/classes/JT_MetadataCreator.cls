/**
 * @description Creates Custom Metadata records via Tooling API
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 11-30-2025
 * @last modified by Jaime Terrats
 * @warning Use only in Sandbox, Scratch Org, Developer Edition, or Trial - Blocked in Production
 **/
@SuppressWarnings(
  'PMD.AvoidDebugStatements, PMD.UnusedLocalVariable, PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity, PMD.EmptyCatchBlock, PMD.ApexSuggestUsingNamedCred'
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
  @SuppressWarnings('PMD.EmptyCatchBlock')
  public static MetadataCreationResult createConfiguration(String configJson) {
    MetadataCreationResult result = createEmptyResult();

    try {
      // Validate input parameter type
      if (configJson == null) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_configJsonRequired;
        return result;
      }

      // Ensure configJson is a String (handle case where it might be passed as Object)
      String configJsonString = String.valueOf(configJson);

      // If the string appears to be double-encoded JSON, try to fix it
      if (configJsonString.startsWith('"') && configJsonString.endsWith('"')) {
        try {
          configJsonString = (String) JSON.deserialize(
            configJsonString,
            String.class
          );
        } catch (Exception e) {
          // If deserialization fails, use original string
          // This handles the case where it's a normal JSON string that happens to start/end with quotes
        }
      }

      // Deserialize and extract configuration values
      ConfigValues config = extractConfigValues(configJsonString);
      if (config == null) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_configJsonRequired;
        return result;
      }

      // CRITICAL: Only allow in development/test environments
      if (
        !validateSandboxOrScratch(
          result,
          Label.JT_MetadataCreator_creationNotAllowed
        )
      ) {
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
      params.bindings = String.isBlank(config.bindings)
        ? null
        : config.bindings;
      params.objectName = String.isBlank(config.objectName)
        ? null
        : config.objectName;

      // Build XML - catch any exceptions here to prevent serialization issues
      String metadataXml = buildMetadataXmlSafely(params, result);
      if (metadataXml == null) {
        return result;
      }

      // Deploy via Metadata API
      DeploymentResult deployResult = deployMetadata(
        metadataXml,
        sanitizedDevName
      );

      if (!deployResult.success) {
        result.success = false;
        result.errorMessage = deployResult.errorMessage;
        return result;
      }

      result.success = true;
      result.message = String.format(
        Label.JT_MetadataCreator_configCreatedSuccess,
        new List<String>{ config.label }
      );
      result.developerName = sanitizedDevName;
      result.deploymentId = deployResult.deploymentId;

      return result;
    } catch (Exception e) {
      result.success = false;
      setErrorResult(result, e);
      return result;
    }
  }

  /**
   * @description Deletes a Dynamic Query Configuration metadata record using Metadata API
   * @author Jaime Terrats | 12-11-2025
   * @param developerName Developer name of configuration to delete
   * @return MetadataCreationResult
   **/
  @AuraEnabled
  public static MetadataCreationResult deleteConfiguration(
    String developerName
  ) {
    MetadataCreationResult result = createEmptyResult();

    try {
      // CRITICAL: Only allow in development/test environments
      if (
        !validateSandboxOrScratch(
          result,
          Label.JT_MetadataCreator_deletionNotAllowed
        )
      ) {
        return result;
      }

      // Validate required field
      if (String.isBlank(developerName)) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_developerNameRequired;
        return result;
      }

      // Delete via Metadata API using deleteMetadata() SOAP call
      DeploymentResult deployResult = deleteMetadataViaApi(developerName);

      if (!deployResult.success) {
        result.success = false;
        result.errorMessage = deployResult.errorMessage;
        return result;
      }

      result.success = true;
      // Use message from deployResult if available, otherwise use default
      result.message = String.isNotBlank(deployResult.message)
        ? deployResult.message
        : String.format(
            Label.JT_MetadataCreator_configDeletedSuccess,
            new List<String>{ developerName }
          );
      result.developerName = developerName;
      // deleteMetadata() is synchronous, so deploymentId will be null
      // The LWC will handle this as a synchronous success
      result.deploymentId = deployResult.deploymentId;

      return result;
    } catch (Exception e) {
      result.success = false;
      setErrorResult(result, e);
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
    MetadataCreationResult result = createEmptyResult();

    try {
      // Deserialize and extract configuration values
      ConfigValues config = extractConfigValues(configJson);
      if (config == null) {
        result.success = false;
        result.errorMessage = Label.JT_MetadataCreator_configJsonRequired;
        return result;
      }

      // CRITICAL: Only allow in sandbox/scratch
      if (
        !validateSandboxOrScratch(
          result,
          Label.JT_MetadataCreator_editingNotAllowed
        )
      ) {
        return result;
      }

      // Validate required fields
      // Debug: Log the values to help diagnose the issue
      System.debug(
        LoggingLevel.DEBUG,
        'UpdateConfiguration - originalDevName: ' +
          config.originalDevName +
          ', label: ' +
          config.label +
          ', baseQuery: ' +
          (String.isNotBlank(config.baseQuery) ? 'present' : 'blank')
      );

      if (
        String.isBlank(config.originalDevName) ||
        String.isBlank(config.label) ||
        String.isBlank(config.baseQuery)
      ) {
        result.success = false;
        String missingFields = '';
        if (String.isBlank(config.originalDevName)) {
          missingFields += 'Original Developer Name, ';
        }
        if (String.isBlank(config.label)) {
          missingFields += 'Label, ';
        }
        if (String.isBlank(config.baseQuery)) {
          missingFields += 'Base Query, ';
        }
        missingFields = missingFields.removeEnd(', ');
        // Use the label directly if it doesn't support parameters, or format if it does
        try {
          result.errorMessage = String.format(
            Label.JT_MetadataCreator_updateRequiredFieldsMissing,
            new List<String>{ missingFields }
          );
        } catch (Exception e) {
          // Fallback if label doesn't support parameters
          result.errorMessage =
            Label.JT_MetadataCreator_updateRequiredFieldsMissing +
            ' ' +
            missingFields;
        }
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
        MetadataCreationResult renameResult = handleRename(
          config,
          sanitizedDevName
        );
        return renameResult;
      } else {
        // Normal update: Use original dev name
        MetadataParams params = new MetadataParams();
        params.label = config.label;
        params.devName = config.originalDevName;
        params.baseQuery = config.baseQuery;
        params.bindings = String.isBlank(config.bindings)
          ? null
          : config.bindings;
        params.objectName = String.isBlank(config.objectName)
          ? null
          : config.objectName;

        // Build XML - catch any exceptions here to prevent serialization issues
        String metadataXml = buildMetadataXmlSafely(params, result);
        if (metadataXml == null) {
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
        result.message = String.format(
          Label.JT_MetadataCreator_configUpdatedSuccess,
          new List<String>{ config.label }
        );
        result.developerName = config.originalDevName;
        result.deploymentId = deployResult.deploymentId;

        return result;
      }
    } catch (Exception e) {
      result.success = false;
      setErrorResult(result, e);
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
        'organizationType' => org.OrganizationType != null
          ? org.OrganizationType
          : 'Unknown',
        'isScratch' => org.TrialExpirationDate != null,
        'canCreateMetadata' => canCreate,
        'isProduction' => !isDevelopmentOrg,
        'productionOverrideEnabled' => productionOverride
      };
    } catch (Exception e) {
      // Ensure we always return a valid Map, never a String
      System.debug(
        LoggingLevel.ERROR,
        'Error in getOrgInfo: ' +
          e.getMessage() +
          '\n' +
          e.getStackTraceString()
      );
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
      throw new IllegalArgumentException(
        Label.JT_MetadataCreator_xmlGenerationRequiredFields
      );
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
    String message;
  }

  /**
   * @description Creates multipart/form-data body for Metadata API deployment
   * @param deploymentOptionsJson JSON string with deployment options
   * @param zipBlob ZIP file blob
   * @return Blob Multipart form data body
   **/
  private static Blob createMultipartFormDataBody(
    String deploymentOptionsJson,
    Blob zipBlob
  ) {
    String boundary = '--------------------------BOUNDARY';
    String crlf = '\r\n';

    // Part 1: JSON deployment options
    // Format matches successful examples: Content-Disposition and Content-Type on separate lines
    // Using "json" as field name (matches successful curl examples and Ruby examples)
    String jsonPart =
      '--' +
      boundary +
      crlf +
      'Content-Disposition: form-data; name="json"' +
      crlf +
      'Content-Type: application/json' +
      crlf +
      crlf +
      deploymentOptionsJson +
      crlf;

    // Part 2: ZIP file
    // Using "upload" as field name (matches successful curl examples from Stack Overflow)
    // Order: Content-Disposition first, then Content-Type
    String filePartHeader =
      '--' +
      boundary +
      crlf +
      'Content-Disposition: form-data; name="upload"; filename="deploy.zip"' +
      crlf +
      'Content-Type: application/zip' +
      crlf +
      crlf;

    // Footer - must include \r\n after ZIP and before final boundary
    // Format: \r\n--boundary--\r\n (matches successful Ruby example)
    String footer = crlf + '--' + boundary + '--' + crlf;

    // Convert string parts to blobs
    Blob jsonPartBlob = Blob.valueOf(jsonPart);
    Blob filePartHeaderBlob = Blob.valueOf(filePartHeader);
    Blob footerBlob = Blob.valueOf(footer);

    // Combine all parts: convert each to hex, concatenate hex strings, then convert back
    // This approach avoids multiple blob concatenations which could cause issues
    String hexJson = EncodingUtil.convertToHex(jsonPartBlob);
    String hexHeader = EncodingUtil.convertToHex(filePartHeaderBlob);
    String hexZip = EncodingUtil.convertToHex(zipBlob);
    String hexFooter = EncodingUtil.convertToHex(footerBlob);

    String combinedHex = hexJson + hexHeader + hexZip + hexFooter;

    return EncodingUtil.convertFromHex(combinedHex);
  }

  /**
   * @description Deletes metadata via Metadata API using deleteMetadata() SOAP call
   * This is simpler than deploy() with destructiveChanges.xml and avoids ZIP file issues
   * @author Jaime Terrats | 12-22-2025
   * @param devName Developer name of configuration to delete
   * @return DeploymentResult with success status, deploymentId, and errorMessage
   **/
  @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
  private static DeploymentResult deleteMetadataViaApi(String devName) {
    DeploymentResult result = new DeploymentResult();
    result.success = false;

    try {
      // Use deleteMetadata() SOAP call - simpler than deploy() with destructiveChanges.xml
      // Format: CustomMetadataType.DeveloperName
      String fullName = 'JT_DynamicQueryConfiguration__mdt.' + devName;
      List<String> fullNames = new List<String>{ fullName };

      // Create SOAP service
      JT_MetadataApiSoap.MetadataPort service = new JT_MetadataApiSoap.MetadataPort();
      service.SessionHeader = new JT_MetadataApiSoap.SessionHeader_element();
      service.SessionHeader.sessionId = JT_ToolingApiUtil.getApiSessionId();
      service.timeout_x = 120000;

      // Call deleteMetadata() - this is synchronous, no deployment ID needed
      JT_MetadataApiSoap.DeleteResult[] deleteResults = service.deleteMetadata(
        'CustomMetadata',
        fullNames
      );

      if (deleteResults != null && deleteResults.size() > 0) {
        JT_MetadataApiSoap.DeleteResult deleteResult = deleteResults[0];

        if (deleteResult.success != null && deleteResult.success) {
          result.success = true;
          result.message = String.format(
            Label.JT_MetadataCreator_configDeletedSuccess,
            new List<String>{ devName }
          );
          // deleteMetadata() is synchronous, so we don't return a deploymentId
          // The LWC will handle this as a synchronous success
          result.deploymentId = null;
          return result;
        } else {
          result.success = false;
          String errorMsg = String.isNotBlank(deleteResult.errorMessage)
            ? deleteResult.errorMessage
            : 'Delete operation failed';
          result.errorMessage = String.format(
            Label.JT_MetadataCreator_failedDeleteMetadata,
            new List<String>{ errorMsg }
          );
          Map<String, Object> errorDetails = new Map<String, Object>{
            'devName' => devName,
            'fullName' => fullName,
            'deleteResult' => JSON.serialize(deleteResult)
          };
          JT_ErrorLogger.logError(
            'Metadata Deletion Exception',
            result.errorMessage,
            null,
            'JT_MetadataCreator.deleteMetadataViaApi - deleteMetadata() failed',
            JSON.serialize(errorDetails),
            'High'
          );
          return result;
        }
      } else {
        result.success = false;
        result.errorMessage = String.format(
          Label.JT_MetadataCreator_failedDeleteMetadata,
          new List<String>{ 'No result returned from deleteMetadata()' }
        );
        Map<String, Object> errorDetails = new Map<String, Object>{
          'devName' => devName,
          'fullName' => fullName
        };
        JT_ErrorLogger.logError(
          'Metadata Deletion Exception',
          result.errorMessage,
          null,
          'JT_MetadataCreator.deleteMetadataViaApi - No result returned',
          JSON.serialize(errorDetails),
          'High'
        );
        return result;
      }
    } catch (Exception e) {
      String errorMsg = e.getMessage();
      result.success = false;
      result.errorMessage = String.format(
        Label.JT_MetadataCreator_failedDeleteMetadata,
        new List<String>{ errorMsg }
      );
      Map<String, Object> errorDetails = new Map<String, Object>{
        'devName' => devName,
        'exceptionType' => e.getTypeName()
      };
      JT_ErrorLogger.logError(
        'Metadata Deletion Exception',
        errorMsg,
        e,
        'JT_MetadataCreator.deleteMetadataViaApi',
        JSON.serialize(errorDetails),
        'High'
      );
      return result;
    }
  }

  /**
   * @description Creates a ZIP file in memory containing package.xml and destructiveChanges.xml
   * @param packageXml Content of package.xml
   * @param destructiveChangesXml Content of destructiveChanges.xml
   * @return Blob ZIP file content
   **/
  private static Blob createMetadataZip(
    String packageXml,
    String destructiveChangesXml
  ) {
    Blob packageBlob = Blob.valueOf(packageXml);
    Blob destructiveBlob = Blob.valueOf(destructiveChangesXml);

    // Build ZIP file structure
    List<Blob> zipParts = new List<Blob>();

    // Entry 1: package.xml local file header + data
    Blob packageHeader = createZipLocalFileHeaderBlob(
      'package.xml',
      packageBlob.size()
    );
    Integer packageOffset = 0; // Offset of package.xml header in ZIP
    zipParts.add(packageHeader);
    zipParts.add(packageBlob);

    // Entry 2: destructiveChanges.xml local file header + data
    Blob destructiveHeader = createZipLocalFileHeaderBlob(
      'destructiveChanges.xml',
      destructiveBlob.size()
    );
    // Calculate offset: package header + package data
    Integer destructiveOffset = packageHeader.size() + packageBlob.size();
    zipParts.add(destructiveHeader);
    zipParts.add(destructiveBlob);

    // Calculate central directory offset
    // Sum of: package header + package data + destructive header + destructive data
    Integer centralDirOffset =
      packageHeader.size() +
      packageBlob.size() +
      destructiveHeader.size() +
      destructiveBlob.size();

    System.debug(
      LoggingLevel.INFO,
      '📦 ZIP Structure: packageHeader=' +
        packageHeader.size() +
        ', packageData=' +
        packageBlob.size() +
        ', destructiveHeader=' +
        destructiveHeader.size() +
        ', destructiveData=' +
        destructiveBlob.size() +
        ', centralDirOffset=' +
        centralDirOffset
    );
    System.debug(
      LoggingLevel.INFO,
      '📦 Offsets: packageOffset=' +
        packageOffset +
        ', destructiveOffset=' +
        destructiveOffset
    );

    // Central directory
    Blob centralDir = createZipCentralDirectoryBlob(
      'package.xml',
      packageBlob.size(),
      packageOffset
    );
    Blob destructiveCentralDir = createZipCentralDirectoryBlob(
      'destructiveChanges.xml',
      destructiveBlob.size(),
      destructiveOffset
    );
    centralDir = combineBlobs(centralDir, destructiveCentralDir);
    zipParts.add(centralDir);

    // End of central directory
    Integer centralDirSize = centralDir.size();
    System.debug(
      LoggingLevel.INFO,
      '📦 Central Directory: size=' +
        centralDirSize +
        ', offset=' +
        centralDirOffset
    );
    zipParts.add(
      createZipEndOfCentralDirectoryBlob(2, centralDirSize, centralDirOffset)
    );

    // Combine all parts into final ZIP
    Blob finalZip = zipParts[0];
    Integer cumulativeSize = zipParts[0].size();
    for (Integer i = 1; i < zipParts.size(); i++) {
      System.debug(
        LoggingLevel.INFO,
        '📦 Combining part ' +
          i +
          ': size=' +
          zipParts[i].size() +
          ', cumulative=' +
          cumulativeSize
      );
      finalZip = combineBlobs(finalZip, zipParts[i]);
      cumulativeSize += zipParts[i].size();
    }

    System.debug(
      LoggingLevel.INFO,
      '📦 Final ZIP size: ' +
        finalZip.size() +
        ' bytes (expected: ' +
        cumulativeSize +
        ')'
    );

    return finalZip;
  }

  /**
   * @description Combines two Blobs into one
   * @param blob1 First blob
   * @param blob2 Second blob
   * @return Blob Combined blob
   **/
  private static Blob combineBlobs(Blob blob1, Blob blob2) {
    // Combine blobs using hex encoding (more reliable than base64 concatenation)
    String hex1 = EncodingUtil.convertToHex(blob1);
    String hex2 = EncodingUtil.convertToHex(blob2);
    String combinedHex = hex1 + hex2;
    return EncodingUtil.convertFromHex(combinedHex);
  }

  /**
   * @description Creates a ZIP local file header as Blob
   * @param fileName File name
   * @param fileSize File size
   * @return Blob ZIP local file header
   **/
  private static Blob createZipLocalFileHeaderBlob(
    String fileName,
    Integer fileSize
  ) {
    // ZIP local file header structure (30 bytes + filename length)
    // Signature: PK\x03\x04 (4 bytes)
    // Version: 20 (2 bytes)
    // Flags: 0 (2 bytes)
    // Compression: 0 (2 bytes)
    // Mod time: 0 (2 bytes)
    // Mod date: 0 (2 bytes)
    // CRC32: 0 (4 bytes)
    // Compressed size: fileSize (4 bytes, little endian)
    // Uncompressed size: fileSize (4 bytes, little endian)
    // Filename length: fileName.length() (2 bytes, little endian)
    // Extra field length: 0 (2 bytes)
    // Filename: fileName (variable length)

    List<Integer> headerBytes = new List<Integer>();

    // PK\x03\x04 (signature)
    headerBytes.add(80); // P
    headerBytes.add(75); // K
    headerBytes.add(3);
    headerBytes.add(4);

    // Version (20 = 0x14)
    headerBytes.add(20);
    headerBytes.add(0);

    // Flags (0)
    headerBytes.add(0);
    headerBytes.add(0);

    // Compression method (0 = stored)
    headerBytes.add(0);
    headerBytes.add(0);

    // Mod time (0)
    headerBytes.add(0);
    headerBytes.add(0);

    // Mod date (0)
    headerBytes.add(0);
    headerBytes.add(0);

    // CRC32 (0)
    headerBytes.add(0);
    headerBytes.add(0);
    headerBytes.add(0);
    headerBytes.add(0);

    // Compressed size (little endian, 4 bytes)
    List<Integer> sizeBytes = intToLittleEndianBytes(fileSize, 4);
    headerBytes.addAll(sizeBytes);

    // Uncompressed size (little endian, 4 bytes)
    headerBytes.addAll(sizeBytes);

    // Filename length (little endian, 2 bytes)
    List<Integer> nameLenBytes = intToLittleEndianBytes(fileName.length(), 2);
    headerBytes.addAll(nameLenBytes);

    // Extra field length (0)
    headerBytes.add(0);
    headerBytes.add(0);

    // Filename (convert string to bytes)
    Blob fileNameBlob = Blob.valueOf(fileName);
    String hexFileName = EncodingUtil.convertToHex(fileNameBlob);
    // Convert hex string back to bytes
    for (Integer i = 0; i < hexFileName.length(); i += 2) {
      String hexByte = hexFileName.substring(i, i + 2);
      headerBytes.add(hexToInteger(hexByte));
    }

    // Convert to Blob
    return bytesToBlob(headerBytes);
  }

  /**
   * @description Creates a ZIP central directory entry as Blob
   * @param fileName File name
   * @param fileSize File size
   * @param localHeaderOffset Offset of local file header
   * @return Blob ZIP central directory entry
   **/
  private static Blob createZipCentralDirectoryBlob(
    String fileName,
    Integer fileSize,
    Integer localHeaderOffset
  ) {
    // ZIP central directory entry structure (46 bytes + filename length)
    List<Integer> entryBytes = new List<Integer>();

    // PK\x01\x02 (signature)
    entryBytes.add(80); // P
    entryBytes.add(75); // K
    entryBytes.add(1);
    entryBytes.add(2);

    // Version made by (20)
    entryBytes.add(20);
    entryBytes.add(0);

    // Version needed (20)
    entryBytes.add(20);
    entryBytes.add(0);

    // Flags (0)
    entryBytes.add(0);
    entryBytes.add(0);

    // Compression method (0)
    entryBytes.add(0);
    entryBytes.add(0);

    // Mod time (0)
    entryBytes.add(0);
    entryBytes.add(0);

    // Mod date (0)
    entryBytes.add(0);
    entryBytes.add(0);

    // CRC32 (0)
    entryBytes.add(0);
    entryBytes.add(0);
    entryBytes.add(0);
    entryBytes.add(0);

    // Compressed size (little endian, 4 bytes)
    entryBytes.addAll(intToLittleEndianBytes(fileSize, 4));

    // Uncompressed size (little endian, 4 bytes)
    entryBytes.addAll(intToLittleEndianBytes(fileSize, 4));

    // Filename length (little endian, 2 bytes)
    entryBytes.addAll(intToLittleEndianBytes(fileName.length(), 2));

    // Extra field length (0)
    entryBytes.add(0);
    entryBytes.add(0);

    // Comment length (0)
    entryBytes.add(0);
    entryBytes.add(0);

    // Disk number (0)
    entryBytes.add(0);
    entryBytes.add(0);

    // Internal attributes (0)
    entryBytes.add(0);
    entryBytes.add(0);

    // External attributes (0, 4 bytes)
    entryBytes.add(0);
    entryBytes.add(0);
    entryBytes.add(0);
    entryBytes.add(0);

    // Local header offset (little endian, 4 bytes)
    entryBytes.addAll(intToLittleEndianBytes(localHeaderOffset, 4));

    // Filename (convert string to bytes)
    Blob fileNameBlob = Blob.valueOf(fileName);
    String hexFileName = EncodingUtil.convertToHex(fileNameBlob);
    // Convert hex string back to bytes
    for (Integer i = 0; i < hexFileName.length(); i += 2) {
      String hexByte = hexFileName.substring(i, i + 2);
      entryBytes.add(hexToInteger(hexByte));
    }

    return bytesToBlob(entryBytes);
  }

  /**
   * @description Creates ZIP end of central directory record as Blob
   * @param entryCount Number of entries
   * @param centralDirSize Size of central directory
   * @param centralDirOffset Offset of central directory
   * @return Blob ZIP end of central directory record
   **/
  private static Blob createZipEndOfCentralDirectoryBlob(
    Integer entryCount,
    Integer centralDirSize,
    Integer centralDirOffset
  ) {
    // ZIP end of central directory record (22 bytes)
    List<Integer> recordBytes = new List<Integer>();

    // PK\x05\x06 (signature)
    recordBytes.add(80); // P
    recordBytes.add(75); // K
    recordBytes.add(5);
    recordBytes.add(6);

    // Disk number (0, 2 bytes)
    recordBytes.add(0);
    recordBytes.add(0);

    // Central directory disk (0, 2 bytes)
    recordBytes.add(0);
    recordBytes.add(0);

    // Entries on this disk (little endian, 2 bytes)
    recordBytes.addAll(intToLittleEndianBytes(entryCount, 2));

    // Total entries (little endian, 2 bytes)
    recordBytes.addAll(intToLittleEndianBytes(entryCount, 2));

    // Central directory size (little endian, 4 bytes)
    recordBytes.addAll(intToLittleEndianBytes(centralDirSize, 4));

    // Central directory offset (little endian, 4 bytes)
    recordBytes.addAll(intToLittleEndianBytes(centralDirOffset, 4));

    // Comment length (0, 2 bytes)
    recordBytes.add(0);
    recordBytes.add(0);

    return bytesToBlob(recordBytes);
  }

  /**
   * @description Converts integer to little-endian byte array
   * @param value Integer value
   * @param byteCount Number of bytes (2 or 4)
   * @return List<Integer> Little-endian byte representation
   **/
  private static List<Integer> intToLittleEndianBytes(
    Integer value,
    Integer byteCount
  ) {
    List<Integer> bytes = new List<Integer>();
    Integer mask = 255; // 0xFF equivalent
    for (Integer i = 0; i < byteCount; i++) {
      bytes.add((value >> (i * 8)) & mask);
    }
    return bytes;
  }

  /**
   * @description Converts hexadecimal string to integer
   * @param hex Hexadecimal string (e.g., "FF", "0A")
   * @return Integer Decimal value
   **/
  private static Integer hexToInteger(String hex) {
    // Convert hex string to integer manually
    Integer result = 0;
    String upperHex = hex.toUpperCase();
    for (Integer i = 0; i < upperHex.length(); i++) {
      Integer digit = 0;
      String charAt = upperHex.substring(i, i + 1);
      if (charAt >= '0' && charAt <= '9') {
        digit = Integer.valueOf(charAt);
      } else if (charAt >= 'A' && charAt <= 'F') {
        digit = charAt.charAt(0) - 'A'.charAt(0) + 10;
      }
      result = result * 16 + digit;
    }
    return result;
  }

  /**
   * @description Converts list of bytes to Blob
   * @param bytes List of byte values (0-255)
   * @return Blob Blob representation
   **/
  private static Blob bytesToBlob(List<Integer> bytes) {
    // Convert bytes to hex string, then to Blob
    // Use a more direct approach: convert each byte to 2-digit hex
    String hexString = '';
    Integer mask = 255; // 0xFF equivalent
    String hexChars = '0123456789ABCDEF';
    for (Integer b : bytes) {
      // Ensure byte is in valid range (0-255)
      Integer byteValue = b & mask;
      // Convert to 2-digit hex string
      Integer highNibble = (byteValue >> 4) & 15;
      Integer lowNibble = byteValue & 15;
      hexString += hexChars.substring(highNibble, highNibble + 1);
      hexString += hexChars.substring(lowNibble, lowNibble + 1);
    }
    return EncodingUtil.convertFromHex(hexString);
  }

  /**
   * @description Deploys metadata via native Metadata API
   * @author Jaime Terrats | 12-13-2025
   * @param metadataXml XML content
   * @param devName Developer name
   * @return DeploymentResult with success status, deploymentId, and errorMessage
   **/
  private static DeploymentResult deployMetadata(
    String metadataXml,
    String devName
  ) {
    DeploymentResult result = new DeploymentResult();
    result.success = false;

    try {
      // Parse XML to extract metadata values
      Map<String, Object> metadataJson = parseMetadataXmlToJson(metadataXml);

      // Create CustomMetadata object using native Metadata API
      Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
      customMetadata.fullName = 'JT_DynamicQueryConfiguration__mdt.' + devName;

      // Set label (required field)
      if (metadataJson.containsKey('label')) {
        customMetadata.label = (String) metadataJson.get('label');
      } else {
        customMetadata.label = devName; // Fallback to devName if label not provided
      }

      // Add field values
      if (metadataJson.containsKey('values')) {
        List<Object> values = (List<Object>) metadataJson.get('values');
        for (Object valueObj : values) {
          Map<String, Object> valueMap = (Map<String, Object>) valueObj;
          Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
          customField.field = (String) valueMap.get('field');
          customField.value = valueMap.get('value');
          customMetadata.values.add(customField);
        }
      }

      // Create deployment container
      Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
      mdContainer.addMetadata(customMetadata);

      // Create callback
      JT_MetadataDeployCallback callback = new JT_MetadataDeployCallback();

      // Enqueue deployment (asynchronous)
      Id deployRequestId = Metadata.Operations.enqueueDeployment(
        mdContainer,
        callback
      );

      // Return immediately with deployment ID for polling
      result.success = true;
      result.deploymentId = deployRequestId;
      return result;
    } catch (Exception e) {
      String errorMsg = e.getMessage();
      if (String.isBlank(errorMsg)) {
        errorMsg = String.format(
          Label.JT_MetadataCreator_unexpectedErrorDeployment,
          new List<String>{ e.getTypeName() }
        );
      }
      result.errorMessage = String.format(
        Label.JT_MetadataCreator_errorDeployingMetadata,
        new List<String>{ errorMsg }
      );

      // Log deployment exception
      Map<String, Object> details = new Map<String, Object>{
        'devName' => devName,
        'exceptionType' => e.getTypeName()
      };
      JT_ErrorLogger.logError(
        'Metadata Deployment Exception',
        errorMsg,
        e,
        'JT_MetadataCreator.deployMetadata',
        JSON.serialize(details),
        'High'
      );

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
      // Handle case where configJson might already be a Map (shouldn't happen, but defensive)
      Map<String, Object> configMap;

      // Try to deserialize as JSON string first
      try {
        Object deserialized = JSON.deserializeUntyped(configJson);

        // Ensure we have a Map, not a List or String
        if (deserialized instanceof Map<String, Object>) {
          configMap = (Map<String, Object>) deserialized;
        } else if (deserialized instanceof String) {
          // If it's a String, try to deserialize again (double-encoded case)
          Object innerDeserialized = JSON.deserializeUntyped(
            (String) deserialized
          );
          if (innerDeserialized instanceof Map<String, Object>) {
            configMap = (Map<String, Object>) innerDeserialized;
          } else {
            System.debug(
              LoggingLevel.ERROR,
              String.format(
                Label.JT_MetadataCreator_invalidJsonFormat,
                new List<String>{
                  'Expected Map but got: ' + String.valueOf(innerDeserialized)
                }
              )
            );
            return null;
          }
        } else {
          System.debug(
            LoggingLevel.ERROR,
            String.format(
              Label.JT_MetadataCreator_invalidJsonFormat,
              new List<String>{
                'Expected Map but got: ' + String.valueOf(deserialized)
              }
            )
          );
          return null;
        }
      } catch (Exception je) {
        // If JSON deserialization fails, log and return null
        System.debug(
          LoggingLevel.ERROR,
          String.format(
            Label.JT_MetadataCreator_errorDeserializingJson,
            new List<String>{ je.getMessage() }
          )
        );
        return null;
      }

      System.debug(
        LoggingLevel.ERROR,
        '🔍 Extracted configMap: ' + JSON.serialize(configMap)
      );

      // Extract values from map (handle null values safely)
      ConfigValues config = new ConfigValues();
      config.label = configMap.get('label') != null
        ? String.valueOf(configMap.get('label'))
        : null;
      config.developerName = configMap.get('developerName') != null
        ? String.valueOf(configMap.get('developerName'))
        : null;
      config.baseQuery = configMap.get('baseQuery') != null
        ? String.valueOf(configMap.get('baseQuery'))
        : null;
      config.bindings = configMap.get('bindings') != null
        ? String.valueOf(configMap.get('bindings'))
        : null;
      config.objectName = configMap.get('objectName') != null
        ? String.valueOf(configMap.get('objectName'))
        : null;
      config.originalDevName = configMap.get('originalDevName') != null
        ? String.valueOf(configMap.get('originalDevName'))
        : null;

      return config;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        String.format(
          Label.JT_MetadataCreator_errorDeserializingJson,
          new List<String>{ e.getMessage() }
        )
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
    MetadataCreationResult result = createEmptyResult();

    // Step 1: Delete old record
    MetadataCreationResult deleteResult = deleteConfiguration(
      config.originalDevName
    );

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
        throw new AuraHandledException(
          Label.JT_MetadataCreator_queryMustStartWithSelect
        );
      }

      if (!query.toUpperCase().contains('FROM')) {
        throw new AuraHandledException(
          Label.JT_MetadataCreator_queryMustContainFrom
        );
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
      String errorMsg = e.getMessage();
      // AuraHandledException messages are already user-friendly, use as-is
      result.message = String.isNotBlank(errorMsg)
        ? errorMsg
        : Label.JT_MetadataCreator_queryMustStartWithSelect;
    }

    return result;
  }

  /**
   * @description Creates an empty MetadataCreationResult with all fields initialized
   * Centralizes result initialization to avoid duplication
   * @return MetadataCreationResult Empty result with all fields initialized
   **/
  private static MetadataCreationResult createEmptyResult() {
    MetadataCreationResult result = new MetadataCreationResult();
    result.success = false;
    result.message = null;
    result.errorMessage = null;
    result.stackTrace = null;
    result.developerName = null;
    result.deploymentId = null;
    return result;
  }

  /**
   * @description Sets error information on a MetadataCreationResult
   * Centralizes error handling to avoid duplication
   * @param result Result object to update
   * @param e Exception that occurred
   **/
  private static void setErrorResult(
    MetadataCreationResult result,
    Exception e
  ) {
    String errorMsg = e.getMessage();
    if (String.isBlank(errorMsg)) {
      errorMsg = String.format(
        Label.JT_MetadataCreator_unexpectedError,
        new List<String>{ e.getTypeName() }
      );
    }
    result.errorMessage = errorMsg;
    result.stackTrace = e.getStackTraceString();
  }

  /**
   * @description Validates if current org is sandbox/scratch and sets error if not
   * Centralizes sandbox validation to avoid duplication
   * @param result Result object to update if validation fails
   * @param errorLabel Label to use for error message
   * @return Boolean True if validation passes, false otherwise
   **/
  private static Boolean validateSandboxOrScratch(
    MetadataCreationResult result,
    String errorLabel
  ) {
    if (!isSandboxOrScratch()) {
      result.success = false;
      result.errorMessage = errorLabel;
      return false;
    }
    return true;
  }

  /**
   * @description Builds metadata XML safely with error handling
   * Centralizes XML building error handling to avoid duplication
   * @param params MetadataParams wrapper containing all metadata fields
   * @param result Result object to update if building fails
   * @return String XML content, or null if building failed
   **/
  private static String buildMetadataXmlSafely(
    MetadataParams params,
    MetadataCreationResult result
  ) {
    try {
      return buildMetadataXml(params);
    } catch (IllegalArgumentException iae) {
      result.success = false;
      String iaeMsg = iae.getMessage();
      result.errorMessage = String.isNotBlank(iaeMsg)
        ? iaeMsg
        : Label.JT_MetadataCreator_invalidMetadataParams;
      return null;
    } catch (Exception xmlEx) {
      result.success = false;
      String xmlMsg = xmlEx.getMessage();
      String xmlErrorMsg = String.isNotBlank(xmlMsg)
        ? xmlMsg
        : xmlEx.getTypeName();
      result.errorMessage = String.format(
        Label.JT_MetadataCreator_errorBuildingXml,
        new List<String>{ xmlErrorMsg }
      );
      return null;
    }
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
   * @description Checks the status of a metadata deployment
   * @author Jaime Terrats | 12-13-2025
   * @param deploymentId The deployment ID returned from enqueueDeployment
   * @return Map<String, Object> Deployment status information
   **/
  @AuraEnabled
  public static Map<String, Object> checkDeploymentStatus(String deploymentId) {
    Map<String, Object> status = new Map<String, Object>();
    status.put('deploymentId', deploymentId);

    try {
      if (String.isBlank(deploymentId)) {
        status.put('status', 'ERROR');
        status.put('error', 'Deployment ID is required');
        return status;
      }

      // Check deployment status via Metadata API (not Tooling API)
      // Note: Metadata API uses /services/data/vXX.X/metadata/deployRequest/ID
      final String endpointPath =
        '/services/data/' +
        JT_ToolingApiUtil.getApiVersion() +
        '/metadata/deployRequest/' +
        deploymentId +
        '?includeDetails=true';

      final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
        endpointPath,
        'GET',
        30000
      );

      final Http httpClient = new Http();
      final HttpResponse response = httpClient.send(request);

      if (response.getStatusCode() == 200) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
          response.getBody()
        );

        // Extract deployResult from response
        Map<String, Object> deployResult = (Map<String, Object>) responseMap.get(
          'deployResult'
        );

        // Extract status, done, and success from deployResult
        String deployStatus = deployResult != null
          ? (String) deployResult.get('status')
          : null;
        Boolean done = deployResult != null
          ? (Boolean) deployResult.get('done')
          : null;
        Boolean success = deployResult != null
          ? (Boolean) deployResult.get('success')
          : null;

        status.put('status', deployStatus != null ? deployStatus : 'UNKNOWN');
        status.put('done', done != null ? done : false);
        status.put('success', success != null ? success : false);

        // Extract error details if deployment failed
        if (done != null && done && success != null && !success) {
          if (deployResult != null) {
            Map<String, Object> details = (Map<String, Object>) deployResult.get(
              'details'
            );
            if (details != null) {
              List<Object> componentFailures = (List<Object>) details.get(
                'componentFailures'
              );
              if (componentFailures != null && !componentFailures.isEmpty()) {
                Map<String, Object> firstFailure = (Map<String, Object>) componentFailures[0];
                String problem = (String) firstFailure.get('problem');
                status.put('error', problem);
                status.put('fullName', firstFailure.get('fullName'));
              }
            }
            String errorMessage = (String) deployResult.get('errorMessage');
            if (String.isNotBlank(errorMessage)) {
              status.put('error', errorMessage);
            }
          }
        } else if (done != null && done && success != null && success) {
          // Deployment succeeded
          if (deployResult != null) {
            Map<String, Object> details = (Map<String, Object>) deployResult.get(
              'details'
            );
            if (details != null) {
              List<Object> componentSuccesses = (List<Object>) details.get(
                'componentSuccesses'
              );
              if (componentSuccesses != null) {
                status.put('componentsDeployed', componentSuccesses.size());
              }
            }
          }
        }
      } else {
        status.put('status', 'ERROR');
        status.put(
          'error',
          'Failed to check deployment status: ' + response.getBody()
        );
      }
    } catch (Exception e) {
      status.put('status', 'ERROR');
      String errorMsg = e.getMessage();
      if (String.isBlank(errorMsg)) {
        errorMsg =
          'Unexpected error checking deployment status: ' + e.getTypeName();
      }
      status.put('error', errorMsg);

      // Log error
      Map<String, Object> details = new Map<String, Object>{
        'deploymentId' => deploymentId,
        'exceptionType' => e.getTypeName()
      };
      JT_ErrorLogger.logError(
        'Deployment Status Check Failed',
        errorMsg,
        e,
        'JT_MetadataCreator.checkDeploymentStatus',
        JSON.serialize(details),
        'Medium'
      );
    }

    // Log final status map before returning
    return status;
  }

  /**
   * @description Parses error response from Metadata API
   * @param errorBody Raw error response body
   * @return String Parsed error message
   **/
  private static String parseErrorResponse(String errorBody) {
    if (String.isBlank(errorBody)) {
      return 'Unknown error: Empty response';
    }

    try {
      // Try to parse as JSON array (common format: [{"message":"...","errorCode":"..."}])
      Object parsed = JSON.deserializeUntyped(errorBody);
      if (parsed instanceof List<Object>) {
        List<Object> errors = (List<Object>) parsed;
        List<String> errorMessages = new List<String>();
        for (Object errorObj : errors) {
          if (errorObj instanceof Map<String, Object>) {
            Map<String, Object> errorMap = (Map<String, Object>) errorObj;
            String message = (String) errorMap.get('message');
            String errorCode = (String) errorMap.get('errorCode');
            if (String.isNotBlank(message)) {
              String fullMessage = message;
              if (String.isNotBlank(errorCode)) {
                fullMessage += ' (Error Code: ' + errorCode + ')';
              }
              errorMessages.add(fullMessage);
            }
          }
        }
        if (!errorMessages.isEmpty()) {
          return String.join(errorMessages, '; ');
        }
      } else if (parsed instanceof Map<String, Object>) {
        // Try as single object
        Map<String, Object> errorMap = (Map<String, Object>) parsed;
        String message = (String) errorMap.get('message');
        if (String.isNotBlank(message)) {
          return message;
        }
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.WARN,
        '⚠️ Failed to parse error response: ' + e.getMessage()
      );
    }

    // Fallback: return raw body if parsing fails
    return errorBody;
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
