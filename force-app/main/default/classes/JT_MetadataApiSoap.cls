/**
 * @description Minimal SOAP wrapper for Salesforce Metadata API deploy() method
 * Used for deploying metadata with destructiveChanges.xml (deletions)
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 12-22-2025
 **/
public class JT_MetadataApiSoap {
  /**
   * @description Deploy options for Metadata API deployment
   */
  public class DeployOptions {
    public Boolean allowMissingFiles;
    public Boolean autoUpdatePackage;
    public Boolean checkOnly;
    public Boolean ignoreWarnings;
    public Boolean performRetrieve;
    public Boolean purgeOnDelete;
    public Boolean rollbackOnError;
    public Boolean runAllTests;
    public String[] runTests;
    public Boolean singlePackage;
    public String testLevel;
  }

  /**
   * @description Async result from deploy() call
   */
  public class AsyncResult {
    public Boolean done;
    public String id;
    public String message;
    public String state;
    public String statusCode;
    public String[] warnings;
  }

  /**
   * @description Session header for SOAP authentication
   */
  public class SessionHeader_element {
    public String sessionId;
  }

  /**
   * @description Metadata API SOAP endpoint
   * Uses the Metadata API WSDL endpoint
   */
  public class MetadataPort {
    public String endpoint_x {
      get {
        if (endpoint_x == null) {
          String apiVersion = JT_ToolingApiUtil.getApiVersion().substring(1); // Remove 'v' prefix
          endpoint_x =
            URL.getOrgDomainUrl().toExternalForm() +
            '/services/Soap/m/' +
            apiVersion;
        }
        return endpoint_x;
      }
      set;
    }
    public Map<String, String> inputHttpHeaders_x;
    public Map<String, String> outputHttpHeaders_x;
    public String clientCertName_x;
    public String clientCert_x;
    public String clientCertPasswd_x;
    public Integer timeout_x;
    public JT_MetadataApiSoap.SessionHeader_element SessionHeader;

    /**
     * @description Deploys metadata ZIP file via SOAP API
     * @param zipFile ZIP file blob containing package.xml and destructiveChanges.xml
     * @param deployOptions Deployment options
     * @return AsyncResult Async result with deployment ID
     */
    public JT_MetadataApiSoap.AsyncResult deploy(
      Blob zipFile,
      JT_MetadataApiSoap.DeployOptions deployOptions
    ) {
      JT_MetadataApiSoap.AsyncResult result = new JT_MetadataApiSoap.AsyncResult();

      JT_MetadataApiSoap.deploy_element request_x = new JT_MetadataApiSoap.deploy_element();
      request_x.zipFile = zipFile;
      request_x.DeployOptions = deployOptions;

      // Build SOAP request
      String soapAction = '""';
      String soapBody = buildSoapRequest(request_x);

      HttpRequest req = new HttpRequest();
      req.setEndpoint(this.endpoint_x);
      req.setMethod('POST');
      req.setHeader('Content-Type', 'text/xml; charset=UTF-8');
      req.setHeader('SOAPAction', soapAction);
      req.setBody(soapBody);
      req.setTimeout(this.timeout_x != null ? this.timeout_x : 120000);

      Http http = new Http();
      HttpResponse res = http.send(req);

      // Always parse SOAP response, even if HTTP status is not 200
      // SOAP Faults are returned in the body with HTTP 500, but can be parsed
      JT_MetadataApiSoap.AsyncResult parsedResult = parseDeployResponse(
        res.getBody()
      );

      // If parsing failed or HTTP status is not 200, include status code in message
      if (res.getStatusCode() != 200 && String.isBlank(parsedResult.message)) {
        parsedResult.message = 'HTTP Error: ' + res.getStatusCode();
      } else if (
        res.getStatusCode() != 200 && String.isNotBlank(parsedResult.message)
      ) {
        // Prepend HTTP status to parsed fault message
        parsedResult.message =
          'HTTP ' +
          res.getStatusCode() +
          ': ' +
          parsedResult.message;
      }

      return parsedResult;
    }

