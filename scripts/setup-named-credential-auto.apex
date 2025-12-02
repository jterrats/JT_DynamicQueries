// Setup automático de Named Credential con URL dinámica del org actual
// Ejecuta este script una vez para configurar Tooling API

String orgUrl = URL.getOrgDomainUrl().toExternalForm();
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
System.debug('🚀 Auto-Setup Named Credential');
System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
System.debug('Current Org URL: ' + orgUrl);
System.debug('');

try {
    // 1. Create External Credential
    System.debug('📋 Step 1: Creating External Credential...');
    
    ConnectApi.ExternalCredentialInput extCredInput = new ConnectApi.ExternalCredentialInput();
    extCredInput.developerName = 'JT_Tooling_API_External';
    extCredInput.masterLabel = 'JT Tooling API External';
    extCredInput.authenticationProtocol = ConnectApi.CredentialAuthenticationProtocol.NoAuthentication;
    
    ConnectApi.ExternalCredential extCred = ConnectApi.ExternalCredentials.createExternalCredential(extCredInput);
    
    System.debug('✅ External Credential created!');
    System.debug('   Developer Name: ' + extCred.developerName);
    System.debug('');
    
    // 2. Create Named Credential with DYNAMIC org URL
    System.debug('📋 Step 2: Creating Named Credential...');
    
    ConnectApi.NamedCredentialInput namedCredInput = new ConnectApi.NamedCredentialInput();
    namedCredInput.developerName = 'JT_Tooling_API';
    namedCredInput.masterLabel = 'JT Tooling API';
    namedCredInput.type = ConnectApi.NamedCredentialType.SecuredEndpoint;
    namedCredInput.calloutUrl = orgUrl; // 🔥 DYNAMIC! Works in any org
    namedCredInput.allowMergeFieldsInBody = false;
    namedCredInput.allowMergeFieldsInHeader = false;
    namedCredInput.generateAuthorizationHeader = false;
    namedCredInput.externalCredentialDeveloperName = 'JT_Tooling_API_External';
    
    ConnectApi.NamedCredential namedCred = ConnectApi.NamedCredentials.createNamedCredential(namedCredInput);
    
    System.debug('✅ Named Credential created!');
    System.debug('   Developer Name: ' + namedCred.developerName);
    System.debug('   Callout URL: ' + namedCred.calloutUrl);
    System.debug('');
    
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('✅ SETUP COMPLETE!');
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('');
    System.debug('💡 Named Credential configured for THIS org');
    System.debug('   Works in: ' + orgUrl);
    System.debug('');
    System.debug('🎯 Usage:');
    System.debug('   req.setEndpoint(\'callout:JT_Tooling_API/services/data/v65.0/tooling/...\');');
    System.debug('   req.setHeader(\'Authorization\', \'Bearer \' + UserInfo.getSessionId());');
    
} catch (ConnectApi.ConnectApiException e) {
    System.debug('❌ ConnectApi Error: ' + e.getMessage());
    if (e.getMessage().contains('duplicate') || e.getMessage().contains('already exists')) {
        System.debug('');
        System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        System.debug('⚠️  Named Credential already exists');
        System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        System.debug('');
        System.debug('To update, delete existing and re-run:');
        System.debug('   Setup → Named Credentials → Delete "JT_Tooling_API"');
        System.debug('   Setup → External Credentials → Delete "JT_Tooling_API_External"');
    }
} catch (Exception e) {
    System.debug('❌ Unexpected Error: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

