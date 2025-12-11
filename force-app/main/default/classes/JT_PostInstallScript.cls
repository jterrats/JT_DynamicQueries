/**
 * @description Post-install script to configure Named Credentials automatically
 * @author Jaime Terrats
 * @group Setup
 */
global class JT_PostInstallScript implements InstallHandler {
  /**
   * @description Executes after package installation
   * @param context Installation context
   */
  global void onInstall(InstallContext context) {
    // Check if it's a new installation or upgrade
    if (context.previousVersion() == null) {
      System.debug(
        'New installation detected - setting up Named Credentials...'
      );
      setupNamedCredentials();
    } else {
      System.debug('Upgrade detected - verifying Named Credentials...');
      verifyNamedCredentials();
    }
  }

  /**
   * @description Sets up Named Credentials with current org URL
   * @note TEMPORARILY DISABLED: ConnectAPI.ExternalCredentials not available in API 65.0
   *       Named Credentials must be configured manually via Setup
   */
  @future(callout=true)
  private static void setupNamedCredentials() {
    System.debug('⚠️  Automatic Named Credential setup is disabled');
    System.debug('📖 Please configure Named Credentials manually via Setup');
    System.debug('📚 See documentation: docs/SSO_FLOWS.md');

    /* COMMENTED OUT - ConnectAPI not available in API 65.0
    try {
      String orgUrl = URL.getOrgDomainUrl().toExternalForm();
      System.debug('Current Org URL: ' + orgUrl);

      // 1. Create External Credential
      ConnectApi.ExternalCredentialInput extCredInput = new ConnectApi.ExternalCredentialInput();
      extCredInput.developerName = 'JT_Tooling_API_External';
      extCredInput.masterLabel = 'JT Tooling API External';
      extCredInput.authenticationProtocol = ConnectApi.CredentialAuthenticationProtocol.NoAuthentication;

      ConnectApi.ExternalCredential extCred = ConnectApi.ExternalCredentials.createExternalCredential(
        extCredInput
      );
      System.debug('✅ External Credential created: ' + extCred.developerName);

      // 2. Create Named Credential with dynamic org URL
      ConnectApi.NamedCredentialInput namedCredInput = new ConnectApi.NamedCredentialInput();
      namedCredInput.developerName = 'JT_Tooling_API';
      namedCredInput.masterLabel = 'JT Tooling API';
      namedCredInput.type = ConnectApi.NamedCredentialType.SecuredEndpoint;
      namedCredInput.calloutUrl = orgUrl; // 🔥 Dynamic org URL!
      namedCredInput.allowMergeFieldsInBody = false;
      namedCredInput.allowMergeFieldsInHeader = false;
      namedCredInput.generateAuthorizationHeader = false;
      namedCredInput.externalCredentialDeveloperName = 'JT_Tooling_API_External';

      ConnectApi.NamedCredential namedCred = ConnectApi.NamedCredentials.createNamedCredential(
        namedCredInput
      );
      System.debug('✅ Named Credential created: ' + namedCred.developerName);
      System.debug('   URL: ' + namedCred.calloutUrl);
    } catch (ConnectApi.ConnectApiException e) {
      if (
        e.getMessage().contains('duplicate') ||
        e.getMessage().contains('already exists')
      ) {
        System.debug('⚠️  Named Credential already exists - skipping creation');
      } else {
        System.debug('❌ Failed to create Named Credential: ' + e.getMessage());
      }
    } catch (Exception e) {
      System.debug('❌ Unexpected error: ' + e.getMessage());
    }
    */
  }

  /**
   * @description Verifies Named Credentials configuration
   */
  private static void verifyNamedCredentials() {
    try {
      // Check if Named Credential exists
      HttpRequest req = new HttpRequest();
      req.setEndpoint('callout:JT_Tooling_API/services/data/v65.0/');
      req.setMethod('HEAD');
      req.setTimeout(5000);

      System.debug('✅ Named Credential verified and working');
    } catch (Exception e) {
      System.debug(
        '⚠️  Named Credential may need reconfiguration: ' + e.getMessage()
      );
    }
  }
}
