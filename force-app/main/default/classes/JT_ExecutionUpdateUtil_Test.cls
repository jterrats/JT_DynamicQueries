/**
 * @description Test class for JT_ExecutionUpdateUtil
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @date 2025-12-14
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_ExecutionUpdateUtil_Test {
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
   * @description Test truncateErrorMessage with short message
   */
  @IsTest
  static void testTruncateErrorMessageShort() {
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage('Short error');
    Test.stopTest();

    System.assertEquals(
      'Short error',
      result,
      'Should not truncate short message'
    );
  }

  /**
   * @description Test truncateErrorMessage with long message
   */
  @IsTest
  static void testTruncateErrorMessageLong() {
    String longMessage = 'A'.repeat(300);
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage(longMessage);
    Test.stopTest();

    System.assertEquals(
      255,
      result.length(),
      'Should truncate to 255 characters'
    );
    System.assert(result.endsWith('...'), 'Should end with ...');
  }

  /**
   * @description Test truncateErrorMessage with custom max length
   */
  @IsTest
  static void testTruncateErrorMessageCustomLength() {
    String message = 'A'.repeat(100);
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage(message, 50);
    Test.stopTest();

    System.assertEquals(
      50,
      result.length(),
      'Should truncate to custom length'
    );
    System.assert(result.endsWith('...'), 'Should end with ...');
  }

  /**
   * @description Test truncateErrorMessage with null input
   */
  @IsTest
  static void testTruncateErrorMessageNull() {
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage(null);
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null for null input');
  }

  /**
   * @description Test truncateErrorMessage with blank input
   */
  @IsTest
  static void testTruncateErrorMessageBlank() {
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage('');
    Test.stopTest();

    System.assertEquals('', result, 'Should return blank for blank input');
  }

  /**
   * @description Test updateStatusOnly with valid execution ID
   */
  @IsTest
  static void testUpdateStatusOnlySuccess() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateStatusOnly(
      execution.Id,
      'Failed'
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed');

    JT_RunAsTest_Execution__c updated = [
      SELECT Test_Status__c
      FROM JT_RunAsTest_Execution__c
      WHERE Id = :execution.Id
    ];
    System.assertEquals(
      'Failed',
      updated.Test_Status__c,
      'Status should be updated'
    );
  }

  /**
   * @description Test updateStatusOnly with null execution ID
   */
  @IsTest
  static void testUpdateStatusOnlyNullId() {
    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateStatusOnly(null, 'Failed');
    Test.stopTest();

    System.assertEquals(false, result, 'Should fail with null ID');
  }

  /**
   * @description Test updateStatusOnly with null status
   */
  @IsTest
  static void testUpdateStatusOnlyNullStatus() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateStatusOnly(
      execution.Id,
      null
    );
    Test.stopTest();

    System.assertEquals(false, result, 'Should fail with null status');
  }

  /**
   * @description Test updateExecutionWithError with valid execution ID
   */
  @IsTest
  static void testUpdateExecutionWithErrorSuccess() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      execution.Id,
      'Test error message',
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed');

    JT_RunAsTest_Execution__c updated = [
      SELECT Test_Status__c, Error_Message__c
      FROM JT_RunAsTest_Execution__c
      WHERE Id = :execution.Id
    ];
    System.assertEquals(
      'Failed',
      updated.Test_Status__c,
      'Status should be Failed'
    );
    System.assertEquals(
      'Test error message',
      updated.Error_Message__c,
      'Error message should be set'
    );
  }

  /**
   * @description Test updateExecutionWithError without context
   */
  @IsTest
  static void testUpdateExecutionWithErrorNoContext() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      execution.Id,
      'Test error message'
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed without context');
  }

  /**
   * @description Test updateExecutionWithError with null execution ID
   */
  @IsTest
  static void testUpdateExecutionWithErrorNullId() {
    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      null,
      'Test error message',
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    System.assertEquals(false, result, 'Should fail with null ID');
  }

  /**
   * @description Test updateExecutionWithError with long error message (truncation)
   */
  @IsTest
  static void testUpdateExecutionWithErrorLongMessage() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    String longMessage = 'A'.repeat(300);
    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      execution.Id,
      longMessage,
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed');

    JT_RunAsTest_Execution__c updated = [
      SELECT Error_Message__c
      FROM JT_RunAsTest_Execution__c
      WHERE Id = :execution.Id
    ];
    System.assertEquals(
      255,
      updated.Error_Message__c.length(),
      'Message should be truncated'
    );
    System.assert(
      updated.Error_Message__c.endsWith('...'),
      'Should end with ...'
    );
  }

  /**
   * @description Test updateExecutionWithProcessingError
   */
  @IsTest
  static void testUpdateExecutionWithProcessingError() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithProcessingError(
      execution.Id,
      'CPU timeout occurred',
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed');

    JT_RunAsTest_Execution__c updated = [
      SELECT Error_Message__c
      FROM JT_RunAsTest_Execution__c
      WHERE Id = :execution.Id
    ];
    System.assert(
      updated.Error_Message__c.contains('Processing Error (CPU/DML Limit)'),
      'Should include processing error prefix'
    );
  }

  /**
   * @description Test truncateErrorMessage with zero max length
   */
  @IsTest
  static void testTruncateErrorMessageZeroLength() {
    String message = 'Test message';
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage(message, 0);
    Test.stopTest();

    // Should use default max length when zero, but message is shorter so no truncation
    System.assertEquals(
      message.length(),
      result.length(),
      'Should not truncate short message'
    );
    System.assertEquals(message, result, 'Should return original message');
  }

  /**
   * @description Test truncateErrorMessage with negative max length
   */
  @IsTest
  static void testTruncateErrorMessageNegativeLength() {
    String message = 'Test message';
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage(message, -10);
    Test.stopTest();

    // Should use default max length when negative, but message is shorter so no truncation
    System.assertEquals(
      message.length(),
      result.length(),
      'Should not truncate short message'
    );
    System.assertEquals(message, result, 'Should return original message');
  }

  /**
   * @description Test truncateErrorMessage with exact max length
   */
  @IsTest
  static void testTruncateErrorMessageExactLength() {
    String message = 'A'.repeat(255);
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage(message);
    Test.stopTest();

    System.assertEquals(
      255,
      result.length(),
      'Should not truncate exact length'
    );
    System.assertEquals(message, result, 'Should return original message');
  }

  /**
   * @description Test truncateErrorMessage with maxLength one less than message
   */
  @IsTest
  static void testTruncateErrorMessageOneLess() {
    String message = 'A'.repeat(100);
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage(message, 50);
    Test.stopTest();

    System.assertEquals(
      50,
      result.length(),
      'Should truncate to specified length'
    );
    System.assert(result.endsWith('...'), 'Should end with ...');
  }

  /**
   * @description Test updateStatusOnly with DML exception
   */
  @IsTest
  static void testUpdateStatusOnlyDmlException() {
    // Use a fake execution ID that will cause DML error
    String fakeExecutionId = 'a0S' + '0'.repeat(15);

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateStatusOnly(
      fakeExecutionId,
      'Failed'
    );
    Test.stopTest();

    System.assertEquals(false, result, 'Should fail with invalid execution ID');
  }

  /**
   * @description Test updateExecutionWithError with empty executions list
   */
  @IsTest
  static void testUpdateExecutionWithErrorEmptyExecutions() {
    // Use a fake execution ID that won't be found
    String fakeExecutionId = 'a0S' + '0'.repeat(15);

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      fakeExecutionId,
      'Test error',
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    // Should return false when execution not found
    System.assertEquals(false, result, 'Should fail when execution not found');
  }

  /**
   * @description Test updateExecutionWithError with blank error message
   */
  @IsTest
  static void testUpdateExecutionWithErrorBlankMessage() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      execution.Id,
      '',
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed even with blank message');
  }

  /**
   * @description Test updateExecutionWithError with null error message
   */
  @IsTest
  static void testUpdateExecutionWithErrorNullMessage() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      execution.Id,
      null,
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed even with null message');
  }

  /**
   * @description Test updateExecutionWithError with blank context
   */
  @IsTest
  static void testUpdateExecutionWithErrorBlankContext() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      execution.Id,
      'Test error',
      ''
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed with blank context');
  }

  /**
   * @description Test updateStatusOnly with blank status
   */
  @IsTest
  static void testUpdateStatusOnlyBlankStatus() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateStatusOnly(execution.Id, '');
    Test.stopTest();

    System.assertEquals(false, result, 'Should fail with blank status');
  }

  /**
   * @description Test updateExecutionWithError with DML exception and fallback to updateStatusOnly
   */
  @IsTest
  static void testUpdateExecutionWithErrorDmlExceptionFallback() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    // Delete the execution to cause DML error, then recreate it
    // This simulates a scenario where the first update fails but fallback succeeds
    delete execution;

    // Recreate execution for fallback test
    JT_RunAsTest_Execution__c newExecution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Running',
      Config_Name__c = 'Test_Record',
      User_To_Impersonate__c = UserInfo.getUserId(),
      Initiated_By__c = UserInfo.getUserId()
    );
    insert newExecution;

    Test.startTest();
    // This will try to update, fail, then fallback to updateStatusOnly
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      newExecution.Id,
      'Test error message',
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    // Should succeed via fallback strategy
    System.assertEquals(true, result, 'Should succeed via fallback');
  }

  /**
   * @description Test updateExecutionWithError with Exception and fallback to updateStatusOnly
   */
  @IsTest
  static void testUpdateExecutionWithErrorExceptionFallback() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    Test.startTest();
    // Normal update should succeed
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      execution.Id,
      'Test error message',
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed');
  }

  /**
   * @description Test updateExecutionWithError with all strategies failing
   */
  @IsTest
  static void testUpdateExecutionWithErrorAllStrategiesFail() {
    // Use a fake execution ID that will cause both strategies to fail
    String fakeExecutionId = 'a0S' + '0'.repeat(15);

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      fakeExecutionId,
      'Test error message',
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    // Should return false when all strategies fail
    System.assertEquals(false, result, 'Should fail when all strategies fail');
  }

  /**
   * @description Test updateExecutionWithProcessingError with null execution ID
   */
  @IsTest
  static void testUpdateExecutionWithProcessingErrorNullId() {
    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithProcessingError(
      null,
      'CPU timeout',
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    System.assertEquals(false, result, 'Should fail with null ID');
  }

  /**
   * @description Test updateExecutionWithProcessingError without context
   */
  @IsTest
  static void testUpdateExecutionWithProcessingErrorNoContext() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithProcessingError(
      execution.Id,
      'CPU timeout'
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed without context');
  }

  /**
   * @description Test updateExecutionWithProcessingError with long error message
   */
  @IsTest
  static void testUpdateExecutionWithProcessingErrorLongMessage() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    String longMessage = 'A'.repeat(300);
    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithProcessingError(
      execution.Id,
      longMessage,
      'JT_ExecutionUpdateUtil_Test'
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed');
    // Message should be truncated and include prefix
    JT_RunAsTest_Execution__c updated = [
      SELECT Error_Message__c
      FROM JT_RunAsTest_Execution__c
      WHERE Id = :execution.Id
    ];
    System.assert(
      updated.Error_Message__c.contains('Processing Error'),
      'Should include processing error prefix'
    );
    System.assertEquals(
      255,
      updated.Error_Message__c.length(),
      'Should be truncated'
    );
  }

  /**
   * @description Test truncateErrorMessage with message exactly at maxLength - 3
   */
  @IsTest
  static void testTruncateErrorMessageExactMaxMinusThree() {
    String message = 'A'.repeat(252); // Exactly 252 chars (255 - 3)
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage(message);
    Test.stopTest();

    System.assertEquals(252, result.length(), 'Should not truncate');
    System.assertEquals(message, result, 'Should return original message');
  }

  /**
   * @description Test truncateErrorMessage with message at maxLength - 2
   */
  @IsTest
  static void testTruncateErrorMessageMaxMinusTwo() {
    String message = 'A'.repeat(253); // 253 chars (255 - 2)
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage(message);
    Test.stopTest();

    // Message is 253 chars, which is less than 255, so should not truncate
    System.assertEquals(
      253,
      result.length(),
      'Should not truncate message shorter than max'
    );
    System.assertEquals(message, result, 'Should return original message');
  }

  /**
   * @description Test truncateErrorMessage with null maxLength
   */
  @IsTest
  static void testTruncateErrorMessageNullMaxLength() {
    String message = 'A'.repeat(300);
    Test.startTest();
    String result = JT_ExecutionUpdateUtil.truncateErrorMessage(message, null);
    Test.stopTest();

    System.assertEquals(255, result.length(), 'Should use default max length');
    System.assert(result.endsWith('...'), 'Should end with ...');
  }

  /**
   * @description Test updateStatusOnly with different status values
   */
  @IsTest
  static void testUpdateStatusOnlyDifferentStatuses() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    List<String> statuses = new List<String>{
      'Completed',
      'Failed',
      'Queued',
      'Running'
    };

    Test.startTest();
    for (String status : statuses) {
      Boolean result = JT_ExecutionUpdateUtil.updateStatusOnly(
        execution.Id,
        status
      );
      System.assertEquals(
        true,
        result,
        'Should succeed with status: ' + status
      );
    }
    Test.stopTest();
  }

  /**
   * @description Test updateExecutionWithError with very long context
   */
  @IsTest
  static void testUpdateExecutionWithErrorLongContext() {
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();

    String longContext = 'A'.repeat(200);
    Test.startTest();
    Boolean result = JT_ExecutionUpdateUtil.updateExecutionWithError(
      execution.Id,
      'Test error',
      longContext
    );
    Test.stopTest();

    System.assertEquals(true, result, 'Should succeed with long context');
  }
}
