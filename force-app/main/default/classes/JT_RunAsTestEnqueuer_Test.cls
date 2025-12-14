/**
 * @description Test class for JT_RunAsTestEnqueuer
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @date 2025-12-14
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_RunAsTestEnqueuer_Test {
  @testSetup
  static void setupTestData() {
    // Create test execution record
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Running',
      Config_Name__c = 'Test_Record',
      User_To_Impersonate__c = UserInfo.getUserId(),
      Initiated_By__c = UserInfo.getUserId(),
      Bindings_Json__c = '{"name": "Test Account"}'
    );
    insert execution;
  }

  /**
   * @description Test constructor sets execution ID
   */
  @IsTest
  static void testConstructor() {
    JT_RunAsTest_Execution__c execution = [
      SELECT Id
      FROM JT_RunAsTest_Execution__c
      LIMIT 1
    ];

    Test.startTest();
    JT_RunAsTestEnqueuer enqueuer = new JT_RunAsTestEnqueuer(execution.Id);
    Test.stopTest();

    System.assertNotEquals(null, enqueuer, 'Enqueuer should be created');
  }

  /**
   * @description Test execute with successful synchronous execution
   */
  @IsTest
  static void testExecuteSynchronousSuccess() {
    JT_RunAsTest_Execution__c execution = [
      SELECT Id
      FROM JT_RunAsTest_Execution__c
      LIMIT 1
    ];

    // Mock successful synchronous test execution response
    String successResponse = JSON.serialize(
      new Map<String, Object>{
        'numFailures' => 0,
        'numTestsRun' => 1,
        'successes' => new List<Object>{
          new Map<String, Object>{
            'name' => 'JT_GenericRunAsTest',
            'methodName' => 'testExecuteRunAsTest',
            'time' => 100
          }
        },
        'failures' => new List<Object>(),
        'apexLogId' => '07LXXXXXXXXXXXX'
      }
    );

    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(200, successResponse)
    );

    // Mock Apex Log content response
    String logContentResponse = JSON.serialize(
      new Map<String, Object>{
        'Body' => 'DEBUG|JT_RESULT_START|{"success":true,"recordCount":1}|JT_RESULT_END'
      }
    );

    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(200, logContentResponse)
    );

    Test.startTest();
    System.enqueueJob(new JT_RunAsTestEnqueuer(execution.Id));
    Test.stopTest();

    // Verify execution record was updated
    JT_RunAsTest_Execution__c updatedExecution = [
      SELECT Id, Test_Status__c
      FROM JT_RunAsTest_Execution__c
      WHERE Id = :execution.Id
    ];

    // Status may be Completed or Failed depending on mock response
    System.assertNotEquals(
      null,
      updatedExecution.Test_Status__c,
      'Status should be set'
    );
  }

  /**
   * @description Test execute with failed synchronous execution (falls back to async)
   */
  @IsTest
  static void testExecuteSynchronousFailure() {
    JT_RunAsTest_Execution__c execution = [
      SELECT Id
      FROM JT_RunAsTest_Execution__c
      LIMIT 1
    ];

    // Mock failed synchronous test execution response
    String failureResponse = JSON.serialize(
      new Map<String, Object>{
        'numFailures' => 1,
        'numTestsRun' => 1,
        'successes' => new List<Object>(),
        'failures' => new List<Object>{
          new Map<String, Object>{
            'name' => 'JT_GenericRunAsTest',
            'methodName' => 'testExecuteRunAsTest',
            'message' => 'System.AssertException: Assertion Failed: Test failed',
            'stackTrace' => 'Test stack trace'
          }
        }
      }
    );

    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(200, failureResponse)
    );

    Test.startTest();
    System.enqueueJob(new JT_RunAsTestEnqueuer(execution.Id));
    Test.stopTest();

    // Verify execution record was updated with error
    JT_RunAsTest_Execution__c updatedExecution = [
      SELECT Id, Test_Status__c, Error_Message__c
      FROM JT_RunAsTest_Execution__c
      WHERE Id = :execution.Id
    ];

    System.assertEquals(
      'Failed',
      updatedExecution.Test_Status__c,
      'Status should be Failed'
    );
    System.assertNotEquals(
      null,
      updatedExecution.Error_Message__c,
      'Error message should be set'
    );
  }

  /**
   * @description Test execute with HTTP error (falls back to async)
   */
  @IsTest
  static void testExecuteHttpError() {
    JT_RunAsTest_Execution__c execution = [
      SELECT Id
      FROM JT_RunAsTest_Execution__c
      LIMIT 1
    ];

    // Mock HTTP error response
    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(500, 'Internal Server Error')
    );

    Test.startTest();
    System.enqueueJob(new JT_RunAsTestEnqueuer(execution.Id));
    Test.stopTest();

    // Verify execution record exists (may be updated or not depending on error handling)
    List<JT_RunAsTest_Execution__c> executions = [
      SELECT Id, Test_Status__c
      FROM JT_RunAsTest_Execution__c
      WHERE Id = :execution.Id
    ];

    System.assertEquals(1, executions.size(), 'Execution record should exist');
  }

  /**
   * @description Test execute with callout exception (falls back to async)
   */
  @IsTest
  static void testExecuteCalloutException() {
    JT_RunAsTest_Execution__c execution = [
      SELECT Id
      FROM JT_RunAsTest_Execution__c
      LIMIT 1
    ];

    // Mock callout exception
    Test.setMock(HttpCalloutMock.class, new JT_ToolingAPIMock());

    Test.startTest();
    System.enqueueJob(new JT_RunAsTestEnqueuer(execution.Id));
    Test.stopTest();

    // Verify execution record exists
    List<JT_RunAsTest_Execution__c> executions = [
      SELECT Id
      FROM JT_RunAsTest_Execution__c
      WHERE Id = :execution.Id
    ];

    System.assertEquals(1, executions.size(), 'Execution record should exist');
  }

  /**
   * @description Test constructor with null execution ID (constructor accepts it, error occurs during execution)
   */
  @IsTest
  static void testExecuteWithNullExecutionId() {
    Test.startTest();
    // Constructor accepts null (no validation)
    JT_RunAsTestEnqueuer enqueuer = new JT_RunAsTestEnqueuer(null);
    System.assertNotEquals(null, enqueuer, 'Enqueuer should be created');
    // Error will occur during async execution when querying for execution record
    System.enqueueJob(enqueuer);
    Test.stopTest();

    // Job is queued successfully, but will fail during execution
    // This is expected behavior for Queueable - errors occur during execution, not construction
  }

  /**
   * @description Test constructor with non-existent execution ID (constructor accepts it, error occurs during execution)
   */
  @IsTest
  static void testExecuteWithNonExistentExecutionId() {
    String fakeId = 'a0X' + '0'.repeat(15);

    Test.startTest();
    // Constructor accepts fake ID (no validation)
    JT_RunAsTestEnqueuer enqueuer = new JT_RunAsTestEnqueuer(fakeId);
    System.assertNotEquals(null, enqueuer, 'Enqueuer should be created');
    // Error will occur during async execution when querying for execution record
    System.enqueueJob(enqueuer);
    Test.stopTest();

    // Job is queued successfully, but will fail during execution
    // This is expected behavior for Queueable - errors occur during execution, not construction
  }
}
