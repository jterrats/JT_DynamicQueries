/**
 * @description Utility class for extracting and formatting user-friendly error messages
 * Centralizes error message parsing logic used across multiple classes
 * @author Jaime Terrats
 * @group Dynamic Queries
 */
public class JT_ErrorMessageUtil {
  /**
   * @description Error type enumeration for consistent error categorization
   */
  public enum ErrorType {
    OBJECT_ACCESS_DENIED,
    FIELD_ACCESS_DENIED,
    INSUFFICIENT_PERMISSIONS,
    LICENSE_RESTRICTION,
    CONFIGURATION_ACCESS_DENIED,
    INVALID_SOQL_SYNTAX,
    UNKNOWN
  }

  /**
   * @description Detects error type from error message
   * @param errorMessage Error message to analyze
   * @return ErrorType Detected error type
   */
  public static ErrorType detectErrorType(String errorMessage) {
    if (String.isBlank(errorMessage)) {
      return ErrorType.UNKNOWN;
    }

    String lowerError = errorMessage.toLowerCase();

    if (
      lowerError.contains('sobject type') &&
      lowerError.contains('does not exist')
    ) {
      return ErrorType.OBJECT_ACCESS_DENIED;
    }

    if (
      lowerError.contains('no such column') ||
      lowerError.contains('invalid field')
    ) {
      return ErrorType.FIELD_ACCESS_DENIED;
    }

    if (
      lowerError.contains('insufficient access') ||
      lowerError.contains('insufficient privileges') ||
      lowerError.contains('insufficient access rights') ||
      lowerError.contains('permission')
    ) {
      return ErrorType.INSUFFICIENT_PERMISSIONS;
    }

    if (
      lowerError.contains('license') ||
      lowerError.contains('not available') ||
      lowerError.contains('not licensed')
    ) {
      return ErrorType.LICENSE_RESTRICTION;
    }

    if (
      lowerError.contains('custommetadata') ||
      lowerError.contains('jt_dynamicqueryconfiguration__mdt')
    ) {
      return ErrorType.CONFIGURATION_ACCESS_DENIED;
    }

    if (
      lowerError.contains('unexpected token') ||
      lowerError.contains('expecting')
    ) {
      return ErrorType.INVALID_SOQL_SYNTAX;
    }

    return ErrorType.UNKNOWN;
  }

  /**
   * @description Extracts user-friendly error message from Assertion Failed exception
   * @param errorMessage Full error message containing "Assertion Failed:"
   * @return String Extracted assertion message or null if not found
   */
  public static String extractAssertionMessage(String errorMessage) {
    if (String.isBlank(errorMessage)) {
      return null;
    }

    if (!errorMessage.contains('Assertion Failed')) {
      return null;
    }

    Integer assertionIndex = errorMessage.indexOf('Assertion Failed:');
    if (assertionIndex == -1) {
      return null;
    }

    String assertionMessage = errorMessage
      .substring(assertionIndex + 'Assertion Failed:'.length())
      .trim();

    if (
      String.isNotBlank(assertionMessage) &&
      assertionMessage != 'Assertion Failed'
    ) {
      return assertionMessage;
    }

    return null;
  }

  /**
   * @description Extracts user-friendly error message from various error sources
   * Handles Assertion Failed, stack traces, and direct error messages
   * Returns ErrorType so calling classes can use their own Custom Labels
   * @param errorMessage Error message to process
   * @param stackTrace Optional stack trace for additional context
   * @return ErrorAnalysisResult Contains error type and extracted assertion message
   */
  public static ErrorAnalysisResult analyzeError(
    String errorMessage,
    String stackTrace
  ) {
    ErrorAnalysisResult result = new ErrorAnalysisResult();

    if (String.isBlank(errorMessage)) {
      result.errorType = ErrorType.UNKNOWN;
      return result;
    }

    String assertionMessage = extractAssertionMessage(errorMessage);
    if (String.isNotBlank(assertionMessage)) {
      result.assertionMessage = assertionMessage;
      result.errorType = ErrorType.UNKNOWN;
      return result;
    }

    String sourceToAnalyze = String.isNotBlank(stackTrace)
      ? stackTrace.toLowerCase()
      : errorMessage.toLowerCase();
    result.errorType = detectErrorType(sourceToAnalyze);

    if (
      errorMessage.contains('System.AssertException') ||
      errorMessage.contains('Assertion Failed')
    ) {
      result.isAssertionFailed = true;
    }

    return result;
  }

  /**
   * @description Result wrapper for error analysis
   */
  public class ErrorAnalysisResult {
    public ErrorType errorType;
    public String assertionMessage;
    public Boolean isAssertionFailed;

    public ErrorAnalysisResult() {
      this.errorType = JT_ErrorMessageUtil.ErrorType.UNKNOWN;
      this.assertionMessage = null;
      this.isAssertionFailed = false;
    }
  }
}
