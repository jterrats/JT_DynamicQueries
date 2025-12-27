/**
 * @description Utility class for updating JT_RunAsTest_Execution__c records with robust error handling
 * Consolidates duplicate error handling logic from JT_RunAsTestEnqueuer and JT_GenericRunAsTest
 * Provides fallback strategies to ensure execution records are never left in inconsistent state
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @date 2025-12-14
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class JT_ExecutionUpdateUtil {
  /**
   * @description Maximum length for error messages in JT_RunAsTest_Execution__c.Error_Message__c field
   */
  private static final Integer MAX_ERROR_MESSAGE_LENGTH = 255;

  /**
   * @description Truncates error message to fit in Error_Message__c field
   * @param errorMessage Error message to truncate
   * @param maxLength Maximum length (defaults to 255)
   * @return String Truncated error message with "..." suffix if needed
   */
  public static String truncateErrorMessage(
    String errorMessage,
    Integer maxLength
  ) {
    if (String.isBlank(errorMessage)) {
      return errorMessage;
    }

    Integer effectiveMaxLength = maxLength != null &&
      maxLength > 0
      ? maxLength
      : MAX_ERROR_MESSAGE_LENGTH;

    if (errorMessage.length() <= effectiveMaxLength) {
      return errorMessage;
    }

    // Leave room for "..."
    Integer truncateLength = effectiveMaxLength - 3;
    return errorMessage.substring(0, truncateLength) + '...';
  }

  /**
   * @description Truncates error message using default max length (255)
   * @param errorMessage Error message to truncate
   * @return String Truncated error message
   */
  public static String truncateErrorMessage(String errorMessage) {
    return truncateErrorMessage(errorMessage, MAX_ERROR_MESSAGE_LENGTH);
  }

  /**
   * @description Updates execution record status only (minimal update fallback strategy)
   * Used when full update fails due to DML limits or field access issues
   * @param executionId ID of the execution record to update
   * @param status Status to set (e.g., 'Failed', 'Completed')
   * @return Boolean True if update succeeded, false otherwise
   */
  public static Boolean updateStatusOnly(Id executionId, String status) {
    if (executionId == null || String.isBlank(status)) {
      return false;
    }

    try {
      JT_RunAsTest_Execution__c minimalUpdate = new JT_RunAsTest_Execution__c(
        Id = executionId,
        Test_Status__c = status
      );
      update minimalUpdate;
      return true;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ Minimal update failed: ' + e.getMessage()
      );
      return false;
    }
  }

  /**
   * @description Updates execution record with error status and message using robust fallback strategy
   * CRITICAL: This method MUST succeed to prevent records from staying in 'Queued' state
   * Uses multiple fallback strategies to ensure update succeeds even under DML limits
   * @param executionId ID of the execution record to update
   * @param errorMessage Error message to store (will be truncated if too long)
   * @param context Context where error occurred (for logging)
   * @return Boolean True if update succeeded, false if all strategies failed
   */
  public static Boolean updateExecutionWithError(
    Id executionId,
    String errorMessage,
    String context
  ) {
    if (executionId == null) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ Cannot update execution: executionId is null'
      );
      return false;
    }

    String truncatedError = truncateErrorMessage(errorMessage);

    // Strategy 1: Try with fresh query and minimal fields
    try {
      List<JT_RunAsTest_Execution__c> executions = [
        SELECT Id, Test_Status__c, Error_Message__c
        FROM JT_RunAsTest_Execution__c
        WHERE Id = :executionId
        LIMIT 1
      ];

      if (!executions.isEmpty()) {
        executions[0].Test_Status__c = 'Failed';
        executions[0].Error_Message__c = truncatedError;
        update executions[0];
        return true;
      }
    } catch (DmlException dmlEx) {
      Map<String, Object> details = new Map<String, Object>{
        'dmlStatusCode' => dmlEx.getDmlStatusCode(0),
        'dmlFields' => dmlEx.getDmlFields(0),
        'executionId' => executionId,
        'errorMessage' => errorMessage,
        'context' => context
      };
      JT_ErrorLogger.logError(
        'DML Update Failed',
        dmlEx.getMessage(),
        dmlEx,
        String.isNotBlank(context)
          ? context + '.updateExecutionWithError'
          : 'JT_ExecutionUpdateUtil.updateExecutionWithError',
        JSON.serialize(details),
        'Critical'
      );

      // Strategy 2: Try with minimal update (only status)
      if (updateStatusOnly(executionId, 'Failed')) {
        return true;
      }

      JT_ErrorLogger.logError(
        'DML Update Failed - All Strategies',
        dmlEx.getMessage(),
        dmlEx,
        String.isNotBlank(context)
          ? context + '.updateExecutionWithError (Strategy 2)'
          : 'JT_ExecutionUpdateUtil.updateExecutionWithError (Strategy 2)',
        JSON.serialize(new Map<String, Object>{ 'executionId' => executionId }),
        'Critical'
      );
    } catch (Exception updateEx) {
      JT_ErrorLogger.logError(
        'Execution Update Failed',
        updateEx.getMessage(),
        updateEx,
        String.isNotBlank(context)
          ? context + '.updateExecutionWithError'
          : 'JT_ExecutionUpdateUtil.updateExecutionWithError'
      );
      System.debug(
        LoggingLevel.ERROR,
        'Stack trace: ' + updateEx.getStackTraceString()
      );

      // Strategy 2: Try with minimal update (only status)
      if (updateStatusOnly(executionId, 'Failed')) {
        return true;
      }
    }

    System.debug(
      LoggingLevel.ERROR,
      '❌ CRITICAL: All update strategies failed for execution: ' + executionId
    );
    System.debug(
      LoggingLevel.ERROR,
      Label.JT_RunAsTestEnqueuer_recordInconsistentState
    );

    return false;
  }

  /**
   * @description Updates execution record with error status and message (without context)
   * @param executionId ID of the execution record to update
   * @param errorMessage Error message to store
   * @return Boolean True if update succeeded, false otherwise
   */
  public static Boolean updateExecutionWithError(
    Id executionId,
    String errorMessage
  ) {
    return updateExecutionWithError(executionId, errorMessage, null);
  }

  /**
   * @description Updates execution record with error status and message for processing errors (CPU/DML limit)
   * @param executionId ID of the execution record to update
   * @param errorMessage Error message to store
   * @param context Context where error occurred
   * @return Boolean True if update succeeded, false otherwise
   */
  public static Boolean updateExecutionWithProcessingError(
    Id executionId,
    String errorMessage,
    String context
  ) {
    return updateExecutionWithError(
      executionId,
      'Processing Error (CPU/DML Limit): ' + errorMessage,
      context
    );
  }

  /**
   * @description Updates execution record with error status and message for processing errors (without context)
   * @param executionId ID of the execution record to update
   * @param errorMessage Error message to store
   * @return Boolean True if update succeeded, false otherwise
   */
  public static Boolean updateExecutionWithProcessingError(
    Id executionId,
    String errorMessage
  ) {
    return updateExecutionWithProcessingError(executionId, errorMessage, null);
  }
}