    /**
     * @description Builds SOAP request XML
     */
    private String buildSoapRequest(
      JT_MetadataApiSoap.deploy_element request_x
    ) {
      String soapBody = '<?xml version="1.0" encoding="UTF-8"?>';
      soapBody += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:met="http://soap.sforce.com/2006/04/metadata">';
      soapBody += '<soapenv:Header>';
      if (this.SessionHeader != null) {
        soapBody += '<met:SessionHeader>';
        soapBody +=
          '<met:sessionId>' +
          String.valueOf(this.SessionHeader.sessionId).escapeXml() +
          '</met:sessionId>';
        soapBody += '</met:SessionHeader>';
      }
      soapBody += '</soapenv:Header>';
      soapBody += '<soapenv:Body>';
      soapBody += '<met:deploy>';
      soapBody +=
        '<met:ZipFile>' +
        EncodingUtil.base64Encode(request_x.zipFile) +
        '</met:ZipFile>';
      if (request_x.DeployOptions != null) {
        soapBody += '<met:DeployOptions>';
        if (request_x.DeployOptions.allowMissingFiles != null) {
          soapBody +=
            '<met:allowMissingFiles>' +
            request_x.DeployOptions.allowMissingFiles +
            '</met:allowMissingFiles>';
        }
        if (request_x.DeployOptions.autoUpdatePackage != null) {
          soapBody +=
            '<met:autoUpdatePackage>' +
            request_x.DeployOptions.autoUpdatePackage +
            '</met:autoUpdatePackage>';
        }
        if (request_x.DeployOptions.checkOnly != null) {
          soapBody +=
            '<met:checkOnly>' +
            request_x.DeployOptions.checkOnly +
            '</met:checkOnly>';
        }
        if (request_x.DeployOptions.ignoreWarnings != null) {
          soapBody +=
            '<met:ignoreWarnings>' +
            request_x.DeployOptions.ignoreWarnings +
            '</met:ignoreWarnings>';
        }
        if (request_x.DeployOptions.performRetrieve != null) {
          soapBody +=
            '<met:performRetrieve>' +
            request_x.DeployOptions.performRetrieve +
            '</met:performRetrieve>';
        }
        if (request_x.DeployOptions.purgeOnDelete != null) {
          soapBody +=
            '<met:purgeOnDelete>' +
            request_x.DeployOptions.purgeOnDelete +
            '</met:purgeOnDelete>';
        }
        if (request_x.DeployOptions.rollbackOnError != null) {
          soapBody +=
            '<met:rollbackOnError>' +
            request_x.DeployOptions.rollbackOnError +
            '</met:rollbackOnError>';
        }
        if (request_x.DeployOptions.runAllTests != null) {
          soapBody +=
            '<met:runAllTests>' +
            request_x.DeployOptions.runAllTests +
            '</met:runAllTests>';
        }
        if (
          request_x.DeployOptions.runTests != null &&
          request_x.DeployOptions.runTests.size() > 0
        ) {
          soapBody += '<met:runTests>';
          for (String test : request_x.DeployOptions.runTests) {
            soapBody +=
              '<met:runTests>' +
              String.valueOf(test).escapeXml() +
              '</met:runTests>';
          }
          soapBody += '</met:runTests>';
        }
        if (request_x.DeployOptions.singlePackage != null) {
          soapBody +=
            '<met:singlePackage>' +
            request_x.DeployOptions.singlePackage +
            '</met:singlePackage>';
        }
        if (request_x.DeployOptions.testLevel != null) {
          soapBody +=
            '<met:testLevel>' +
            String.valueOf(request_x.DeployOptions.testLevel).escapeXml() +
            '</met:testLevel>';
        }
        soapBody += '</met:DeployOptions>';
      }
      soapBody += '</met:deploy>';
      soapBody += '</soapenv:Body>';
      soapBody += '</soapenv:Envelope>';
      return soapBody;
    }

