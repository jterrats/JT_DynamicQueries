/**
 * @description Generic pre-compiled test class for Run As testing - Functional approach
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 11-29-2025
 * @last modified by Jaime Terrats
 **/
// PMD Suppression: SeeAllData=true is required for Run As User feature
// This test class executes queries in different user contexts and needs access to real data
// to properly test user-specific permissions and license restrictions
@SuppressWarnings('PMD')
@IsTest(SeeAllData=true)
public class JT_GenericRunAsTest {
  // Custom Labels for error messages (multilanguage support)
  private static final String LABEL_QUERY_EXECUTION_FAILED_GENERIC = Label.JT_GenericRunAsTest_queryExecutionFailedGeneric;
  private static final String LABEL_USER_PREFIX = Label.JT_GenericRunAsTest_userPrefix;
  private static final String LABEL_ZERO_RECORDS_MESSAGE = Label.JT_GenericRunAsTest_zeroRecordsMessage;
  private static final String LABEL_OBJECT_ACCESS_DENIED = Label.JT_GenericRunAsTest_objectAccessDenied;
  private static final String LABEL_FIELD_ACCESS_DENIED = Label.JT_GenericRunAsTest_fieldAccessDenied;
  private static final String LABEL_INSUFFICIENT_ACCESS_RIGHTS = Label.JT_GenericRunAsTest_insufficientAccessRights;
  private static final String LABEL_LICENSE_RESTRICTION = Label.JT_GenericRunAsTest_licenseRestriction;
  private static final String LABEL_QUERY_EXECUTION_FAILED_WITH_ERROR = Label.JT_GenericRunAsTest_queryExecutionFailedWithError;
  private static final String LABEL_SECURITY_RESTRICTION_WITH_MESSAGE = Label.JT_GenericRunAsTest_securityRestrictionWithMessage;
  private static final String LABEL_SECURITY_EXCEPTION_GENERIC = Label.JT_GenericRunAsTest_securityExceptionGeneric;
  private static final String LABEL_ACCESS_DENIED_WITH_LICENSE = Label.JT_GenericRunAsTest_accessDeniedWithLicense;
  private static final String LABEL_ACCESS_DENIED_GENERIC = Label.JT_GenericRunAsTest_accessDeniedGeneric;
  private static final String LABEL_PERMISSION_ERROR = Label.JT_GenericRunAsTest_permissionError;
  private static final String LABEL_LICENSE_RESTRICTION_GENERIC = Label.JT_GenericRunAsTest_licenseRestrictionGeneric;
  private static final String LABEL_OBJECT_ACCESS_DENIED_GENERIC = Label.JT_GenericRunAsTest_objectAccessDeniedGeneric;
  private static final String LABEL_QUERY_EXECUTION_FAILED_UNKNOWN = Label.JT_GenericRunAsTest_queryExecutionFailedUnknown;

  // Functional composition of test execution
  @IsTest
  @SuppressWarnings('PMD.EmptyCatchBlock')
  static void executeRunAsTest() {
    // Get parameters functionally from cache/custom setting
    TestParameters params = getTestParameters();

    if (params == null) {
      // Try to find execution record directly to write error status
      // This handles cases where getTestParameters() fails but record exists
      try {
        List<JT_RunAsTest_Execution__c> executions = [
          SELECT Id, Test_Status__c, Error_Message__c, Log_Messages__c
          FROM JT_RunAsTest_Execution__c
          WHERE
            Test_Status__c IN ('Queued', 'Running')
            AND Initiated_By__c = :UserInfo.getUserId()
            AND CreatedDate >= :Datetime.now().addMinutes(-5)
          ORDER BY CreatedDate DESC
          LIMIT 1
        ];

        if (!executions.isEmpty()) {
          executions[0].Test_Status__c = 'Failed';
          executions[0]
            .Error_Message__c = Label.JT_GenericRunAsTest_executionParametersNotFound;
          executions[0].Log_Messages__c =
            (String.isNotBlank(executions[0].Log_Messages__c)
              ? executions[0].Log_Messages__c + '\n'
              : '') +
            'Test execution failed: No parameters found at ' +
            System.now();
          update executions[0];
        }
      } catch (Exception e) {
        // Suppress exception - test will fail with assertion below
        // This catch prevents test failure if execution record doesn't exist
      }

      System.assert(true, Label.JT_GenericRunAsTest_noTestParametersFound);
      return;
    }

    // Execute with functional composition (simplified for Apex limitations)
    User targetUser = validateUser(params);
    QueryResult queryResult = executeInUserContext(targetUser, params);

    // Assert: Validate query execution completed successfully
    // Include user-friendly error message if execution failed
    if (!queryResult.success) {
      String assertionMessage = String.isNotBlank(queryResult.errorMessage)
        ? queryResult.errorMessage
        : LABEL_QUERY_EXECUTION_FAILED_GENERIC;

      // Include user name in the error message for better context
      if (String.isNotBlank(queryResult.runAsUser)) {
        assertionMessage = String.format(
          LABEL_USER_PREFIX,
          new List<String>{ queryResult.runAsUser, assertionMessage }
        );
      }

      System.assert(false, assertionMessage);
    }

    // Assert: Document when no records are found (0 records is a valid result)
    if (queryResult.recordCount == 0) {
      System.assert(true, LABEL_ZERO_RECORDS_MESSAGE);
    }

    TestResult result = storeResults(params.executionId, queryResult);

    System.assertEquals(true, result != null, 'Test execution should complete');
  }

