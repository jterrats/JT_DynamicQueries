// Quick script to get the most recent test log
// RUN THIS IMMEDIATELY after clicking "Execute Query" with Run As User

System.debug('🔍 Searching for most recent test log...');

// Get logs from the last 2 minutes
Datetime twoMinutesAgo = System.now().addMinutes(-2);

List<ApexLog> logs = [
  SELECT Id, Operation, Status, StartTime, LogLength, Request, LogUser.Name
  FROM ApexLog
  WHERE
    Operation IN ('Test', 'Testmethod')
    AND StartTime >= :twoMinutesAgo
  ORDER BY StartTime DESC
  LIMIT 5
];

if (logs.isEmpty()) {
  System.debug('❌ No test logs found in the last 2 minutes');
  System.debug('💡 Make sure to run this script IMMEDIATELY after executing Run As User');
  return;
}

System.debug('✅ Found ' + logs.size() + ' test log(s):');
for (Integer i = 0; i < logs.size(); i++) {
  ApexLog log = logs[i];
  System.debug('\n[' + (i+1) + '] Log ID: ' + log.Id);
  System.debug('    Status: ' + log.Status);
  System.debug('    User: ' + log.LogUser.Name);
  System.debug('    Start: ' + log.StartTime);
  System.debug('    Size: ' + log.LogLength + ' bytes');
}

// Get the body of the most recent log
ApexLog mostRecent = logs[0];
System.debug('\n📥 Fetching body of most recent log via Tooling API...');

try {
  HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
    '/sobjects/ApexLog/' + mostRecent.Id + '/Body',
    'GET'
  );

  Http http = new Http();
  HttpResponse response = http.send(request);

  if (response.getStatusCode() == 200) {
    String logBody = response.getBody();

    System.debug('\n' + '='.repeat(80));
    System.debug('TEST LOG BODY (' + logBody.length() + ' characters)');
    System.debug('='.repeat(80));
    System.debug(logBody);
    System.debug('='.repeat(80));

    // Extract key debug lines
    System.debug('\n🔍 KEY DEBUG LINES:');
    String[] lines = logBody.split('\n');
    for (String line : lines) {
      if (line.contains('getTestParameters') ||
          line.contains('storeResults') ||
          line.contains('Parameters found') ||
          line.contains('cacheKey:') ||
          line.contains('SUCCESS:') ||
          line.contains('FAILURE:') ||
          line.contains('❌') ||
          line.contains('✅')) {
        System.debug(line);
      }
    }
  } else {
    System.debug('❌ Failed to get log body: ' + response.getStatusCode());
    System.debug('Response: ' + response.getBody());
  }
} catch (Exception e) {
  System.debug('❌ Error: ' + e.getMessage());
}

System.debug('\n💡 You can also view this log in Setup:');
System.debug('   Setup > Debug Logs > ' + mostRecent.Id);

