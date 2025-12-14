/**
 * @description Functional approach to Run As testing using pre-compiled test class
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 11-29-2025
 * @last modified by Jaime Terrats
 **/
@SuppressWarnings('PMD.AvoidDebugStatements')
public with sharing class JT_RunAsTestExecutor {
  /**
   * @description Executes query as specified user using test context
   * @author Jaime Terrats | 11-29-2025
   * @param userId User ID to run as
   * @param configName Configuration name
   * @param bindingsJson JSON bindings
   * @return TestExecutionResult
   **/
  /**
   * @description Executes query as a specific user using System.runAs() in test context
   * Uses @future to separate DML (insert execution record) from callout (enqueue test)
   * @author Jaime Terrats | 12-13-2025
   * @param userId User ID to impersonate
   * @param configName Configuration name
   * @param bindingsJson JSON bindings
   * @return TestExecutionResult
   **/
  @AuraEnabled
  public static TestExecutionResult executeAsUser(
    String userId,
    String configName,
    String bindingsJson
  ) {
    TestExecutionResult result = new TestExecutionResult();

    try {
      // Validate permissions
      if (!canUseRunAsTest()) {
        throw new AuraHandledException(
          Label.JT_RunAsTestExecutor_insufficientPermissionsRunAsTest
        );
      }

      // Validate user
      User targetUser = validateUser(userId);
      result.runAsUserName = targetUser.Name + ' (' + targetUser.Username + ')';

      // Rate limiting: Check for pending executions to avoid queue saturation
      Integer pendingExecutions = [
        SELECT COUNT()
        FROM JT_RunAsTest_Execution__c
        WHERE
          Initiated_By__c = :UserInfo.getUserId()
          AND Test_Status__c IN ('Queued', 'Running')
          AND CreatedDate >= :Datetime.now().addMinutes(-10)
        WITH USER_MODE
      ];

      final Integer maxPendingExecutions = 3;
      if (pendingExecutions >= maxPendingExecutions) {
        throw new AuraHandledException(
          'Too many test executions in queue (' +
            pendingExecutions +
            '). Please wait for pending executions to complete before starting a new one. Maximum allowed: ' +
            maxPendingExecutions +
            '.'
        );
      }

      JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
        Test_Status__c = 'Queued',
        User_To_Impersonate__c = userId,
        Run_As_User_Name__c = result.runAsUserName,
        Config_Name__c = configName,
        Bindings_Json__c = bindingsJson,
        Initiated_By__c = UserInfo.getUserId()
      );

      // Validate CRUD permissions before DML
      if (!Schema.sObjectType.JT_RunAsTest_Execution__c.isCreateable()) {
        throw new AuraHandledException(
          Label.JT_RunAsTestExecutor_insufficientPermissionsCreate
        );
      }

      try {
        insert execution;
        System.debug(
          '  Run_As_User_Name__c after insert: ' + execution.Run_As_User_Name__c
        );
        System.debug(
          '  Bindings_Json__c after insert: ' +
          (execution.Bindings_Json__c != null
            ? execution.Bindings_Json__c.length() + ' chars'
            : 'NULL')
        );
      } catch (DmlException dmlEx) {
        System.debug(
          LoggingLevel.ERROR,
          '❌ DML error inserting execution record: ' + dmlEx.getMessage()
        );
        System.debug(
          LoggingLevel.ERROR,
          'DML Status Code: ' + dmlEx.getDmlStatusCode(0)
        );
        System.debug(
          LoggingLevel.ERROR,
          'DML Fields: ' + dmlEx.getDmlFields(0)
        );

        // Check for specific error codes and provide user-friendly messages
        String statusCode = dmlEx.getDmlStatusCode(0);
        String errorMessage;

        if (statusCode == 'STORAGE_LIMIT_EXCEEDED') {
          errorMessage = Label.JT_RunAsTestExecutor_storageLimitExceeded;
        } else {
          // Generic DML error message
          errorMessage =
            'Failed to create execution record: ' + dmlEx.getMessage();
        }

        throw new AuraHandledException(errorMessage);
      } catch (Exception insertEx) {
        System.debug(
          LoggingLevel.ERROR,
          '❌ Error inserting execution record: ' + insertEx.getMessage()
        );
        System.debug(
          LoggingLevel.ERROR,
          'Stack trace: ' + insertEx.getStackTraceString()
        );

        // Check if this is a DmlException that wasn't caught by the DmlException catch block
        // (shouldn't happen, but handle gracefully)
        String errorMsg = insertEx.getMessage();
        if (insertEx instanceof DmlException) {
          DmlException dmlEx = (DmlException) insertEx;
          String statusCode = dmlEx.getDmlStatusCode(0);
          if (statusCode == 'STORAGE_LIMIT_EXCEEDED') {
            errorMsg = Label.JT_RunAsTestExecutor_storageLimitExceeded;
          } else {
            errorMsg =
              'Failed to create execution record: ' + dmlEx.getMessage();
          }
        } else {
          errorMsg =
            'Failed to create execution record: ' + insertEx.getMessage();
        }

        throw new AuraHandledException(errorMsg);
      }

      // Enqueue test execution via Tooling API using Queueable
      // This separates DML (insert above) from callout to avoid "uncommitted work pending" error
      // Queueable provides Job ID for monitoring and avoids async resource contention
      System.debug('📤 Enqueuing Queueable to enqueue test execution...');
      Id queueableJobId = System.enqueueJob(
        new JT_RunAsTestEnqueuer(execution.Id)
      );

      // Store Queueable Job ID and update status to "Running" in execution record
      // CRITICAL: All DML must be completed BEFORE the Queueable executes (which makes callout)
      // This update happens AFTER enqueueJob but BEFORE Queueable executes (different transaction)
      // This ensures the Queueable can find the record in "Running" status and avoids "uncommitted work pending" error
      try {
        execution.Test_Status__c = 'Running';
        execution.Apex_Queueable_Job_Id__c = String.valueOf(queueableJobId);
        execution.Log_Messages__c =
          (String.isNotBlank(execution.Log_Messages__c)
            ? execution.Log_Messages__c + '\n'
            : '') +
          'Queueable enqueued at ' +
          System.now() +
          '. Job ID: ' +
          queueableJobId;

        // Validate CRUD permissions before DML
        if (!Schema.sObjectType.JT_RunAsTest_Execution__c.isUpdateable()) {
          throw new AuraHandledException(
            Label.JT_RunAsTestExecutor_insufficientPermissionsUpdate
          );
        }
        update execution;
        System.debug(
          '✅ Execution record updated to Running with Queueable Job ID: ' +
          queueableJobId
        );
      } catch (DmlException dmlEx) {
        System.debug(
          LoggingLevel.ERROR,
          '❌ Failed to update Apex_Queueable_Job_Id__c: ' + dmlEx.getMessage()
        );
        System.debug(
          LoggingLevel.ERROR,
          'DML Status Code: ' + dmlEx.getDmlStatusCode(0)
        );
        System.debug(
          LoggingLevel.ERROR,
          'DML Fields: ' + dmlEx.getDmlFields(0)
        );
        // Continue execution even if update fails - the Queueable will still run
        // The execution record ID is still returned for polling
      } catch (Exception updateEx) {
        System.debug(
          LoggingLevel.ERROR,
          '❌ Error updating Apex_Queueable_Job_Id__c: ' + updateEx.getMessage()
        );
        System.debug(
          LoggingLevel.ERROR,
          'Stack trace: ' + updateEx.getStackTraceString()
        );
        // Continue execution even if update fails - the Queueable will still run
      }

      result.jobId = execution.Id; // Return execution record ID for polling
      result.message = Label.JT_RunAsTestExecutor_testExecutionInitiated;
      result.success = true;

      return result;
    } catch (Exception e) {
      result.success = false;

      // Extract error message - check if it's an AuraHandledException with user-friendly message
      String errorMsg = e.getMessage();

      // If it's an AuraHandledException, use its message directly
      if (e instanceof AuraHandledException) {
        errorMsg = e.getMessage();
      } else {
        // For other exceptions, check if message contains storage limit error
        String exceptionMsg = e.getMessage();
        if (
          exceptionMsg != null &&
          exceptionMsg.contains('STORAGE_LIMIT_EXCEEDED')
        ) {
          errorMsg = Label.JT_RunAsTestExecutor_storageLimitExceeded;
        } else {
          errorMsg = exceptionMsg;
        }
      }

      result.errorMessage = errorMsg;
      result.stackTrace = e.getStackTraceString();
      System.debug(LoggingLevel.ERROR, 'Exception type: ' + e.getTypeName());
      return result;
    }
  }

  /**
   * @description Retrieves test results from Custom Object (replaces Platform Cache)
   * @author Jaime Terrats | 12-13-2025
   * @param executionId The ID of the JT_RunAsTest_Execution__c record
   * @return TestExecutionResult
   **/
  @AuraEnabled
  public static TestExecutionResult getTestResults(String executionId) {
    TestExecutionResult result = new TestExecutionResult();

    try {
      // Query the execution record
      List<JT_RunAsTest_Execution__c> executions = [
        SELECT
          Id,
          Test_Status__c,
          User_To_Impersonate__c,
          Run_As_User_Name__c,
          Config_Name__c,
          Bindings_Json__c,
          Results_Json__c,
          Error_Message__c,
          Record_Count__c,
          Execution_Time__c,
          Log_Messages__c,
          Apex_Test_Queue_Item_Id__c,
          Apex_Queueable_Job_Id__c,
          CreatedDate,
          LastModifiedDate
        FROM JT_RunAsTest_Execution__c
        WHERE Id = :executionId
        WITH USER_MODE
        LIMIT 1
      ];

      if (executions.isEmpty()) {
        result.success = false;
        result.errorMessage = Label.JT_RunAsTestExecutor_executionRecordNotFound;
        result.message = Label.JT_RunAsTestExecutor_executionRecordNotFoundMessage;
        return result;
      }

      JT_RunAsTest_Execution__c execution = executions[0];

      // Check status
      if (
        execution.Test_Status__c ==
        Label.JT_RunAsTestExecutor_testStatusQueued ||
        execution.Test_Status__c == Label.JT_RunAsTestExecutor_testStatusRunning
      ) {
        // First, check if Queueable Job is still running (before test is enqueued)
        if (String.isNotBlank(execution.Apex_Queueable_Job_Id__c)) {
          try {
            List<AsyncApexJob> queueableJobs = [
              SELECT Id, Status, ExtendedStatus, NumberOfErrors
              FROM AsyncApexJob
              WHERE Id = :execution.Apex_Queueable_Job_Id__c
              WITH USER_MODE
              LIMIT 1
            ];

            if (!queueableJobs.isEmpty()) {
              AsyncApexJob queueableJob = queueableJobs[0];

              if (
                queueableJob.Status == 'Queued' ||
                queueableJob.Status == 'Processing'
              ) {
                result.success = false;
                result.message =
                  'Enqueuing test execution (' +
                  queueableJob.Status.toLowerCase() +
                  '). Please wait...';
                return result;
              } else if (queueableJob.Status == 'Failed') {
                result.success = false;
                result.errorMessage =
                  'Failed to enqueue test: ' +
                  (String.isNotBlank(queueableJob.ExtendedStatus)
                    ? queueableJob.ExtendedStatus
                    : 'Queueable job failed');
                result.message = result.errorMessage;
                execution.Test_Status__c = 'Failed';
                execution.Error_Message__c = result.errorMessage;

                // Validate CRUD permissions before DML
                if (
                  Schema.sObjectType.JT_RunAsTest_Execution__c.isUpdateable()
                ) {
                  update execution;
                }
                return result;
              }
            }
          } catch (Exception e) {
            System.debug(
              LoggingLevel.WARN,
              String.format(
                Label.JT_RunAsTestExecutor_couldNotCheckQueueableStatus,
                new List<String>{ e.getMessage() }
              )
            );
          }
        }

        // Check if test has been queued for too long (possible Developer Org limitation)
        if (execution.Apex_Test_Queue_Item_Id__c != null) {
          try {
            List<ApexTestQueueItem> queueItems = [
              SELECT Id, Status, ExtendedStatus
              FROM ApexTestQueueItem
              WHERE Id = :execution.Apex_Test_Queue_Item_Id__c
              WITH USER_MODE
              LIMIT 1
            ];

            if (!queueItems.isEmpty()) {
              ApexTestQueueItem queueItem = queueItems[0];

              // If test is still queued after 30 seconds, it might not execute automatically in Developer Orgs
              Long queuedDuration =
                System.now().getTime() - execution.CreatedDate.getTime();
              if (queueItem.Status == 'Queued' && queuedDuration > 30000) {
                result.success = false;
                result.message = Label.JT_RunAsTestExecutor_testQueuedTooLong;
                System.debug(
                  '⚠️ Test has been queued for ' +
                    queuedDuration +
                    'ms without executing'
                );
                return result;
              }
            }
          } catch (Exception e) {
            System.debug(
              LoggingLevel.WARN,
              String.format(
                Label.JT_RunAsTestExecutor_couldNotCheckQueueItemStatus,
                new List<String>{ e.getMessage() }
              )
            );
          }
        }

        result.success = false;
        result.message =
          String.format(
            Label.JT_RunAsTestExecutor_testIsStatus,
            new List<String>{ execution.Test_Status__c.toLowerCase() }
          ) + '. Please wait...';
        return result;
      }

      // Test completed - parse results
      if (
        execution.Test_Status__c ==
        Label.JT_RunAsTestExecutor_testStatusCompleted
      ) {
        if (String.isNotBlank(execution.Results_Json__c)) {
          // Parse JSON result
          Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(
            execution.Results_Json__c
          );

          result.success = (Boolean) resultMap.get('success');
          result.recordCount = execution.Record_Count__c != null
            ? execution.Record_Count__c.intValue()
            : (Integer) resultMap.get('recordCount');
          result.errorMessage = String.isNotBlank(execution.Error_Message__c)
            ? execution.Error_Message__c
            : (String) resultMap.get('errorMessage');
          result.executionTime = execution.Execution_Time__c != null
            ? execution.Execution_Time__c.intValue()
            : (Integer) resultMap.get('executionTime');
          result.runAsUserName = execution.Run_As_User_Name__c;
          result.assertMessage = execution.Test_Status__c ==
            Label.JT_RunAsTestExecutor_testStatusCompleted
            ? 'SUCCESS: Found ' +
              result.recordCount +
              ' record(s) as ' +
              result.runAsUserName
            : null;

          // Return serialized data for LWC to parse
          result.queryResults = execution.Results_Json__c;
          result.fields = (List<Object>) resultMap.get('fields');
          result.records = (List<Object>) resultMap.get('records');

          System.debug('  success: ' + result.success);
          System.debug('  recordCount: ' + result.recordCount);
          System.debug('  runAsUserName: ' + result.runAsUserName);

          result.message = result.success
            ? String.format(
                Label.JT_RunAsTestExecutor_queryExecutedSuccessfully,
                new List<String>{ result.runAsUserName }
              )
            : String.format(
                Label.JT_RunAsTestExecutor_queryFailed,
                new List<String>{ result.errorMessage }
              );
        } else {
          // Test completed but no results stored
          result.success = false;
          result.errorMessage = String.isNotBlank(execution.Error_Message__c)
            ? execution.Error_Message__c
            : Label.JT_RunAsTestExecutor_testCompletedNoResults;
          result.message = result.errorMessage;
          System.debug('  Log Messages: ' + execution.Log_Messages__c);
        }
      } else if (execution.Test_Status__c == 'Failed') {
        result.success = false;
        result.errorMessage = String.isNotBlank(execution.Error_Message__c)
          ? execution.Error_Message__c
          : Label.JT_RunAsTestExecutor_testExecutionFailed;
        result.message = result.errorMessage;
        System.debug('  Log Messages: ' + execution.Log_Messages__c);
      }

      return result;
    } catch (Exception e) {
      result.success = false;
      result.errorMessage = e.getMessage();
      result.message = 'Error retrieving results: ' + e.getMessage();
      System.debug(
        LoggingLevel.ERROR,
        '❌ Error in getTestResults: ' + e.getMessage()
      );
      System.debug(
        LoggingLevel.ERROR,
        'Stack trace: ' + e.getStackTraceString()
      );
      return result;
    }
  }

  /**
   * @description Gets test execution status from Custom Object (polling endpoint)
   * @author Jaime Terrats | 12-13-2025
   * @param executionId The ID of the JT_RunAsTest_Execution__c record
   * @return Map<String, Object> Status information
   **/
  @AuraEnabled
  public static Map<String, Object> getTestStatus(String executionId) {
    Map<String, Object> status = new Map<String, Object>();

    try {
      // Query the execution record
      List<JT_RunAsTest_Execution__c> executions = [
        SELECT Id, Test_Status__c, Results_Json__c, Error_Message__c
        FROM JT_RunAsTest_Execution__c
        WHERE Id = :executionId
        WITH USER_MODE
        LIMIT 1
      ];

      if (executions.isEmpty()) {
        status.put('status', 'NOT_FOUND');
        status.put('hasResults', false);
        return status;
      }

      JT_RunAsTest_Execution__c execution = executions[0];
      String testStatus = execution.Test_Status__c;

      if (testStatus == Label.JT_RunAsTestExecutor_testStatusCompleted) {
        status.put('status', 'COMPLETED');
        status.put('hasResults', String.isNotBlank(execution.Results_Json__c));
        if (String.isBlank(execution.Results_Json__c)) {
          status.put('warning', 'Test completed but no results stored');
        }
      } else if (testStatus == 'Failed') {
        status.put('status', 'FAILED');
        status.put('hasResults', false);
        status.put('error', execution.Error_Message__c);
      } else if (testStatus == 'Queued' || testStatus == 'Running') {
        status.put('status', 'PENDING');
        status.put('hasResults', false);
      } else {
        status.put('status', testStatus);
        status.put('hasResults', false);
      }
    } catch (Exception e) {
      status.put('status', 'ERROR');
      status.put('error', e.getMessage());
    }

    return status;
  }

  /**
   * @description Validates user (pure function)
   * @author Jaime Terrats | 11-29-2025
   * @param userId User ID
   * @return User
   **/
  private static User validateUser(String userId) {
    List<User> users = [
      SELECT Id, Name, Username, IsActive
      FROM User
      WHERE Id = :userId
      WITH USER_MODE
      LIMIT 1
    ];

    if (users.isEmpty() || !users[0].IsActive) {
      throw new AuraHandledException(
        Label.JT_RunAsTestExecutor_userNotFoundOrInactive
      );
    }

    return users[0];
  }

  /**
   * @description Checks permissions (pure function)
   * @author Jaime Terrats | 11-29-2025
   * @return Boolean
   **/
  @AuraEnabled(cacheable=true)
  public static Boolean canUseRunAsTest() {
    return JT_QueryViewerController.canUseRunAs();
  }

  /**
   * @description Queueable for async test execution with Finalizer support
   * @author Jaime Terrats | 11-29-2025
   **/
  public class RunAsTestQueueable implements Queueable {
    /** User ID to run query as */
    private final String userId;
    /** Configuration name */
    private final String configName;
    /** JSON bindings */
    private final String bindingsJson;

    /**
     * @description Constructor for RunAsTestQueueable
     * @author Jaime Terrats | 11-29-2025
     * @param userId User ID to run query as
     * @param configName Configuration name to execute
     * @param bindingsJson JSON string with bind variables
     **/
    public RunAsTestQueueable(
      String userId,
      String configName,
      String bindingsJson
    ) {
      this.userId = userId;
      this.configName = configName;
      this.bindingsJson = bindingsJson;
    }

    /**
     * @description Executes the test query asynchronously
     * @author Jaime Terrats | 11-29-2025
     * @param context Queueable context
     **/
    public void execute(QueueableContext context) {
      // Attach finalizer for error handling and cleanup
      System.attachFinalizer(new TestExecutionFinalizer(userId));

      try {
        // ⚠️ LIMITATION: This Queueable executes with USER_MODE but NOT System.runAs()
        // System.runAs() only works in Test context (Test.startTest() / Test.stopTest())
        // This means the query executes with the CURRENT user's sharing rules,
        // not the selected user's permissions. It only enforces FLS/CRUD.

        // Execute query and store results functionally
        Map<String, Object> bindings = String.isNotBlank(bindingsJson)
          ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
          : new Map<String, Object>();

        Long startTime = System.now().getTime();
        List<SObject> records = JT_DataSelector.getRecords(
          configName,
          true,
          bindings
        );
        Long endTime = System.now().getTime();

        // Sanitize userId for Platform Cache key
        final String sanitizedUserId = JT_ToolingApiUtil.toAlphanumeric(userId);

        // Extract field names from first record
        List<String> fieldNames = new List<String>();
        if (!records.isEmpty() && records[0] != null) {
          Map<String, Object> recordMap = records[0].getPopulatedFieldsAsMap();
          fieldNames.addAll(recordMap.keySet());
        }

        // Store results in cache as JSON string (keys must be alphanumeric)
        Cache.Org.put(
          'RunAsTestResult' + sanitizedUserId,
          JSON.serialize(
            new Map<String, Object>{
              'success' => true,
              'records' => records,
              'fields' => fieldNames,
              'recordCount' => records.size(),
              'errorMessage' => null,
              'executionTime' => (Integer) (endTime - startTime),
              'runAsUserName' => 'Current User (Queueable)'
            }
          ),
          300
        );
      } catch (Exception e) {
        // Sanitize userId for Platform Cache key
        final String sanitizedUserId = JT_ToolingApiUtil.toAlphanumeric(userId);

        // Store error as JSON string
        Cache.Org.put(
          'RunAsTestResult' + sanitizedUserId,
          JSON.serialize(
            new Map<String, Object>{
              'success' => false,
              'queryResults' => null,
              'recordCount' => 0,
              'errorMessage' => e.getMessage(),
              'executionTime' => 0
            }
          ),
          300
        );
      }
    }
  }

  /**
   * @description Finalizer for queueable cleanup and error handling
   * @author Jaime Terrats | 11-29-2025
   **/
  public class TestExecutionFinalizer implements System.Finalizer {
    /** User ID for result storage */
    private final String userId;

    /**
     * @description Constructor for TestExecutionFinalizer
     * @author Jaime Terrats | 11-29-2025
     * @param userId User ID for cache key
     **/
    public TestExecutionFinalizer(String userId) {
      this.userId = userId;
    }

    /**
     * @description Finalizer method for cleanup and error handling
     * @author Jaime Terrats | 11-29-2025
     * @param context Finalizer context with execution status
     **/
    public void execute(System.FinalizerContext context) {
      if (context.getResult() == System.ParentJobResult.UNHANDLED_EXCEPTION) {
        // Log exception for monitoring
        System.debug(
          LoggingLevel.ERROR,
          Label.JT_RunAsTestExecutor_testExecutionFailedException
        );

        // Sanitize userId for Platform Cache key
        final String sanitizedUserId = JT_ToolingApiUtil.toAlphanumeric(userId);

        // Store error in cache
        Cache.Org.put(
          'RunAsTestResult' + sanitizedUserId,
          JSON.serialize(
            new Map<String, Object>{
              'success' => false,
              'errorMessage' => Label.JT_RunAsTestExecutor_testExecutionFailedUnexpectedly,
              'recordCount' => 0
            }
          ),
          300
        );
      }
    }
  }

  /**
   * @description Wrapper class for test execution result (LWC-friendly)
   * @author Jaime Terrats | 11-29-2025
   **/
  public class TestExecutionResult {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public String queryResults; // Complete JSON string
    @AuraEnabled
    public List<Object> records; // Parsed records array
    @AuraEnabled
    public List<Object> fields; // Field names array
    @AuraEnabled
    public Integer recordCount;
    @AuraEnabled
    public String errorMessage;
    @AuraEnabled
    public String runAsUserName;
    @AuraEnabled
    public String jobId;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String assertMessage; // Test assertion message
    @AuraEnabled
    public Integer executionTime;
    @AuraEnabled
    public String stackTrace;
  }
}