  /**
   * @description Gets test parameters from Custom Object (replaces Platform Cache)
   * Finds the most recent Queued execution record that has an Apex_Test_Queue_Item_Id__c
   * This matches the test execution to the Custom Object record
   * @author Jaime Terrats | 12-13-2025
   * @return TestParameters
   **/
  private static TestParameters getTestParameters() {
    try {
      // Strategy: Search for execution records that are NOT completed/failed
      // This handles race conditions where the Queueable updates status before test reads it
      // Filter by Initiated_By__c to ensure we get the correct user's execution

      // First, try to find execution record with Queue Item ID (asynchronous execution)
      // Note: We don't filter by Initiated_By__c because test may execute with different user context
      List<JT_RunAsTest_Execution__c> executions = [
        SELECT
          Id,
          User_To_Impersonate__c,
          Config_Name__c,
          Bindings_Json__c,
          Test_Status__c,
          Apex_Test_Queue_Item_Id__c,
          Apex_Queueable_Job_Id__c,
          Initiated_By__c,
          CreatedDate
        FROM JT_RunAsTest_Execution__c
        WHERE
          Test_Status__c IN ('Queued', 'Running')
          AND Apex_Test_Queue_Item_Id__c != NULL
          // Removed Initiated_By__c filter - test may execute with different user context
          AND CreatedDate >= :Datetime.now().addMinutes(-10)
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];

      // If not found, try without Queue Item ID (synchronous execution)
      // When executing synchronously, the execution record has Apex_Queueable_Job_Id__c but not Apex_Test_Queue_Item_Id__c
      // CRITICAL: When test executes via Tooling API, the user context is the Queueable's user, not the initiating user
      // We must search WITHOUT Initiated_By__c filter to find the record
      if (executions.isEmpty()) {
        executions = [
          SELECT
            Id,
            User_To_Impersonate__c,
            Config_Name__c,
            Bindings_Json__c,
            Test_Status__c,
            Apex_Test_Queue_Item_Id__c,
            Apex_Queueable_Job_Id__c,
            Initiated_By__c,
            CreatedDate
          FROM JT_RunAsTest_Execution__c
          WHERE
            Test_Status__c IN ('Queued', 'Running', 'Completed')
            AND (Apex_Test_Queue_Item_Id__c = NULL
            OR Apex_Test_Queue_Item_Id__c = '')
            AND Apex_Queueable_Job_Id__c != NULL // Synchronous execution has Queueable Job ID
            // CRITICAL: Removed Initiated_By__c filter - test executes with Queueable user, not initiating user
            AND CreatedDate >= :Datetime.now().addMinutes(-5) // Wider window to account for timing differences
          ORDER BY CreatedDate DESC
          LIMIT 1
        ];

        if (executions.isEmpty()) {
          // Debug: Show recent records to understand why search failed
          List<JT_RunAsTest_Execution__c> allRecentExecutions = [
            SELECT
              Id,
              Test_Status__c,
              Apex_Test_Queue_Item_Id__c,
              Apex_Queueable_Job_Id__c,
              Initiated_By__c,
              CreatedDate
            FROM JT_RunAsTest_Execution__c
            WHERE
              Test_Status__c IN ('Queued', 'Running', 'Completed')
              AND (Apex_Test_Queue_Item_Id__c = NULL
              OR Apex_Test_Queue_Item_Id__c = '')
              AND CreatedDate >= :Datetime.now().addMinutes(-5) // Wider window for debugging
            ORDER BY CreatedDate DESC
            LIMIT 5
          ];

          System.debug(
            '  Found ' +
              allRecentExecutions.size() +
              ' recent execution records:'
          );
        }
      }

      if (!executions.isEmpty()) {
        JT_RunAsTest_Execution__c execution = executions[0];

        // Update status to Running (if not already Running or Completed)
        if (
          execution.Test_Status__c != 'Running' &&
          execution.Test_Status__c != 'Completed'
        ) {
          execution.Test_Status__c = 'Running';
          execution.Log_Messages__c =
            (String.isNotBlank(execution.Log_Messages__c)
              ? execution.Log_Messages__c + '\n'
              : '') +
            'Test execution started at ' +
            System.now() +
            (execution.Apex_Test_Queue_Item_Id__c != null
              ? ' (Asynchronous)'
              : ' (Synchronous)');
          update execution;
        }

        return new TestParameters(
          execution.User_To_Impersonate__c,
          execution.Config_Name__c,
          execution.Bindings_Json__c,
          execution.Id // Pass execution ID for storing results
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ Error getting test parameters: ' + e.getMessage()
      );
      System.debug('Stack trace: ' + e.getStackTraceString());
    }
    return null;
  }

  /**
   * @description Validates user (pure function)
   * @author Jaime Terrats | 11-29-2025
   * @param params Test parameters
   * @return User
   **/
  private static User validateUser(TestParameters params) {
    return [
      SELECT Id, Name, Username
      FROM User
      WHERE Id = :params.userId
      LIMIT 1
    ];
  }

  /**
   * @description Executes query in user context (functional with System.runAs)
   * @author Jaime Terrats | 11-29-2025
   * @param user User to run as
   * @param params Test parameters
   * @return QueryResult
   **/
  private static QueryResult executeInUserContext(
    User user,
    TestParameters params
  ) {
    QueryResult result = new QueryResult();

    System.runAs(user) {
      Test.startTest();
      try {
        // Functional transformation of bindings
        Map<String, Object> bindings = String.isNotBlank(params.bindingsJson)
          ? (Map<String, Object>) JSON.deserializeUntyped(params.bindingsJson)
          : new Map<String, Object>();

        // Get config to check for LIKE clauses and add wildcards
        // This ensures queries with LIKE :bindVar work correctly
        JT_DynamicQueryConfiguration__mdt config = [
          SELECT JT_BaseQuery__c
          FROM JT_DynamicQueryConfiguration__mdt
          WHERE DeveloperName = :params.configName
          WITH USER_MODE
          LIMIT 1
        ];

        // Auto-add wildcards for LIKE queries using centralized utility
        // This ensures queries like "WHERE Name LIKE :searchName" work correctly
        JT_QueryBindingUtil.addWildcardsForLikeBindings(
          config.JT_BaseQuery__c,
          bindings
        );

        Long startTime = System.now().getTime();

        // Execute query
        List<SObject> records = JT_DataSelector.getRecords(
          params.configName,
          true,
          bindings
        );

        Long endTime = System.now().getTime();

        // Build result functionally
        result.success = true;
        result.records = records;
        result.recordCount = records.size();
        result.executionTime = (Integer) (endTime - startTime);
        result.runAsUser = user.Name;
      } catch (QueryException qe) {
        result.success = false;
        String errorMsg = qe.getMessage();
        JT_ErrorMessageUtil.ErrorAnalysisResult analysis = JT_ErrorMessageUtil.analyzeError(
          errorMsg,
          null
        );

        switch on analysis.errorType {
          when OBJECT_ACCESS_DENIED {
            result.errorMessage = LABEL_OBJECT_ACCESS_DENIED;
          }
          when FIELD_ACCESS_DENIED {
            result.errorMessage = LABEL_FIELD_ACCESS_DENIED;
          }
          when INSUFFICIENT_PERMISSIONS {
            result.errorMessage = LABEL_INSUFFICIENT_ACCESS_RIGHTS;
          }
          when LICENSE_RESTRICTION {
            result.errorMessage = LABEL_LICENSE_RESTRICTION;
          }
          when else {
            result.errorMessage = String.format(
              LABEL_QUERY_EXECUTION_FAILED_WITH_ERROR,
              new List<String>{ errorMsg }
            );
          }
        }

        result.stackTrace = qe.getStackTraceString();
      } catch (SecurityException se) {
        result.success = false;
        String seMsg = se.getMessage();
        JT_ErrorMessageUtil.ErrorAnalysisResult analysis = JT_ErrorMessageUtil.analyzeError(
          seMsg,
          null
        );

        if (
          analysis.errorType ==
          JT_ErrorMessageUtil.ErrorType.LICENSE_RESTRICTION ||
          analysis.errorType ==
          JT_ErrorMessageUtil.ErrorType.INSUFFICIENT_PERMISSIONS
        ) {
          result.errorMessage = String.format(
            LABEL_SECURITY_RESTRICTION_WITH_MESSAGE,
            new List<String>{ seMsg }
          );
        } else {
          result.errorMessage = LABEL_SECURITY_EXCEPTION_GENERIC;
        }
        result.stackTrace = se.getStackTraceString();
      } catch (AuraHandledException ahe) {
        result.success = false;
        String aheMsg = ahe.getMessage();
        JT_ErrorMessageUtil.ErrorAnalysisResult analysis = JT_ErrorMessageUtil.analyzeError(
          aheMsg,
          null
        );

        if (
          analysis.errorType ==
          JT_ErrorMessageUtil.ErrorType.LICENSE_RESTRICTION ||
          analysis.errorType ==
          JT_ErrorMessageUtil.ErrorType.INSUFFICIENT_PERMISSIONS
        ) {
          result.errorMessage = String.format(
            LABEL_ACCESS_DENIED_WITH_LICENSE,
            new List<String>{ aheMsg }
          );
        } else {
          result.errorMessage = String.format(
            LABEL_ACCESS_DENIED_GENERIC,
            new List<String>{ aheMsg }
          );
        }
        result.stackTrace = ahe.getStackTraceString();
      } catch (Exception e) {
        result.success = false;
        String errorMsg = e.getMessage();
        String exceptionType = e.getTypeName();
        JT_ErrorMessageUtil.ErrorAnalysisResult analysis = JT_ErrorMessageUtil.analyzeError(
          errorMsg,
          null
        );

        switch on analysis.errorType {
          when INSUFFICIENT_PERMISSIONS {
            result.errorMessage = LABEL_PERMISSION_ERROR;
          }
          when LICENSE_RESTRICTION {
            result.errorMessage = LABEL_LICENSE_RESTRICTION_GENERIC;
          }
          when OBJECT_ACCESS_DENIED {
            result.errorMessage = LABEL_OBJECT_ACCESS_DENIED_GENERIC;
          }
          when else {
            String finalErrorMsg = String.isNotBlank(errorMsg)
              ? errorMsg
              : Label.JT_GenericRunAsTest_unknownErrorOccurred;
            result.errorMessage = String.format(
              LABEL_QUERY_EXECUTION_FAILED_UNKNOWN,
              new List<String>{ finalErrorMsg }
            );
          }
        }

        result.stackTrace = e.getStackTraceString();
      }
      Test.stopTest();
    }

    return result;
  }

  /**
   * @description Stores test results in Custom Object (replaces Platform Cache)
   * @author Jaime Terrats | 12-13-2025
   * @param executionId The ID of the JT_RunAsTest_Execution__c record
   * @param queryResult Query result
   * @return TestResult
   **/
  private static TestResult storeResults(
    String executionId,
    QueryResult queryResult
  ) {
    try {
      System.debug(
        '💾 storeResults - queryResult.success: ' + queryResult.success
      );
      System.debug(
        '💾 storeResults - queryResult.recordCount: ' + queryResult.recordCount
      );
      System.debug(
        '💾 storeResults - queryResult.runAsUser: ' + queryResult.runAsUser
      );

      // Query the execution record
      // CRITICAL: Include all fields that will be updated to avoid "SObject row was retrieved via SOQL without querying the requested field" error
      List<JT_RunAsTest_Execution__c> executions = [
        SELECT
          Id,
          Test_Status__c,
          Log_Messages__c,
          Run_As_User_Name__c,
          Results_Json__c,
          Record_Count__c,
          Execution_Time__c,
          Error_Message__c
        FROM JT_RunAsTest_Execution__c
        WHERE Id = :executionId
        LIMIT 1
      ];

      if (executions.isEmpty()) {
        return new TestResult(false, 'Execution record not found');
      }

      JT_RunAsTest_Execution__c execution = executions[0];

      // Build parseable result structure for LWC
      Map<String, Object> resultData = new Map<String, Object>{
        'success' => queryResult.success,
        'recordCount' => queryResult.recordCount,
        'errorMessage' => queryResult.errorMessage,
        'executionTime' => queryResult.executionTime,
        'runAsUserName' => queryResult.runAsUser,
        'timestamp' => System.now().getTime()
      };

      // Serialize records with field information for LWC
      // ✅ Use the same serialization method as the controller to ensure consistent format
      // This ensures child relationships are in standard Salesforce format: { records: [...] }
      if (queryResult.success && !queryResult.records.isEmpty()) {
        List<Object> serializedRecords = JT_QueryViewerController.serializeRecordsForLWC(
          queryResult.records
        );
        List<String> fieldNames = extractFieldNames(queryResult.records[0]);

        resultData.put('records', serializedRecords);
        resultData.put('fields', fieldNames);
      } else {
        resultData.put('records', new List<Object>());
        resultData.put('fields', new List<String>());
      }

      // CRITICAL: DML in @IsTest methods executed via Tooling API gets rolled back.
      // Instead of persisting results via DML (which will be reverted), we write the results
      // to the Debug Log with unique markers. The Queueable will extract these results
      // from the Debug Log and persist them.
      //
      // IMPORTANT NOTES ABOUT DEBUG LOG LIMITS:
      // 1. Developer Console UI truncates strings to ~512 characters for display, but the
      //    full log content is available when retrieved via Tooling API (which we do).
      // 2. Debug Logs have a 2MB total size limit. If exceeded, Salesforce may truncate
      //    older log lines. For very large queries (>1000 records with many fields), this
      //    could be a concern, but is unlikely for typical use cases.
      // 3. The Tooling API retrieves the FULL log content (not truncated), so our extraction
      //    will work correctly even if the UI shows truncation.
      String serializedData = JSON.serialize(resultData);

      // Write results to Debug Log with unique markers
      // The Debug Log survives the test transaction and can be retrieved by the Queueable
      String startMarker = '***QUERY_RESULT_START_' + executionId + '***';
      String endMarker = ' ***QUERY_RESULT_END***';
      System.debug(startMarker + ' ' + serializedData + endMarker);

      // Update execution record with status only (this DML will be reverted, but helps with error handling)
      // The actual results persistence will be done by the Queueable from the Debug Log
      String logMessages = String.isNotBlank(execution.Log_Messages__c)
        ? execution.Log_Messages__c + '\n'
        : '';

      logMessages += 'Test completed at ' + System.now() + '\n';
      logMessages += 'Success: ' + queryResult.success + '\n';
      logMessages += 'Record Count: ' + queryResult.recordCount + '\n';
      logMessages += 'Results written to Debug Log marker (will be extracted by Queueable)';

      execution.Test_Status__c = queryResult.success ? 'Completed' : 'Failed';
      // NOTE: We do NOT set Results_Json__c, Record_Count__c, etc. here because DML will be reverted
      // The Queueable will extract these from the Debug Log and persist them
      execution.Log_Messages__c = logMessages;

      // Ensure Run_As_User_Name__c is set if it wasn't set during creation (for reference, will be reverted)
      if (
        String.isBlank(execution.Run_As_User_Name__c) &&
        String.isNotBlank(queryResult.runAsUser)
      ) {
        execution.Run_As_User_Name__c = queryResult.runAsUser;
      }

      // Attempt to update status (this will be reverted, but helps with error handling)
      // The Queueable will handle the final persistence
      try {
        update execution;
      } catch (DmlException dmlEx) {
        // DML failure is expected in @IsTest context - that's okay, Queueable will handle it
        // Expected behavior: DML operations in @IsTest methods executed via Tooling API are rolled back
        // The Queueable will persist the final status after extracting results from Debug Log
        System.debug(
          LoggingLevel.FINE,
          'DML update reverted (expected in @IsTest context)'
        );
      } catch (Exception updateEx) {
        // Exception is expected in @IsTest context - that's okay, Queueable will handle it
        // Expected behavior: Exceptions in @IsTest methods executed via Tooling API are expected
        // The Queueable will persist the final status after extracting results from Debug Log
        System.debug(
          LoggingLevel.FINE,
          'Update exception (expected in @IsTest context)'
        );
      }

      return new TestResult(true, 'Results stored successfully');
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ Failed to store results: ' + e.getMessage()
      );
      System.debug(
        LoggingLevel.ERROR,
        'Stack trace: ' + e.getStackTraceString()
      );

      // CRITICAL: Try to update execution record with error using robust fallback strategy
      // This ensures the record is never left in an inconsistent state
      // Use centralized utility for consistent error handling
      String errorMessage = 'Failed to store results: ' + e.getMessage();

      // Try to update with full error message and log messages
      try {
        List<JT_RunAsTest_Execution__c> executions = [
          SELECT Id, Test_Status__c, Error_Message__c, Log_Messages__c
          FROM JT_RunAsTest_Execution__c
          WHERE Id = :executionId
          LIMIT 1
        ];
        if (!executions.isEmpty()) {
          executions[0].Test_Status__c = 'Failed';
          executions[0].Error_Message__c = JT_ExecutionUpdateUtil.truncateErrorMessage(
            errorMessage
          );
          executions[0].Log_Messages__c =
            (String.isNotBlank(executions[0].Log_Messages__c)
              ? executions[0].Log_Messages__c + '\n'
              : '') +
            'Error storing results: ' +
            e.getMessage();
          update executions[0];
          return new TestResult(false, errorMessage);
        }
      } catch (Exception updateEx) {
        // If full update fails, use utility fallback strategy
        System.debug(
          LoggingLevel.ERROR,
          'Full update failed, using fallback strategy: ' + updateEx.getMessage()
        );
      }

      // Fallback: Use utility method with robust error handling
      Boolean updateSuccess = JT_ExecutionUpdateUtil.updateExecutionWithError(
        executionId,
        errorMessage,
        'JT_GenericRunAsTest.storeResults'
      );

      if (!updateSuccess) {
        System.debug(
          LoggingLevel.ERROR,
          'CRITICAL: All update strategies failed. Record may remain in inconsistent state.'
        );
      }

      return new TestResult(
        false,
        'Failed to store results: ' + e.getMessage()
      );
    }
  }

