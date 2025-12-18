/**
 * @description Callback class for Metadata API deployments
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 12-13-2025
 * @last modified by Jaime Terrats
 **/
public class JT_MetadataDeployCallback implements Metadata.DeployCallback {
  /**
   * @description Handles the result of a metadata deployment
   * @param result The deployment result
   * @param context The deployment callback context
   **/
  public void handleResult(
    Metadata.DeployResult result,
    Metadata.DeployCallbackContext context
  ) {
    Id jobId = context != null ? context.getCallbackJobId() : null;
    processDeploymentResult(result, jobId);
  }

  /**
   * @description Processes deployment result - extracted for testability
   * @param result The deployment result
   * @param jobId The deployment job ID
   * @TestVisible
   **/
  @TestVisible
  private void processDeploymentResult(Metadata.DeployResult result, Id jobId) {
    if (result == null) {
      return;
    }

    switch on result.status {
      when Succeeded {
        handleSuccess(jobId);
      }
      when SucceededPartial {
        handlePartialSuccess(result, jobId);
      }
      when Failed {
        handleFailure(result, jobId);
      }
      when Canceled {
        handleCanceled(jobId);
      }
      when Pending, InProgress, Canceling {
        handleInProgress(result, jobId);
      }
    }
  }

  /**
   * @description Handles successful deployment
   * @param jobId The deployment job ID
   * @TestVisible
   **/
  @TestVisible
  private void handleSuccess(Id jobId) {
    System.debug(
      LoggingLevel.INFO,
      'Metadata deployment succeeded. Job ID: ' + jobId
    );
  }

  /**
   * @description Handles partially successful deployment
   * @param result The deployment result
   * @param jobId The deployment job ID
   * @TestVisible
   **/
  @TestVisible
  private void handlePartialSuccess(Metadata.DeployResult result, Id jobId) {
    System.debug(
      LoggingLevel.WARN,
      'Metadata deployment partially succeeded. Job ID: ' + jobId
    );
    if (result.details != null && result.details.componentFailures != null) {
      for (Metadata.DeployMessage failure : result.details.componentFailures) {
        System.debug(
          LoggingLevel.ERROR,
          'Component failure: ' +
          failure.fullName +
          ' - ' +
          failure.problem
        );
      }
    }
  }

  /**
   * @description Handles failed deployment
   * @param result The deployment result
   * @param jobId The deployment job ID
   * @TestVisible
   **/
  @TestVisible
  private void handleFailure(Metadata.DeployResult result, Id jobId) {
    System.debug(
      LoggingLevel.ERROR,
      'Metadata deployment failed. Job ID: ' + jobId
    );
    if (result.details != null && result.details.componentFailures != null) {
      for (Metadata.DeployMessage failure : result.details.componentFailures) {
        logDeploymentFailure(failure, jobId);
      }
    }
  }

  /**
   * @description Logs deployment failure to error logger
   * @param failure The deployment failure message
   * @param jobId The deployment job ID
   * @TestVisible
   **/
  @TestVisible
  private void logDeploymentFailure(
    Metadata.DeployMessage failure,
    Id jobId
  ) {
    String errorMsg = 'Deployment failed: ' + failure.fullName;
    if (String.isNotBlank(failure.problem)) {
      errorMsg += ' - ' + failure.problem;
    }
    JT_ErrorLogger.logError(
      'Metadata Deployment Failed',
      errorMsg,
      null,
      'JT_MetadataDeployCallback.handleResult',
      JSON.serialize(
        new Map<String, Object>{
          'jobId' => jobId,
          'fullName' => failure.fullName,
          'problem' => failure.problem,
          'problemType' => failure.problemType != null
            ? String.valueOf(failure.problemType)
            : null
        }
      ),
      'High'
    );
  }

  /**
   * @description Handles canceled deployment
   * @param jobId The deployment job ID
   * @TestVisible
   **/
  @TestVisible
  private void handleCanceled(Id jobId) {
    System.debug(
      LoggingLevel.WARN,
      'Metadata deployment canceled. Job ID: ' + jobId
    );
  }

  /**
   * @description Handles in-progress deployment
   * @param result The deployment result
   * @param jobId The deployment job ID
   * @TestVisible
   **/
  @TestVisible
  private void handleInProgress(Metadata.DeployResult result, Id jobId) {
    System.debug(
      LoggingLevel.INFO,
      'Metadata deployment in progress. Status: ' +
      result.status +
      ', Job ID: ' +
      jobId
    );
  }
}




