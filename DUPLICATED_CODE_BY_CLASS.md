# Revisión de Código Duplicado - Clase por Clase

**Fecha:** 2025-12-14
**Método:** Revisión manual clase por clase buscando código duplicado dentro de cada clase

---

## 1. JT_DataSelector.cls (804 líneas)

### ❌ Duplicación 1: Deserialización de Bindings del Config
**Líneas:** 204-206, 411-413, 610-612, 724-726

**Código Duplicado:**
```apex
Map<String, Object> bindings = String.isNotBlank(config.JT_Binding__c)
  ? (Map<String, Object>) JSON.deserializeUntyped(config.JT_Binding__c)
  : new Map<String, Object>();
```

**Lugares:**
- Línea 204: `getRecords(String devName, Boolean enforceSecurity)`
- Línea 411: `processRecordsWithCursor(CursorProcessingParams params)`
- Línea 610: `countRecordsForConfig(...)`
- Línea 724: `getRecordsWithAutoStrategy(AutoStrategyParams params)`

**Impacto:** ~12 líneas duplicadas (3 líneas × 4 lugares)

**Solución:** Extraer a método privado:
```apex
private static Map<String, Object> getConfigBindings(JT_DynamicQueryConfiguration__mdt config) {
  return String.isNotBlank(config.JT_Binding__c)
    ? (Map<String, Object>) JSON.deserializeUntyped(config.JT_Binding__c)
    : new Map<String, Object>();
}
```

---

### ❌ Duplicación 2: Merge de Bindings
**Líneas:** 414-419, 613-618, 727-732

**Código Duplicado:**
```apex
Map<String, Object> mergedBindings = new Map<String, Object>(configBindings);
if (params.bindings != null) {
  mergedBindings.putAll(params.bindings);
}
```

**Lugares:**
- Línea 414: `processRecordsWithCursor`
- Línea 613: `countRecordsForConfig`
- Línea 727: `getRecordsWithAutoStrategy`

**Impacto:** ~9 líneas duplicadas (3 líneas × 3 lugares)

**Solución:** Extraer a método privado:
```apex
private static Map<String, Object> mergeBindings(
  Map<String, Object> configBindings,
  Map<String, Object> customBindings
) {
  Map<String, Object> merged = new Map<String, Object>(configBindings);
  if (customBindings != null) {
    merged.putAll(customBindings);
  }
  return merged;
}
```

---

### ❌ Duplicación 3: Determinación de AccessLevel
**Líneas:** 209-211, 421-423, 652-654

**Código Duplicado:**
```apex
AccessLevel accessMode = enforceSecurity
  ? AccessLevel.USER_MODE
  : AccessLevel.SYSTEM_MODE;
```

**Lugares:**
- Línea 209: `getRecords(String, Boolean)`
- Línea 421: `processRecordsWithCursor`
- Línea 652: `countRecordsInternal`

**Impacto:** ~6 líneas duplicadas (2 líneas × 3 lugares)

**Solución:** Extraer a método privado:
```apex
private static AccessLevel getAccessLevel(Boolean enforceSecurity) {
  return enforceSecurity ? AccessLevel.USER_MODE : AccessLevel.SYSTEM_MODE;
}
```

---

**Total en JT_DataSelector:** ~27 líneas duplicadas

---

## 2. JT_QueryViewerController.cls (888 líneas)

### ❌ Duplicación 1: Deserialización de Bindings JSON
**Líneas:** 69-71, 193-195, 513-515, 692-694

**Código Duplicado:**
```apex
Map<String, Object> bindings = String.isNotBlank(bindingsJson)
  ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
  : new Map<String, Object>();
```

**Lugares:**
- Línea 69: `executeQuery`
- Línea 193: `executeQueryPreview`
- Línea 513: `assessQueryRisk`
- Línea 692: `executeQueryWithBatchProcessing`

**Impacto:** ~12 líneas duplicadas (3 líneas × 4 lugares)

**Solución:** Ya existe `JT_QueryBindingUtil.processBindings()` pero solo se usa en algunos lugares. Usar en todos:
```apex
// Reemplazar con:
Map<String, Object> bindings = JT_QueryBindingUtil.processBindings(query, bindingsJson);
// O crear método sobrecargado que solo deserializa si no hay query
```

---

### ❌ Duplicación 2: Serialización de Records para LWC
**Líneas:** 107-108, 736-737

**Código Duplicado:**
```apex
String recordsJson = JSON.serialize(sobjectRecords);
result.records = (List<Object>) JSON.deserializeUntyped(recordsJson);
```

**Lugares:**
- Línea 107: `executeQuery`
- Línea 736: `executeQueryWithBatchProcessing`

