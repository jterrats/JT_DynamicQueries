// Script simplificado: usar Remote Site Settings + callout directo
// En lugar de Named Credential, habilitamos Remote Site Settings

String orgUrl = URL.getOrgDomainUrl().toExternalForm();
System.debug('Org URL: ' + orgUrl);

// Create Remote Site Setting via Tooling API
HttpRequest req = new HttpRequest();
req.setEndpoint(orgUrl + '/services/data/v65.0/tooling/sobjects/RemoteSiteSetting');
req.setMethod('POST');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setHeader('Content-Type', 'application/json');

Map<String, Object> remoteSite = new Map<String, Object>{
    'FullName' => 'JT_Tooling_API_Site',
    'Metadata' => new Map<String, Object>{
        'description' => 'Allow callouts to Tooling API in same org',
        'disableProtocolSecurity' => false,
        'isActive' => true,
        'url' => orgUrl
    }
};

req.setBody(JSON.serialize(remoteSite));

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('Remote Site Response: ' + res.getStatusCode());
System.debug('Response Body: ' + res.getBody());

if (res.getStatusCode() == 201 || res.getStatusCode() == 200) {
    System.debug('✅ Remote Site Setting created successfully');
    System.debug('');
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('✅ SETUP COMPLETE');
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('Remote Site: JT_Tooling_API_Site');
    System.debug('Endpoint: ' + orgUrl);
    System.debug('');
    System.debug('💡 Note: You can now make direct callouts to Tooling API');
    System.debug('   No Named Credential needed - use session ID directly');
} else if (res.getStatusCode() == 400) {
    Map<String, Object> errorBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    if (res.getBody().contains('duplicate value found') ||
        res.getBody().contains('already exists')) {
        System.debug('⚠️  Remote Site Setting already exists');
        System.debug('✅ Configuration is already complete');
    } else {
        System.debug('❌ Failed to create Remote Site Setting');
        System.debug('Error: ' + res.getBody());
    }
} else {
    System.debug('❌ Failed to create Remote Site Setting');
    System.debug('Error: ' + res.getBody());
}



