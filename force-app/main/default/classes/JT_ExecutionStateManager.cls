/**
 * @description State transition validator for JT_RunAsTest_Execution__c
 * Prevents invalid state transitions and ensures state consistency
 * @author Jaime Terrats
 * @group Dynamic Queries
 */
public class JT_ExecutionStateManager {
  /**
   * @description Execution state constants
   */
  public static final String STATE_QUEUED = 'Queued';
  public static final String STATE_RUNNING = 'Running';
  public static final String STATE_COMPLETED = 'Completed';
  public static final String STATE_FAILED = 'Failed';
  public static final String STATE_EXPIRED = 'Expired';

  /**
   * @description Valid state transitions map
   * Key: Current state, Value: Set of allowed next states
   */
  private static final Map<String, Set<String>> VALID_TRANSITIONS = new Map<String, Set<String>>{
    STATE_QUEUED => new Set<String>{
      STATE_RUNNING,
      STATE_FAILED,
      STATE_EXPIRED
    },
    STATE_RUNNING => new Set<String>{
      STATE_COMPLETED,
      STATE_FAILED,
      STATE_EXPIRED
    },
    STATE_COMPLETED => new Set<String>{}, // Final state
    STATE_FAILED => new Set<String>{}, // Final state
    STATE_EXPIRED => new Set<String>{} // Final state
  };

  /**
   * @description Validates if a state transition is allowed
   * @param fromState Current state
   * @param toState Desired next state
   * @return Boolean True if transition is valid
   */
  public static Boolean isValidTransition(String fromState, String toState) {
    if (String.isBlank(fromState) || String.isBlank(toState)) {
      return false;
    }

    Set<String> allowedStates = VALID_TRANSITIONS.get(fromState);
    if (allowedStates == null) {
      return false; // Unknown current state
    }

    return allowedStates.contains(toState);
  }

  /**
   * @description Transitions execution record to new state with validation
   * @param execution Execution record to update
   * @param newState Target state
   * @throws StateTransitionException if transition is invalid
   */
  public static void transition(
    JT_RunAsTest_Execution__c execution,
    String newState
  ) {
    String currentState = execution.Test_Status__c;

    if (!isValidTransition(currentState, newState)) {
      String errorMessage = String.format(
        Label.JT_ExecutionStateManager_invalidTransition,
        new List<String>{ currentState, newState }
      );
      throw new StateTransitionException(errorMessage);
    }

    execution.Test_Status__c = newState;
  }

  /**
   * @description Custom exception for invalid state transitions
   */
  public class StateTransitionException extends Exception {
  }
}