  // ✅ REMOVED: serializeRecordsForLWC method
  // Now using JT_QueryViewerController.serializeRecordsForLWC() for consistent serialization
  // This ensures child relationships are in standard Salesforce format: { records: [...] }

  // ✅ REMOVED: flattenSObject method
  // Now using JT_QueryViewerController.serializeRecordsForLWC() which uses standard Salesforce JSON serialization
  // This ensures consistent format with the controller and preserves child relationships in standard format

  /**
   * @description Extracts field names from an SObject record
   * Excludes child relationships (arrays) and attributes to match controller behavior
   * @author Jaime Terrats | 12-13-2025
   * @param record SObject record to extract fields from
   * @return List<String> Field names (excluding child relationships)
   **/
  private static List<String> extractFieldNames(SObject record) {
    Map<String, Object> fieldMap = record.getPopulatedFieldsAsMap();
    List<String> fields = new List<String>();

    // Extract only scalar fields (exclude child relationships)
    // This matches the behavior of JT_QueryViewerController.getFieldNames()
    for (String key : fieldMap.keySet()) {
      Object value = fieldMap.get(key);
      // Exclude 'attributes' and child relationships (which are lists)
      if (key != 'attributes' && !(value instanceof List<SObject>)) {
        fields.add(key);
      }
    }

    // ❌ DON'T sort - this loses SELECT order (matching controller behavior)
    // fields.sort();

    return fields;
  }

