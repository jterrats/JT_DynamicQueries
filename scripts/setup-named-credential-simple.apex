// Script simplificado: Named Credential para callouts al mismo org
// Usa NoAuthentication porque el session ID se pasa manualmente en el código

String orgUrl = URL.getOrgDomainUrl().toExternalForm();
System.debug('Org URL: ' + orgUrl);
System.debug('');

try {
    // Crear External Credential con NoAuthentication
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('📋 Step 1: Creating External Credential...');
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    ConnectApi.ExternalCredentialInput extCredInput = new ConnectApi.ExternalCredentialInput();
    extCredInput.developerName = 'JT_Tooling_API_External';
    extCredInput.masterLabel = 'JT Tooling API External';
    extCredInput.authenticationProtocol = ConnectApi.CredentialAuthenticationProtocol.NoAuthentication;

    ConnectApi.ExternalCredential extCred = ConnectApi.ExternalCredentials.createExternalCredential(extCredInput);

    System.debug('✅ External Credential created!');
    System.debug('   Developer Name: ' + extCred.developerName);
    System.debug('   Master Label: ' + extCred.masterLabel);
    System.debug('   Protocol: NoAuthentication');
    System.debug('');

    // Crear Named Credential
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('📋 Step 2: Creating Named Credential...');
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    ConnectApi.NamedCredentialInput namedCredInput = new ConnectApi.NamedCredentialInput();
    namedCredInput.developerName = 'JT_Tooling_API';
    namedCredInput.masterLabel = 'JT Tooling API';
    namedCredInput.type = ConnectApi.NamedCredentialType.SecuredEndpoint;
    namedCredInput.calloutUrl = orgUrl;
    namedCredInput.allowMergeFieldsInBody = false;
    namedCredInput.allowMergeFieldsInHeader = false;
    namedCredInput.generateAuthorizationHeader = false;
    namedCredInput.externalCredentialDeveloperName = 'JT_Tooling_API_External';

    ConnectApi.NamedCredential namedCred = ConnectApi.NamedCredentials.createNamedCredential(namedCredInput);

    System.debug('✅ Named Credential created!');
    System.debug('   Developer Name: ' + namedCred.developerName);
    System.debug('   Master Label: ' + namedCred.masterLabel);
    System.debug('   Callout URL: ' + namedCred.calloutUrl);
    System.debug('   Type: ' + namedCred.type);
    System.debug('');

    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('✅ SETUP COMPLETE!');
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('');
    System.debug('💡 Usage:');
    System.debug('   req.setEndpoint(\'callout:JT_Tooling_API/services/data/v65.0/tooling/...\');');
    System.debug('   req.setHeader(\'Authorization\', \'Bearer \' + UserInfo.getSessionId());');
    System.debug('');
    System.debug('Note: Session ID must be set manually in code (no auto-auth)');

} catch (ConnectApi.ConnectApiException e) {
    System.debug('❌ ConnectApi Error: ' + e.getMessage());
    if (e.getMessage().contains('duplicate') || e.getMessage().contains('already exists')) {
        System.debug('');
        System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        System.debug('⚠️  Named Credential may already exist');
        System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        System.debug('To verify, go to Setup → Named Credentials');
        System.debug('Look for: JT_Tooling_API');
    }
} catch (Exception e) {
    System.debug('❌ Unexpected Error: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}



