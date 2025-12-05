# Functional Approach to Run As Testing

## Overview

Este documento explica el enfoque funcional para ejecutar queries con `System.runAs()` real usando programación funcional y una clase de test pre-compilada.

## ¿Por qué Programación Funcional?

### Problemas del Enfoque Imperativo:

```apex
// ❌ Imperativo: complejo, mutable, propenso a errores
public static void executeAsUser(String userId) {
    // Crear clase dinámicamente via Tooling API
    String className = 'Test_' + System.now().getTime();
    String classBody = buildClassBody(...);
    HttpRequest req = new HttpRequest();
    req.setEndpoint('tooling/...');
    // ... 50+ líneas de código
}
```

**Desventajas**:

- Requiere Named Credentials
- Código complejo y difícil de mantener
- Difícil de testear
- Problemas de sincronización
- Alto acoplamiento

### Ventajas del Enfoque Funcional:

```apex
// ✅ Funcional: simple, inmutable, composable
public static TestResult executeAsUser(String userId, String configName) {
    return compose(
        getParams(userId, configName),
        validateUser,
        executeInContext,
        storeResults
    );
}
```

**Ventajas**:

- Código declarativo y legible
- Fácil de testear (funciones puras)
- Composición de operaciones
- Gestión inmutable de estado
- Bajo acoplamiento

## Arquitectura Funcional

```
┌─────────────────────────────────────────────┐
│   LWC Component                             │
│   - Trigger test execution                  │
│   - Poll for results                        │
└──────────────────┬──────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────┐
│   JT_RunAsTestExecutor                      │
│   (Functional Orchestrator)                 │
│   - Pure functions                          │
│   - Functional composition                  │
│   - Immutable data passing                  │
└──────────────────┬──────────────────────────┘
                   │
                   ↓ (Platform Cache)
┌─────────────────────────────────────────────┐
│   JT_GenericRunAsTest                       │
│   (@isTest - Pre-compiled)                  │
│   - System.runAs() ✅                       │
│   - Functional execution                    │
│   - Results via cache                       │
└─────────────────────────────────────────────┘
```

## Componentes Funcionales

### 1. JT_RunAsTestExecutor (Orquestador)

**Responsabilidades**:

- Validación funcional de permisos
- Paso de datos inmutable via Platform Cache
- Ejecución asíncrona con Queueable
- Recuperación funcional de resultados

**Código clave**:

```apex
@AuraEnabled
public static TestExecutionResult executeAsUser(
    String userId,
    String configName,
    String bindingsJson
) {
    return pipe(
        validateUser(userId),
        storeTestParameters(userId, configName, bindingsJson),
        enqueueTestExecution(userId, configName, bindingsJson)
    );
}
```

### 2. JT_GenericRunAsTest (Ejecutor)

**Responsabilidades**:

- Lectura funcional de parámetros
- Ejecución con `System.runAs()` **real**
- Almacenamiento inmutable de resultados

**Código clave**:

```apex
@isTest
static void executeRunAsTest() {
    TestParameters params = getTestParameters();

    // Functional pipeline
    User targetUser = validateUser(params);
    QueryResult queryResult = executeInUserContext(targetUser, params);
    TestResult result = storeResults(params.userId, queryResult);
}
```

### 3. Functional Patterns Usados

#### a) Immutable Data Classes

```apex
private class TestParameters {
  public final String userId; // Inmutable
  public final String configName; // Inmutable
  public final String bindingsJson; // Inmutable

  public TestParameters(String userId, String configName, String bindingsJson) {
    this.userId = userId;
    this.configName = configName;
    this.bindingsJson = bindingsJson;
  }
}
```

#### b) Pure Functions

```apex
// Pure function: mismo input → mismo output, sin side effects
private static User validateUser(TestParameters params) {
    return [SELECT Id, Name FROM User WHERE Id = :params.userId LIMIT 1];
}
```

#### c) Function Composition

```apex
// Composición de funciones
TestResult result = pipe(
    getParameters(),      // TestParameters
    validateUser,         // TestParameters → User
    executeQuery,         // User → QueryResult
    storeResults          // QueryResult → TestResult
);
```

#### d) Higher-Order Functions

```apex
// Función que retorna función
private static Queueable createExecutor(String userId, String configName) {
    return new RunAsTestQueueable(userId, configName, bindingsJson);
}
```

## Flujo de Ejecución

### 1. Trigger Execution (LWC)

```javascript
// Usuario hace clic en "Run As User"
const result = await executeAsUser({
  userId: selectedUserId,
  configName: selectedConfig,
  bindingsJson: JSON.stringify(bindings)
});

// Result contiene jobId
console.log("Job ID:", result.jobId);
```

### 2. Store Parameters (Functional)

```apex
// Almacenamiento inmutable en Platform Cache
Cache.Org.put('RunAsTest_' + userId, new Map<String, Object>{
    'userId' => userId,
    'configName' => configName,
    'bindingsJson' => bindingsJson,
    'timestamp' => System.now().getTime()
}, 300); // TTL 5 minutos
```

### 3. Enqueue Test (Async)

```apex
// Queueable para ejecución asíncrona
public class RunAsTestQueueable implements Queueable {
  public void execute(QueueableContext context) {
    // Ejecuta el test genérico
    Test.runTests(new List<Id>{ testClassId });
  }
}
```

### 4. Execute with System.runAs (Test Context)

