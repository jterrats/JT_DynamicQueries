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
      Integer queuedJobs = [
        SELECT COUNT()
        FROM AsyncApexJob
        WHERE
          Status IN ('Queued', 'Processing')
          AND JobType = 'Queueable'
          AND CreatedDate >= :Datetime.now().addMinutes(-5)
      ];

      if (queuedJobs > 50) {
        System.debug(
          LoggingLevel.WARN,
          '⚠️ High async queue contention detected (' +
            queuedJobs +
            ' jobs). Synchronous execution will be attempted to bypass the queue.'
        );
      }

      ApexClass testClass = JT_SystemSelector.getApexClassByName(
        'JT_GenericRunAsTest'
      );

      if (testClass == null) {
        throw new AuraHandledException(
          Label.JT_RunAsTestEnqueuer_testClassNotFound
        );
      }

      // CRITICAL: No DML before callout!
      // The execution record should already be in "Running" status (updated by JT_RunAsTestExecutor)
      // This Queueable only handles the callout and final DML updates
      // DML + callout in same transaction causes "uncommitted work pending" error

      Boolean synchronousSuccess = executeTestSynchronously(testClass.Name);

      if (!synchronousSuccess) {
        enqueueTestAsynchronously(testClass.Id);
      }
    } catch (Exception e) {
      JT_ErrorLogger.logError(
        'Test Execution Failed',
        e,
        'JT_RunAsTestEnqueuer.execute'
      );

      JT_ExecutionUpdateUtil.updateExecutionWithError(
        this.executionId,
        'Failed to execute test: ' + e.getMessage(),
        'JT_RunAsTestEnqueuer.execute'
      );
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
        // CRITICAL: With skipCodeCoverage=true, response is minimal and deserialization is fast
        // If this still times out, it indicates a CPU limit issue unrelated to code coverage
        try {
          Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(
            response.getBody()
          );

          processSynchronousTestResults(responseBody);
          return true;
        } catch (JSONException jsonEx) {
          return handleDeserializationError(
            jsonEx,
            response,
            'JSON Deserialization'
          );
        } catch (Exception deserializeEx) {
          return handleDeserializationError(
            deserializeEx,
            response,
            'Response Deserialization'
          );
        }
      } else {
        Map<String, Object> details = new Map<String, Object>{
          'httpStatusCode' => response.getStatusCode(),
          'httpStatus' => response.getStatus(),
          'responseBody' => response.getBody() != null &&
            response.getBody().length() < 1000
            ? response.getBody()
            : 'Response too long',
          'executionId' => this.executionId
        };
        JT_ErrorLogger.logError(
          'Tooling API HTTP Error',
          'Synchronous execution failed with HTTP status: ' +
          response.getStatusCode(),
          null,
          'JT_RunAsTestEnqueuer.executeTestSynchronously',
          JSON.serialize(details),
          'High'
        );

        JT_ExecutionUpdateUtil.updateExecutionWithError(
          this.executionId,
          'Synchronous execution failed with HTTP status: ' +
          response.getStatusCode(),
          'JT_RunAsTestEnqueuer.executeTestSynchronously'
        );
        return false;
      }
    } catch (CalloutException e) {
      JT_ErrorLogger.logError(
        'Tooling API Callout Exception',
        e.getMessage(),
        e,
        'JT_RunAsTestEnqueuer.executeTestSynchronously'
      );
      return false;
    } catch (Exception e) {
      JT_ErrorLogger.logError(
        'Tooling API Unexpected Error',
        e.getMessage(),
        e,
        'JT_RunAsTestEnqueuer.executeTestSynchronously'
      );
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
      // NOTE: With skipCodeCoverage=true, responseBody is minimal (no code coverage data)
      // We only extract essential fields to minimize CPU usage
      Integer numFailures = (Integer) responseBody.get('numFailures');
      Integer numTestsRun = (Integer) responseBody.get('numTestsRun');
      List<Object> successes = (List<Object>) responseBody.get('successes');
      List<Object> failures = (List<Object>) responseBody.get('failures');

      System.debug(
        '📊 Parsed synchronous test results: numFailures=' +
          numFailures +
          ', numTestsRun=' +
          numTestsRun
      );

      if (numFailures > 0 && !failures.isEmpty()) {
        Map<String, Object> failure = (Map<String, Object>) failures[0];
        String errorMessage = (String) failure.get('message');

        String friendlyMessage = extractUserFriendlyErrorMessage(
          errorMessage,
          failure
        );

        JT_ExecutionUpdateUtil.updateExecutionWithError(
          this.executionId,
          friendlyMessage,
          'JT_RunAsTestEnqueuer.processSynchronousTestResults'
        );
        return;
      }

      if (!successes.isEmpty()) {
        // CRITICAL: The test class (@IsTest) may not persist DML reliably
        // We must write the final status based on Tooling API response
        // If the test class wrote additional data (records, fields), we preserve it
        // If not, we at least have the final status for LWC polling

        String apexLogId = (String) responseBody.get('apexLogId');

        // CRITICAL: DML in @IsTest methods executed via Tooling API gets rolled back.
        // The test class writes results to Debug Log with unique markers instead of persisting via DML.
        // We must extract the results from the Debug Log and persist them here.

        String logContent = JT_ToolingApiUtil.getApexLogContent(apexLogId);
        String resultJsonFromLog = null;

        if (String.isNotBlank(logContent)) {
          // IMPORTANT: Developer Console UI truncates strings to ~512 chars, but Tooling API
          // retrieves the FULL log content. The extraction will work correctly even if UI shows truncation.
          String startMarker =
            '***QUERY_RESULT_START_' +
            this.executionId +
            '***';
          String endMarker = ' ***QUERY_RESULT_END***';

          System.debug(
            LoggingLevel.DEBUG,
            '🔍 Searching for markers in Debug Log. ExecutionId: ' +
              this.executionId +
              ', LogContent length: ' +
              (logContent != null ? logContent.length() : 0)
          );
          System.debug(LoggingLevel.DEBUG, '🔍 StartMarker: ' + startMarker);
          System.debug(LoggingLevel.DEBUG, '🔍 EndMarker: ' + endMarker);

          Integer startIndex = logContent.indexOf(startMarker);
          System.debug(
            LoggingLevel.DEBUG,
            '🔍 StartMarker found at index: ' + startIndex
          );

          Integer endIndex = -1;
          if (startIndex != -1) {
            endIndex = logContent.indexOf(endMarker, startIndex);
            System.debug(
              LoggingLevel.DEBUG,
              '🔍 EndMarker found at index: ' + endIndex
            );
          } else {
            // StartMarker not found - try searching for endMarker anyway (for debugging)
            System.debug(
              LoggingLevel.WARN,
              '⚠️ StartMarker not found. Searching entire log for endMarker...'
            );
            endIndex = logContent.indexOf(endMarker);
            System.debug(
              LoggingLevel.DEBUG,
              '🔍 EndMarker found at index (without start): ' + endIndex
            );
          }

          if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            // Note: There's a space between startMarker and JSON, so we skip it with +1
            Integer jsonStartIndex = startIndex + startMarker.length() + 1;

            // Ensure we don't go beyond endIndex
            if (jsonStartIndex < endIndex) {
              resultJsonFromLog = logContent.substring(jsonStartIndex, endIndex)
                .trim();
            } else {
              System.debug(
                LoggingLevel.ERROR,
                '❌ Invalid indices: jsonStartIndex (' +
                  jsonStartIndex +
                  ') >= endIndex (' +
                  endIndex +
                  ')'
              );
              resultJsonFromLog = null;
            }

            System.debug(
              LoggingLevel.DEBUG,
              '✅ Successfully extracted JSON from Debug Log. Length: ' +
              (resultJsonFromLog != null ? resultJsonFromLog.length() : 0)
            );
            System.debug(
              LoggingLevel.FINEST,
              '✅ Extracted JSON (first 500 chars): ' +
              (resultJsonFromLog != null &&
                resultJsonFromLog.length() > 500
                ? resultJsonFromLog.substring(0, 500) + '...'
                : resultJsonFromLog)
            );
          } else {
            System.debug(
              LoggingLevel.WARN,
              '⚠️ Marker not found in Debug Log. StartIndex: ' +
                startIndex +
                ', EndIndex: ' +
                endIndex +
                ', ApexLogId: ' +
                apexLogId
            );

            if (logContent.length() > 1000) {
              System.debug(
                LoggingLevel.DEBUG,
                '🔍 Log content sample (last 1000 chars): ' +
                logContent.substring(logContent.length() - 1000)
              );
            } else {
              System.debug(
                LoggingLevel.DEBUG,
                '🔍 Full log content: ' + logContent
              );
            }
          }
        } else {
          System.debug(
            LoggingLevel.WARN,
            '⚠️ Could not retrieve Debug Log content. ApexLogId: ' + apexLogId
          );
        }

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
          return;
        }

        JT_RunAsTest_Execution__c execution = executions[0];

        execution.Test_Status__c = (numFailures == 0) ? 'Completed' : 'Failed';

        if (String.isNotBlank(resultJsonFromLog)) {
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

            appendLogMessage(
              execution,
              'Synchronous test execution completed. Results extracted from Debug Log. Log ID: ' +
              apexLogId
            );

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
          if (failures != null && !failures.isEmpty()) {
            Map<String, Object> failure = (Map<String, Object>) failures[0];
            String errorMessage = (String) failure.get('message');
            execution.Error_Message__c = extractUserFriendlyErrorMessage(
              errorMessage,
              failure
            );
            execution.Results_Json__c = null;
            execution.Record_Count__c = 0;
          }
          appendLogMessage(
            execution,
            'Synchronous test execution failed. Log ID: ' + apexLogId
          );
        } else {
          execution.Error_Message__c =
            'Test passed but query results could not be extracted from Debug Log (Marker missing or query returned 0 rows). Log ID: ' +
            apexLogId;
          execution.Results_Json__c = null;
          execution.Record_Count__c = 0;
          appendLogMessage(
            execution,
            'Synchronous test execution completed but no results found in Debug Log. Log ID: ' +
            apexLogId
          );
        }

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
          JT_ExecutionUpdateUtil.updateExecutionWithProcessingError(
            this.executionId,
            'Error persisting final status: ' + updateEx.getMessage(),
            'JT_RunAsTestEnqueuer.processSynchronousTestResults'
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
      JT_ExecutionUpdateUtil.updateExecutionWithProcessingError(
        this.executionId,
        'Error processing synchronous test results (CPU/DML limit): ' +
        e.getMessage(),
        'JT_RunAsTestEnqueuer.processSynchronousTestResults'
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
        appendLogMessage(
          executions[0],
          'Fell back to asynchronous execution. Queue Item ID: ' + queueItemId
        );
        update executions[0];
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
   * @description Handles deserialization errors with consistent error handling
   * Centralizes deserialization error handling to avoid duplication
   * @param e Exception that occurred during deserialization
   * @param response HTTP response that failed to deserialize
   * @param errorType Type of error (e.g., "JSON Deserialization", "Response Deserialization")
   * @return Boolean Always returns false (indicates failure)
   **/
  private Boolean handleDeserializationError(
    Exception e,
    HttpResponse response,
    String errorType
  ) {
    Map<String, Object> details = new Map<String, Object>{
      'responseStatusCode' => response.getStatusCode(),
      'responseBodyLength' => response.getBody() != null
        ? response.getBody().length()
        : 0,
      'executionId' => this.executionId,
      'errorType' => errorType
    };
    JT_ErrorLogger.logError(
      'Tooling API ' + errorType + ' Failed',
      e.getMessage(),
      e,
      'JT_RunAsTestEnqueuer.executeTestSynchronously',
      JSON.serialize(details),
      'High'
    );
    JT_ExecutionUpdateUtil.updateExecutionWithProcessingError(
      this.executionId,
      errorType + ' failed (CPU limit): ' + e.getMessage(),
      'JT_RunAsTestEnqueuer.executeTestSynchronously'
    );
    return false;
  }

  /**
   * @description Appends a log message to execution record
   * Centralizes log message construction to avoid duplication
   * @param execution Execution record to update
   * @param message Message to append
   **/
  private void appendLogMessage(
    JT_RunAsTest_Execution__c execution,
    String message
  ) {
    execution.Log_Messages__c =
      (String.isNotBlank(execution.Log_Messages__c)
        ? execution.Log_Messages__c + '\n'
        : '') +
      message;
  }

  /**
   * @description Extracts user-friendly error message from test failure
   * Uses JT_ErrorMessageUtil for consistent error detection
   * @param errorMessage Raw error message from Tooling API
   * @param failure Failure map from Tooling API response
   * @return String User-friendly error message
   **/
  private String extractUserFriendlyErrorMessage(
    String errorMessage,
    Map<String, Object> failure
  ) {
    if (String.isBlank(errorMessage)) {
      return Label.JT_RunAsTestEnqueuer_testExecutionFailed;
    }

    String stackTrace = failure != null
      ? (String) failure.get('stackTrace')
      : null;
    JT_ErrorMessageUtil.ErrorAnalysisResult analysis = JT_ErrorMessageUtil.analyzeError(
      errorMessage,
      stackTrace
    );

    if (String.isNotBlank(analysis.assertionMessage)) {
      return analysis.assertionMessage;
    }

    if (
      analysis.isAssertionFailed &&
      analysis.errorType == JT_ErrorMessageUtil.ErrorType.UNKNOWN
    ) {
      return Label.JT_RunAsTestEnqueuer_assertionFailedGeneric;
    }

    switch on analysis.errorType {
      when OBJECT_ACCESS_DENIED {
        return Label.JT_RunAsTestEnqueuer_objectAccessDenied;
      }
      when FIELD_ACCESS_DENIED {
        return Label.JT_RunAsTestEnqueuer_fieldAccessDenied;
      }
      when INSUFFICIENT_PERMISSIONS {
        return Label.JT_RunAsTestEnqueuer_insufficientAccessRights;
      }
      when LICENSE_RESTRICTION {
        return Label.JT_RunAsTestEnqueuer_licenseRestriction;
      }
      when CONFIGURATION_ACCESS_DENIED {
        return Label.JT_RunAsTestEnqueuer_configurationAccessDenied;
      }
      when else {
        return errorMessage;
      }
    }
  }

}