    /**
     * @description Parses SOAP response XML using Dom.Document
     */
    private JT_MetadataApiSoap.AsyncResult parseDeployResponse(
      String soapResponse
    ) {
      JT_MetadataApiSoap.AsyncResult result = new JT_MetadataApiSoap.AsyncResult();

      try {
        Dom.Document doc = new Dom.Document();
        doc.load(soapResponse);

        Dom.XmlNode envelope = doc.getRootElement();

        // Check for SOAP Fault - it's inside Body, not directly in Envelope
        Dom.XmlNode body = envelope.getChildElement(
          'Body',
          'http://schemas.xmlsoap.org/soap/envelope/'
        );

        if (body != null) {
          Dom.XmlNode fault = body.getChildElement(
            'Fault',
            'http://schemas.xmlsoap.org/soap/envelope/'
          );

          if (fault != null) {
            // Extract faultcode and faultstring
            Dom.XmlNode faultCode = fault.getChildElement('faultcode', null);
            Dom.XmlNode faultString = fault.getChildElement(
              'faultstring',
              null
            );

            String faultCodeText = faultCode != null
              ? faultCode.getText()
              : 'UNKNOWN';
            String faultStringText = faultString != null
              ? faultString.getText()
              : 'Unknown SOAP fault';

            // Extract just the error code and message (remove namespace prefix if present)
            String errorCode = faultCodeText.contains(':')
              ? faultCodeText.substring(faultCodeText.indexOf(':') + 1)
              : faultCodeText;

            // Extract just the main error message (before colon if present)
            String errorMessage = faultStringText.contains(':')
              ? faultStringText.substring(faultStringText.indexOf(':') + 1)
                  .trim()
              : faultStringText;

            result.message = errorCode + ': ' + errorMessage;
            JT_ErrorLogger.logError(
              'SOAP Fault',
              result.message,
              null,
              'JT_MetadataApiSoap.parseDeployResponse',
              JSON.serialize(
                new Map<String, Object>{
                  'faultCode' => faultCodeText,
                  'faultString' => faultStringText
                }
              ),
              'High'
            );
            return result;
          }
        }

        // Body was already retrieved above for Fault checking
        if (body == null) {
          body = envelope.getChildElement(
            'Body',
            'http://schemas.xmlsoap.org/soap/envelope/'
          );
        }

        if (body == null) {
          String errorMsg = 'SOAP Body element not found';
          JT_ErrorLogger.logError(
            'SOAP Parse Error',
            errorMsg,
            null,
            'JT_MetadataApiSoap.parseDeployResponse',
            JSON.serialize(
              new Map<String, Object>{
                'availableChildren' => getChildElementNames(envelope)
              }
            ),
            'High'
          );
          result.message = errorMsg;
          return result;
        }

        // Try to find deployResponse - it might not have a namespace prefix
        Dom.XmlNode deployResponse = null;
        for (Dom.XmlNode child : body.getChildElements()) {
          if (
            child.getName() == 'deployResponse' ||
            child.getName().endsWith(':deployResponse')
          ) {
            deployResponse = child;
            break;
          }
        }

        if (deployResponse == null) {
          String errorMsg = 'deployResponse element not found in SOAP Body';
          JT_ErrorLogger.logError(
            'SOAP Parse Error',
            errorMsg,
            null,
            'JT_MetadataApiSoap.parseDeployResponse',
            JSON.serialize(
              new Map<String, Object>{
                'availableChildren' => getChildElementNames(body)
              }
            ),
            'High'
          );
          result.message = errorMsg;
          return result;
        }

        // Find result element
        Dom.XmlNode resultNode = null;
        for (Dom.XmlNode child : deployResponse.getChildElements()) {
          if (
            child.getName() == 'result' || child.getName().endsWith(':result')
          ) {
            resultNode = child;
            break;
          }
        }

        if (resultNode == null) {
          String errorMsg = 'result element not found in deployResponse';
          JT_ErrorLogger.logError(
            'SOAP Parse Error',
            errorMsg,
            null,
            'JT_MetadataApiSoap.parseDeployResponse',
            JSON.serialize(
              new Map<String, Object>{
                'availableChildren' => getChildElementNames(deployResponse)
              }
            ),
            'High'
          );
          result.message = errorMsg;
          return result;
        }

        // Extract fields from result node
        for (Dom.XmlNode child : resultNode.getChildElements()) {
          String name = child.getName();
          String text = child.getText();

          if (name == 'id' || name.endsWith(':id')) {
            result.id = text;
          } else if (name == 'done' || name.endsWith(':done')) {
            result.done = Boolean.valueOf(text);
          } else if (name == 'state' || name.endsWith(':state')) {
            result.state = text;
          } else if (name == 'message' || name.endsWith(':message')) {
            result.message = text;
          }
        }
      } catch (Exception e) {
        String errorMsg = 'Error parsing SOAP response: ' + e.getMessage();
        JT_ErrorLogger.logError(
          'SOAP Parse Exception',
          errorMsg,
          e,
          'JT_MetadataApiSoap.parseDeployResponse',
          null,
          'High'
        );
        result.message = errorMsg;
      }

      return result;
    }

