/**
 * @description Test class for JT_ErrorLogger
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @date 2025-12-14
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_ErrorLogger_Test {
  /**
   * @description Test ErrorLogParams constructor with all parameters
   */
  @IsTest
  static void testErrorLogParamsFullConstructor() {
    Test.startTest();
    Exception testEx = new DmlException('Test exception');
    JT_ErrorLogger.ErrorLogParams params = new JT_ErrorLogger.ErrorLogParams(
      'TestError',
      'Test error message',
      testEx,
      'TestContext',
      '{"key": "value"}',
      'High'
    );
    Test.stopTest();

    System.assertEquals(
      'TestError',
      params.errorType,
      'Error type should match'
    );
    System.assertEquals(
      'Test error message',
      params.errorMessage,
      'Error message should match'
    );
    System.assertEquals(testEx, params.ex, 'Exception should match');
    System.assertEquals('TestContext', params.context, 'Context should match');
    System.assertEquals(
      '{"key": "value"}',
      params.additionalDetails,
      'Additional details should match'
    );
    System.assertEquals('High', params.severity, 'Severity should match');
  }

  /**
   * @description Test ErrorLogParams constructor with minimal parameters
   */
  @IsTest
  static void testErrorLogParamsMinimalConstructor() {
    Test.startTest();
    Exception testEx = new DmlException('Test exception');
    JT_ErrorLogger.ErrorLogParams params = new JT_ErrorLogger.ErrorLogParams(
      'TestError',
      'Test error message',
      testEx,
      'TestContext'
    );
    Test.stopTest();

    System.assertEquals(
      'TestError',
      params.errorType,
      'Error type should match'
    );
    System.assertEquals(
      'Test error message',
      params.errorMessage,
      'Error message should match'
    );
    System.assertEquals(
      'Medium',
      params.severity,
      'Severity should default to Medium'
    );
    System.assertEquals(
      null,
      params.additionalDetails,
      'Additional details should be null'
    );
  }

  /**
   * @description Test logError with ErrorLogParams object
   */
  @IsTest
  static void testLogErrorWithParams() {
    Exception testEx = new DmlException('Test exception message');

    Test.startTest();
    JT_ErrorLogger.ErrorLogParams params = new JT_ErrorLogger.ErrorLogParams(
      'TestError',
      'User-friendly error message',
      testEx,
      'JT_ErrorLogger_Test.testLogErrorWithParams'
    );
    String logId = JT_ErrorLogger.logError(params);
    Test.stopTest();

    System.assertNotEquals(null, logId, 'Log ID should be returned');
    System.assert(logId.length() > 0, 'Log ID should be a valid Salesforce ID');

    // Verify log was created
    List<JT_ErrorLog__c> logs = [
      SELECT
        Id,
        JT_ErrorType__c,
        JT_ErrorMessage__c,
        JT_ExceptionType__c,
        JT_Context__c,
        JT_Severity__c,
        OwnerId
      FROM JT_ErrorLog__c
      WHERE Id = :logId
    ];

    System.assertEquals(1, logs.size(), 'One log should be created');
    System.assertEquals(
      'TestError',
      logs[0].JT_ErrorType__c,
      'Error type should match'
    );
    System.assertEquals(
      'User-friendly error message',
      logs[0].JT_ErrorMessage__c,
      'Error message should match'
    );
    System.assertEquals(
      'System.DmlException',
      logs[0].JT_ExceptionType__c,
      'Exception type should match'
    );
    System.assertEquals(
      'Medium',
      logs[0].JT_Severity__c,
      'Severity should match'
    );
    System.assertEquals(
      UserInfo.getUserId(),
      logs[0].OwnerId,
      'Owner should be current user'
    );
  }

  /**
   * @description Test logError with null params (should return null gracefully)
   */
  @IsTest
  static void testLogErrorWithNullParams() {
    Test.startTest();
    String logId = JT_ErrorLogger.logError(
      (JT_ErrorLogger.ErrorLogParams) null
    );
    Test.stopTest();

    System.assertEquals(null, logId, 'Should return null for null params');
  }

  /**
   * @description Test logError with ErrorType enum
   */
  @IsTest
  static void testLogErrorWithErrorType() {
    Exception testEx = new DmlException('Test exception');

    Test.startTest();
    String logId = JT_ErrorLogger.logError(
      JT_ErrorMessageUtil.ErrorType.OBJECT_ACCESS_DENIED,
      'Object access denied message',
      testEx,
      'TestContext'
    );
    Test.stopTest();

    System.assertNotEquals(null, logId, 'Log ID should be returned');

    List<JT_ErrorLog__c> logs = [
      SELECT JT_ErrorType__c, JT_Severity__c
      FROM JT_ErrorLog__c
      WHERE Id = :logId
    ];

    System.assertEquals(1, logs.size(), 'One log should be created');
    System.assertEquals(
      'OBJECT_ACCESS_DENIED',
      logs[0].JT_ErrorType__c,
      'Error type should match enum name'
    );
    System.assertEquals(
      'High',
      logs[0].JT_Severity__c,
      'Severity should be High for object access'
    );
  }

  /**
   * @description Test logError with String errorType and Exception
   */
  @IsTest
  static void testLogErrorWithStringAndException() {
    Exception testEx = new DmlException('Test exception message');

    Test.startTest();
    String logId = JT_ErrorLogger.logError(
      'CustomError',
      testEx,
      'TestContext'
    );
    Test.stopTest();

    System.assertNotEquals(null, logId, 'Log ID should be returned');

    List<JT_ErrorLog__c> logs = [
      SELECT JT_ErrorType__c, JT_ErrorMessage__c
      FROM JT_ErrorLog__c
      WHERE Id = :logId
    ];

    System.assertEquals(1, logs.size(), 'One log should be created');
    System.assertEquals(
      'CustomError',
      logs[0].JT_ErrorType__c,
      'Error type should match'
    );
    System.assertEquals(
      'Test exception message',
      logs[0].JT_ErrorMessage__c,
      'Error message should come from exception'
    );
  }

  /**
   * @description Test logError with String errorType, message, and Exception
   */
  @IsTest
  static void testLogErrorWithStringMessageAndException() {
    Exception testEx = new DmlException('Original exception');

    Test.startTest();
    String logId = JT_ErrorLogger.logError(
      'CustomError',
      'User-friendly message',
      testEx,
      'TestContext'
    );
    Test.stopTest();

    System.assertNotEquals(null, logId, 'Log ID should be returned');

    List<JT_ErrorLog__c> logs = [
      SELECT JT_ErrorMessage__c
      FROM JT_ErrorLog__c
      WHERE Id = :logId
    ];

    System.assertEquals(1, logs.size(), 'One log should be created');
    System.assertEquals(
      'User-friendly message',
      logs[0].JT_ErrorMessage__c,
      'Error message should use provided message, not exception message'
    );
  }

  /**
   * @description Test logError with full parameters (legacy method)
   */
  @IsTest
  static void testLogErrorWithFullParameters() {
    Exception testEx = new DmlException('Test exception');

    Test.startTest();
    String logId = JT_ErrorLogger.logError(
      'CustomError',
      'User-friendly message',
      testEx,
      'TestContext',
      '{"additional": "data"}',
      'Critical'
    );
    Test.stopTest();

    System.assertNotEquals(null, logId, 'Log ID should be returned');

    List<JT_ErrorLog__c> logs = [
      SELECT JT_Severity__c, JT_AdditionalDetails__c
      FROM JT_ErrorLog__c
      WHERE Id = :logId
    ];

    System.assertEquals(1, logs.size(), 'One log should be created');
    System.assertEquals(
      'Critical',
      logs[0].JT_Severity__c,
      'Severity should match'
    );
    System.assertEquals(
      '{"additional": "data"}',
      logs[0].JT_AdditionalDetails__c,
      'Additional details should match'
    );
  }

  /**
   * @description Test logError with null exception (should handle gracefully)
   */
  @IsTest
  static void testLogErrorWithNullException() {
    Test.startTest();
    JT_ErrorLogger.ErrorLogParams params = new JT_ErrorLogger.ErrorLogParams(
      'TestError',
      'Error message without exception',
      null,
      'TestContext'
    );
    String logId = JT_ErrorLogger.logError(params);
    Test.stopTest();

    System.assertNotEquals(null, logId, 'Log ID should be returned');

    List<JT_ErrorLog__c> logs = [
      SELECT JT_ExceptionType__c, JT_StackTrace__c
      FROM JT_ErrorLog__c
      WHERE Id = :logId
    ];

    System.assertEquals(1, logs.size(), 'One log should be created');
    System.assertEquals(
      null,
      logs[0].JT_ExceptionType__c,
      'Exception type should be null'
    );
    System.assertEquals(
      null,
      logs[0].JT_StackTrace__c,
      'Stack trace should be null'
    );
  }

  /**
   * @description Test logError with blank error message (should use fallback)
   */
  @IsTest
  static void testLogErrorWithBlankMessage() {
    Exception testEx = new DmlException('Test exception');

    Test.startTest();
    JT_ErrorLogger.ErrorLogParams params = new JT_ErrorLogger.ErrorLogParams(
      'TestError',
      '',
      testEx,
      'TestContext'
    );
    String logId = JT_ErrorLogger.logError(params);
    Test.stopTest();

    System.assertNotEquals(null, logId, 'Log ID should be returned');

    List<JT_ErrorLog__c> logs = [
      SELECT JT_ErrorMessage__c
      FROM JT_ErrorLog__c
      WHERE Id = :logId
    ];

    System.assertEquals(1, logs.size(), 'One log should be created');
    System.assertEquals(
      'Unknown error',
      logs[0].JT_ErrorMessage__c,
      'Should use fallback message when blank'
    );
  }

  /**
   * @description Test severity determination for different error types
   */
  @IsTest
  static void testSeverityDetermination() {
    Exception testEx = new DmlException('Test exception');

    Test.startTest();
    // Test LICENSE_RESTRICTION -> Medium
    String logId1 = JT_ErrorLogger.logError(
      JT_ErrorMessageUtil.ErrorType.LICENSE_RESTRICTION,
      'License error',
      testEx,
      'TestContext'
    );

    // Test OBJECT_ACCESS_DENIED -> High
    String logId2 = JT_ErrorLogger.logError(
      JT_ErrorMessageUtil.ErrorType.OBJECT_ACCESS_DENIED,
      'Object access error',
      testEx,
      'TestContext'
    );

    // Test INVALID_SOQL_SYNTAX -> Low
    String logId3 = JT_ErrorLogger.logError(
      JT_ErrorMessageUtil.ErrorType.INVALID_SOQL_SYNTAX,
      'Syntax error',
      testEx,
      'TestContext'
    );
    Test.stopTest();

    List<JT_ErrorLog__c> logs = [
      SELECT JT_ErrorType__c, JT_Severity__c
      FROM JT_ErrorLog__c
      WHERE Id IN :new List<String>{ logId1, logId2, logId3 }
      ORDER BY JT_ErrorType__c
    ];

    System.assertEquals(3, logs.size(), 'Three logs should be created');

    // Find each log by error type
    for (JT_ErrorLog__c log : logs) {
      if (log.JT_ErrorType__c == 'LICENSE_RESTRICTION') {
        System.assertEquals(
          'Medium',
          log.JT_Severity__c,
          'License restriction should be Medium'
        );
      } else if (log.JT_ErrorType__c == 'OBJECT_ACCESS_DENIED') {
        System.assertEquals(
          'High',
          log.JT_Severity__c,
          'Object access denied should be High'
        );
      } else if (log.JT_ErrorType__c == 'INVALID_SOQL_SYNTAX') {
        System.assertEquals(
          'Low',
          log.JT_Severity__c,
          'Syntax error should be Low'
        );
      }
    }
  }
}
