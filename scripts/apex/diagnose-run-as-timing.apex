// Enhanced diagnostic to understand timing issues with Run As User feature

System.debug('='.repeat(80));
System.debug('RUN AS USER - TIMING DIAGNOSTIC');
System.debug('='.repeat(80));

String currentUserId = UserInfo.getUserId();
String sanitized = currentUserId.replaceAll('[^a-zA-Z0-9]', '');
String impersonatedUserId = '0050b000005coD2AAI'; // Chatter Expert
String sanitizedImpersonated = impersonatedUserId.replaceAll('[^a-zA-Z0-9]', '');

System.debug('\n👤 User Context:');
System.debug('  Current User (Admin): ' + currentUserId);
System.debug('  Sanitized: ' + sanitized);
System.debug('  Impersonated User: ' + impersonatedUserId);
System.debug('  Sanitized Impersonated: ' + sanitizedImpersonated);

// 1. Check parameters cache (stored by admin for admin)
System.debug('\n📦 PARAMETERS CACHE (stored when "Execute Query" clicked):');
String paramsKey = 'RunAsTest' + sanitized;
String cachedParams = (String) Cache.Org.get(paramsKey);

if (String.isNotBlank(cachedParams)) {
  System.debug('  ✅ FOUND with key: ' + paramsKey);
  Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(cachedParams);
  System.debug('  Stored at timestamp: ' + params.get('timestamp'));
  System.debug('  Config: ' + params.get('configName'));
  System.debug('  User to impersonate: ' + params.get('userId'));

  // Calculate age
  Long storedTime = (Long) params.get('timestamp');
  Long now = System.now().getTime();
  Long ageSeconds = (now - storedTime) / 1000;
  System.debug('  Age: ' + ageSeconds + ' seconds');
  System.debug('  TTL: 900 seconds (15 minutes)');
  System.debug('  Expires in: ' + (900 - ageSeconds) + ' seconds');
} else {
  System.debug('  ❌ NOT FOUND with key: ' + paramsKey);
  System.debug('  Parameters may have expired or never been stored');
}

// 2. Check results cache (stored by test for impersonated user)
System.debug('\n📊 RESULTS CACHE (stored by test after execution):');
String resultsKey = 'RunAsTestResult' + sanitizedImpersonated;
String cachedResults = (String) Cache.Org.get(resultsKey);

if (String.isNotBlank(cachedResults)) {
  System.debug('  ✅ FOUND with key: ' + resultsKey);
  Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(cachedResults);
  System.debug('  Stored at timestamp: ' + results.get('timestamp'));
  System.debug('  Success: ' + results.get('success'));
  System.debug('  Record count: ' + results.get('recordCount'));
  System.debug('  Run as user: ' + results.get('runAsUserName'));
} else {
  System.debug('  ❌ NOT FOUND with key: ' + resultsKey);
}

// 3. Check diagnostic info (stored by test when params not found)
System.debug('\n🔍 DIAGNOSTIC INFO (stored by test if params missing):');
String diagnosticKey = 'RunAsTestDiagnostic' + sanitized;
String cachedDiagnostic = (String) Cache.Org.get(diagnosticKey);

if (String.isNotBlank(cachedDiagnostic)) {
  System.debug('  ✅ FOUND diagnostic with key: ' + diagnosticKey);
  Map<String, Object> diagnostic = (Map<String, Object>) JSON.deserializeUntyped(cachedDiagnostic);
  System.debug('  Error: ' + diagnostic.get('error'));
  System.debug('  Cache key test looked for: ' + diagnostic.get('cacheKey'));
  System.debug('  Test executed at: ' + diagnostic.get('testExecutedAt'));
  System.debug('  Test timestamp: ' + diagnostic.get('timestamp'));

  // If we have both params and diagnostic, compare timestamps
  if (String.isNotBlank(cachedParams)) {
    Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(cachedParams);
    Long paramsTime = (Long) params.get('timestamp');
    Long diagnosticTime = (Long) diagnostic.get('timestamp');
    Long delay = (diagnosticTime - paramsTime) / 1000;

    System.debug('\n⏱️  TIMING ANALYSIS:');
    System.debug('  Params stored at: ' + paramsTime);
    System.debug('  Test executed at: ' + diagnosticTime);
    System.debug('  Delay: ' + delay + ' seconds');
    System.debug('  TTL: 900 seconds');

    if (delay > 900) {
      System.debug('  ❌ PROBLEM: Test executed ' + (delay - 900) + ' seconds after TTL expired!');
    } else {
      System.debug('  ✅ Test executed within TTL window');
      System.debug('  🤔 MYSTERY: Params should have been found but weren\'t');
    }
  }
} else {
  System.debug('  ℹ️  No diagnostic found (test may have found params)');
}

// 4. Check ApexTestResult
System.debug('\n🧪 APEX TEST EXECUTION:');
List<ApexTestResult> results = [
  SELECT Id, Outcome, TestTimestamp, Message
  FROM ApexTestResult
  WHERE ApexClass.Name = 'JT_GenericRunAsTest'
    AND MethodName = 'executeRunAsTest'
  ORDER BY TestTimestamp DESC
  LIMIT 1
];

if (!results.isEmpty()) {
  ApexTestResult testResult = results[0];
  System.debug('  ✅ Test found');
  System.debug('  Outcome: ' + testResult.Outcome);
  System.debug('  Timestamp: ' + testResult.TestTimestamp);
  System.debug('  Message: ' + testResult.Message);

  // Calculate when test ran vs now
  Long testTime = testResult.TestTimestamp.getTime();
  Long now = System.now().getTime();
  Long testAge = (now - testTime) / 1000;
  System.debug('  Test ran ' + testAge + ' seconds ago');
} else {
  System.debug('  ❌ No test execution found');
}

System.debug('\n='.repeat(80));
System.debug('CONCLUSION:');
System.debug('='.repeat(80));

if (String.isBlank(cachedParams) && String.isNotBlank(cachedDiagnostic)) {
  System.debug('❌ Parameters expired before test could execute');
  System.debug('💡 Increase TTL further or reduce test queue delay');
} else if (String.isNotBlank(cachedParams) && String.isNotBlank(cachedDiagnostic)) {
  System.debug('🤔 Parameters exist but test couldn\'t find them');
  System.debug('💡 Possible cache partition or key mismatch issue');
} else if (String.isBlank(cachedDiagnostic) && String.isBlank(cachedResults)) {
  System.debug('⏳ Test hasn\'t run yet or params never stored');
} else {
  System.debug('✅ Everything looks normal');
}

System.debug('='.repeat(80));

