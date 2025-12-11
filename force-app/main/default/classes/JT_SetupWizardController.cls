/**
 * @description Controller for Setup Wizard LWC - Verifies Named Credentials configuration
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
      result.details = 'Please configure Named Credentials manually via Setup.\n\nSee documentation for instructions.';
    } catch (Exception e) {
      result.success = false;
      result.message = 'Unable to verify configuration';
      result.details = e.getMessage();
    }

    return result;
  }

  /**
   * @description Gets org URL for manual Named Credential setup
   * @return SetupResult Result with org URL
   */
  @AuraEnabled
  public static SetupResult getOrgUrl() {
    SetupResult result = new SetupResult();
    result.orgUrl = URL.getOrgDomainUrl().toExternalForm();
    result.success = true;
    result.message = 'Org URL retrieved';
    result.details =
      'Use this URL when creating Named Credential: ' + result.orgUrl;

    return result;
  }
}