    /**
     * @description Helper method to get child element names for debugging
     */
    private String getChildElementNames(Dom.XmlNode parent) {
      List<String> names = new List<String>();
      for (Dom.XmlNode child : parent.getChildElements()) {
        names.add(child.getName() + ' (ns: ' + child.getNamespace() + ')');
      }
      return String.join(names, ', ');
    }

    /**
     * @description Deletes metadata via SOAP API deleteMetadata() call
     * This is simpler than deploy() with destructiveChanges.xml
     * @param metadataType Metadata type (e.g., 'CustomMetadata')
     * @param fullNames Array of full names (e.g., ['JT_DynamicQueryConfiguration__mdt.DevName'])
     * @return DeleteResult[] Array of delete results
     */
    public JT_MetadataApiSoap.DeleteResult[] deleteMetadata(
      String metadataType,
      String[] fullNames
    ) {
      List<JT_MetadataApiSoap.DeleteResult> results = new List<JT_MetadataApiSoap.DeleteResult>();

      // Build SOAP request
      String soapBody = '<?xml version="1.0" encoding="UTF-8"?>';
      soapBody += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:met="http://soap.sforce.com/2006/04/metadata">';
      soapBody += '<soapenv:Header>';
      if (this.SessionHeader != null) {
        soapBody += '<met:SessionHeader>';
        soapBody +=
          '<met:sessionId>' +
          String.valueOf(this.SessionHeader.sessionId).escapeXml() +
          '</met:sessionId>';
        soapBody += '</met:SessionHeader>';
      }
      soapBody += '</soapenv:Header>';
      soapBody += '<soapenv:Body>';
      soapBody += '<met:deleteMetadata>';
      soapBody +=
        '<met:type>' +
        String.valueOf(metadataType).escapeXml() +
        '</met:type>';
      if (fullNames != null) {
        for (String fullName : fullNames) {
          soapBody +=
            '<met:fullNames>' +
            String.valueOf(fullName).escapeXml() +
            '</met:fullNames>';
        }
      }
      soapBody += '</met:deleteMetadata>';
      soapBody += '</soapenv:Body>';
      soapBody += '</soapenv:Envelope>';

      HttpRequest req = new HttpRequest();
      req.setEndpoint(this.endpoint_x);
      req.setMethod('POST');
      req.setHeader('Content-Type', 'text/xml; charset=UTF-8');
      req.setHeader('SOAPAction', '""');
      req.setBody(soapBody);
      req.setTimeout(this.timeout_x != null ? this.timeout_x : 120000);

      Http http = new Http();
      HttpResponse res = http.send(req);

      // Parse SOAP response
      return parseDeleteMetadataResponse(res.getBody(), res.getStatusCode());
    }

