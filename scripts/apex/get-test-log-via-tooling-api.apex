// Script to retrieve the ApexLog body from the most recent test execution
// using Tooling API to see what actually happened inside the test

System.debug('='.repeat(80));
System.debug('RETRIEVING TEST EXECUTION LOG VIA TOOLING API');
System.debug('='.repeat(80));

// 1. Get the most recent test result to find the approximate time
List<ApexTestResult> results = [
  SELECT Id, TestTimestamp, QueueItemId, ApexClass.Name
  FROM ApexTestResult
  WHERE ApexClass.Name = 'JT_GenericRunAsTest'
  ORDER BY TestTimestamp DESC
  LIMIT 1
];

if (results.isEmpty()) {
  System.debug('❌ No test results found');
  return;
}

ApexTestResult lastTest = results[0];
System.debug('Last test execution: ' + lastTest.TestTimestamp);
System.debug('Queue Item: ' + lastTest.QueueItemId);

// 2. Query ApexLog records around that time
Datetime testTime = lastTest.TestTimestamp;
Datetime startTime = testTime.addSeconds(-10);
Datetime endTime = testTime.addSeconds(10);

List<ApexLog> logs = [
  SELECT Id, Operation, Status, StartTime, LogLength, Request
  FROM ApexLog
  WHERE
    Operation = 'Test'
    AND StartTime >= :startTime
    AND StartTime <= :endTime
  ORDER BY StartTime DESC
  LIMIT 1
];

if (logs.isEmpty()) {
  System.debug('❌ No ApexLog found for that test');
  System.debug('💡 Logs might have been auto-deleted. Try running the test again.');
  return;
}

ApexLog testLog = logs[0];
System.debug('\n✅ Found ApexLog:');
System.debug('  Id: ' + testLog.Id);
System.debug('  Status: ' + testLog.Status);
System.debug('  StartTime: ' + testLog.StartTime);
System.debug('  Size: ' + testLog.LogLength + ' bytes');

// 3. Use Tooling API to get the log body
System.debug('\n📥 Fetching log body via Tooling API...');

try {
  HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
    '/sobjects/ApexLog/' + testLog.Id + '/Body',
    'GET'
  );

  Http http = new Http();
  HttpResponse response = http.send(request);

  if (response.getStatusCode() == 200) {
    String logBody = response.getBody();
    System.debug('\n✅ LOG RETRIEVED (' + logBody.length() + ' characters)');
    System.debug('='.repeat(80));
    System.debug('FULL TEST LOG BODY:');
    System.debug('='.repeat(80));

    // Print the log (this will be LONG)
    System.debug(logBody);

    System.debug('='.repeat(80));
    System.debug('END OF LOG');
    System.debug('='.repeat(80));

    // Parse for key information
    System.debug('\n🔍 KEY INFORMATION FROM LOG:');

    if (logBody.contains('No test parameters found')) {
      System.debug('❌ Test did NOT find parameters in cache!');
      System.debug('   This explains why no results were stored.');
    } else if (logBody.contains('Parameters found')) {
      System.debug('✅ Test found parameters');
    }

    if (logBody.contains('SUCCESS: Found')) {
      System.debug('✅ Test successfully executed query and found records');
    } else if (logBody.contains('FAILURE:')) {
      System.debug('❌ Test query failed');
    }

    if (logBody.contains('Results stored successfully')) {
      System.debug('✅ Results were stored in cache');
    } else if (logBody.contains('Failed to store results')) {
      System.debug('❌ Failed to store results in cache');
    }

  } else {
    System.debug('❌ Failed to retrieve log body');
    System.debug('Status Code: ' + response.getStatusCode());
    System.debug('Response: ' + response.getBody());
  }
} catch (Exception e) {
  System.debug('❌ Error retrieving log: ' + e.getMessage());
  System.debug('Stack Trace: ' + e.getStackTraceString());
}

System.debug('\n💡 If the log is too large, you can also view it in Setup:');
System.debug('   Setup > Debug Logs > View log ' + testLog.Id);

