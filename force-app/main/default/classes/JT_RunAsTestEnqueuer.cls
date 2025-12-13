/**
 * @description Queueable class to execute test via Tooling API
 * Attempts synchronous execution first to avoid async queue contention
 * Falls back to asynchronous execution if synchronous fails (timeout, etc.)
 * Replaces @future method to avoid async resource contention and provide Job ID for monitoring
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 12-13-2025
 **/
public without sharing class JT_RunAsTestEnqueuer implements Queueable, Database.AllowsCallouts {
  private final String executionId;

  /**
   * @description Constructor
   * @param executionId The ID of the JT_RunAsTest_Execution__c record
   **/
  public JT_RunAsTestEnqueuer(String executionId) {
    this.executionId = executionId;
  }

  /**
   * @description Executes the queueable job to run test synchronously via Tooling API
   * Falls back to asynchronous execution if synchronous fails (timeout, etc.)
   * @param context Queueable context
   **/
  public void execute(QueueableContext context) {
    try {
      // Check for async queue contention
      Integer queuedJobs = [
        SELECT COUNT()
        FROM AsyncApexJob
        WHERE
          Status IN ('Queued', 'Processing')
          AND JobType = 'Queueable'
          AND CreatedDate >= :Datetime.now().addMinutes(-5)
      ];

      // If queue is heavily loaded, log a warning but proceed anyway
      // The synchronous execution should bypass the queue
      if (queuedJobs > 50) {
        System.debug(
          LoggingLevel.WARN,
          '⚠️ High async queue contention detected (' +
            queuedJobs +
            ' jobs). Synchronous execution will be attempted to bypass the queue.'
        );
      }

      // Get the ApexClass for JT_GenericRunAsTest
      ApexClass testClass = JT_SystemSelector.getApexClassByName(
        'JT_GenericRunAsTest'
      );

      if (testClass == null) {
        throw new AuraHandledException(
          'Test class JT_GenericRunAsTest not found. Please ensure it is deployed.'
        );
      }

      // CRITICAL: No DML before callout!
      // The execution record should already be in "Running" status (updated by JT_RunAsTestExecutor)
      // This Queueable only handles the callout and final DML updates
      // DML + callout in same transaction causes "uncommitted work pending" error

      // Try synchronous execution first (avoids async queue contention)
      Boolean synchronousSuccess = executeTestSynchronously(testClass.Name);

      if (!synchronousSuccess) {
        // Fallback to asynchronous execution if synchronous failed
        enqueueTestAsynchronously(testClass.Id);
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ Error in JT_RunAsTestEnqueuer: ' + e.getMessage()
      );
      System.debug(
        LoggingLevel.ERROR,
        'Stack trace: ' + e.getStackTraceString()
      );

      // Try to update execution record with error status
      updateExecutionWithError('Failed to execute test: ' + e.getMessage());
    }
  }

  /**
   * @description Executes test synchronously via Tooling API runTestsSynchronous endpoint
   * This avoids async queue contention by running in the API thread
   * @param className Name of the test class to execute
   * @return Boolean True if synchronous execution succeeded, false otherwise
   **/
  private Boolean executeTestSynchronously(String className) {
    try {
      System.debug(
        '⚡ Attempting synchronous test execution for: ' + className
      );

      final String apiVersion = JT_ToolingApiUtil.getApiVersion();
      final String toolingEndpoint =
        '/services/data/' +
        apiVersion +
        '/tooling/runTestsSynchronous/';

      HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
        toolingEndpoint,
        'POST'
      );

      // Synchronous execution format: {"tests":[{"className":"ClassName"}]}
      // CRITICAL: skipCodeCoverage=true reduces JSON response size dramatically
      // Without this, the response includes all org code coverage data, causing CPU timeout during deserialization
      Map<String, Object> requestBody = new Map<String, Object>{
        'tests' => new List<Map<String, Object>>{
          new Map<String, Object>{ 'className' => className }
        },
        'skipCodeCoverage' => true
      };
      request.setBody(JSON.serialize(requestBody));
      request.setTimeout(120000); // 2 minutes timeout for synchronous execution

      Http http = new Http();
      HttpResponse response = http.send(request);

      System.debug(
        'Synchronous test response: ' +
          response.getStatusCode() +
          ' - ' +
          response.getBody()
      );

      if (response.getStatusCode() == 200) {
        // Parse synchronous test results
        // CRITICAL: With skipCodeCoverage=true, response is minimal and deserialization is fast
        // If this still times out, it indicates a CPU limit issue unrelated to code coverage
        try {
          Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(
            response.getBody()
          );

          // Process results and update execution record
          // Note: Test execution writes results to Custom Object in a separate transaction
          // We need to wait a bit and retry reading the results
          processSynchronousTestResults(responseBody);
          return true;
        } catch (JSONException jsonEx) {
          System.debug(
            LoggingLevel.ERROR,
            '❌ JSON deserialization error: ' + jsonEx.getMessage()
          );
          System.debug(
            LoggingLevel.ERROR,
            'Response body length: ' +
            (response.getBody() != null ? response.getBody().length() : 0)
          );
          // CRITICAL: CPU/DML limit error - use specific handler
          updateExecutionWithProcessingError(
            'JSON deserialization failed (CPU limit): ' + jsonEx.getMessage()
          );
          return false;
        } catch (Exception deserializeEx) {
          System.debug(
            LoggingLevel.ERROR,
            '❌ Error deserializing response (possible CPU timeout): ' +
            deserializeEx.getMessage()
          );
          System.debug(
            LoggingLevel.ERROR,
            'Stack trace: ' + deserializeEx.getStackTraceString()
          );
          // CRITICAL: CPU/DML limit error - use specific handler
          updateExecutionWithProcessingError(
            'Error deserializing response (CPU timeout): ' +
            deserializeEx.getMessage()
          );
          return false;
        }
      } else {
        System.debug(
          '⚠️ Synchronous execution failed with status: ' +
          response.getStatusCode()
        );
        updateExecutionWithError(
          'Synchronous execution failed with HTTP status: ' +
          response.getStatusCode()
        );
        return false;
      }
    } catch (CalloutException e) {
      // Timeout or callout error - fallback to async
      System.debug('⚠️ Synchronous execution timeout/error: ' + e.getMessage());
      return false;
    } catch (Exception e) {
      System.debug('⚠️ Synchronous execution error: ' + e.getMessage());
      return false;
    }
  }

  /**
   * @description Processes synchronous test results and updates execution record
   * After synchronous execution, the test class stores results in the Custom Object
   * We need to poll for results since the test writes them in a separate transaction
   * CRITICAL: Minimizes CPU usage by only extracting essential fields from responseBody
   * @param responseBody Response from runTestsSynchronous endpoint
   **/
  private void processSynchronousTestResults(Map<String, Object> responseBody) {
    try {
      // Parse test results from synchronous response
      // Format: {"numFailures":0,"numTestsRun":1,"successes":[...],"failures":[],"apexLogId":"..."}
      // NOTE: With skipCodeCoverage=true, responseBody is minimal (no code coverage data)
      // We only extract essential fields to minimize CPU usage
      Integer numFailures = (Integer) responseBody.get('numFailures');
      Integer numTestsRun = (Integer) responseBody.get('numTestsRun');
      List<Object> successes = (List<Object>) responseBody.get('successes');
      List<Object> failures = (List<Object>) responseBody.get('failures');
      // Extract apexLogId if available (for debugging, but don't store full responseBody)

      System.debug(
        '📊 Parsed synchronous test results: numFailures=' +
          numFailures +
          ', numTestsRun=' +
          numTestsRun
      );

      if (numFailures > 0 && !failures.isEmpty()) {
        // Test execution failed (compilation error, etc.)
        Map<String, Object> failure = (Map<String, Object>) failures[0];
        String errorMessage = (String) failure.get('message');
        updateExecutionWithError(
          'Synchronous test execution failed: ' + errorMessage
        );
        System.debug('❌ Synchronous test failed: ' + errorMessage);
        return;
      }

      if (!successes.isEmpty()) {
        // Test passed - Tooling API indicates test execution succeeded
        // CRITICAL: The test class (@IsTest) may not persist DML reliably
        // We must write the final status based on Tooling API response
        // If the test class wrote additional data (records, fields), we preserve it
        // If not, we at least have the final status for LWC polling

        String apexLogId = (String) responseBody.get('apexLogId');

        // CRITICAL: DML in @IsTest methods executed via Tooling API gets rolled back.
        // The test class writes results to Debug Log with unique markers instead of persisting via DML.
        // We must extract the results from the Debug Log and persist them here.

        // 1. Get the Debug Log content
        String logContent = JT_ToolingApiUtil.getApexLogContent(apexLogId);
        String resultJsonFromLog = null;

        if (String.isNotBlank(logContent)) {
          // 2. Extract JSON from Debug Log using unique markers
          // IMPORTANT: Developer Console UI truncates strings to ~512 chars, but Tooling API
          // retrieves the FULL log content. The extraction will work correctly even if UI shows truncation.
          String startMarker =
            '***QUERY_RESULT_START_' +
            this.executionId +
            '***';
          String endMarker = ' ***QUERY_RESULT_END***';

          Integer startIndex = logContent.indexOf(startMarker);
          Integer endIndex = logContent.indexOf(
            endMarker,
            startIndex != -1 ? startIndex : 0
          );

          if (startIndex != -1 && endIndex != -1) {
            // Extract the JSON between markers
            // Note: There's a space between startMarker and JSON, so we skip it with +1
            Integer jsonStartIndex = startIndex + startMarker.length() + 1; // +1 for the space
            resultJsonFromLog = logContent.substring(jsonStartIndex, endIndex)
              .trim();
          } else {
            // Marker not found - log error for debugging
            System.debug(
              LoggingLevel.WARN,
              '⚠️ Marker not found in Debug Log. Test class may not have written results. ApexLogId: ' +
              apexLogId
            );
          }
        } else {
          System.debug(
            LoggingLevel.WARN,
            '⚠️ Could not retrieve Debug Log content. ApexLogId: ' + apexLogId
          );
        }

        // 3. Query execution record
        List<JT_RunAsTest_Execution__c> executions = [
          SELECT
            Id,
            Test_Status__c,
            Results_Json__c,
            Record_Count__c,
            Execution_Time__c,
            Error_Message__c,
            Log_Messages__c,
            Run_As_User_Name__c
          FROM JT_RunAsTest_Execution__c
          WHERE Id = :this.executionId
          LIMIT 1
        ];

        if (executions.isEmpty()) {
          System.debug('⚠️ Execution record not found: ' + this.executionId);
          return;
        }

        JT_RunAsTest_Execution__c execution = executions[0];

        // 4. Update execution record with results from Debug Log
        execution.Test_Status__c = (numFailures == 0) ? 'Completed' : 'Failed';
        // Store apexLogId in Log_Messages__c since Apex_Log_Id__c field doesn't exist

        if (String.isNotBlank(resultJsonFromLog)) {
          // Successfully extracted results from Debug Log - parse and persist
          try {
            Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(
              resultJsonFromLog
            );

            execution.Results_Json__c = resultJsonFromLog;
            execution.Record_Count__c = resultData.get('recordCount') != null
              ? (Integer) resultData.get('recordCount')
              : 0;
            execution.Execution_Time__c = resultData.get('executionTime') !=
              null
              ? (Integer) resultData.get('executionTime')
              : null;
            execution.Error_Message__c = (String) resultData.get(
              'errorMessage'
            );
            execution.Run_As_User_Name__c = (String) resultData.get(
              'runAsUserName'
            );

            execution.Log_Messages__c =
              (String.isNotBlank(execution.Log_Messages__c)
                ? execution.Log_Messages__c + '\n'
                : '') +
              'Synchronous test execution completed. Results extracted from Debug Log. Log ID: ' +
              apexLogId;

            System.debug('  Execution Time: ' + execution.Execution_Time__c);
            System.debug('  Run As User: ' + execution.Run_As_User_Name__c);
          } catch (JSONException jsonEx) {
            System.debug(
              LoggingLevel.ERROR,
              '❌ Error parsing JSON from Debug Log: ' + jsonEx.getMessage()
            );
            execution.Error_Message__c =
              'Failed to parse results from Debug Log: ' + jsonEx.getMessage();
            execution.Results_Json__c = null;
            execution.Record_Count__c = 0;
          }
        } else if (numFailures > 0) {
          // Test failed - extract failure message from Tooling API response
          // Note: failures variable already declared at method start (line 179)
          if (failures != null && !failures.isEmpty()) {
            Map<String, Object> failure = (Map<String, Object>) failures[0];
            execution.Error_Message__c = (String) failure.get('message');
            execution.Results_Json__c = null;
            execution.Record_Count__c = 0;
          }
          execution.Log_Messages__c =
            (String.isNotBlank(execution.Log_Messages__c)
              ? execution.Log_Messages__c + '\n'
              : '') +
            'Synchronous test execution failed. Log ID: ' +
            apexLogId;
        } else {
          // Test passed but no results found in Debug Log
          execution.Error_Message__c =
            'Test passed but query results could not be extracted from Debug Log (Marker missing or query returned 0 rows). Log ID: ' +
            apexLogId;
          execution.Results_Json__c = null;
          execution.Record_Count__c = 0;
          execution.Log_Messages__c =
            (String.isNotBlank(execution.Log_Messages__c)
              ? execution.Log_Messages__c + '\n'
              : '') +
            'Synchronous test execution completed but no results found in Debug Log. Log ID: ' +
            apexLogId;
        }

        // 5. Persist the final status and results
        try {
          update execution;
          System.debug(
            '✅ Final status and results persisted to execution record'
          );
        } catch (Exception updateEx) {
          System.debug(
            LoggingLevel.ERROR,
            '❌ Error persisting final status: ' + updateEx.getMessage()
          );
          updateExecutionWithProcessingError(
            'Error persisting final status: ' + updateEx.getMessage()
          );
        }
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Error processing synchronous results: ' + e.getMessage()
      );
      System.debug(
        LoggingLevel.ERROR,
        'Stack trace: ' + e.getStackTraceString()
      );
      // CRITICAL: CPU/DML limit error - use specific handler
      updateExecutionWithProcessingError(
        'Error processing synchronous test results (CPU/DML limit): ' +
        e.getMessage()
      );
    }
  }

  /**
   * @description Falls back to asynchronous test execution via ApexTestQueueItem
   * @param testClassId ApexClass Id of the test class
   **/
  private void enqueueTestAsynchronously(Id testClassId) {
    System.debug('📤 Enqueuing test asynchronously via ApexTestQueueItem...');

    final String apiVersion = JT_ToolingApiUtil.getApiVersion();
    final String toolingEndpoint =
      '/services/data/' +
      apiVersion +
      '/tooling/sobjects/ApexTestQueueItem';

    HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
      toolingEndpoint,
      'POST'
    );

    Map<String, Object> requestBody = new Map<String, Object>{
      'ApexClassId' => testClassId
    };
    request.setBody(JSON.serialize(requestBody));

    Http http = new Http();
    HttpResponse response = http.send(request);

    System.debug(
      'Async enqueue response: ' +
        response.getStatusCode() +
        ' - ' +
        response.getBody()
    );

    if (response.getStatusCode() == 201) {
      Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(
        response.getBody()
      );
      String queueItemId = (String) responseBody.get('id');

      List<JT_RunAsTest_Execution__c> executions = [
        SELECT Id, Apex_Test_Queue_Item_Id__c, Log_Messages__c
        FROM JT_RunAsTest_Execution__c
        WHERE Id = :this.executionId
        LIMIT 1
      ];
      if (!executions.isEmpty()) {
        executions[0].Apex_Test_Queue_Item_Id__c = queueItemId;
        executions[0].Log_Messages__c =
          (String.isNotBlank(executions[0].Log_Messages__c)
            ? executions[0].Log_Messages__c + '\n'
            : '') +
          'Fell back to asynchronous execution. Queue Item ID: ' +
          queueItemId;
        update executions[0];
        System.debug(
          '✅ Test enqueued asynchronously with Queue Item ID: ' + queueItemId
        );
      }
    } else {
      throw new AuraHandledException(
        'Failed to enqueue test asynchronously: ' +
          response.getStatusCode() +
          ' - ' +
          response.getBody()
      );
    }
  }

  /**
   * @description Updates execution record with processing error status (CPU/DML limit errors)
   * CRITICAL: This method MUST succeed to prevent records from staying in 'Queued' state
   * Specifically designed for CPU timeout and DML limit errors
   * @param errorMessage Error message to store
   **/
  private void updateExecutionWithProcessingError(String errorMessage) {
    // Use the same robust error handler but with specific error message prefix
    updateExecutionWithError(
      'Processing Error (CPU/DML Limit): ' + errorMessage
    );
  }

  /**
   * @description Updates execution record with error status
   * CRITICAL: This method MUST succeed to prevent records from staying in 'Queued' state
   * Uses minimal DML operations and has multiple fallback strategies
   * @param errorMessage Error message to store
   **/
  private void updateExecutionWithError(String errorMessage) {
    // Strategy 1: Try with fresh query and minimal fields
    try {
      List<JT_RunAsTest_Execution__c> executions = [
        SELECT Id, Test_Status__c, Error_Message__c
        FROM JT_RunAsTest_Execution__c
        WHERE Id = :this.executionId
        LIMIT 1
      ];
      if (!executions.isEmpty()) {
        executions[0].Test_Status__c = 'Failed';
        // Truncate error message if too long to avoid DML issues
        String truncatedError = errorMessage.length() > 255
          ? errorMessage.substring(0, 252) + '...'
          : errorMessage;
        executions[0].Error_Message__c = truncatedError;
        update executions[0];
        return;
      }
    } catch (DmlException dmlEx) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ DML error in updateExecutionWithError (Strategy 1): ' +
        dmlEx.getMessage()
      );
      System.debug(
        LoggingLevel.ERROR,
        'DML Status Code: ' + dmlEx.getDmlStatusCode(0)
      );

      // Strategy 2: Try with even more minimal update (only status, no error message)
      try {
        JT_RunAsTest_Execution__c minimalUpdate = new JT_RunAsTest_Execution__c(
          Id = this.executionId,
          Test_Status__c = 'Failed'
        );
        update minimalUpdate;
        return;
      } catch (Exception minimalEx) {
        System.debug(
          LoggingLevel.ERROR,
          '❌ Minimal update also failed (Strategy 2): ' +
          minimalEx.getMessage()
        );
      }
    } catch (Exception updateEx) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ General error in updateExecutionWithError (Strategy 1): ' +
        updateEx.getMessage()
      );
      System.debug(
        LoggingLevel.ERROR,
        'Stack trace: ' + updateEx.getStackTraceString()
      );

      // Strategy 2: Try with minimal update
      try {
        JT_RunAsTest_Execution__c minimalUpdate = new JT_RunAsTest_Execution__c(
          Id = this.executionId,
          Test_Status__c = 'Failed'
        );
        update minimalUpdate;
        return;
      } catch (Exception minimalEx) {
        System.debug(
          LoggingLevel.ERROR,
          '❌ Minimal update also failed (Strategy 2 fallback): ' +
          minimalEx.getMessage()
        );
      }
    }

    // Strategy 3: Last resort - log but don't fail silently
    System.debug(
      LoggingLevel.ERROR,
      '❌ CRITICAL: All update strategies failed for execution: ' +
      this.executionId
    );
    System.debug(
      LoggingLevel.ERROR,
      'Record may remain in inconsistent state. Manual intervention required.'
    );
  }
}