    /**
     * @description Parses deleteMetadata SOAP response
     */
    private JT_MetadataApiSoap.DeleteResult[] parseDeleteMetadataResponse(
      String soapResponse,
      Integer statusCode
    ) {
      List<JT_MetadataApiSoap.DeleteResult> results = new List<JT_MetadataApiSoap.DeleteResult>();

      try {
        Dom.Document doc = new Dom.Document();
        doc.load(soapResponse);

        Dom.XmlNode envelope = doc.getRootElement();

        // Check for SOAP Fault
        Dom.XmlNode body = envelope.getChildElement(
          'Body',
          'http://schemas.xmlsoap.org/soap/envelope/'
        );

        if (body == null) {
          String errorMsg = 'SOAP Body element not found';
          JT_ErrorLogger.logError(
            'SOAP Parse Error',
            errorMsg,
            null,
            'JT_MetadataApiSoap.parseDeleteMetadataResponse',
            JSON.serialize(
              new Map<String, Object>{
                'availableChildren' => getChildElementNames(envelope),
                'statusCode' => statusCode
              }
            ),
            'High'
          );
          JT_MetadataApiSoap.DeleteResult errorResult = new JT_MetadataApiSoap.DeleteResult();
          errorResult.success = false;
          errorResult.deleted = false;
          errorResult.errorMessage = errorMsg;
          results.add(errorResult);
          return results;
        }

        Dom.XmlNode fault = body.getChildElement(
          'Fault',
          'http://schemas.xmlsoap.org/soap/envelope/'
        );

        if (fault != null) {
          Dom.XmlNode faultCode = fault.getChildElement('faultcode', null);
          Dom.XmlNode faultString = fault.getChildElement('faultstring', null);

          String faultCodeText = faultCode != null
            ? faultCode.getText()
            : 'UNKNOWN';
          String faultStringText = faultString != null
            ? faultString.getText()
            : 'Unknown SOAP fault';

          String errorCode = faultCodeText.contains(':')
            ? faultCodeText.substring(faultCodeText.indexOf(':') + 1)
            : faultCodeText;
          String errorMessage = faultStringText.contains(':')
            ? faultStringText.substring(faultStringText.indexOf(':') + 1).trim()
            : faultStringText;

          JT_MetadataApiSoap.DeleteResult errorResult = new JT_MetadataApiSoap.DeleteResult();
          errorResult.success = false;
          errorResult.deleted = false;
          errorResult.errorMessage =
            'HTTP ' +
            statusCode +
            ': ' +
            errorCode +
            ': ' +
            errorMessage;
          errorResult.errorStatusCode = String.valueOf(statusCode);
          results.add(errorResult);
          return results;
        }

        // Parse successful response - look for deleteMetadataResponse
        Dom.XmlNode deleteResponse = null;
        for (Dom.XmlNode child : body.getChildElements()) {
          if (
            child.getName() == 'deleteMetadataResponse' ||
            child.getName().endsWith(':deleteMetadataResponse')
          ) {
            deleteResponse = child;
            break;
          }
        }

        if (deleteResponse == null) {
          String errorMsg = 'deleteMetadataResponse element not found in SOAP Body';
          JT_ErrorLogger.logError(
            'SOAP Parse Error',
            errorMsg,
            null,
            'JT_MetadataApiSoap.parseDeleteMetadataResponse',
            JSON.serialize(
              new Map<String, Object>{
                'availableChildren' => getChildElementNames(body),
                'statusCode' => statusCode
              }
            ),
            'High'
          );
          JT_MetadataApiSoap.DeleteResult errorResult = new JT_MetadataApiSoap.DeleteResult();
          errorResult.success = false;
          errorResult.deleted = false;
          errorResult.errorMessage = errorMsg;
          results.add(errorResult);
          return results;
        }

        // Find result element - it might be directly under deleteResponse or nested
        Dom.XmlNode resultNode = null;
        for (Dom.XmlNode child : deleteResponse.getChildElements()) {
          if (
            child.getName() == 'result' || child.getName().endsWith(':result')
          ) {
            resultNode = child;
            break;
          }
        }

        if (resultNode == null) {
          String errorMsg = 'result element not found in deleteMetadataResponse';
          JT_ErrorLogger.logError(
            'SOAP Parse Error',
            errorMsg,
            null,
            'JT_MetadataApiSoap.parseDeleteMetadataResponse',
            JSON.serialize(
              new Map<String, Object>{
                'availableChildren' => getChildElementNames(deleteResponse),
                'statusCode' => statusCode
              }
            ),
            'High'
          );
          JT_MetadataApiSoap.DeleteResult errorResult = new JT_MetadataApiSoap.DeleteResult();
          errorResult.success = false;
          errorResult.deleted = false;
          errorResult.errorMessage = errorMsg;
          results.add(errorResult);
          return results;
        }

        // Parse result - result can be a single element or array
        List<Dom.XmlNode> resultNodes = new List<Dom.XmlNode>();

        // Check if resultNode has nested result elements
        for (Dom.XmlNode child : resultNode.getChildElements()) {
          if (
            child.getName() == 'result' || child.getName().endsWith(':result')
          ) {
            resultNodes.add(child);
          }
        }

        // If no nested results, treat the resultNode itself as the result
        if (resultNodes.isEmpty()) {
          resultNodes.add(resultNode);
        }

        for (Dom.XmlNode result : resultNodes) {
          JT_MetadataApiSoap.DeleteResult deleteResult = new JT_MetadataApiSoap.DeleteResult();

          for (Dom.XmlNode child : result.getChildElements()) {
            String name = child.getName();
            String text = child.getText();

            if (name == 'fullName' || name.endsWith(':fullName')) {
              deleteResult.fullName = text;
            } else if (name == 'success' || name.endsWith(':success')) {
              deleteResult.success = Boolean.valueOf(text);
            } else if (name == 'deleted' || name.endsWith(':deleted')) {
              deleteResult.deleted = Boolean.valueOf(text);
            } else if (name == 'errors' || name.endsWith(':errors')) {
              // Parse errors if present
              for (Dom.XmlNode error : child.getChildElements()) {
                Dom.XmlNode errorMsg = error.getChildElement('message', null);
                if (errorMsg != null) {
                  deleteResult.errorMessage = errorMsg.getText();
                }
                Dom.XmlNode errorCode = error.getChildElement(
                  'statusCode',
                  null
                );
                if (errorCode != null) {
                  deleteResult.errorStatusCode = errorCode.getText();
                }
              }
            }
          }

          results.add(deleteResult);
        }
      } catch (Exception e) {
        String errorMsg =
          'Error parsing deleteMetadata SOAP response: ' + e.getMessage();
        JT_ErrorLogger.logError(
          'SOAP Parse Exception',
          errorMsg,
          e,
          'JT_MetadataApiSoap.parseDeleteMetadataResponse',
          JSON.serialize(
            new Map<String, Object>{
              'statusCode' => statusCode,
              'responseLength' => soapResponse != null
                ? soapResponse.length()
                : 0
            }
          ),
          'High'
        );
        JT_MetadataApiSoap.DeleteResult errorResult = new JT_MetadataApiSoap.DeleteResult();
        errorResult.success = false;
        errorResult.deleted = false;
        errorResult.errorMessage = errorMsg;
        results.add(errorResult);
      }

      return results;
    }
  }

  /**
   * @description Deploy request element
   */
  public class deploy_element {
    public Blob zipFile;
    public JT_MetadataApiSoap.DeployOptions DeployOptions;
  }

  /**
   * @description Deploy response element
   */
  public class deployResponse_element {
    public JT_MetadataApiSoap.AsyncResult result;
  }

  /**
   * @description Delete result for deleteMetadata() call
   */
  public class DeleteResult {
    public Boolean success;
    public String fullName;
    public Boolean deleted;
    public String errorMessage;
    public String errorStatusCode;
  }

  /**
   * @description Delete metadata element
   */
  public class deleteMetadata_element {
    public String metadataType;
    public String[] fullNames;
  }

  /**
   * @description Delete metadata response element
   */
  public class deleteMetadataResponse_element {
    public JT_MetadataApiSoap.DeleteResult[] result;
  }
}
