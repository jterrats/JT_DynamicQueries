/**
 * @description Controller for Setup Wizard LWC - Configures Named Credentials automatically
 * @author Jaime Terrats
 * @group Setup
 */
public with sharing class JT_SetupWizardController {
  /**
   * @description Result wrapper for setup operations
   */
  public class SetupResult {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String details;
    @AuraEnabled
    public String orgUrl;
  }

  /**
   * @description Configures Named Credentials for Tooling API
   * @return SetupResult Result of the configuration
   */
  @AuraEnabled
  public static SetupResult setupNamedCredentials() {
    SetupResult result = new SetupResult();
    result.orgUrl = URL.getOrgDomainUrl().toExternalForm();

    try {
      // 1. Create External Credential
      ConnectApi.ExternalCredentialInput extCredInput = new ConnectApi.ExternalCredentialInput();
      extCredInput.developerName = 'JT_Tooling_API_External';
      extCredInput.masterLabel = 'JT Tooling API External';
      extCredInput.authenticationProtocol = ConnectApi.CredentialAuthenticationProtocol.NoAuthentication;

      ConnectApi.ExternalCredential extCred = ConnectApi.ExternalCredentials.createExternalCredential(
        extCredInput
      );

      // 2. Create Named Credential with dynamic org URL
      ConnectApi.NamedCredentialInput namedCredInput = new ConnectApi.NamedCredentialInput();
      namedCredInput.developerName = 'JT_Tooling_API';
      namedCredInput.masterLabel = 'JT Tooling API';
      namedCredInput.type = ConnectApi.NamedCredentialType.SecuredEndpoint;
      namedCredInput.calloutUrl = result.orgUrl;
      namedCredInput.allowMergeFieldsInBody = false;
      namedCredInput.allowMergeFieldsInHeader = false;
      namedCredInput.generateAuthorizationHeader = false;
      namedCredInput.externalCredentialDeveloperName = 'JT_Tooling_API_External';

      ConnectApi.NamedCredential namedCred = ConnectApi.NamedCredentials.createNamedCredential(
        namedCredInput
      );

      result.success = true;
      result.message = 'Named Credentials configured successfully!';
      result.details =
        'External Credential: ' +
        extCred.developerName +
        '\n' +
        'Named Credential: ' +
        namedCred.developerName +
        '\n' +
        'Org URL: ' +
        namedCred.calloutUrl;
    } catch (ConnectApi.ConnectApiException e) {
      if (
        e.getMessage().contains('duplicate') ||
        e.getMessage().contains('already exists')
      ) {
        result.success = true;
        result.message = 'Named Credentials already configured';
        result.details = 'The configuration already exists for this org. No action needed.';
      } else {
        result.success = false;
        result.message = 'Failed to configure Named Credentials';
        result.details = e.getMessage();
      }
    } catch (Exception e) {
      result.success = false;
      result.message = 'Unexpected error during setup';
      result.details = e.getMessage();
    }

    return result;
  }

  /**
   * @description Checks if Named Credentials are already configured
   * @return SetupResult Status of current configuration
   */
  @AuraEnabled
  @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
  // Named Credential uses NoAuthentication protocol, requiring manual Authorization header
  // This is the correct pattern for same-org Tooling API calls using session ID
  public static SetupResult checkConfiguration() {
    SetupResult result = new SetupResult();
    result.orgUrl = URL.getOrgDomainUrl().toExternalForm();

    try {
      // Try to use Named Credential
      HttpRequest req = new HttpRequest();
      req.setEndpoint('callout:JT_Tooling_API/services/data/v65.0/');
      req.setMethod('HEAD');
      req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
      req.setTimeout(5000);

      Http http = new Http();
      HttpResponse res = http.send(req);

      result.success = true;
      result.message = 'Named Credentials are configured and working';
      result.details = 'Tooling API is accessible via Named Credential';
    } catch (System.CalloutException e) {
      result.success = false;
      result.message = 'Named Credentials not configured';
      result.details = 'Click "Setup Now" to configure automatically';
    } catch (Exception e) {
      result.success = false;
      result.message = 'Unable to verify configuration';
      result.details = e.getMessage();
    }

    return result;
  }

  /**
   * @description Deletes existing Named Credentials (for reset)
   * @return SetupResult Result of the deletion
   */
  @AuraEnabled
  public static SetupResult resetConfiguration() {
    SetupResult result = new SetupResult();
    result.orgUrl = URL.getOrgDomainUrl().toExternalForm();

    try {
      // Note: ConnectApi doesn't support deletion yet
      // User must delete manually via Setup
      result.success = false;
      result.message = 'Manual reset required';
      result.details =
        'To reset:\n1. Setup → Named Credentials → Delete "JT_Tooling_API"\n' +
        '2. Setup → External Credentials → Delete "JT_Tooling_API_External"\n' +
        '3. Click "Setup Now" again';
    } catch (Exception e) {
      result.success = false;
      result.message = 'Error during reset';
      result.details = e.getMessage();
    }

    return result;
  }
}
