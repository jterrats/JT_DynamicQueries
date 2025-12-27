// Diagnostic script to check Run As User cache state
// Run this to understand why the test results are not being retrieved

String impersonatedUserId = '0050b000005coD2AAI'; // The user you selected
String currentUserId = UserInfo.getUserId(); // The admin user

System.debug('='.repeat(80));
System.debug('RUN AS USER CACHE DIAGNOSTIC');
System.debug('='.repeat(80));

// Sanitize user IDs
String sanitizedImpersonated = impersonatedUserId.replaceAll('[^a-zA-Z0-9]', '');
String sanitizedCurrent = currentUserId.replaceAll('[^a-zA-Z0-9]', '');

System.debug('Impersonated User ID: ' + impersonatedUserId);
System.debug('Sanitized Impersonated: ' + sanitizedImpersonated);
System.debug('Current User ID (Admin): ' + currentUserId);
System.debug('Sanitized Current: ' + sanitizedCurrent);

System.debug('\n1. CHECKING TEST PARAMETERS CACHE (stored by admin, read by test):');
String paramsKey = 'RunAsTest' + sanitizedCurrent;
System.debug('Cache Key: ' + paramsKey);
Object cachedParams = Cache.Org.get(paramsKey);
if (cachedParams != null) {
  System.debug('✅ Parameters found in cache:');
  System.debug(cachedParams);
} else {
  System.debug('❌ NO parameters found in cache');
}

System.debug('\n2. CHECKING TEST RESULTS CACHE (stored by test, read by admin):');
String resultsKey = 'RunAsTestResult' + sanitizedImpersonated;
System.debug('Cache Key: ' + resultsKey);
Object cachedResults = Cache.Org.get(resultsKey);
if (cachedResults != null) {
  System.debug('✅ Results found in cache:');
  System.debug(cachedResults);

  // Parse JSON
  try {
    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped((String)cachedResults);
    System.debug('\nParsed Results:');
    System.debug('  success: ' + resultMap.get('success'));
    System.debug('  recordCount: ' + resultMap.get('recordCount'));
    System.debug('  runAsUserName: ' + resultMap.get('runAsUserName'));
    System.debug('  fields: ' + resultMap.get('fields'));
    System.debug('  records count: ' + ((List<Object>)resultMap.get('records'))?.size());
  } catch (Exception e) {
    System.debug('❌ Error parsing results: ' + e.getMessage());
  }
} else {
  System.debug('❌ NO results found in cache');
}

System.debug('\n3. CHECKING ASSERT MESSAGE CACHE:');
String assertKey = 'RunAsTestAssert' + sanitizedImpersonated;
System.debug('Cache Key: ' + assertKey);
Object cachedAssert = Cache.Org.get(assertKey);
if (cachedAssert != null) {
  System.debug('✅ Assert message found: ' + cachedAssert);
} else {
  System.debug('❌ NO assert message found');
}

System.debug('\n4. CHECKING TEST CLASS:');
try {
  ApexClass testClass = [
    SELECT Id, Name, Status
    FROM ApexClass
    WHERE Name = 'JT_GenericRunAsTest'
    LIMIT 1
  ];
  System.debug('✅ Test class found:');
  System.debug('  Id: ' + testClass.Id);
  System.debug('  Name: ' + testClass.Name);
  System.debug('  Status: ' + testClass.Status);
} catch (Exception e) {
  System.debug('❌ Test class not found: ' + e.getMessage());
}

System.debug('\n5. CHECKING RECENT TEST RUNS:');
try {
  List<ApexTestQueueItem> queueItems = [
    SELECT Id, Status, ApexClass.Name, ParentJobId, CreatedDate
    FROM ApexTestQueueItem
    WHERE ApexClass.Name = 'JT_GenericRunAsTest'
    ORDER BY CreatedDate DESC
    LIMIT 5
  ];

  if (!queueItems.isEmpty()) {
    System.debug('✅ Recent test queue items:');
    for (ApexTestQueueItem item : queueItems) {
      System.debug('  - Status: ' + item.Status + ', Created: ' + item.CreatedDate + ', Job: ' + item.ParentJobId);
    }
  } else {
    System.debug('❌ No recent test queue items found');
  }
} catch (Exception e) {
  System.debug('❌ Error querying test queue: ' + e.getMessage());
}

System.debug('\n6. CHECKING TEST RESULTS:');
try {
  List<ApexTestResult> testResults = [
    SELECT Id, Outcome, Message, StackTrace, ApexClass.Name, TestTimestamp
    FROM ApexTestResult
    WHERE ApexClass.Name = 'JT_GenericRunAsTest'
    ORDER BY TestTimestamp DESC
    LIMIT 5
  ];

  if (!testResults.isEmpty()) {
    System.debug('✅ Recent test results:');
    for (ApexTestResult testResult : testResults) {
      System.debug('  - Outcome: ' + testResult.Outcome + ', Time: ' + testResult.TestTimestamp);
      if (testResult.Outcome != 'Pass') {
        System.debug('    Message: ' + testResult.Message);
        System.debug('    StackTrace: ' + testResult.StackTrace);
      }
    }
  } else {
    System.debug('❌ No test results found');
  }
} catch (Exception e) {
  System.debug('❌ Error querying test results: ' + e.getMessage());
}

System.debug('='.repeat(80));
System.debug('DIAGNOSTIC COMPLETE');
System.debug('='.repeat(80));