**Impacto:** ~4 líneas duplicadas (2 líneas × 2 lugares)

**Solución:** Ya existe método `serializeRecordsForLWC()` en línea 165. Usar en ambos lugares:
```apex
result.records = serializeRecordsForLWC(sobjectRecords);
```

---

### ❌ Duplicación 3: Manejo de Errores con QueryResult
**Líneas:** 123-128, 244-249, 749-754

**Código Duplicado:**
```apex
QueryResult result = new QueryResult();
result.success = false;
result.errorMessage = e.getMessage();
result.records = new List<Object>();
result.recordCount = 0;
return result;
```

**Lugares:**
- Línea 123: `executeQuery` catch block
- Línea 244: `executeQueryPreview` catch block
- Línea 749: `executeQueryWithBatchProcessing` catch block

**Impacto:** ~15 líneas duplicadas (5 líneas × 3 lugares)

**Solución:** Extraer a método privado:
```apex
private static QueryResult createErrorResult(Exception e) {
  QueryResult result = new QueryResult();
  result.success = false;
  result.errorMessage = e.getMessage();
  result.records = new List<Object>();
  result.recordCount = 0;
  return result;
}
```

---

### ❌ Duplicación 4: Query de Config con Mismo SELECT
**Líneas:** 74-80, 204-210, 518-524, 697-703

**Código Duplicado:**
```apex
JT_DynamicQueryConfiguration__mdt config = [
  SELECT JT_BaseQuery__c
  FROM JT_DynamicQueryConfiguration__mdt
  WHERE DeveloperName = :devName
  WITH USER_MODE
  LIMIT 1
];
```

**Lugares:**
- Línea 74: `executeQuery` (solo JT_BaseQuery__c)
- Línea 204: `executeQueryPreview` (JT_BaseQuery__c, JT_ObjectName__c)
- Línea 518: `assessQueryRisk` (JT_BaseQuery__c, JT_ObjectName__c, JT_Binding__c)
- Línea 697: `executeQueryWithBatchProcessing` (solo JT_BaseQuery__c)

**Impacto:** ~28 líneas duplicadas (7 líneas × 4 lugares, con variaciones en campos)

**Solución:** Usar selector layer `JT_ConfigurationSelector` o crear métodos sobrecargados:
```apex
private static JT_DynamicQueryConfiguration__mdt getConfig(String devName) {
  return JT_ConfigurationSelector.getConfiguration(devName);
}
```

---

**Total en JT_QueryViewerController:** ~59 líneas duplicadas

---

## 3. JT_MetadataCreator.cls (1754 líneas)

### ❌ Duplicación 1: Inicialización de MetadataCreationResult
**Líneas:** 45-52, 192-199, 257-264, 1411-1418

**Código Duplicado:**
```apex
MetadataCreationResult result = new MetadataCreationResult();
// Initialize all fields to ensure proper serialization
result.success = false;
result.message = null;
result.errorMessage = null;
result.stackTrace = null;
result.developerName = null;
result.deploymentId = null;
```

**Lugares:**
- Línea 45: `createConfiguration`
- Línea 192: `deleteConfiguration`
- Línea 257: `updateConfiguration`
- Línea 1411: `handleRename`

**Impacto:** ~32 líneas duplicadas (8 líneas × 4 lugares)

**Solución:** Crear método factory:
```apex
private static MetadataCreationResult createEmptyResult() {
  MetadataCreationResult result = new MetadataCreationResult();
  result.success = false;
  result.message = null;
  result.errorMessage = null;
  result.stackTrace = null;
  result.developerName = null;
  result.deploymentId = null;
  return result;
}
```

---

### ❌ Duplicación 2: Manejo de Error Message con Fallback
**Líneas:** 169-176, 236-243, 405-412

**Código Duplicado:**
```apex
String errorMsg = e.getMessage();
if (String.isBlank(errorMsg)) {
  errorMsg = String.format(
    Label.JT_MetadataCreator_unexpectedError,
    new List<String>{ e.getTypeName() }
  );
}
result.errorMessage = errorMsg;
result.stackTrace = e.getStackTraceString();
```

**Lugares:**
- Línea 169: `createConfiguration` catch block
- Línea 236: `deleteConfiguration` catch block
- Línea 405: `updateConfiguration` catch block

**Impacto:** ~21 líneas duplicadas (7 líneas × 3 lugares)

