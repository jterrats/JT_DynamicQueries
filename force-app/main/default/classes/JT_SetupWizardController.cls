/**
 * @description Controller for Setup Wizard LWC - Verifies OAuth 2.0 Named Credentials configuration
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
   * @description Step status for multi-step setup wizard
   */
  public class SetupStepStatus {
    @AuraEnabled
    public String stepName;
    @AuraEnabled
    public Boolean isComplete;
    @AuraEnabled
    public Boolean isRequired;
    @AuraEnabled
    public String statusMessage;
    @AuraEnabled
    public String setupUrl;
  }

  /**
   * @description Complete setup status with all steps
   */
  public class CompleteSetupStatus {
    @AuraEnabled
    public Boolean allStepsComplete;
    @AuraEnabled
    public List<SetupStepStatus> steps;
    @AuraEnabled
    public String orgUrl;
    @AuraEnabled
    public String documentationUrl;
  }

  /**
   * @description Checks complete OAuth 2.0 setup status
   * @return CompleteSetupStatus Status of all setup steps
   */
  @AuraEnabled
  public static CompleteSetupStatus checkCompleteSetup() {
    final CompleteSetupStatus status = new CompleteSetupStatus();
    status.orgUrl = URL.getOrgDomainUrl().toExternalForm();
    status.documentationUrl = '/lightning/n/JT_Project_Docs';
    status.steps = new List<SetupStepStatus>();

    // Step 1: Authentication Provider
    final SetupStepStatus authProviderStep = new SetupStepStatus();
    authProviderStep.stepName = 'Authentication Provider';
    authProviderStep.isRequired = true;
    authProviderStep.setupUrl = '/lightning/setup/AuthProvider/home';
    authProviderStep.statusMessage = 'Create Authentication Provider: JT_Tooling_API_Auth_Provider';
    authProviderStep.isComplete = checkAuthProviderExists();
    status.steps.add(authProviderStep);

    // Step 2: Connected App
    final SetupStepStatus connectedAppStep = new SetupStepStatus();
    connectedAppStep.stepName = 'Connected App';
    connectedAppStep.isRequired = true;
    connectedAppStep.setupUrl = '/lightning/setup/ConnectedApplication/home';
    connectedAppStep.statusMessage = 'Create Connected App: JT Tooling API';
    connectedAppStep.isComplete = checkConnectedAppExists();
    status.steps.add(connectedAppStep);

    // Step 3: External Credential
    final SetupStepStatus externalCredStep = new SetupStepStatus();
    externalCredStep.stepName = 'External Credential';
    externalCredStep.isRequired = true;
    externalCredStep.setupUrl = '/lightning/setup/ExternalCredential/home';
    externalCredStep.statusMessage = 'Create External Credential: JT_Tooling_API_External';
    externalCredStep.isComplete = checkExternalCredentialExists();
    status.steps.add(externalCredStep);

    // Step 4: Named Credential
    final SetupStepStatus namedCredStep = new SetupStepStatus();
    namedCredStep.stepName = 'Named Credential';
    namedCredStep.isRequired = true;
    namedCredStep.setupUrl = '/lightning/setup/NamedCredential/home';
    namedCredStep.statusMessage = 'Link Named Credential: JT_Tooling_API';
    final Boolean namedCredConfigured = checkNamedCredentialConfigured();
    namedCredStep.isComplete = namedCredConfigured;
    if (!namedCredConfigured) {
      namedCredStep.statusMessage += ' (Update URL and link External Credential)';
    }
    status.steps.add(namedCredStep);

    // Step 5: Test Connection
    final SetupStepStatus testStep = new SetupStepStatus();
    testStep.stepName = 'Test Connection';
    testStep.isRequired = false;
    testStep.setupUrl = null;
    final Boolean connectionWorks = testToolingAPIConnection();
    testStep.isComplete = connectionWorks;
    testStep.statusMessage = connectionWorks
      ? 'Tooling API is accessible'
      : 'Tooling API connection failed - check authentication';
    status.steps.add(testStep);

    // Calculate overall status
    status.allStepsComplete =
      authProviderStep.isComplete &&
      connectedAppStep.isComplete &&
      externalCredStep.isComplete &&
      namedCredStep.isComplete &&
      testStep.isComplete;

    return status;
  }

  /**
   * @description Checks if Authentication Provider exists (via SOQL)
   * @return Boolean True if Auth Provider exists
   */
  private static Boolean checkAuthProviderExists() {
    try {
      final String queryString = 'SELECT Id, DeveloperName FROM AuthProvider WHERE DeveloperName = \'JT_Tooling_API_Auth_Provider\' LIMIT 1';
      final List<SObject> providers = Database.query(queryString);
      return !providers.isEmpty();
    } catch (Exception e) {
      return false;
    }
  }

  /**
   * @description Checks if Connected App exists (via SOQL)
   * @return Boolean True if Connected App exists
   */
  private static Boolean checkConnectedAppExists() {
    try {
      final String queryString = 'SELECT Id, Name FROM ConnectedApplication WHERE Name = \'JT Tooling API\' LIMIT 1';
      final List<SObject> apps = Database.query(queryString);
      return !apps.isEmpty();
    } catch (Exception e) {
      return false;
    }
  }

  /**
   * @description Checks if External Credential exists (via Tooling API query)
   * @return Boolean True if External Credential exists
   */
  private static Boolean checkExternalCredentialExists() {
    try {
      final HttpRequest request = new HttpRequest();
      final String toolingQuery = 'SELECT Id, DeveloperName FROM ExternalCredential WHERE DeveloperName = \'JT_Tooling_API_External\' LIMIT 1';
      request.setEndpoint(
        'callout:JT_Tooling_API/services/data/v65.0/tooling/query/?q=' +
        EncodingUtil.urlEncode(toolingQuery, 'UTF-8')
      );
      request.setMethod('GET');
      request.setTimeout(5000);

      final Http httpClient = new Http();
      final HttpResponse response = httpClient.send(request);

      if (response.getStatusCode() == 200) {
        final Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
          response.getBody()
        );
        final List<Object> records = (List<Object>) result.get('records');
        return records != null && !records.isEmpty();
      }
      return false;
    } catch (Exception e) {
      // If Named Credential not configured, this will fail - that's OK
      return false;
    }
  }

  /**
   * @description Checks if Named Credential is properly configured
   * @return Boolean True if Named Credential exists and is linked
   */
  private static Boolean checkNamedCredentialConfigured() {
    try {
      final String queryString = 'SELECT Id, DeveloperName, Endpoint FROM NamedCredential WHERE DeveloperName = \'JT_Tooling_API\' LIMIT 1';
      final List<SObject> creds = Database.query(queryString);
      if (creds.isEmpty()) {
        return false;
      }
      // Check if URL is set (Endpoint field)
      final SObject cred = creds[0];
      final String endpoint = (String) cred.get('Endpoint');
      // For Next-Gen, we verify by testing the connection instead of checking ExternalCredentialId
      return String.isNotBlank(endpoint);
    } catch (Exception e) {
      return false;
    }
  }

  /**
   * @description Tests Tooling API connection via Named Credential
   * @return Boolean True if connection works
   */
  @AuraEnabled
  @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
  public static Boolean testToolingAPIConnection() {
    try {
      final HttpRequest request = new HttpRequest();
      request.setEndpoint('callout:JT_Tooling_API/services/data/v65.0/');
      request.setMethod('HEAD');
      request.setTimeout(5000);

      final Http httpClient = new Http();
      final HttpResponse response = httpClient.send(request);

      return response.getStatusCode() == 200 || response.getStatusCode() == 404;
    } catch (Exception e) {
      return false;
    }
  }

  /**
   * @description Gets org URL for manual setup
   * @return String Org instance URL
   */
  @AuraEnabled
  public static String getOrgUrl() {
    return URL.getOrgDomainUrl().toExternalForm();
  }
}
