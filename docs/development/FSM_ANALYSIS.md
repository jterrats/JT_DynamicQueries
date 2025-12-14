# Analysis: Finite State Machine (FSM) for JT_DynamicQueries

## Current State

### Existing States (Test_Status\_\_c)

- `Queued`: Execution created, waiting for processing
- `Running`: Execution in progress
- `Completed`: Successful execution with results
- `Failed`: Failed execution
- `Expired`: Timeout or abandoned execution

### Current Flow

```
1. LWC → executeAsUser()
   ↓
2. Queued (creates JT_RunAsTest_Execution__c)
   ↓
3. Running (updates before enqueue Queueable)
   ↓
4. Queueable.execute()
   ↓
5. Tooling API callout (runTestsSynchronous)
   ↓
6. Extracts Debug Log (REST API)
   ↓
7. Parses JSON from log
   ↓
8. Completed/Failed (updates record)
   ↓
9. LWC polling detects change
```

## Proposal: Lightweight FSM (Recommended)

### Option 1: Only Improve Transition Validation (Minimum)

**Advantages:**

- Low overhead
- Prevents invalid states
- Easy to implement

**Implementation:**

```apex
public class ExecutionStateManager {
  private static final Map<String, Set<String>> VALID_TRANSITIONS = new Map<String, Set<String>>{
    'Queued' => new Set<String>{ 'Running', 'Failed', 'Expired' },
    'Running' => new Set<String>{ 'Completed', 'Failed', 'Expired' },
    'Completed' => new Set<String>{}, // Final state
    'Failed' => new Set<String>{}, // Final state
    'Expired' => new Set<String>{} // Final state
  };

  public static Boolean isValidTransition(String fromState, String toState) {
    Set<String> allowedStates = VALID_TRANSITIONS.get(fromState);
    return allowedStates != null && allowedStates.contains(toState);
  }

  public static void transition(
    JT_RunAsTest_Execution__c execution,
    String newState
  ) {
    String currentState = execution.Test_Status__c;
    if (!isValidTransition(currentState, newState)) {
      throw new StateTransitionException(
        'Invalid transition from ' + currentState + ' to ' + newState
      );
    }
    execution.Test_Status__c = newState;
  }
}
```

### Option 2: Complete FSM with Sub-States (Complete)

**Advantages:**

- Maximum process visibility
- Better debugging
- Robust error handling

**Disadvantages:**

- More complexity
- More fields in object
- Possible over-engineering

**Implementation:**

```apex
// Add Sub_Status__c (Text) field to object

public enum ExecutionSubState {
    INITIALIZING,
    WAITING_FOR_QUEUEABLE,
    EXECUTING_TEST,
    EXTRACTING_LOG,
    PARSING_RESULTS,
    STORING_DATA,
    FINALIZING
}

public class ExecutionStateManager {
    public static void transitionToSubState(
        JT_RunAsTest_Execution__c execution,
        ExecutionSubState subState
    ) {
        execution.Sub_Status__c = subState.name();
        // Log for debugging
        addStateLog(execution, 'Transitioned to: ' + subState.name());
    }
}
```

## Final Recommendation

### ✅ Implement: Option 1 (Transition Validation)

**Reasons:**

1. **Cost/Benefit:** Low cost, high benefit
2. **Simplicity:** No object changes required
3. **Bug Prevention:** Prevents invalid states
4. **Maintainability:** Easy to understand and maintain

### ❌ Don't Implement (For Now): Option 2 (Complete FSM)

**Reasons:**

1. **Over-Engineering:** Current flow works well
2. **Complexity:** Adds complexity without immediate need
3. **YAGNI:** "You Aren't Gonna Need It" - solve problems when they appear

### When to Consider Complete FSM

Consider implementing complete FSM if:

- ✅ You need automatic retries
- ✅ You have multiple complex parallel flows
- ✅ You need detailed audit of each step
- ✅ You have frequent inconsistent state problems

## Conclusion

**For your current project:**

- ✅ Implement transition validation (Option 1)
- ❌ Don't implement complete FSM (Option 2) - for now

**Current code already has a functional implicit FSM.**
**What's missing is explicit transition validation, not a complete rewrite.**