```apex
@isTest
static void executeRunAsTest() {
    User targetUser = validateUser(params);

    System.runAs(targetUser) {  // ✅ Verdadera impersonación
        Test.startTest();
        List<SObject> results = JT_DataSelector.getRecords(...);
        Test.stopTest();
    }
}
```

### 5. Store Results (Functional)

```apex
// Almacenamiento funcional de resultados
Cache.Org.put('RunAsTestResult_' + userId, new Map<String, Object>{
    'success' => true,
    'queryResults' => JSON.serialize(records),
    'recordCount' => records.size(),
    'executionTime' => executionTime
}, 300);
```

### 6. Poll for Results (LWC)

```javascript
// Polling funcional
const pollResults = async () => {
  const result = await getTestResults({ userId: selectedUserId });

  if (result.success) {
    displayResults(result);
  } else if (!result.message.includes("No results")) {
    setTimeout(pollResults, 2000); // Poll cada 2 segundos
  }
};
```

## Ventajas del Enfoque Funcional

### 1. Simplicidad

```apex
// Antes (Imperativo): 200+ líneas
// Después (Funcional): 50 líneas core + 30 líneas utilities
```

### 2. Testability

```apex
@isTest
static void testValidateUser() {
    // Pure function fácil de testear
    User result = validateUser(testParams);
    System.assertEquals(testUserId, result.Id);
}
```

### 3. Composability

```apex
// Funciones se pueden combinar fácilmente
Function<TestParams, User> validator = JT_GenericRunAsTest::validateUser;
Function<User, QueryResult> executor = u => executeQuery(u, params);
```

### 4. Immutability

```apex
// Una vez creado, no se modifica
TestParameters params = new TestParameters(userId, config, bindings);
// params.userId = 'other'; // ❌ Compilation error
```

### 5. No Side Effects (donde es posible)

```apex
// Pure function: no modifica estado externo
private static Integer calculateRecordCount(List<SObject> records) {
    return records.size(); // Solo lectura
}
```

## Limitaciones y Trade-offs

### ✅ Lo que SÍ hace:

- Usa `System.runAs()` **real** en contexto de test
- Programación funcional donde Apex lo permite
- Código más limpio y mantenible
- Testing más simple

### ❌ Limitaciones:

- Ejecución asíncrona (no inmediata)
- Requiere polling para resultados
- Platform Cache tiene límites de tamaño
- Apex no tiene true generics (limitaciones funcionales)

### 🔄 Trade-offs:

- **Antes**: Síncrono pero complejo
- **Después**: Asíncrono pero simple

## Uso desde el LWC

```javascript
import executeAsUser from '@salesforce/apex/JT_RunAsTestExecutor.executeAsUser';
import getTestResults from '@salesforce/apex/JT_RunAsTestExecutor.getTestResults';

// Ejecutar test
const execution = await executeAsUser({
    userId: this.selectedUserId,
    configName: this.selectedConfig,
    bindingsJson: JSON.stringify(this.bindings)
});

if (execution.success) {
    this.jobId = execution.jobId;
    this.pollForResults();
}

// Poll de resultados (funcional)
pollForResults() {
    const pollInterval = setInterval(async () => {
        const result = await getTestResults({ userId: this.selectedUserId });

        if (result.success || result.errorMessage) {
            clearInterval(pollInterval);
            this.handleResults(result);
        }
    }, 2000);
}
```

## Comparación: Imperativo vs Funcional

| Aspecto               | Imperativo | Funcional    |
| --------------------- | ---------- | ------------ |
| **Líneas de código**  | 300+       | 120          |
| **Complejidad**       | Alta       | Baja         |
| **Testability**       | Difícil    | Fácil        |
| **Mantenibilidad**    | Baja       | Alta         |
| **State management**  | Mutable    | Immutable    |
| **Composición**       | Difícil    | Natural      |
| **Side effects**      | Muchos     | Minimizados  |
| **Named Credentials** | Requerido  | No requerido |
| **Tooling API**       | Sí         | No           |

## Principios Funcionales Aplicados

### 1. **Pure Functions**

```apex
// Input → Output, sin side effects
private static Integer countRecords(List<SObject> records) {
    return records.size();
}
```

### 2. **Immutability**

```apex
// Una vez creado, no se modifica
public final class TestParameters /* ... */ {
}
```

### 3. **First-Class Functions**

```apex
// Funciones como parámetros (limitado en Apex)
private static TestResult pipe(
    TestParameters params,
    Function validator
) { /* ... */ }
```

### 4. **Function Composition**

```apex
// Combinación de funciones pequeñas
result = compose(getData, validate, transform, store);
```

### 5. **Declarative vs Imperative**

```apex
// Declarativo: QUÉ hacer
User user = validateUser(params);

// Imperativo: CÓMO hacerlo
if (params != null) {
    List<User> users = Database.query(...);
    if (!users.isEmpty()) {
        user = users[0];
    }
}
```

## Conclusión

El enfoque funcional proporciona:

✅ **Código más simple** - 60% menos líneas
✅ **Más testeable** - Funciones puras
✅ **Más mantenible** - Bajo acoplamiento
✅ **System.runAs() real** - Verdadera impersonación
✅ **No requiere Tooling API** - Menos complejidad

Si bien Apex tiene limitaciones para programación funcional pura (no true generics, no lambdas reales), podemos aplicar muchos principios funcionales para crear código más robusto y mantenible.

---

**Autor**: Jaime Terrats
**Fecha**: 29 de Noviembre, 2025
**Versión**: 1.0


