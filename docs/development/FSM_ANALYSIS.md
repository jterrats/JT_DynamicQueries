# Análisis: Máquina de Estados Finitos (FSM) para JT_DynamicQueries

## Estado Actual

### Estados Existentes (Test_Status\_\_c)

- `Queued`: Ejecución creada, esperando procesamiento
- `Running`: Ejecución en progreso
- `Completed`: Ejecución exitosa con resultados
- `Failed`: Ejecución fallida
- `Expired`: Timeout o ejecución abandonada

### Flujo Actual

```
1. LWC → executeAsUser()
   ↓
2. Queued (crea JT_RunAsTest_Execution__c)
   ↓
3. Running (actualiza antes de enqueue Queueable)
   ↓
4. Queueable.execute()
   ↓
5. Tooling API callout (runTestsSynchronous)
   ↓
6. Extrae Debug Log (REST API)
   ↓
7. Parsea JSON del log
   ↓
8. Completed/Failed (actualiza registro)
   ↓
9. LWC polling detecta cambio
```

## Propuesta: FSM Ligera (Recomendada)

### Opción 1: Solo Mejorar Validación de Transiciones (Mínimo)

**Ventajas:**

- Bajo overhead
- Previene estados inválidos
- Fácil de implementar

**Implementación:**

```apex
public class ExecutionStateManager {
  private static final Map<String, Set<String>> VALID_TRANSITIONS = new Map<String, Set<String>>{
    'Queued' => new Set<String>{ 'Running', 'Failed', 'Expired' },
    'Running' => new Set<String>{ 'Completed', 'Failed', 'Expired' },
    'Completed' => new Set<String>{}, // Estado final
    'Failed' => new Set<String>{}, // Estado final
    'Expired' => new Set<String>{} // Estado final
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

### Opción 2: FSM Completa con Sub-Estados (Completa)

**Ventajas:**

- Máxima visibilidad del proceso
- Mejor debugging
- Manejo robusto de errores

**Desventajas:**

- Más complejidad
- Más campos en el objeto
- Posible over-engineering

**Implementación:**

```apex
// Agregar campo Sub_Status__c (Text) al objeto

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
        // Log para debugging
        addStateLog(execution, 'Transitioned to: ' + subState.name());
    }
}
```

## Recomendación Final

### ✅ Implementar: Opción 1 (Validación de Transiciones)

**Razones:**

1. **Costo/Beneficio:** Bajo costo, alto beneficio
2. **Simplicidad:** No requiere cambios en el objeto
3. **Prevención de Bugs:** Evita estados inválidos
4. **Mantenibilidad:** Fácil de entender y mantener

### ❌ No Implementar (Por Ahora): Opción 2 (FSM Completa)

**Razones:**

1. **Over-Engineering:** El flujo actual funciona bien
2. **Complejidad:** Añade complejidad sin necesidad inmediata
3. **YAGNI:** "You Aren't Gonna Need It" - resolver problemas cuando aparezcan

### Cuándo Considerar FSM Completa

Considera implementar FSM completa si:

- ✅ Necesitas reintentos automáticos
- ✅ Tienes múltiples flujos paralelos complejos
- ✅ Necesitas auditoría detallada de cada paso
- ✅ Tienes problemas frecuentes de estados inconsistentes

## Conclusión

**Para tu proyecto actual:**

- ✅ Implementa validación de transiciones (Opción 1)
- ❌ No implementes FSM completa (Opción 2) - por ahora

**El código actual ya tiene una FSM implícita funcional.**
**Lo que falta es validación explícita de transiciones, no una reescritura completa.**