**Solución:** Extraer a método privado:
```apex
private static void setErrorResult(MetadataCreationResult result, Exception e) {
  String errorMsg = e.getMessage();
  if (String.isBlank(errorMsg)) {
    errorMsg = String.format(
      Label.JT_MetadataCreator_unexpectedError,
      new List<String>{ e.getTypeName() }
    );
  }
  result.errorMessage = errorMsg;
  result.stackTrace = e.getStackTraceString();
}
```

---

### ❌ Duplicación 3: Manejo de Excepciones al Construir XML
**Líneas:** 122-143, 358-379

**Código Duplicado:**
```apex
String metadataXml;
try {
  metadataXml = buildMetadataXml(params);
} catch (IllegalArgumentException iae) {
  result.success = false;
  String iaeMsg = iae.getMessage();
  result.errorMessage = String.isNotBlank(iaeMsg)
    ? iaeMsg
    : Label.JT_MetadataCreator_invalidMetadataParams;
  return result;
} catch (Exception xmlEx) {
  result.success = false;
  String xmlMsg = xmlEx.getMessage();
  String xmlErrorMsg = String.isNotBlank(xmlMsg)
    ? xmlMsg
    : xmlEx.getTypeName();
  result.errorMessage = String.format(
    Label.JT_MetadataCreator_errorBuildingXml,
    new List<String>{ xmlErrorMsg }
  );
  return result;
}
```

**Lugares:**
- Línea 122: `createConfiguration`
- Línea 358: `updateConfiguration`

**Impacto:** ~42 líneas duplicadas (21 líneas × 2 lugares)

**Solución:** Extraer a método privado:
```apex
private static String buildMetadataXmlSafely(
  MetadataParams params,
  MetadataCreationResult result
) {
  try {
    return buildMetadataXml(params);
  } catch (IllegalArgumentException iae) {
    result.success = false;
    String iaeMsg = iae.getMessage();
    result.errorMessage = String.isNotBlank(iaeMsg)
      ? iaeMsg
      : Label.JT_MetadataCreator_invalidMetadataParams;
    return null;
  } catch (Exception xmlEx) {
    result.success = false;
    String xmlMsg = xmlEx.getMessage();
    String xmlErrorMsg = String.isNotBlank(xmlMsg)
      ? xmlMsg
      : xmlEx.getTypeName();
    result.errorMessage = String.format(
      Label.JT_MetadataCreator_errorBuildingXml,
      new List<String>{ xmlErrorMsg }
    );
    return null;
  }
}
```

---

### ❌ Duplicación 4: Validación de Sandbox/Scratch
**Líneas:** 84-88, 203-207, 276-280

**Código Duplicado:**
```apex
if (!isSandboxOrScratch()) {
  result.success = false;
  result.errorMessage = Label.JT_MetadataCreator_creationNotAllowed; // varía el label
  return result;
}
```

**Lugares:**
- Línea 84: `createConfiguration` (Label.JT_MetadataCreator_creationNotAllowed)
- Línea 203: `deleteConfiguration` (Label.JT_MetadataCreator_deletionNotAllowed)
- Línea 276: `updateConfiguration` (Label.JT_MetadataCreator_editingNotAllowed)

**Impacto:** ~12 líneas duplicadas (4 líneas × 3 lugares, con variación en label)

**Solución:** Extraer a método privado:
```apex
private static Boolean validateSandboxOrScratch(
  MetadataCreationResult result,
  String errorLabel
) {
  if (!isSandboxOrScratch()) {
    result.success = false;
    result.errorMessage = errorLabel;
    return false;
  }
  return true;
}
```

---

**Total en JT_MetadataCreator:** ~107 líneas duplicadas

---

## 4. JT_RunAsTestExecutor.cls (770 líneas)

### ❌ Duplicación 1: Cache Operations con JSON Serialization
**Líneas:** 654-668, 674-686, 725-730

**Código Duplicado:**
```apex
final String sanitizedUserId = JT_ToolingApiUtil.toAlphanumeric(userId);

Cache.Org.put(
  'RunAsTestResult' + sanitizedUserId,
  JSON.serialize(
    new Map<String, Object>{
      'success' => true/false,
      'records' => records/null,
      'recordCount' => count/0,
      'errorMessage' => null/errorMsg,
      ...
    }
  ),
  300
);
```

**Lugares:**
- Línea 654: Success case
- Línea 674: Error case
- Línea 725: Finalizer error case

**Impacto:** ~45 líneas duplicadas (15 líneas × 3 lugares, con variaciones en valores)

**Solución:** Crear métodos utilitarios:
```apex
private static void cacheRunAsTestResult(
  String userId,
  Map<String, Object> resultData,
  Integer ttl
) {
  String sanitizedUserId = JT_ToolingApiUtil.toAlphanumeric(userId);
  String cacheKey = 'RunAsTestResult' + sanitizedUserId;
  Cache.Org.put(cacheKey, JSON.serialize(resultData), ttl);
}
```

