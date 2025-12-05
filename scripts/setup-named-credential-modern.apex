// Script moderno usando ConnectApi para Named Credentials
// Basado en apex-recipes de Salesforce:
// https://github.com/trailheadapps/apex-recipes/wiki/NamedCredentialRecipes

String orgUrl = URL.getOrgDomainUrl().toExternalForm();
System.debug('Org URL: ' + orgUrl);
System.debug('');

try {
    // 1. Crear External Credential
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('📋 Step 1: Creating External Credential...');
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    ConnectApi.ExternalCredentialInput extCredInput = new ConnectApi.ExternalCredentialInput();
    extCredInput.developerName = 'JT_Tooling_API_External';
    extCredInput.masterLabel = 'JT Tooling API External';
    extCredInput.authenticationProtocol = ConnectApi.CredentialAuthenticationProtocol.Oauth;

    // Create principal (per-user authentication)
    ConnectApi.ExternalCredentialPrincipalInput principalInput = new ConnectApi.ExternalCredentialPrincipalInput();
    principalInput.principalName = 'Admin';
    principalInput.principalType = ConnectApi.CredentialPrincipalType.PerUser;
    principalInput.sequenceNumber = 1;

    extCredInput.principals = new List<ConnectApi.ExternalCredentialPrincipalInput>{ principalInput };

    ConnectApi.ExternalCredential extCred = ConnectApi.ExternalCredentials.createExternalCredential(extCredInput);

    System.debug('✅ External Credential created!');
    System.debug('   Developer Name: ' + extCred.developerName);
    System.debug('   Master Label: ' + extCred.masterLabel);
    System.debug('');

    // 2. Crear Named Credential que apunta al External Credential
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
    namedCredInput.generateAuthorizationHeader = true;
    namedCredInput.externalCredentialDeveloperName = 'JT_Tooling_API_External';

    ConnectApi.NamedCredential namedCred = ConnectApi.NamedCredentials.createNamedCredential(namedCredInput);

    System.debug('✅ Named Credential created!');
    System.debug('   Developer Name: ' + namedCred.developerName);
    System.debug('   Master Label: ' + namedCred.masterLabel);
    System.debug('   Callout URL: ' + namedCred.calloutUrl);
    System.debug('');

    // 3. Grant Permission Set Access
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('📋 Step 3: Granting Permission Set Access...');
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('⚠️  Manual step required:');
    System.debug('   1. Go to Setup → Permission Sets');
    System.debug('   2. Select "JT_Dynamic_Queries"');
    System.debug('   3. Click "External Credential Principal Access"');
    System.debug('   4. Add "JT_Tooling_API_External"');
    System.debug('');

    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('✅ SETUP COMPLETE!');
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('Named Credential: callout:JT_Tooling_API');
    System.debug('Usage Example:');
    System.debug('  req.setEndpoint(\'callout:JT_Tooling_API/services/data/v65.0/tooling/...\');');
    System.debug('');
    System.debug('💡 Note: Don\'t forget to complete the manual permission step above!');

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



