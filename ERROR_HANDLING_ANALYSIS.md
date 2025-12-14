# Análisis de Manejo de Errores: "Uncommitted Work Pending"

## Problema Identificado

El error "You have uncommitted work pending. Please commit or rollback before calling out" ocurre cuando:

1. **En Run As User:**
   - Se crea/actualiza `JT_RunAsTest_Execution__c` (DML)
   - Luego se intenta callout a Tooling API
   - Salesforce no permite DML + callout en la misma transacción
   - Esto ocurre especialmente durante deployments/setup operations

2. **Flujo actual:**
   ```
   JT_RunAsTestExecutor.executeAsUser()
   → Crea JT_RunAsTest_Execution__c (DML)
   → Encola JT_RunAsTestEnqueuer (Queueable)
   → JT_RunAsTestEnqueuer.execute()
   → Intenta callout síncrono (403 ORG_ADMIN_LOCKED)
   → Intenta fallback asíncrono
   → ❌ CalloutException: "uncommitted work pending"
   ```

3. **En "Where is this used?":**
   - Usa Continuation (no tiene problema de DML + callout)
   - Pero podría tener otros errores relacionados con deployments

## Impacto en UX

### Escenarios donde ocurre:

1. **Durante Deployments:**
   - Org está bloqueada para operaciones admin
   - Usuario ve error técnico confuso
   - No sabe que debe esperar o reintentar

2. **Durante Setup Operations:**
   - Configuración inicial de la app
   - Migraciones de datos
   - Operaciones masivas en progreso

3. **Durante Operaciones Concurrentes:**
   - Múltiples usuarios ejecutando Run As simultáneamente
   - Límites de org alcanzados

### Mensajes Actuales (Técnicos):

- ❌ "Failed to execute test: You have uncommitted work pending. Please commit or rollback before calling out"
- ❌ "Synchronous execution failed with HTTP status: 403"
- ❌ Stack traces visibles al usuario

### Mensajes Propuestos (User-Friendly):

1. **Para "uncommitted work pending":**
   ```
   "The system is currently processing another operation.
   Please wait a moment and try again.
   This may occur during deployments or system maintenance."
   ```

2. **Para "ORG_ADMIN_LOCKED" (403):**
   ```
   "The system is temporarily unavailable due to an ongoing deployment or maintenance operation.
   Please wait a few minutes and try again."
   ```

3. **Para errores de deployment/setup:**
   ```
   "This feature is temporarily unavailable.
   The system may be processing a deployment or configuration change.
   Please try again in a few minutes."
   ```

## Cambios Propuestos

### 1. Custom Labels a Crear:

```xml
<labels>
    <fullName>JT_RunAsTestEnqueuer_uncommittedWorkPending</fullName>
    <value>The system is currently processing another operation. Please wait a moment and try again. This may occur during deployments or system maintenance.</value>
</labels>
<labels>
    <fullName>JT_RunAsTestEnqueuer_orgAdminLocked</fullName>
    <value>The system is temporarily unavailable due to an ongoing deployment or maintenance operation. Please wait a few minutes and try again.</value>
</labels>
<labels>
    <fullName>JT_RunAsTestEnqueuer_deploymentInProgress</fullName>
    <value>This feature is temporarily unavailable. The system may be processing a deployment or configuration change. Please try again in a few minutes.</value>
</labels>
```

### 2. Cambios en `JT_RunAsTestEnqueuer.cls`:

```apex
// En execute() - Detectar error específico
catch (Exception e) {
    String errorMessage = e.getMessage();
    String userFriendlyMessage;

    // Detectar "uncommitted work pending"
    if (errorMessage.contains('uncommitted work') ||
        errorMessage.contains('CalloutException')) {
        userFriendlyMessage = Label.JT_RunAsTestEnqueuer_uncommittedWorkPending;
    }
    // Detectar ORG_ADMIN_LOCKED (403)
    else if (errorMessage.contains('ORG_ADMIN_LOCKED') ||
             errorMessage.contains('admin operation already in progress')) {
        userFriendlyMessage = Label.JT_RunAsTestEnqueuer_orgAdminLocked;
    }
    // Otros errores de deployment
    else if (errorMessage.contains('deployment') ||
             errorMessage.contains('maintenance')) {
        userFriendlyMessage = Label.JT_RunAsTestEnqueuer_deploymentInProgress;
    }
    // Error genérico
    else {
        userFriendlyMessage = 'Failed to execute test: ' + errorMessage;
    }

    updateExecutionWithError(userFriendlyMessage);
}
```

### 3. Cambios en `JT_UsageFinder.cls`:

```apex
// En processFlowSearchCallback() - Manejar errores de deployment
catch (Exception e) {
    String errorMessage = e.getMessage();
    String userFriendlyError;

    if (errorMessage.contains('ORG_ADMIN_LOCKED') ||
        errorMessage.contains('admin operation')) {
        userFriendlyError = Label.JT_RunAsTestEnqueuer_orgAdminLocked;
    } else {
        userFriendlyError = 'Flow search failed: ' + errorMessage;
    }

    response.success = false;
    response.error = userFriendlyError;
}
```

### 4. Cambios en LWC (`jtQueryViewer.js`):

```javascript
// En handleTestResults() - Mostrar mensajes user-friendly
if (!result.success) {
    // El mensaje ya viene user-friendly desde Apex
    this.showError = true;
    this.errorMessage = result.errorMessage;
    // No mostrar toast adicional si ya hay banner de error
}
```

## Consideraciones

### ✅ Ventajas:

1. **Mejor UX:** Usuarios entienden qué pasó y qué hacer
2. **Menos confusión:** No ven stack traces técnicos
3. **Acción clara:** Saben que deben esperar y reintentar
4. **Consistencia:** Mismo patrón para todos los errores de deployment

### ⚠️ Desventajas:

1. **Menos información para debugging:** Perdemos detalles técnicos
   - **Solución:** Mantener detalles técnicos en Debug Logs

2. **Detección de errores:** Necesitamos detectar correctamente los tipos de error
   - **Solución:** Usar múltiples patrones de detección

3. **Mensajes genéricos:** Podrían no cubrir todos los casos
   - **Solución:** Tener fallback a mensaje genérico con instrucciones

## Próximos Pasos

1. ✅ Crear Custom Labels
2. ✅ Actualizar `JT_RunAsTestEnqueuer.cls` con detección específica
3. ✅ Actualizar `JT_UsageFinder.cls` para manejar errores similares
4. ✅ Verificar que LWC muestra mensajes correctamente
5. ✅ Probar durante deployment real
6. ✅ Actualizar documentación

## Testing

### Escenarios a probar:

1. **Durante deployment activo:**
   - Ejecutar Run As User → Debe mostrar mensaje user-friendly
   - Ejecutar "Where is this used?" → Debe manejar error gracefully

2. **Con operaciones concurrentes:**
   - Múltiples usuarios ejecutando simultáneamente
   - Verificar que mensajes son apropiados

3. **Con setup operations:**
   - Durante configuración inicial
   - Durante migraciones

