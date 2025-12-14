/**
 * @description Utility class for logging errors/exceptions to JT_ErrorLog__c
 * Provides centralized error logging with automatic context capture
 * @author Jaime Terrats
 * @group Dynamic Queries
 */
public class JT_ErrorLogger {
  /**
   * @description Parameter object for error logging
   * Follows project rule: no many parameters, always use objects
   */
  public class ErrorLogParams {
    public String errorType;
    public String errorMessage;
    public Exception ex;
    public String context;
    public String additionalDetails;
    public String severity;

    /**
     * @description Constructor with all parameters
     */
    public ErrorLogParams(
      String errorType,
      String errorMessage,
      Exception ex,
      String context,
      String additionalDetails,
      String severity
    ) {
      this.errorType = errorType;
      this.errorMessage = errorMessage;
      this.ex = ex;
      this.context = context;
      this.additionalDetails = additionalDetails;
      this.severity = severity;
    }

    /**
     * @description Constructor with minimal required parameters
     */
    public ErrorLogParams(
      String errorType,
      String errorMessage,
      Exception ex,
      String context
    ) {
      this(errorType, errorMessage, ex, context, null, 'Medium');
    }
  }

  /**
   * @description Logs an error with full context information
   * @param params ErrorLogParams object containing all error information
   * @return String ID of created error log record (null if logging fails)
   */
  public static String logError(ErrorLogParams params) {
    if (params == null) {
      return null;
    }
    try {
      // Get org info
      Organization org = JT_SystemSelector.getOrganizationType();

      // Build error log record
      JT_ErrorLog__c errorLog = new JT_ErrorLog__c(
        JT_ErrorType__c = params.errorType,
        JT_ErrorMessage__c = String.isNotBlank(params.errorMessage)
          ? params.errorMessage
          : 'Unknown error',
        JT_ExceptionType__c = params.ex != null
          ? params.ex.getTypeName()
          : null,
        JT_StackTrace__c = params.ex != null
          ? params.ex.getStackTraceString()
          : null,
        JT_Context__c = params.context,
        JT_AdditionalDetails__c = params.additionalDetails,
        JT_Severity__c = String.isNotBlank(params.severity)
          ? params.severity
          : 'Medium',
        OwnerId = UserInfo.getUserId(), // Use standard Owner field
        JT_Timestamp__c = System.now(),
        JT_OrgType__c = org != null ? org.OrganizationType : null,
        JT_Resolved__c = false
      );

      // Insert via Domain layer (without sharing)
      JT_ErrorLogDomain.insertLog(errorLog);
      return errorLog.Id;
    } catch (Exception e) {
      // Don't fail the main operation if error logging fails
      // Logging errors should not break user workflows
      System.debug(
        LoggingLevel.WARN,
        'Error logging failed: ' + e.getMessage()
      );
      return null;
    }
  }

  /**
   * @description Logs an error from JT_ErrorMessageUtil.ErrorType
   * @param errorType Error type enum
   * @param errorMessage User-friendly error message
   * @param ex The exception that occurred (optional)
   * @param context Context where error occurred
   * @return String ID of created error log record (null if logging fails)
   */
  public static String logError(
    JT_ErrorMessageUtil.ErrorType errorType,
    String errorMessage,
    Exception ex,
    String context
  ) {
    ErrorLogParams params = new ErrorLogParams(
      errorType.name(),
      errorMessage,
      ex,
      context,
      null,
      determineSeverity(errorType)
    );
    return logError(params);
  }

  /**
   * @description Determines severity based on error type
   * @param errorType Error type
   * @return String Severity level
   */
  private static String determineSeverity(
    JT_ErrorMessageUtil.ErrorType errorType
  ) {
    switch on errorType {
      when LICENSE_RESTRICTION, INSUFFICIENT_PERMISSIONS {
        return 'Medium';
      }
      when OBJECT_ACCESS_DENIED, FIELD_ACCESS_DENIED {
        return 'High';
      }
      when CONFIGURATION_ACCESS_DENIED {
        return 'High';
      }
      when INVALID_SOQL_SYNTAX {
        return 'Low';
      }
      when else {
        return 'Medium';
      }
    }
  }

  /**
   * @description Logs an error with error type and exception (convenience method)
   * @param errorType Error type/category
   * @param ex The exception that occurred
   * @param context Context where error occurred
   * @return String ID of created error log record (null if logging fails)
   */
  public static String logError(
    String errorType,
    Exception ex,
    String context
  ) {
    String errorMessage = ex != null ? ex.getMessage() : 'Unknown error';
    ErrorLogParams params = new ErrorLogParams(
      errorType,
      errorMessage,
      ex,
      context
    );
    return logError(params);
  }

  /**
   * @description Logs an error with error type and message (convenience method for backward compatibility)
   * @param errorType Error type/category
   * @param errorMessage User-friendly error message
   * @param ex The exception that occurred
   * @param context Context where error occurred
   * @return String ID of created error log record (null if logging fails)
   */
  public static String logError(
    String errorType,
    String errorMessage,
    Exception ex,
    String context
  ) {
    ErrorLogParams params = new ErrorLogParams(
      errorType,
      errorMessage,
      ex,
      context
    );
    return logError(params);
  }

  /**
   * @description Logs an error with full context information (legacy method signature for backward compatibility)
   * @param errorType Error type/category (from JT_ErrorMessageUtil.ErrorType or custom)
   * @param errorMessage User-friendly error message
   * @param ex The exception that occurred (optional)
   * @param context Context where error occurred (e.g., 'jtQueryViewer.executeQuery')
   * @param additionalDetails Additional context as JSON string (optional)
   * @param severity Error severity (defaults to Medium)
   * @return String ID of created error log record (null if logging fails)
   */
  public static String logError(
    String errorType,
    String errorMessage,
    Exception ex,
    String context,
    String additionalDetails,
    String severity
  ) {
    ErrorLogParams params = new ErrorLogParams(
      errorType,
      errorMessage,
      ex,
      context,
      additionalDetails,
      severity
    );
    return logError(params);
  }
}