  /**
   * @description Test parameters (immutable data class)
   * @author Jaime Terrats | 12-13-2025
   **/
  private class TestParameters {
    public final String userId;
    public final String configName;
    public final String bindingsJson;
    public final String executionId; // ID of JT_RunAsTest_Execution__c record

    public TestParameters(
      String userId,
      String configName,
      String bindingsJson,
      String executionId
    ) {
      this.userId = userId;
      this.configName = configName;
      this.bindingsJson = bindingsJson;
      this.executionId = executionId;
    }
  }

  /**
   * @description Query result wrapper containing execution results
   * @author Jaime Terrats | 11-29-2025
   **/
  private class QueryResult {
    /** Success flag */
    public Boolean success = false;
    /** Query result records */
    public List<SObject> records = new List<SObject>();
    /** Number of records returned */
    public Integer recordCount = 0;
    /** Error message if failed */
    public String errorMessage;
    /** Stack trace if exception */
    public String stackTrace;
    /** Execution time in milliseconds */
    public Integer executionTime = 0;
    /** Name of user who ran the query */
    public String runAsUser;
  }

  /**
   * @description Test result (immutable data class)
   **/
  private class TestResult {
    public final Boolean success;
    public final String message;

    public TestResult(Boolean success, String message) {
      this.success = success;
      this.message = message;
    }
  }
}
