// Verify that the test is being enqueued correctly via Tooling API

System.debug('🧪 Testing the enqueueTestExecution flow...');

// Step 1: Store test parameters (simulate what executeAsUser does)
String testUserId = '0050b000005coD2AAI';
String currentUserId = UserInfo.getUserId();
String sanitizedCurrent = currentUserId.replaceAll('[^a-zA-Z0-9]', '');

System.debug('Current User: ' + currentUserId);
System.debug('Sanitized: ' + sanitizedCurrent);

Map<String, Object> testParams = new Map<String, Object>{
  'userId' => testUserId,
  'configName' => 'Account_By_Name',
  'bindingsJson' => '{"searchName":"Dynamic"}',
  'timestamp' => System.now().getTime()
};

String paramsKey = 'RunAsTest' + sanitizedCurrent;
Cache.Org.put(paramsKey, JSON.serialize(testParams), 300);
System.debug('✅ Stored parameters with key: ' + paramsKey);

// Verify it was stored
Object retrieved = Cache.Org.get(paramsKey);
System.debug('✅ Verified in cache: ' + (retrieved != null ? 'YES' : 'NO'));

// Step 2: Get the test class ID
ApexClass testClass = [
  SELECT Id, Name
  FROM ApexClass
  WHERE Name = 'JT_GenericRunAsTest'
  LIMIT 1
];

System.debug('\n✅ Test class found: ' + testClass.Name + ' (' + testClass.Id + ')');

// Step 3: Enqueue via Tooling API
System.debug('\n📤 Enqueuing test via Tooling API...');

String orgUrl = URL.getOrgDomainUrl().toExternalForm();
String apiVersion = 'v65.0';
String toolingEndpoint = orgUrl + '/services/data/' + apiVersion + '/tooling/sobjects/ApexTestQueueItem';

HttpRequest request = new HttpRequest();
request.setEndpoint(toolingEndpoint);
request.setMethod('POST');
request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
request.setHeader('Content-Type', 'application/json');
request.setTimeout(30000);

Map<String, Object> requestBody = new Map<String, Object>{
  'ApexClassId' => testClass.Id
};
request.setBody(JSON.serialize(requestBody));

Http http = new Http();
HttpResponse response = http.send(request);

System.debug('Response Status: ' + response.getStatusCode());
System.debug('Response Body: ' + response.getBody());

if (response.getStatusCode() == 201) {
  Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
  String queueItemId = (String) result.get('id');
  System.debug('✅ Test enqueued successfully!');
  System.debug('Queue Item ID: ' + queueItemId);

  // Check status of the queue item
  System.debug('\n⏳ Waiting 3 seconds for test to execute...');
  // Note: Can't actually wait in execute anonymous, but you can check manually

  System.debug('\n💡 NOW CHECK:');
  System.debug('1. Query ApexTestQueueItem: SELECT Status FROM ApexTestQueueItem WHERE Id = \'' + queueItemId + '\'');
  System.debug('2. After ~5 seconds, check cache again with key: ' + paramsKey);
  System.debug('3. Check results cache with key: RunAsTestResult' + testUserId.replaceAll('[^a-zA-Z0-9]', ''));

} else {
  System.debug('❌ Failed to enqueue test');
  System.debug('Status: ' + response.getStatusCode());
  System.debug('Body: ' + response.getBody());
}

