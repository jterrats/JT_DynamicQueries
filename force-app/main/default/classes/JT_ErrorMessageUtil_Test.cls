/**
 * @description Test class for JT_ErrorMessageUtil
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @date 2025-12-14
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_ErrorMessageUtil_Test {
  /**
   * @description Test detectErrorType with OBJECT_ACCESS_DENIED pattern
   */
  @IsTest
  static void testDetectErrorTypeObjectAccessDenied() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorType result = JT_ErrorMessageUtil.detectErrorType(
      'SObject type Account does not exist'
    );
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.OBJECT_ACCESS_DENIED,
      result,
      'Should detect object access denied'
    );
  }

  /**
   * @description Test detectErrorType with FIELD_ACCESS_DENIED pattern
   */
  @IsTest
  static void testDetectErrorTypeFieldAccessDenied() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorType result1 = JT_ErrorMessageUtil.detectErrorType(
      'No such column Account.InvalidField'
    );
    JT_ErrorMessageUtil.ErrorType result2 = JT_ErrorMessageUtil.detectErrorType(
      'Invalid field Account.InvalidField'
    );
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.FIELD_ACCESS_DENIED,
      result1,
      'Should detect field access denied (no such column)'
    );
    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.FIELD_ACCESS_DENIED,
      result2,
      'Should detect field access denied (invalid field)'
    );
  }

  /**
   * @description Test detectErrorType with INSUFFICIENT_PERMISSIONS pattern
   */
  @IsTest
  static void testDetectErrorTypeInsufficientPermissions() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorType result1 = JT_ErrorMessageUtil.detectErrorType(
      'Insufficient access rights'
    );
    JT_ErrorMessageUtil.ErrorType result2 = JT_ErrorMessageUtil.detectErrorType(
      'Insufficient privileges to access'
    );
    JT_ErrorMessageUtil.ErrorType result3 = JT_ErrorMessageUtil.detectErrorType(
      'Permission denied'
    );
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.INSUFFICIENT_PERMISSIONS,
      result1,
      'Should detect insufficient permissions (access rights)'
    );
    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.INSUFFICIENT_PERMISSIONS,
      result2,
      'Should detect insufficient permissions (privileges)'
    );
    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.INSUFFICIENT_PERMISSIONS,
      result3,
      'Should detect insufficient permissions (permission)'
    );
  }

  /**
   * @description Test detectErrorType with LICENSE_RESTRICTION pattern
   */
  @IsTest
  static void testDetectErrorTypeLicenseRestriction() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorType result1 = JT_ErrorMessageUtil.detectErrorType(
      'License not available'
    );
    JT_ErrorMessageUtil.ErrorType result2 = JT_ErrorMessageUtil.detectErrorType(
      'Feature not licensed'
    );
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.LICENSE_RESTRICTION,
      result1,
      'Should detect license restriction (not available)'
    );
    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.LICENSE_RESTRICTION,
      result2,
      'Should detect license restriction (not licensed)'
    );
  }

  /**
   * @description Test detectErrorType with CONFIGURATION_ACCESS_DENIED pattern
   */
  @IsTest
  static void testDetectErrorTypeConfigurationAccessDenied() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorType result1 = JT_ErrorMessageUtil.detectErrorType(
      'Cannot access CustomMetadata'
    );
    JT_ErrorMessageUtil.ErrorType result2 = JT_ErrorMessageUtil.detectErrorType(
      'JT_DynamicQueryConfiguration__mdt not found'
    );
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.CONFIGURATION_ACCESS_DENIED,
      result1,
      'Should detect configuration access denied (CustomMetadata)'
    );
    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.CONFIGURATION_ACCESS_DENIED,
      result2,
      'Should detect configuration access denied (mdt)'
    );
  }

  /**
   * @description Test detectErrorType with INVALID_SOQL_SYNTAX pattern
   */
  @IsTest
  static void testDetectErrorTypeInvalidSoqlSyntax() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorType result1 = JT_ErrorMessageUtil.detectErrorType(
      'Unexpected token'
    );
    JT_ErrorMessageUtil.ErrorType result2 = JT_ErrorMessageUtil.detectErrorType(
      'Expecting FROM'
    );
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.INVALID_SOQL_SYNTAX,
      result1,
      'Should detect invalid SOQL syntax (unexpected token)'
    );
    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.INVALID_SOQL_SYNTAX,
      result2,
      'Should detect invalid SOQL syntax (expecting)'
    );
  }

  /**
   * @description Test detectErrorType with unknown error
   */
  @IsTest
  static void testDetectErrorTypeUnknown() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorType result1 = JT_ErrorMessageUtil.detectErrorType(
      'Some random error message'
    );
    JT_ErrorMessageUtil.ErrorType result2 = JT_ErrorMessageUtil.detectErrorType(
      null
    );
    JT_ErrorMessageUtil.ErrorType result3 = JT_ErrorMessageUtil.detectErrorType(
      ''
    );
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.UNKNOWN,
      result1,
      'Should return UNKNOWN for unrecognized error'
    );
    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.UNKNOWN,
      result2,
      'Should return UNKNOWN for null'
    );
    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.UNKNOWN,
      result3,
      'Should return UNKNOWN for blank'
    );
  }

  /**
   * @description Test extractAssertionMessage with valid assertion message
   */
  @IsTest
  static void testExtractAssertionMessageValid() {
    Test.startTest();
    String result = JT_ErrorMessageUtil.extractAssertionMessage(
      'System.AssertException: Assertion Failed: User does not have access to Account'
    );
    Test.stopTest();

    System.assertEquals(
      'User does not have access to Account',
      result,
      'Should extract assertion message'
    );
  }

  /**
   * @description Test extractAssertionMessage with no assertion message
   */
  @IsTest
  static void testExtractAssertionMessageNoMessage() {
    Test.startTest();
    String result1 = JT_ErrorMessageUtil.extractAssertionMessage(
      'System.AssertException: Assertion Failed'
    );
    String result2 = JT_ErrorMessageUtil.extractAssertionMessage(
      'Some other error message'
    );
    String result3 = JT_ErrorMessageUtil.extractAssertionMessage(null);
    Test.stopTest();

    System.assertEquals(
      null,
      result1,
      'Should return null when no message after Assertion Failed'
    );
    System.assertEquals(
      null,
      result2,
      'Should return null when no Assertion Failed'
    );
    System.assertEquals(null, result3, 'Should return null for null input');
  }

  /**
   * @description Test analyzeError with assertion message
   */
  @IsTest
  static void testAnalyzeErrorWithAssertion() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorAnalysisResult result = JT_ErrorMessageUtil.analyzeError(
      'System.AssertException: Assertion Failed: Custom assertion message',
      null
    );
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.UNKNOWN,
      result.errorType,
      'Error type should be UNKNOWN for assertions'
    );
    System.assertEquals(
      'Custom assertion message',
      result.assertionMessage,
      'Assertion message should be extracted'
    );
    // Note: When assertionMessage is extracted, analyzeError returns early
    // and doesn't set isAssertionFailed (this is by design - assertion message takes precedence)
    System.assertEquals(
      false,
      result.isAssertionFailed,
      'isAssertionFailed is false when assertion message is extracted (early return)'
    );
  }

  /**
   * @description Test analyzeError with object access error
   */
  @IsTest
  static void testAnalyzeErrorWithObjectAccess() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorAnalysisResult result = JT_ErrorMessageUtil.analyzeError(
      'SObject type Account does not exist',
      null
    );
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.OBJECT_ACCESS_DENIED,
      result.errorType,
      'Should detect object access denied'
    );
    System.assertEquals(
      false,
      result.isAssertionFailed,
      'Should not be assertion failed'
    );
    System.assertEquals(null, result.assertionMessage, 'No assertion message');
  }

  /**
   * @description Test analyzeError with stack trace analysis
   */
  @IsTest
  static void testAnalyzeErrorWithStackTrace() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorAnalysisResult result = JT_ErrorMessageUtil.analyzeError(
      'Generic error',
      'Stack trace: SObject type Account does not exist'
    );
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.OBJECT_ACCESS_DENIED,
      result.errorType,
      'Should detect error type from stack trace'
    );
  }

  /**
   * @description Test analyzeError with blank error message
   */
  @IsTest
  static void testAnalyzeErrorWithBlankMessage() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorAnalysisResult result = JT_ErrorMessageUtil.analyzeError(
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.UNKNOWN,
      result.errorType,
      'Should return UNKNOWN for blank message'
    );
    System.assertEquals(null, result.assertionMessage, 'No assertion message');
    System.assertEquals(
      false,
      result.isAssertionFailed,
      'Not assertion failed'
    );
  }

  /**
   * @description Test ErrorAnalysisResult default constructor
   */
  @IsTest
  static void testErrorAnalysisResultDefault() {
    Test.startTest();
    JT_ErrorMessageUtil.ErrorAnalysisResult result = new JT_ErrorMessageUtil.ErrorAnalysisResult();
    Test.stopTest();

    System.assertEquals(
      JT_ErrorMessageUtil.ErrorType.UNKNOWN,
      result.errorType,
      'Default error type should be UNKNOWN'
    );
    System.assertEquals(
      null,
      result.assertionMessage,
      'Default assertion message should be null'
    );
    System.assertEquals(
      false,
      result.isAssertionFailed,
      'Default isAssertionFailed should be false'
    );
  }
}
