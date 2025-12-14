/**
 * @description Test class for JT_ExecutionStateManager
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @date 2025-12-14
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_ExecutionStateManager_Test {
  @testSetup
  static void setupTestData() {
    // Create test execution record
    JT_RunAsTest_Execution__c execution = new JT_RunAsTest_Execution__c(
      Test_Status__c = JT_ExecutionStateManager.STATE_QUEUED,
      Config_Name__c = 'Test_Record',
      User_To_Impersonate__c = UserInfo.getUserId(),
      Initiated_By__c = UserInfo.getUserId()
    );
    insert execution;
  }

  /**
   * @description Test state constants are accessible
   */
  @IsTest
  static void testStateConstants() {
    Test.startTest();
    String queued = JT_ExecutionStateManager.STATE_QUEUED;
    String running = JT_ExecutionStateManager.STATE_RUNNING;
    String completed = JT_ExecutionStateManager.STATE_COMPLETED;
    String failed = JT_ExecutionStateManager.STATE_FAILED;
    String expired = JT_ExecutionStateManager.STATE_EXPIRED;
    Test.stopTest();

    System.assertEquals('Queued', queued, 'Queued state should match');
    System.assertEquals('Running', running, 'Running state should match');
    System.assertEquals('Completed', completed, 'Completed state should match');
    System.assertEquals('Failed', failed, 'Failed state should match');
    System.assertEquals('Expired', expired, 'Expired state should match');
  }

  /**
   * @description Test isValidTransition with valid transitions from Queued
   */
  @IsTest
  static void testIsValidTransitionFromQueued() {
    Test.startTest();
    Boolean toRunning = JT_ExecutionStateManager.isValidTransition(
      JT_ExecutionStateManager.STATE_QUEUED,
      JT_ExecutionStateManager.STATE_RUNNING
    );
    Boolean toFailed = JT_ExecutionStateManager.isValidTransition(
      JT_ExecutionStateManager.STATE_QUEUED,
      JT_ExecutionStateManager.STATE_FAILED
    );
    Boolean toExpired = JT_ExecutionStateManager.isValidTransition(
      JT_ExecutionStateManager.STATE_QUEUED,
      JT_ExecutionStateManager.STATE_EXPIRED
    );
    Boolean toCompleted = JT_ExecutionStateManager.isValidTransition(
      JT_ExecutionStateManager.STATE_QUEUED,
      JT_ExecutionStateManager.STATE_COMPLETED
    );
    Test.stopTest();

    System.assertEquals(true, toRunning, 'Queued -> Running should be valid');
    System.assertEquals(true, toFailed, 'Queued -> Failed should be valid');
    System.assertEquals(true, toExpired, 'Queued -> Expired should be valid');
    System.assertEquals(
      false,
      toCompleted,
      'Queued -> Completed should be invalid'
    );
  }

  /**
   * @description Test isValidTransition with valid transitions from Running
   */
  @IsTest
  static void testIsValidTransitionFromRunning() {
    Test.startTest();
    Boolean toCompleted = JT_ExecutionStateManager.isValidTransition(
      JT_ExecutionStateManager.STATE_RUNNING,
      JT_ExecutionStateManager.STATE_COMPLETED
    );
    Boolean toFailed = JT_ExecutionStateManager.isValidTransition(
      JT_ExecutionStateManager.STATE_RUNNING,
      JT_ExecutionStateManager.STATE_FAILED
    );
    Boolean toExpired = JT_ExecutionStateManager.isValidTransition(
      JT_ExecutionStateManager.STATE_RUNNING,
      JT_ExecutionStateManager.STATE_EXPIRED
    );
    Boolean toQueued = JT_ExecutionStateManager.isValidTransition(
      JT_ExecutionStateManager.STATE_RUNNING,
      JT_ExecutionStateManager.STATE_QUEUED
    );
    Test.stopTest();

    System.assertEquals(
      true,
      toCompleted,
      'Running -> Completed should be valid'
    );
    System.assertEquals(true, toFailed, 'Running -> Failed should be valid');
    System.assertEquals(true, toExpired, 'Running -> Expired should be valid');
    System.assertEquals(false, toQueued, 'Running -> Queued should be invalid');
  }

  /**
   * @description Test isValidTransition with final states (no transitions allowed)
   */
  @IsTest
  static void testIsValidTransitionFromFinalStates() {
    Test.startTest();
    Boolean fromCompleted = JT_ExecutionStateManager.isValidTransition(
      JT_ExecutionStateManager.STATE_COMPLETED,
      JT_ExecutionStateManager.STATE_RUNNING
    );
    Boolean fromFailed = JT_ExecutionStateManager.isValidTransition(
      JT_ExecutionStateManager.STATE_FAILED,
      JT_ExecutionStateManager.STATE_QUEUED
    );
    Boolean fromExpired = JT_ExecutionStateManager.isValidTransition(
      JT_ExecutionStateManager.STATE_EXPIRED,
      JT_ExecutionStateManager.STATE_RUNNING
    );
    Test.stopTest();

    System.assertEquals(
      false,
      fromCompleted,
      'Completed should not allow transitions'
    );
    System.assertEquals(
      false,
      fromFailed,
      'Failed should not allow transitions'
    );
    System.assertEquals(
      false,
      fromExpired,
      'Expired should not allow transitions'
    );
  }

  /**
   * @description Test isValidTransition with invalid inputs
   */
  @IsTest
  static void testIsValidTransitionWithInvalidInputs() {
    Test.startTest();
    Boolean nullFrom = JT_ExecutionStateManager.isValidTransition(
      null,
      'Running'
    );
    Boolean nullTo = JT_ExecutionStateManager.isValidTransition('Queued', null);
    Boolean blankFrom = JT_ExecutionStateManager.isValidTransition(
      '',
      'Running'
    );
    Boolean blankTo = JT_ExecutionStateManager.isValidTransition('Queued', '');
    Boolean unknownState = JT_ExecutionStateManager.isValidTransition(
      'Unknown',
      'Running'
    );
    Test.stopTest();

    System.assertEquals(false, nullFrom, 'Null fromState should return false');
    System.assertEquals(false, nullTo, 'Null toState should return false');
    System.assertEquals(
      false,
      blankFrom,
      'Blank fromState should return false'
    );
    System.assertEquals(false, blankTo, 'Blank toState should return false');
    System.assertEquals(
      false,
      unknownState,
      'Unknown state should return false'
    );
  }

  /**
   * @description Test transition with valid transition
   */
  @IsTest
  static void testTransitionValid() {
    JT_RunAsTest_Execution__c execution = [
      SELECT Id, Test_Status__c
      FROM JT_RunAsTest_Execution__c
      LIMIT 1
    ];

    Test.startTest();
    JT_ExecutionStateManager.transition(
      execution,
      JT_ExecutionStateManager.STATE_RUNNING
    );
    Test.stopTest();

    System.assertEquals(
      JT_ExecutionStateManager.STATE_RUNNING,
      execution.Test_Status__c,
      'Status should be updated to Running'
    );
  }

  /**
   * @description Test transition with invalid transition (should throw exception)
   */
  @IsTest
  static void testTransitionInvalid() {
    JT_RunAsTest_Execution__c execution = [
      SELECT Id, Test_Status__c
      FROM JT_RunAsTest_Execution__c
      LIMIT 1
    ];

    Test.startTest();
    try {
      JT_ExecutionStateManager.transition(
        execution,
        JT_ExecutionStateManager.STATE_COMPLETED
      );
      System.assert(false, 'Should have thrown StateTransitionException');
    } catch (JT_ExecutionStateManager.StateTransitionException e) {
      // Expected
      System.assert(
        e.getMessage().contains('Queued'),
        'Exception message should mention current state'
      );
      System.assert(
        e.getMessage().contains('Completed'),
        'Exception message should mention target state'
      );
    }
    Test.stopTest();

    // Status should remain unchanged
    System.assertEquals(
      JT_ExecutionStateManager.STATE_QUEUED,
      execution.Test_Status__c,
      'Status should remain Queued after invalid transition'
    );
  }

  /**
   * @description Test transition through multiple valid states
   */
  @IsTest
  static void testTransitionMultipleStates() {
    JT_RunAsTest_Execution__c execution = [
      SELECT Id, Test_Status__c
      FROM JT_RunAsTest_Execution__c
      LIMIT 1
    ];

    Test.startTest();
    // Queued -> Running
    JT_ExecutionStateManager.transition(
      execution,
      JT_ExecutionStateManager.STATE_RUNNING
    );
    System.assertEquals(
      JT_ExecutionStateManager.STATE_RUNNING,
      execution.Test_Status__c,
      'Should transition to Running'
    );

    // Running -> Completed
    JT_ExecutionStateManager.transition(
      execution,
      JT_ExecutionStateManager.STATE_COMPLETED
    );
    System.assertEquals(
      JT_ExecutionStateManager.STATE_COMPLETED,
      execution.Test_Status__c,
      'Should transition to Completed'
    );
    Test.stopTest();
  }

  /**
   * @description Test transition from final state (should fail)
   */
  @IsTest
  static void testTransitionFromFinalState() {
    JT_RunAsTest_Execution__c execution = [
      SELECT Id, Test_Status__c
      FROM JT_RunAsTest_Execution__c
      LIMIT 1
    ];

    // First transition to final state
    execution.Test_Status__c = JT_ExecutionStateManager.STATE_COMPLETED;
    execution.Initiated_By__c = UserInfo.getUserId();
    update execution;

    Test.startTest();
    try {
      JT_ExecutionStateManager.transition(
        execution,
        JT_ExecutionStateManager.STATE_RUNNING
      );
      System.assert(false, 'Should have thrown StateTransitionException');
    } catch (JT_ExecutionStateManager.StateTransitionException e) {
      // Expected
      System.assert(
        e.getMessage().contains('Completed'),
        'Exception should mention Completed state'
      );
    }
    Test.stopTest();
  }
}
