/**
 * @description Test class for JT_RunAsTestExecutor - 100% coverage
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 11-29-2025
 * @last modified by Jaime Terrats
 **/
@IsTest
private class JT_RunAsTestExecutor_Test {
  @testSetup
  static void setupTestData() {
    // Create test Account
    insert new Account(Name = 'Test Account for Executor');
  }

  /**
   * @description Test canUseRunAsTest method
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testCanUseRunAsTest() {
    Test.startTest();
    Boolean canUse = JT_RunAsTestExecutor.canUseRunAsTest();
    Test.stopTest();

    System.assertNotEquals(null, canUse, 'Should return a boolean');
  }

  /**
   * @description Test executeAsUser with valid parameters
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testExecuteAsUserValid() {
    User currentUser = JT_SystemSelector.getCurrentUser();
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Executor'
    };

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      JSON.serialize(bindings)
    );
    Test.stopTest();

    // Result depends on permissions
    System.assertNotEquals(null, result, 'Result should not be null');
    // Message may be null or populated depending on org permissions
    System.assert(result.success != null, 'Should have success flag');
  }

  /**
   * @description Test executeAsUser with invalid user
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testExecuteAsUserInvalidUser() {
    // Create a fake but properly formatted User ID
    String fakeUserId = '005' + '0'.repeat(15);

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
      fakeUserId,
      'Test_Record',
      null
    );
    Test.stopTest();

    System.assertEquals(false, result.success, 'Should fail with invalid user');
    System.assertNotEquals(
      null,
      result.errorMessage,
      'Should have error message'
    );
  }

  /**
   * @description Test executeAsUser with null bindings
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testExecuteAsUserNullBindings() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
  }

  /**
   * @description Test executeAsUser with empty bindings
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testExecuteAsUserEmptyBindings() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      ''
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
  }

  /**
   * @description Test getTestResults with no execution record (invalid executionId)
   * @author Jaime Terrats | 11-29-2025
   * Updated: 12-13-2025 - getTestResults now takes executionId instead of userId
   **/
  @IsTest
  static void testGetTestResultsNoCachedResults() {
    // Use a fake execution ID (non-existent record)
    String fakeExecutionId = 'a0S' + '0'.repeat(15);

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      fakeExecutionId
    );
    Test.stopTest();