---

**Total en JT_RunAsTestExecutor:** ~45 líneas duplicadas

---

## 5. JT_UsageFinder.cls (1244 líneas)

### ⚠️ Revisar: Normalización de Config Name
**Líneas:** 552, 825, 1067

**Código Similar:**
```apex
final String normalizedConfigName = configName.toLowerCase();
```

**Lugares:**
- Línea 552: `selectCandidateFlows`
- Línea 825: `findInFlows`
- Línea 1067: `searchFlowMetadata`

**Impacto:** ~3 líneas (1 línea × 3 lugares)

**Conclusión:** No es duplicación real, es una operación simple y necesaria en cada contexto.

---

**Total en JT_UsageFinder:** 0 líneas duplicadas (operaciones simples legítimas)

---

## 6. JT_GenericRunAsTest.cls (718 líneas)

### ❌ Duplicación 1: Deserialización de Bindings JSON
**Línea:** 269-271

**Código Duplicado:**
```apex
Map<String, Object> bindings = String.isNotBlank(params.bindingsJson)
  ? (Map<String, Object>) JSON.deserializeUntyped(params.bindingsJson)
  : new Map<String, Object>();
```

**Impacto:** ~3 líneas duplicadas (ya identificado en análisis de patrones)

**Solución:** Usar `JT_QueryBindingUtil.processBindings()` o método helper.

---

### ⚠️ Duplicación 2: Manejo de Excepciones con Análisis de Error
**Líneas:** 307-334, 337-358, 359-383, 384-415

**Código Similar (no exactamente duplicado):**
Todos los catch blocks hacen:
1. `result.success = false`
2. `String errorMsg = exception.getMessage()`
3. `JT_ErrorMessageUtil.ErrorAnalysisResult analysis = JT_ErrorMessageUtil.analyzeError(...)`
4. Switch sobre `analysis.errorType`
5. `result.stackTrace = exception.getStackTraceString()`

**Lugares:**
- Línea 307: `QueryException` catch
- Línea 337: `SecurityException` catch
- Línea 359: `AuraHandledException` catch
- Línea 384: `Exception` catch genérico

**Impacto:** ~80 líneas con estructura similar pero diferentes labels

**Conclusión:** No es duplicación exacta, cada catch maneja diferentes tipos de excepciones con diferentes mensajes. La estructura es similar pero necesaria para manejar diferentes casos.

---

**Total en JT_GenericRunAsTest:** ~3 líneas duplicadas (deserialización de bindings)

---

## 7. JT_RunAsTestEnqueuer.cls (645 líneas)

### ❌ Duplicación 1: Manejo de Excepciones al Deserializar JSON
**Líneas:** 136-158, 160-182

**Código Duplicado:**
```apex
} catch (JSONException jsonEx) {
  Map<String, Object> details = new Map<String, Object>{
    'responseStatusCode' => response.getStatusCode(),
    'responseBodyLength' => response.getBody() != null ? response.getBody().length() : 0,
    'executionId' => this.executionId
  };
  JT_ErrorLogger.logError(
    'Tooling API JSON Deserialization Failed',
    jsonEx.getMessage(),
    jsonEx,
    'JT_RunAsTestEnqueuer.executeTestSynchronously',
    JSON.serialize(details),
    'High'
  );
  JT_ExecutionUpdateUtil.updateExecutionWithProcessingError(
    this.executionId,
    'JSON deserialization failed (CPU limit): ' + jsonEx.getMessage(),
    'JT_RunAsTestEnqueuer.executeTestSynchronously'
  );
  return false;
} catch (Exception deserializeEx) {
  // Similar structure with different error message
}
```

**Lugares:**
- Línea 136: `JSONException` catch
- Línea 160: `Exception` catch para deserialización

**Impacto:** ~46 líneas duplicadas (23 líneas × 2 lugares, con variaciones menores)

**Solución:** Extraer a método privado:
```apex
private Boolean handleDeserializationError(Exception e, HttpResponse response, String errorType) {
  Map<String, Object> details = new Map<String, Object>{
    'responseStatusCode' => response.getStatusCode(),
    'responseBodyLength' => response.getBody() != null ? response.getBody().length() : 0,
    'executionId' => this.executionId,
    'errorType' => errorType
  };
  JT_ErrorLogger.logError(
    'Tooling API ' + errorType + ' Failed',
    e.getMessage(),
    e,
    'JT_RunAsTestEnqueuer.executeTestSynchronously',
    JSON.serialize(details),
    'High'
  );
  JT_ExecutionUpdateUtil.updateExecutionWithProcessingError(
    this.executionId,
    errorType + ' failed (CPU limit): ' + e.getMessage(),
    'JT_RunAsTestEnqueuer.executeTestSynchronously'
  );
  return false;
}
```

