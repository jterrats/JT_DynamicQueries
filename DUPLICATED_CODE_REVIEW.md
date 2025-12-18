# Revisión de Código Duplicado - Análisis Actualizado

**Fecha:** 2025-12-14
**Objetivo:** Identificar código duplicado que ya está cubierto por tests y podría estar afectando el coverage efectivo

---

## ✅ Ya Refactorizado (No Duplicado)

### 1. ✅ Error Handling Duplicado
- **Estado:** ✅ Ya refactorizado
- **Solución:** Extraído a `JT_ExecutionUpdateUtil`
- **Clases afectadas:** `JT_RunAsTestEnqueuer`, `JT_GenericRunAsTest`
- **Impacto:** ~136 líneas eliminadas

### 2. ✅ Email Sending Duplicado
- **Estado:** ✅ Ya refactorizado
- **Solución:** Extraído método `sendEmail()` en `JT_UsageFinderQueueable`
- **Impacto:** ~10 líneas eliminadas

### 3. ✅ Cache Key Building Duplicado
- **Estado:** ✅ Ya refactorizado
- **Solución:** Extraído método `buildCacheKey()` en `JT_UsageFinderQueueable`
- **Impacto:** ~6 líneas eliminadas

---

## 🔴 Patrones Duplicados Encontrados (Pendientes)

### 1. ❌ **Deserialización de Bindings JSON** (Alta Prioridad)

**Patrón Duplicado:**
```apex
Map<String, Object> bindings = String.isNotBlank(bindingsJson)
  ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
  : new Map<String, Object>();
```

**Lugares donde aparece:**
- `JT_GenericRunAsTest.cls` (línea 269)
- `JT_RunAsTestExecutor.cls` (línea 631)
- `JT_QueryViewerController.cls` (líneas 69, 193, 513, 692) - **4 veces**
- `JT_QueryBindingUtil.cls` (línea 62) - Ya tiene método `processBindings()` que hace esto

**Impacto:** ~8 líneas duplicadas × 6 lugares = **~48 líneas duplicadas**

**Solución Propuesta:**
Ya existe `JT_QueryBindingUtil.processBindings()` que hace exactamente esto. Refactorizar para usar este método en todos los lugares.

**Código Actual en JT_QueryBindingUtil:**
```apex
public static Map<String, Object> processBindings(
  String query,
  String bindingsJson
) {
  Map<String, Object> bindings = String.isNotBlank(bindingsJson)
    ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
    : new Map<String, Object>();

  // Add wildcards for LIKE queries
  addWildcardsForLikeBindings(query, bindings);

  return bindings;
}
```

**Refactorización:**
- Crear método sobrecargado `processBindings(String bindingsJson)` que solo deserializa
- O usar `processBindings(query, bindingsJson)` en todos los lugares (mejor, porque también agrega wildcards)

---

### 2. ⚠️ **Cache Operations con JSON Serialization** (Media Prioridad)

**Patrón Duplicado:**
```apex
// Sanitize userId
final String sanitizedUserId = JT_ToolingApiUtil.toAlphanumeric(userId);

// Store in cache
Cache.Org.put(
  'RunAsTestResult' + sanitizedUserId,
  JSON.serialize(resultMap),
  300
);

// Later retrieve
String cachedJson = (String) Cache.Org.get('RunAsTestResult' + sanitizedUserId);
Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(cachedJson);
```

**Lugares donde aparece:**
- `JT_RunAsTestExecutor.cls` (líneas 644-668, 671-686, 722-730) - **3 veces**
- `JT_UsageFinderQueueable.cls` (ya refactorizado con `buildCacheKey()`)

**Impacto:** ~15 líneas duplicadas × 3 lugares = **~45 líneas duplicadas**

**Solución Propuesta:**
Crear métodos utilitarios en `JT_ToolingApiUtil` o nueva clase `JT_CacheUtil`:

```apex
public class JT_CacheUtil {
  private static final String RUNAS_TEST_PREFIX = 'RunAsTestResult';

  public static void putRunAsTestResult(String userId, Map<String, Object> result, Integer ttl) {
    String cacheKey = RUNAS_TEST_PREFIX + JT_ToolingApiUtil.toAlphanumeric(userId);
    Cache.Org.put(cacheKey, JSON.serialize(result), ttl);
  }

  public static Map<String, Object> getRunAsTestResult(String userId) {
    String cacheKey = RUNAS_TEST_PREFIX + JT_ToolingApiUtil.toAlphanumeric(userId);
    String cachedJson = (String) Cache.Org.get(cacheKey);
    if (String.isBlank(cachedJson)) {
      return null;
    }
    return (Map<String, Object>) JSON.deserializeUntyped(cachedJson);
  }
}
```

---

### 3. ⚠️ **Validación de Usuario** (Baja Prioridad - Diferencias Legítimas)

**Patrones Similares pero con Diferencias:**

1. **JT_GenericRunAsTest.validateUser** (línea 243):
```apex
private static User validateUser(TestParameters params) {
  return [
    SELECT Id, Name, Username
    FROM User
    WHERE Id = :params.userId
    LIMIT 1
  ];
}
```
- No valida `IsActive`
- No lanza excepción si no existe
- Contexto: Test execution

2. **JT_RunAsTestExecutor.validateUser** (línea 558):
```apex
private static User validateUser(String userId) {
  List<User> users = [
    SELECT Id, Name, Username, IsActive
    FROM User
    WHERE Id = :userId
    WITH USER_MODE
    LIMIT 1
  ];

  if (users.isEmpty() || !users[0].IsActive) {
    throw new AuraHandledException(...);
  }

  return users[0];
}
```
- Valida `IsActive`
- Lanza excepción si no existe o inactivo
- Usa `WITH USER_MODE`
- Contexto: Production execution

3. **JT_QueryViewerController.validateRunAsPermission** (línea 400):
```apex
private static void validateRunAsPermission(String userId) {
  if (!canUseRunAs()) {
    throw new AuraHandledException(...);
  }

  User u = JT_SystemSelector.getUserById(userId);
  if (!u.IsActive) {
    throw new AuraHandledException(...);
  }
}
```
- Valida permisos primero
- Usa selector layer
- Contexto: Permission validation

**Conclusión:** Estos métodos tienen propósitos diferentes y diferencias legítimas. **NO son duplicados exactos**, pero podrían beneficiarse de un método base compartido.

**Solución Propuesta (Opcional):**
Crear método base en `JT_SystemSelector`:
```apex
public static User getUserForRunAs(String userId, Boolean requireActive) {
  User u = getUserById(userId);
  if (requireActive && !u.IsActive) {
    throw new AuraHandledException('User is not active');
  }
  return u;
}
```

---

## 📊 Resumen de Impacto

| Patrón | Líneas Duplicadas | Prioridad | Estado |
|--------|-------------------|-----------|--------|
| Deserialización de Bindings JSON | ~48 | 🔴 Alta | Pendiente |
| Cache Operations con JSON | ~45 | 🟡 Media | Pendiente |
| Validación de Usuario | ~0 (diferencias legítimas) | 🟢 Baja | Opcional |

**Total Pendiente:** ~93 líneas duplicadas

---

## 🎯 Recomendaciones

### Prioridad Alta
1. **Refactorizar deserialización de bindings** para usar `JT_QueryBindingUtil.processBindings()` en todos los lugares
   - Impacto: ~48 líneas eliminadas
   - Beneficio adicional: Automáticamente agrega wildcards para LIKE queries

### Prioridad Media
2. **Crear `JT_CacheUtil`** para centralizar operaciones de cache con JSON
   - Impacto: ~45 líneas eliminadas
   - Beneficio: Consistencia en manejo de cache keys

### Prioridad Baja (Opcional)
3. **Mejorar validación de usuario** con método base compartido
   - Impacto: Mejora mantenibilidad, no elimina duplicación real

---

## ✅ Verificación de Coverage

Todos estos patrones duplicados **ya están cubiertos por tests** en múltiples lugares:
- ✅ Deserialización de bindings: Cubierta en `JT_QueryViewerController_Test`, `JT_GenericRunAsTest_Test`, etc.
- ✅ Cache operations: Cubierta en `JT_RunAsTestExecutor_Test`, `JT_UsageFinderQueueable_Test`
- ✅ Validación de usuario: Cubierta en tests individuales de cada clase

**Conclusión:** La duplicación no afecta el coverage (las líneas están cubiertas), pero sí afecta la mantenibilidad del código.