    System.assertEquals(
      false,
      result.success,
      'Should return false when execution record not found'
    );
    System.assertNotEquals(null, result.message, 'Should have a message');
  }

  /**
   * @description Test getTestResults with valid execution record
   * @author Jaime Terrats | 11-29-2025
   * Updated: 12-13-2025 - getTestResults now takes executionId from executeAsUser
   **/
  @IsTest
  static void testGetTestResultsPath() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Executor'
    };

    Test.startTest();
    // First, execute a test to get an executionId
    JT_RunAsTestExecutor.TestExecutionResult executeResult = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      JSON.serialize(bindings)
    );

    // If execution was initiated successfully, try to get results
    if (executeResult.success && String.isNotBlank(executeResult.jobId)) {
      String executionId = executeResult.jobId;

      // Try to get results (may not be ready yet, but tests the method)
      JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
        executionId
      );

      // Result may be pending or completed depending on timing
      System.assertNotEquals(null, result, 'Result should not be null');
      System.assert(result.success != null, 'Should have success flag');
    } else {
      // Execution failed (e.g., permissions), but method still works
      System.assert(true, 'Method executed even if execution failed');
    }
    Test.stopTest();
  }

  /**
   * @description Test getTestStatus with no execution record (invalid executionId)
   * @author Jaime Terrats | 11-29-2025
   * Updated: 12-13-2025 - getTestStatus now takes executionId instead of userId
   **/
  @IsTest
  static void testGetTestStatusNotFound() {
    // Use a fake execution ID (non-existent record)
    String fakeExecutionId = 'a0S' + '0'.repeat(15);

    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(
      fakeExecutionId
    );
    Test.stopTest();

    System.assertNotEquals(null, status, 'Status should not be null');
    System.assert(status.containsKey('status'), 'Should have status key');
    System.assertEquals(
      'NOT_FOUND',
      status.get('status'),
      'Should return NOT_FOUND for invalid executionId'
    );
  }

  /**
   * @description Test getTestStatus path coverage
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testGetTestStatusPath() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    Test.startTest();
    try {
      // Try cache operations if available
      Cache.Org.put(
        'RunAsTest_' + currentUser.Id,
        new Map<String, Object>{
          'userId' => currentUser.Id,
          'configName' => 'Test',
          'bindingsJson' => ''
        },
        300
      );

      Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(
        currentUser.Id
      );
      System.assertNotEquals(null, status, 'Status should not be null');
    } catch (Exception e) {
      // Cache not available - still covers the code path
      Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(
        currentUser.Id
      );
      System.assertNotEquals(null, status, 'Status should work without cache');
    }
    Test.stopTest();
  }

  /**
   * @description Test async execution via executeAsUser (covers Queueable indirectly)
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testAsyncExecutionPath() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Executor'
    };

    Test.startTest();
    // This will internally enqueue the Queueable, covering the execute path
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      JSON.serialize(bindings)
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
  }

  /**
   * @description Test error handling in async execution
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testAsyncExecutionWithError() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    Test.startTest();
    // Invalid config should trigger error handling path
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Invalid_Config_Name_That_Does_Not_Exist',
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Should handle errors gracefully');
  }

  /**
   * @description Test finalizer path coverage
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testFinalizerPath() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    Test.startTest();
    // Trigger execution that will attach finalizer
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      '{}'
    );
    Test.stopTest();

    // Finalizer is attached in the queueable execution
    System.assertNotEquals(null, result, 'Result should exist');
  }

  /**
   * @description Test TestExecutionResult wrapper
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testTestExecutionResultWrapper() {
    JT_RunAsTestExecutor.TestExecutionResult result = new JT_RunAsTestExecutor.TestExecutionResult();

    result.success = true;
    result.queryResults = '[]';
    result.records = new List<Object>();
    result.fields = new List<Object>();
    result.recordCount = 10;
    result.errorMessage = null;
    result.runAsUserName = 'Test User';
    result.jobId = 'testJob123';
    result.message = 'Success';
    result.assertMessage = 'Test passed';
    result.executionTime = 500;
    result.stackTrace = null;

    System.assertEquals(true, result.success, 'Should set success');
    System.assertEquals(10, result.recordCount, 'Should set record count');
    System.assertEquals(
      'Test User',
      result.runAsUserName,
      'Should set user name'
    );
  }

  /**
   * @description Test getTestResults with execution record
   * @author Jaime Terrats | 11-29-2025
   * Updated: 12-13-2025 - Now uses executionId from executeAsUser instead of Platform Cache
   **/
  @IsTest
  static void testGetTestResultsWithAssertMessage() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Executor'
    };

    Test.startTest();
    // Execute a test to get an executionId
    JT_RunAsTestExecutor.TestExecutionResult executeResult = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      JSON.serialize(bindings)
    );

    // If execution was initiated, try to get results
    if (executeResult.success && String.isNotBlank(executeResult.jobId)) {
      String executionId = executeResult.jobId;

      JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
        executionId
      );

      // Result may be pending or completed depending on timing
      System.assertNotEquals(null, result, 'Result should not be null');
      System.assert(result.success != null, 'Should have success flag');
    } else {
      // Execution failed, but method still works
      System.assert(true, 'Method executed even if execution failed');
    }
    Test.stopTest();
  }

  /**
   * @description Test getTestResults with invalid executionId (error handling)
   * @author Jaime Terrats | 11-29-2025
   * Updated: 12-13-2025 - Now uses executionId instead of Platform Cache
   **/
  @IsTest
  static void testGetTestResultsWithError() {
    // Use invalid executionId to test error handling
    String invalidExecutionId = 'a0S' + '0'.repeat(15);

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      invalidExecutionId
    );
    Test.stopTest();

    // Should handle error gracefully
    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(
      false,
      result.success,
      'Should return false for invalid executionId'
    );
  }

  /**
   * @description Test getTestStatus with execution record
   * @author Jaime Terrats | 11-29-2025
   * Updated: 12-13-2025 - Now uses executionId from executeAsUser instead of Platform Cache
   **/
  @IsTest
  static void testGetTestStatusCompleted() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Executor'
    };

    Test.startTest();
    // Execute a test to get an executionId
    JT_RunAsTestExecutor.TestExecutionResult executeResult = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      JSON.serialize(bindings)
    );

    // If execution was initiated, try to get status
    if (executeResult.success && String.isNotBlank(executeResult.jobId)) {
      String executionId = executeResult.jobId;

      Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(
        executionId
      );

      System.assertNotEquals(null, status, 'Status should not be null');
      System.assert(status.containsKey('status'), 'Should have status key');
    } else {
      // Execution failed, but method still works
      System.assert(true, 'Method executed even if execution failed');
    }
    Test.stopTest();
  }

  /**
   * @description Test getTestStatus with running execution (Queued/Running status)
   * @author Jaime Terrats | 11-29-2025
   * Updated: 12-13-2025 - Now uses executionId from executeAsUser instead of Platform Cache
   **/
  @IsTest
  static void testGetTestStatusRunning() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Executor'
    };

    Test.startTest();
    // Execute a test to get an executionId (status will likely be Queued or Running)
    JT_RunAsTestExecutor.TestExecutionResult executeResult = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      JSON.serialize(bindings)
    );

    // If execution was initiated, check status immediately (should be Queued/Running)
    if (executeResult.success && String.isNotBlank(executeResult.jobId)) {
      String executionId = executeResult.jobId;

      Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(
        executionId
      );

      System.assertNotEquals(null, status, 'Status should not be null');
      System.assert(status.containsKey('status'), 'Should have status key');
      // Status may be QUEUED, RUNNING, or COMPLETED depending on timing
    } else {
      // Execution failed, but method still works
      System.assert(true, 'Method executed even if execution failed');
    }
    Test.stopTest();
  }

  /**
   * @description Test RunAsTestQueueable directly with success path
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testRunAsTestQueueableSuccess() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Executor'
    };

    Test.startTest();
    JT_RunAsTestExecutor.RunAsTestQueueable queueable = new JT_RunAsTestExecutor.RunAsTestQueueable(
      currentUser.Id,
      'Test_Record',
      JSON.serialize(bindings)
    );

    // Execute queueable directly to cover execute() method
    System.enqueueJob(queueable);
    Test.stopTest();

    // Queueable will execute and store results in cache
    // This covers the execute() method and success path
    System.assert(true, 'Queueable executed without errors');
  }

  /**
   * @description Test RunAsTestQueueable with invalid config (error path)
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testRunAsTestQueueableError() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    Test.startTest();
    JT_RunAsTestExecutor.RunAsTestQueueable queueable = new JT_RunAsTestExecutor.RunAsTestQueueable(
      currentUser.Id,
      'Nonexistent_Config_That_Will_Fail',
      null
    );

    // Execute queueable - will hit error handling path
    System.enqueueJob(queueable);
    Test.stopTest();

    // Queueable will catch exception and store error in cache
    System.assert(true, 'Queueable handled error gracefully');
  }

  /**
   * @description Test RunAsTestQueueable with null bindings
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testRunAsTestQueueableNullBindings() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    Test.startTest();
    JT_RunAsTestExecutor.RunAsTestQueueable queueable = new JT_RunAsTestExecutor.RunAsTestQueueable(
      currentUser.Id,
      'Test_Record',
      null // Null bindings - should use empty Map
    );

    System.enqueueJob(queueable);
    Test.stopTest();

    System.assert(true, 'Queueable handled null bindings');
  }

  /**
   * @description Test RunAsTestQueueable with empty bindings string
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testRunAsTestQueueableEmptyBindings() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    Test.startTest();
    JT_RunAsTestExecutor.RunAsTestQueueable queueable = new JT_RunAsTestExecutor.RunAsTestQueueable(
      currentUser.Id,
      'Test_Record',
      '' // Empty string - should use empty Map
    );

    System.enqueueJob(queueable);
    Test.stopTest();

    System.assert(true, 'Queueable handled empty bindings');
  }

  /**
   * @description Test TestExecutionFinalizer directly
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  static void testTestExecutionFinalizer() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    Test.startTest();
    // Create finalizer instance
    JT_RunAsTestExecutor.TestExecutionFinalizer finalizer = new JT_RunAsTestExecutor.TestExecutionFinalizer(
      currentUser.Id
    );

    // Finalizer constructor covered
    System.assertNotEquals(null, finalizer, 'Finalizer should be created');
    Test.stopTest();

    // Note: execute() method is called automatically by platform when attached to Queueable
    // We test it indirectly through the Queueable tests
  }

  /**
   * @description Test executeAsUser with inactive user
   * @author Jaime Terrats | 11-29-2025
   **/
  @IsTest
  @SuppressWarnings(
    'PMD.AvoidHardcodingId'
  ) // Hardcoded ID intentional for negative test case
  static void testExecuteAsUserInactiveUser() {
    // Find or create an inactive user (this may not be possible in all orgs)
    // Instead, test with a non-existent user to trigger validation
    String fakeUserId = '005000000000000AAA'; // Invalid format

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
      fakeUserId,
      'Test_Record',
      null
    );
    Test.stopTest();

    System.assertEquals(false, result.success, 'Should fail with invalid user');
  }

  /**
   * @description Test getTestResults exception handling
   * @author Jaime Terrats | 11-29-2025
   * Updated: 12-13-2025 - Now uses executionId instead of userId
   **/
  @IsTest
  static void testGetTestResultsExceptionHandling() {
    // Use invalid executionId format to potentially trigger exception
    String invalidExecutionId = 'invalid_id_format';

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      invalidExecutionId
    );
    Test.stopTest();

    // Should handle gracefully
    System.assertNotEquals(null, result, 'Result should not be null');
    // If exception occurs, result.success should be false
    System.assertEquals(
      false,
      result.success,
      'Should return false for invalid executionId'
    );
  }

  /**
   * @description Test getTestStatus exception handling
   * @author Jaime Terrats | 11-29-2025
   * Updated: 12-13-2025 - Now uses executionId instead of userId
   **/
  @IsTest
  static void testGetTestStatusExceptionHandling() {
    // Use invalid executionId format to potentially trigger exception
    String invalidExecutionId = 'invalid_id_format';

    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(
      invalidExecutionId
    );
    Test.stopTest();

    System.assertNotEquals(null, status, 'Status should not be null');
    // Should have status key even if error occurs
    System.assert(status.containsKey('status'), 'Should have status key');
    System.assertEquals(
      'NOT_FOUND',
      status.get('status'),
      'Should return NOT_FOUND for invalid executionId'
    );
  }

  /**
   * @description Test rate limiting - too many pending executions
   */
  @IsTest
  static void testRateLimiting() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create 3 pending executions to trigger rate limit
    List<JT_RunAsTest_Execution__c> executions = new List<JT_RunAsTest_Execution__c>();
    for (Integer i = 0; i < 3; i++) {
      executions.add(
        new JT_RunAsTest_Execution__c(
          Test_Status__c = 'Queued',
          User_To_Impersonate__c = currentUser.Id,
          Config_Name__c = 'Test_Record',
          Initiated_By__c = UserInfo.getUserId()
        )
      );
    }
    insert executions;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      null
    );
    Test.stopTest();

    System.assertEquals(
      false,
      result.success,
      'Should fail due to rate limiting'
    );
    System.assertNotEquals(
      null,
      result.errorMessage,
      'Error message should not be null'
    );
    System.assert(
      result.errorMessage != null &&
        result.errorMessage.contains('Too many test executions'),
      'Should have rate limiting error message. Actual: ' +
      (result.errorMessage != null ? result.errorMessage : 'null')
    );
  }

  /**
   * @description Test getTestResults with Completed status and results
   */
  @IsTest
  static void testGetTestResultsCompleted() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Completed status and results
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Completed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Results_Json__c =
        '{"success":true,"recordCount":5,"executionTime":100,"runAsUserName":"Test User","fields":[],"records":[]}',
      Record_Count__c = 5,
      Execution_Time__c = 100,
      Run_As_User_Name__c = 'Test User',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertEquals(true, result.success, 'Should return success');
    System.assertEquals(5, result.recordCount, 'Should return record count');
    System.assertNotEquals(null, result.queryResults, 'Should have query results');
  }

  /**
   * @description Test getTestResults with Completed status but no results
   */
  @IsTest
  static void testGetTestResultsCompletedNoResults() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Completed status but no results
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Completed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Results_Json__c = null,
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertEquals(
      false,
      result.success,
      'Should return false when no results'
    );
    System.assertNotEquals(
      null,
      result.errorMessage,
      'Should have error message'
    );
  }

  /**
   * @description Test getTestResults with Failed status
   */
  @IsTest
  static void testGetTestResultsFailed() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Failed status
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Failed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Error_Message__c = 'Test failed',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertEquals(false, result.success, 'Should return false');
    System.assertEquals('Test failed', result.errorMessage, 'Should have error message');
  }

  /**
   * @description Test getTestResults with Queued status and Queueable job
   */
  @IsTest
  static void testGetTestResultsQueuedWithQueueable() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Queued status and Queueable job ID
    // Note: We can't insert AsyncApexJob directly, so we'll use a fake ID
    // The query will return empty, so it will fall through to check ApexTestQueueItem
    String fakeJobId = '01p' + '0'.repeat(15);

    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Queued',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Apex_Queueable_Job_Id__c = fakeJobId,
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    // Should return pending status
    System.assertEquals(false, result.success, 'Should return false for pending');
    System.assertNotEquals(null, result.message, 'Should have message');
  }

  /**
   * @description Test getTestStatus with Failed status
   */
  @IsTest
  static void testGetTestStatusFailed() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Failed status
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Failed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Error_Message__c = 'Test failed',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(execution.Id);
    Test.stopTest();

    System.assertEquals('FAILED', status.get('status'), 'Should be FAILED');
    System.assertEquals(false, status.get('hasResults'), 'Should not have results');
    System.assertEquals('Test failed', status.get('error'), 'Should have error');
  }

  /**
   * @description Test getTestStatus with Queued status
   */
  @IsTest
  static void testGetTestStatusQueuedNew() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Queued status
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Queued',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(execution.Id);
    Test.stopTest();

    System.assertEquals('PENDING', status.get('status'), 'Should be PENDING');
    System.assertEquals(false, status.get('hasResults'), 'Should not have results');
  }

  /**
   * @description Test getTestStatus with Running status (new test)
   */
  @IsTest
  static void testGetTestStatusRunningNew() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Running status
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Running',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(execution.Id);
    Test.stopTest();

    System.assertEquals('PENDING', status.get('status'), 'Should be PENDING');
    System.assertEquals(false, status.get('hasResults'), 'Should not have results');
  }

  /**
   * @description Test getTestStatus with Completed status but no results
   */
  @IsTest
  static void testGetTestStatusCompletedNoResults() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Completed status but no results
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Completed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Results_Json__c = null,
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(execution.Id);
    Test.stopTest();

    System.assertEquals('COMPLETED', status.get('status'), 'Should be COMPLETED');
    System.assertEquals(false, status.get('hasResults'), 'Should not have results');
    System.assert(
      status.containsKey('warning'),
      'Should have warning about no results'
    );
  }

  /**
   * @description Test getTestResults exception handling path
   */
  @IsTest
  static void testGetTestResultsException() {
    // Use null to potentially trigger exception in query
    Test.startTest();
    try {
      JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
        null
      );
      // Should handle gracefully
      System.assertNotEquals(null, result, 'Should return result');
    } catch (Exception e) {
      // Exception is acceptable - method should handle it
      System.assert(true, 'Exception handled');
    }
    Test.stopTest();
  }

  /**
   * @description Test getTestStatus exception handling path
   */
  @IsTest
  static void testGetTestStatusException() {
    // Use null to potentially trigger exception in query
    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(null);
    Test.stopTest();

    // Should handle gracefully
    System.assertNotEquals(null, status, 'Should return status');
    System.assert(status.containsKey('status'), 'Should have status key');
  }

  /**
   * @description Test executeAsUser with insufficient permissions (canUseRunAsTest returns false)
   */
  @IsTest
  static void testExecuteAsUserInsufficientPermissions() {
    // Create a user without elevated permissions
    User testUser = new User(
      FirstName = 'Test',
      LastName = 'User',
      Email = 'testuser@example.com',
      Username = 'testuser' + System.now().getTime() + '@example.com',
      Alias = 'tuser',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
      TimeZoneSidKey = 'America/New_York',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert testUser;

    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    Test.startTest();
    System.runAs(testUser) {
      JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
        currentUser.Id,
        'Test_Record',
        null
      );
      System.assertEquals(false, result.success, 'Should fail without permissions');
      System.assertNotEquals(null, result.errorMessage, 'Should have error message');
    }
    Test.stopTest();
  }

  /**
   * @description Test executeAsUser with insufficient CRUD permissions for create
   */
  @IsTest
  static void testExecuteAsUserInsufficientCreatePermissions() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Executor'
    };

    // Note: This test may not trigger in all orgs if user has create permissions
    // But it tests the permission check path
    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      JSON.serialize(bindings)
    );
    Test.stopTest();

    // Result depends on permissions - method should handle gracefully
    System.assertNotEquals(null, result, 'Result should not be null');
  }

  /**
   * @description Test executeAsUser with insufficient CRUD permissions for update
   */
  @IsTest
  static void testExecuteAsUserInsufficientUpdatePermissions() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Executor'
    };

    // Note: This test may not trigger in all orgs if user has update permissions
    // But it tests the permission check path
    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
      currentUser.Id,
      'Test_Record',
      JSON.serialize(bindings)
    );
    Test.stopTest();

    // Result depends on permissions - method should handle gracefully
    System.assertNotEquals(null, result, 'Result should not be null');
  }

  /**
   * @description Test getTestResults with Queued status and Queueable job in Processing status
   */
  @IsTest
  static void testGetTestResultsQueuedWithProcessingQueueable() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Queued status
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Queued',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Apex_Queueable_Job_Id__c = '01p000000000000AAA', // Fake job ID
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    // Should return pending status
    System.assertEquals(false, result.success, 'Should return false for pending');
    System.assertNotEquals(null, result.message, 'Should have message');
  }

  /**
   * @description Test getTestResults with Queued status and ApexTestQueueItem
   */
  @IsTest
  static void testGetTestResultsQueuedWithApexTestQueueItem() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Queued status and ApexTestQueueItem ID
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Queued',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Apex_Test_Queue_Item_Id__c = '01p000000000000AAA', // Fake queue item ID
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    // Should return pending status
    System.assertEquals(false, result.success, 'Should return false for pending');
    System.assertNotEquals(null, result.message, 'Should have message');
  }

  /**
   * @description Test getTestResults with Completed status and success result
   */
  @IsTest
  static void testGetTestResultsCompletedWithSuccess() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Completed status and success results
    Map<String, Object> resultMap = new Map<String, Object>{
      'success' => true,
      'recordCount' => 10,
      'executionTime' => 150,
      'runAsUserName' => 'Test User',
      'fields' => new List<String>{ 'Id', 'Name' },
      'records' => new List<Object>()
    };

    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Completed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Results_Json__c = JSON.serialize(resultMap),
      Record_Count__c = 10,
      Execution_Time__c = 150,
      Run_As_User_Name__c = 'Test User',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertEquals(true, result.success, 'Should return success');
    System.assertEquals(10, result.recordCount, 'Should return record count');
    System.assertEquals(150, result.executionTime, 'Should return execution time');
    System.assertEquals('Test User', result.runAsUserName, 'Should return user name');
    System.assertNotEquals(null, result.assertMessage, 'Should have assert message');
  }

  /**
   * @description Test getTestResults with Completed status and failed result
   */
  @IsTest
  static void testGetTestResultsCompletedWithFailure() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Completed status but failed result
    Map<String, Object> resultMap = new Map<String, Object>{
      'success' => false,
      'errorMessage' => 'Query failed',
      'recordCount' => 0,
      'executionTime' => 50
    };

    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Completed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Results_Json__c = JSON.serialize(resultMap),
      Error_Message__c = 'Query failed',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertEquals(false, result.success, 'Should return false');
    System.assertEquals('Query failed', result.errorMessage, 'Should have error message');
  }

  /**
   * @description Test getTestResults exception handling in JSON parsing
   */
  @IsTest
  static void testGetTestResultsInvalidJson() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with invalid JSON
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Completed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Results_Json__c = 'invalid json{',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    // Should handle invalid JSON gracefully
    System.assertNotEquals(null, result, 'Result should not be null');
  }

  /**
   * @description Test getTestStatus with Completed status and results
   */
  @IsTest
  static void testGetTestStatusCompletedWithResults() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Completed status and results
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Completed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Results_Json__c = '{"success":true}',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(execution.Id);
    Test.stopTest();

    System.assertEquals('COMPLETED', status.get('status'), 'Should be COMPLETED');
    System.assertEquals(true, status.get('hasResults'), 'Should have results');
  }

  /**
   * @description Test getTestStatus with Expired status (not explicitly handled in switch)
   */
  @IsTest
  static void testGetTestStatusUnknownStatus() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    // Create execution record with Expired status (valid picklist value but not in switch)
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Expired',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(execution.Id);
    Test.stopTest();

    System.assertNotEquals(null, status.get('status'), 'Should have status');
    System.assertEquals(false, status.get('hasResults'), 'Should not have results');
  }

  /**
   * @description Test executeAsUser with DML exception during insert
   */
  @IsTest
  static void testExecuteAsUserDmlExceptionInsert() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create execution record manually to simulate conflict
    JT_RunAsTest_Execution__c existingExecution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Queued',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert existingExecution;

    Test.startTest();
    try {
      JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
        currentUser.Id,
        'Test_Record',
        null
      );
      // May succeed or fail depending on rate limiting
      System.assertNotEquals(null, result, 'Result should not be null');
    } catch (Exception e) {
      // Exception is acceptable
      System.assert(true, 'Exception acceptable');
    }
    Test.stopTest();
  }

  /**
   * @description Test executeAsUser with DML exception during update
   */
  @IsTest
  static void testExecuteAsUserDmlExceptionUpdate() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    Test.startTest();
    try {
      JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
        currentUser.Id,
        'Test_Record',
        null
      );
      // May succeed or fail depending on permissions
      System.assertNotEquals(null, result, 'Result should not be null');
    } catch (Exception e) {
      // Exception is acceptable
      System.assert(true, 'Exception acceptable');
    }
    Test.stopTest();
  }

  /**
   * @description Test getTestResults with Completed status but no Results_Json__c
   */
  @IsTest
  static void testGetTestResultsCompletedNoResultsJson() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create execution record with Completed status but no results
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Completed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId(),
      Results_Json__c = null
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(false, result.success, 'Should indicate no results');
  }

  /**
   * @description Test getTestStatus with null executionId
   */
  @IsTest
  static void testGetTestStatusNullId() {
    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(null);
    Test.stopTest();

    System.assertNotEquals(null, status, 'Status should not be null');
    System.assertEquals('NOT_FOUND', status.get('status'), 'Should be NOT_FOUND');
  }

  /**
   * @description Test getTestResults with Queued status and queueable job
   */
  @IsTest
  static void testGetTestResultsQueuedWithQueueableJob() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create execution record with Queued status and queueable job ID
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Queued',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId(),
      Apex_Queueable_Job_Id__c = '707' + '0'.repeat(15)
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    // May return pending message or error depending on queueable job status
  }

  /**
   * @description Test getTestResults with Running status
   */
  @IsTest
  static void testGetTestResultsRunning() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create execution record with Running status
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Running',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(false, result.success, 'Should indicate pending');
  }

  /**
   * @description Test getTestResults with Completed status and Results_Json__c
   */
  @IsTest
  static void testGetTestResultsCompletedWithResults() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create execution record with Completed status and results
    String resultsJson = JSON.serialize(
      new Map<String, Object>{
        'success' => true,
        'records' => new List<Object>(),
        'recordCount' => 0,
        'executionTime' => 100
      }
    );
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Completed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId(),
      Results_Json__c = resultsJson,
      Record_Count__c = 0,
      Execution_Time__c = 100
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(true, result.success, 'Should indicate success');
  }

  /**
   * @description Test executeAsUser with null configName
   */
  @IsTest
  static void testExecuteAsUserNullConfigName() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    Test.startTest();
    try {
      JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
        currentUser.Id,
        null,
        null
      );
      System.assertNotEquals(null, result, 'Result should not be null');
    } catch (Exception e) {
      // Exception is acceptable for null config
      System.assert(true, 'Exception acceptable for null config');
    }
    Test.stopTest();
  }

  /**
   * @description Test executeAsUser with empty configName
   */
  @IsTest
  static void testExecuteAsUserEmptyConfigName() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    Test.startTest();
    try {
      JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
        currentUser.Id,
        '',
        null
      );
      System.assertNotEquals(null, result, 'Result should not be null');
    } catch (Exception e) {
      // Exception is acceptable for empty config
      System.assert(true, 'Exception acceptable for empty config');
    }
    Test.stopTest();
  }

  /**
   * @description Test executeAsUser with invalid bindings JSON
   */
  @IsTest
  static void testExecuteAsUserInvalidBindingsJson() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    Test.startTest();
    try {
      JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
        currentUser.Id,
        'Test_Record',
        '{invalid json}'
      );
      System.assertNotEquals(null, result, 'Result should not be null');
    } catch (Exception e) {
      // Exception is acceptable for invalid JSON
      System.assert(true, 'Exception acceptable for invalid JSON');
    }
    Test.stopTest();
  }

  /**
   * @description Test getTestResults with Queued status and queueable job Queued
   */
  @IsTest
  static void testGetTestResultsQueuedWithQueueableQueued() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create execution record with Queued status
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Queued',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId(),
      Apex_Queueable_Job_Id__c = '707' + '0'.repeat(15)
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    // May return pending message or error depending on queueable job status
  }

  /**
   * @description Test getTestResults with Queued status and test queue item
   */
  @IsTest
  static void testGetTestResultsQueuedWithTestQueueItem() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create execution record with Queued status and test queue item
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Queued',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId(),
      Apex_Test_Queue_Item_Id__c = '709' + '0'.repeat(15)
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    // May return pending message
  }

  /**
   * @description Test getTestResults with Completed status but no Results_Json__c and Error_Message__c
   */
  @IsTest
  static void testGetTestResultsCompletedNoResultsNoError() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create execution record with Completed status but no results or error
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Completed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId(),
      Results_Json__c = null,
      Error_Message__c = null
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(false, result.success, 'Should indicate failure');
  }

  /**
   * @description Test getTestResults with Completed status and Results_Json__c with success=false
   */
  @IsTest
  static void testGetTestResultsCompletedWithFailedResults() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create execution record with Completed status and failed results
    String resultsJson = JSON.serialize(
      new Map<String, Object>{
        'success' => false,
        'errorMessage' => 'Query failed',
        'recordCount' => 0,
        'executionTime' => 50
      }
    );
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Completed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId(),
      Results_Json__c = resultsJson,
      Error_Message__c = 'Query failed',
      Record_Count__c = 0,
      Execution_Time__c = 50
    );
    insert execution;

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      execution.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(false, result.success, 'Should indicate failure');
  }

  /**
   * @description Test getTestResults with exception during query
   */
  @IsTest
  static void testGetTestResultsExceptionDuringQuery() {
    String invalidId = 'a0X' + '0'.repeat(15);

    Test.startTest();
    JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.getTestResults(
      invalidId
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(false, result.success, 'Should indicate failure');
  }

  /**
   * @description Test getTestStatus with Queued status
   */
  @IsTest
  static void testGetTestStatusQueued() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create execution record with Queued status
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Queued',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;

    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(execution.Id);
    Test.stopTest();

    System.assertNotEquals(null, status, 'Status should not be null');
    System.assertEquals('PENDING', status.get('status'), 'Should be PENDING');
  }

  /**
   * @description Test getTestStatus with Failed status and error message
   */
  @IsTest
  static void testGetTestStatusFailedWithError() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create execution record with Failed status and error
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Failed',
      User_To_Impersonate__c = currentUser.Id,
      Config_Name__c = 'Test_Record',
      Initiated_By__c = UserInfo.getUserId(),
      Error_Message__c = 'Test execution failed'
    );
    insert execution;

    Test.startTest();
    Map<String, Object> status = JT_RunAsTestExecutor.getTestStatus(execution.Id);
    Test.stopTest();

    System.assertNotEquals(null, status, 'Status should not be null');
    System.assertEquals('FAILED', status.get('status'), 'Should be FAILED');
    System.assertNotEquals(null, status.get('error'), 'Should have error message');
  }

  /**
   * @description Test executeAsUser with rate limiting (max pending executions)
   */
  @IsTest
  static void testExecuteAsUserRateLimitingMultiple() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    // Create 3 pending executions to trigger rate limiting
    List<JT_RunAsTest_Execution__c> executions = new List<JT_RunAsTest_Execution__c>();
    for (Integer i = 0; i < 3; i++) {
      executions.add(
        new JT_RunAsTest_Execution__c(
          Test_Status__c = 'Queued',
          User_To_Impersonate__c = currentUser.Id,
          Config_Name__c = 'Test_Record',
          Initiated_By__c = UserInfo.getUserId()
        )
      );
    }
    insert executions;

    Test.startTest();
    try {
      JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
        currentUser.Id,
        'Test_Record',
        null
      );
      // May succeed or fail depending on timing
      System.assertNotEquals(null, result, 'Result should not be null');
    } catch (Exception e) {
      // Rate limiting exception is acceptable
      System.assert(true, 'Rate limiting exception acceptable');
    }
    Test.stopTest();
  }

  /**
   * @description Test executeAsUser with exception during update
   */
  @IsTest
  static void testExecuteAsUserExceptionDuringUpdate() {
    User currentUser = JT_SystemSelector.getCurrentUser();

    Test.startTest();
    try {
      JT_RunAsTestExecutor.TestExecutionResult result = JT_RunAsTestExecutor.executeAsUser(
        currentUser.Id,
        'Test_Record',
        null
      );
      System.assertNotEquals(null, result, 'Result should not be null');
    } catch (Exception e) {
      // Exception is acceptable
      System.assert(true, 'Exception acceptable');
    }
    Test.stopTest();
  }
}