---

### ❌ Duplicación 2: Construcción de Log Messages
**Líneas:** 468-473, 480-485

**Código Duplicado:**
```apex
execution.Log_Messages__c =
  (String.isNotBlank(execution.Log_Messages__c)
    ? execution.Log_Messages__c + '\n'
    : '') +
  'Synchronous test execution failed/completed. Log ID: ' +
  apexLogId;
```

**Lugares:**
- Línea 468: Failed case
- Línea 480: Completed but no results case

**Impacto:** ~6 líneas duplicadas (3 líneas × 2 lugares, con variaciones en mensaje)

**Solución:** Extraer a método privado:
```apex
private void appendLogMessage(JT_RunAsTest_Execution__c execution, String message) {
  execution.Log_Messages__c =
    (String.isNotBlank(execution.Log_Messages__c)
      ? execution.Log_Messages__c + '\n'
      : '') +
    message;
}
```

---

**Total en JT_RunAsTestEnqueuer:** ~52 líneas duplicadas

---

## 8. JT_SystemSelector.cls (482 líneas)

### ⚠️ Duplicación 1: Queries de Organization con Diferentes SELECT
**Líneas:** 37-45, 52-60, 67-75

**Código Similar:**
```apex
List<Organization> orgs = [
  SELECT [campos diferentes]
  FROM Organization
  WITH SECURITY_ENFORCED
  LIMIT 1
];
return orgs.isEmpty() ? null : orgs[0];
```

**Lugares:**
- Línea 37: `getOrganizationInfo()` - SELECT OrganizationType, IsSandbox, TrialExpirationDate
- Línea 52: `getOrganizationInfoWithName()` - SELECT Name, OrganizationType, IsSandbox, TrialExpirationDate
- Línea 67: `getOrganizationType()` - SELECT OrganizationType

**Impacto:** ~27 líneas con estructura similar pero diferentes campos

**Conclusión:** No es duplicación exacta - cada método necesita diferentes campos. Sin embargo, podrían consolidarse en un solo método con parámetro opcional:
```apex
public static Organization getOrganizationInfo(Boolean includeName) {
  String fields = includeName
    ? 'Name, OrganizationType, IsSandbox, TrialExpirationDate'
    : 'OrganizationType, IsSandbox, TrialExpirationDate';
  // Dynamic query o método sobrecargado
}
```

**Recomendación:** Baja prioridad - la duplicación es mínima y cada método tiene propósito específico.

---

**Total en JT_SystemSelector:** 0 líneas duplicadas (diferencias legítimas en campos SELECT)

---

## 📊 Resumen Total por Clase

| Clase | Líneas Duplicadas | Prioridad |
|-------|-------------------|-----------|
| **JT_MetadataCreator** | ~107 | 🔴 Alta |
| **JT_QueryViewerController** | ~59 | 🔴 Alta |
| **JT_RunAsTestEnqueuer** | ~52 | 🟡 Media |
| **JT_RunAsTestExecutor** | ~45 | 🟡 Media |
| **JT_DataSelector** | ~27 | 🟡 Media |
| **JT_GenericRunAsTest** | ~3 | 🟢 Baja |
| **JT_SystemSelector** | 0 | ✅ OK |
| **JT_UsageFinder** | 0 | ✅ OK |
| **TOTAL** | **~293 líneas** | - |

---

## 🎯 Recomendaciones por Prioridad

### Prioridad Alta (166 líneas)
1. **JT_MetadataCreator**: Refactorizar inicialización de resultados y manejo de errores (~107 líneas)
2. **JT_QueryViewerController**: Usar métodos existentes y extraer manejo de errores (~59 líneas)

### Prioridad Media (124 líneas)
3. **JT_RunAsTestEnqueuer**: Extraer manejo de excepciones de deserialización y construcción de log messages (~52 líneas)
4. **JT_RunAsTestExecutor**: Centralizar cache operations (~45 líneas)
5. **JT_DataSelector**: Extraer métodos helper para bindings y access level (~27 líneas)

### Prioridad Baja (3 líneas)
6. **JT_GenericRunAsTest**: Usar método existente para deserialización de bindings (~3 líneas)

---

## ✅ Verificación de Coverage

Todos estos patrones duplicados **ya están cubiertos por tests** en múltiples lugares. La duplicación no afecta el coverage, pero sí afecta la mantenibilidad del código.

