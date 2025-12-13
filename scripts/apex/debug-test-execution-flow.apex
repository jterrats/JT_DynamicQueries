// Debug script to understand the full Run As User test execution flow
// This will help identify why results are not being stored in cache

String impersonatedUserId = '0050b000005coD2AAI';
String currentUserId = UserInfo.getUserId();

System.debug('='.repeat(80));
System.debug('TEST EXECUTION FLOW DEBUG');
System.debug('='.repeat(80));

System.debug('Current User ID (Admin): ' + currentUserId);
System.debug('Impersonated User ID: ' + impersonatedUserId);

// Sanitize
String sanitizedCurrent = currentUserId.replaceAll('[^a-zA-Z0-9]', '');
String sanitizedImpersonated = impersonatedUserId.replaceAll('[^a-zA-Z0-9]', '');

System.debug('Sanitized Current: ' + sanitizedCurrent);
System.debug('Sanitized Impersonated: ' + sanitizedImpersonated);

// 1. Check last test result
System.debug('\n1. LAST TEST EXECUTION:');
List<ApexTestResult> results = [
  SELECT Id, Outcome, Message, StackTrace, MethodName, TestTimestamp,
         ApexClass.Name, RunTime, QueueItemId
  FROM ApexTestResult
  WHERE ApexClass.Name = 'JT_GenericRunAsTest'
  ORDER BY TestTimestamp DESC
  LIMIT 1
];

if (!results.isEmpty()) {
  ApexTestResult lastResult = results[0];
  System.debug('✅ Last test found:');
  System.debug('  Outcome: ' + lastResult.Outcome);
  System.debug('  Method: ' + lastResult.MethodName);
  System.debug('  Timestamp: ' + lastResult.TestTimestamp);
  System.debug('  RunTime: ' + lastResult.RunTime + 'ms');
  System.debug('  QueueItemId: ' + lastResult.QueueItemId);

  if (lastResult.Outcome != 'Pass') {
    System.debug('  ❌ Message: ' + lastResult.Message);
    System.debug('  ❌ StackTrace: ' + lastResult.StackTrace);
  }

  // 2. Get the ApexLog for that test execution
  System.debug('\n2. CHECKING FOR DEBUG LOGS:');
  try {
    // Query for logs around that test execution time
    Datetime testTime = lastResult.TestTimestamp;
    Datetime startTime = testTime.addSeconds(-5);
    Datetime endTime = testTime.addSeconds(5);

    List<ApexLog> logs = [
      SELECT Id, Operation, Status, DurationMilliseconds, StartTime, LogLength
      FROM ApexLog
      WHERE
        Operation = 'Test'
        AND StartTime >= :startTime
        AND StartTime <= :endTime
      ORDER BY StartTime DESC
      LIMIT 5
    ];

    if (!logs.isEmpty()) {
      System.debug('✅ Found ' + logs.size() + ' test logs:');
      for (ApexLog log : logs) {
        System.debug('  - Log: ' + log.Id + ', Status: ' + log.Status +
                     ', Duration: ' + log.DurationMilliseconds + 'ms' +
                     ', Size: ' + log.LogLength + ' bytes');
      }
      System.debug('\n💡 TO SEE FULL DEBUG LOGS, GO TO:');
      System.debug('   Setup > Apex Jobs > Apex Test Results > View Details');
      System.debug('   Or query the ApexLog body using Tooling API');
    } else {
      System.debug('❌ No logs found for test execution');
    }
  } catch (Exception e) {
    System.debug('⚠️ Could not query logs: ' + e.getMessage());
  }
} else {
  System.debug('❌ No test results found');
}

// 3. Check what parameters WOULD be used
System.debug('\n3. PARAMETER CACHE KEY CALCULATION:');
System.debug('When storeTestParameters() is called:');
System.debug('  UserInfo.getUserId() = ' + currentUserId);
System.debug('  Sanitized = ' + sanitizedCurrent);
System.debug('  Cache Key = RunAsTest' + sanitizedCurrent);

System.debug('\nWhen test class calls getTestParameters():');
System.debug('  Inside test: UserInfo.getUserId() = ???');
System.debug('  Expected Cache Key = RunAsTest' + sanitizedCurrent);
System.debug('  ⚠️ If UserInfo.getUserId() is different inside test, keys won\'t match!');

// 4. Check current cache state
System.debug('\n4. CURRENT CACHE STATE:');
String paramsKey = 'RunAsTest' + sanitizedCurrent;
Object params = Cache.Org.get(paramsKey);
System.debug('Parameters cache (' + paramsKey + '): ' +
             (params != null ? '✅ EXISTS' : '❌ EMPTY'));
if (params != null) {
  System.debug('  ' + params);
}

String resultsKey = 'RunAsTestResult' + sanitizedImpersonated;
Object testResults = Cache.Org.get(resultsKey);
System.debug('Results cache (' + resultsKey + '): ' +
             (testResults != null ? '✅ EXISTS' : '❌ EMPTY'));
if (testResults != null) {
  System.debug('  ' + testResults);
}

// 5. Simulate what the test class does
System.debug('\n5. SIMULATING TEST CLASS BEHAVIOR:');
System.debug('Step 1: Test class calls getTestParameters()');
System.debug('  Looks for cache key: RunAsTest' + sanitizedCurrent);

if (params != null) {
  System.debug('  ✅ Parameters found!');
  try {
    Map<String, Object> paramsMap = (Map<String, Object>) JSON.deserializeUntyped((String)params);
    String userId = (String) paramsMap.get('userId');
    String configName = (String) paramsMap.get('configName');
    System.debug('  Will impersonate: ' + userId);
    System.debug('  Will run config: ' + configName);

    // Step 2: Test class would execute query
    System.debug('\nStep 2: Test executes System.runAs(user) with Test.startTest()');
    System.debug('  Query results would be stored in cache');

    // Step 3: Test class would store results
    String sanitizedUserId = userId.replaceAll('[^a-zA-Z0-9]', '');
    String expectedResultsKey = 'RunAsTestResult' + sanitizedUserId;
    System.debug('\nStep 3: Test calls storeResults()');
    System.debug('  Should store to: ' + expectedResultsKey);
    System.debug('  Currently in cache: ' + (testResults != null ? 'YES ✅' : 'NO ❌'));
  } catch (Exception e) {
    System.debug('  ❌ Error parsing params: ' + e.getMessage());
  }
} else {
  System.debug('  ❌ Parameters NOT found!');
  System.debug('  Test would do: System.assert(true, \'No test parameters found - skipping\')');
  System.debug('  Test PASSES but stores NOTHING in cache');
}

System.debug('\n' + '='.repeat(80));
System.debug('DIAGNOSIS SUMMARY:');
System.debug('='.repeat(80));
System.debug('Possible causes of missing results:');
System.debug('1. ❌ Test couldn\'t find parameters (wrong cache key)');
System.debug('2. ❌ Test found parameters but failed during execution');
System.debug('3. ❌ Test succeeded but failed to store results in cache');
System.debug('4. ❌ Results were stored but with wrong cache key');
System.debug('5. ❌ Cache TTL expired before polling (< 5 minutes)');
System.debug('\nNext steps:');
System.debug('- Check the ApexLog for the test execution to see actual debug output');
System.debug('- Verify UserInfo.getUserId() is the same in test context');
System.debug('- Add more debug statements in JT_GenericRunAsTest.executeRunAsTest()');
System.debug('='.repeat(80));

