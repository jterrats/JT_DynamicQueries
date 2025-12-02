// Script para configurar Named Credential via Tooling API
// Este script crea una External Credential y Named Credential que permite callouts al mismo org

String orgUrl = URL.getOrgDomainUrl().toExternalForm();
System.debug('Org URL: ' + orgUrl);

// 1. Create External Credential (using Tooling API)
HttpRequest req1 = new HttpRequest();
req1.setEndpoint(orgUrl + '/services/data/v65.0/tooling/sobjects/ExternalCredential');
req1.setMethod('POST');
req1.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req1.setHeader('Content-Type', 'application/json');

Map<String, Object> externalCred = new Map<String, Object>{
    'DeveloperName' => 'JT_Tooling_API_External',
    'MasterLabel' => 'JT Tooling API External',
    'AuthenticationProtocol' => 'Oauth'
};

req1.setBody(JSON.serialize(externalCred));

Http http = new Http();
HttpResponse res1 = http.send(req1);

System.debug('External Credential Response: ' + res1.getStatusCode());
System.debug('Response Body: ' + res1.getBody());

if (res1.getStatusCode() == 201 || res1.getStatusCode() == 200) {
    System.debug('✅ External Credential created successfully');
    
    // 2. Create Named Credential pointing to External Credential
    HttpRequest req2 = new HttpRequest();
    req2.setEndpoint(orgUrl + '/services/data/v65.0/tooling/sobjects/NamedCredential');
    req2.setMethod('POST');
    req2.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
    req2.setHeader('Content-Type', 'application/json');
    
    Map<String, Object> namedCred = new Map<String, Object>{
        'DeveloperName' => 'JT_Tooling_API',
        'MasterLabel' => 'JT Tooling API',
        'Endpoint' => orgUrl,
        'PrincipalType' => 'NamedUser',
        'Protocol' => 'NoAuthentication'
    };
    
    req2.setBody(JSON.serialize(namedCred));
    
    HttpResponse res2 = http.send(req2);
    
    System.debug('Named Credential Response: ' + res2.getStatusCode());
    System.debug('Response Body: ' + res2.getBody());
    
    if (res2.getStatusCode() == 201 || res2.getStatusCode() == 200) {
        System.debug('✅ Named Credential created successfully');
        System.debug('');
        System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        System.debug('✅ SETUP COMPLETE');
        System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        System.debug('Named Credential: JT_Tooling_API');
        System.debug('Endpoint: ' + orgUrl);
        System.debug('Usage: callout:JT_Tooling_API/services/data/v65.0/tooling/...');
    } else {
        System.debug('❌ Failed to create Named Credential');
        System.debug('Error: ' + res2.getBody());
    }
} else {
    System.debug('❌ Failed to create External Credential');
    System.debug('Error: ' + res1.getBody());
}

