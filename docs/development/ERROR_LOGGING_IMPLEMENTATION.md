# Error Logging Implementation

## Overview

Se ha creado un sistema centralizado de logging de errores usando el objeto `JT_ErrorLog__c` para capturar excepciones que se presentan a los usuarios, con información detallada para soporte técnico.

## Objeto: JT_ErrorLog\_\_c

### Campos

- **JT_ErrorType\_\_c** (Text, Required): Tipo/categoría del error
- **JT_ErrorMessage\_\_c** (Text, Required): Mensaje amigable mostrado al usuario
- **JT_ExceptionType\_\_c** (Text): Tipo de excepción Apex (AuraHandledException, QueryException, etc.)
- **JT_StackTrace\_\_c** (LongTextArea): Stack trace completo para debugging
- **JT_Context\_\_c** (Text): Contexto donde ocurrió el error (componente, método, acción)
- **JT_Severity\_\_c** (Picklist): Severidad (Low, Medium, High, Critical)
- **OwnerId** (Standard Owner field): Usuario que encontró el error (campo estándar de Salesforce)
- **JT_Timestamp\_\_c** (DateTime, Required): Cuándo ocurrió el error
- **JT_AdditionalDetails\_\_c** (LongTextArea): Información adicional en JSON (opcional)
- **JT_OrgType\_\_c** (Text): Tipo de organización donde ocurrió
- **JT_Resolved\_\_c** (Checkbox): Si el error ha sido resuelto

## Clases

### JT_ErrorLogDomain.cls

Domain layer para operaciones DML en `JT_ErrorLog__c`. Ejecuta `without sharing` para garantizar que los logs siempre se creen.

### JT_ErrorLogger.cls

Utility class para facilitar el logging de errores. Proporciona métodos sobrecargados para diferentes escenarios.

## Ejemplos de Uso

### Ejemplo 1: Logging básico desde Apex

```apex
try {
    // Código que puede fallar
    executeQuery();
} catch (Exception e) {
    // Log del error
    JT_ErrorLogger.logError(
        'Query Execution Failed',
        e,
        'JT_QueryViewerController.executeQuery'
    );

    // Mostrar mensaje amigable al usuario
    throw new AuraHandledException('Unable to execute query. Please try again.');
}
```

### Ejemplo 2: Logging con ErrorType específico

```apex
try {
    // Código que puede fallar
    executeRunAsTest();
} catch (AuraHandledException ahe) {
    JT_ErrorMessageUtil.ErrorAnalysisResult analysis =
        JT_ErrorMessageUtil.analyzeError(ahe.getMessage(), null);

    // Log con tipo específico
    JT_ErrorLogger.logError(
        analysis.errorType,
        ahe.getMessage(),
        ahe,
        'JT_RunAsTestEnqueuer.execute'
    );

    throw ahe;
}
```

### Ejemplo 3: Logging con detalles adicionales

```apex
try {
    // Código que puede fallar
    createConfiguration(configJson);
} catch (Exception e) {
    // Construir detalles adicionales en JSON
    Map<String, Object> details = new Map<String, Object>{
        'configName' => configName,
        'userId' => UserInfo.getUserId(),
        'orgId' => UserInfo.getOrganizationId()
    };

    // Log con detalles adicionales
    JT_ErrorLogger.logError(
        'Configuration Creation Failed',
        e.getMessage(),
        e,
        'JT_MetadataCreator.createConfiguration',
        JSON.serialize(details),
        'High'
    );

    throw new AuraHandledException('Failed to create configuration.');
}
```

### Ejemplo 4: Integración en JT_RunAsTestEnqueuer

```apex
private void updateExecutionWithError(String errorMessage) {
    try {
        // ... código existente para actualizar execution ...

        // Log del error para soporte
        JT_ErrorLogger.logError(
            'Test Execution Failed',
            new AuraHandledException(errorMessage),
            'JT_RunAsTestEnqueuer.updateExecutionWithError'
        );
    } catch (Exception e) {
        // Log incluso si el update falla
        JT_ErrorLogger.logError(
            'Failed to Update Execution Record',
            e,
            'JT_RunAsTestEnqueuer.updateExecutionWithError'
        );
        throw e;
    }
}
```

### Ejemplo 5: Logging desde LWC (vía Apex)

En el componente LWC, cuando se captura un error:

```javascript
.catch((error) => {
    // Extraer mensaje de error
    const errorMsg = extractErrorMessage(error, this.labels.unknownError);

    // Mostrar al usuario
    this.showError = true;
    this.errorMessage = errorMsg;

    // Log en Apex para soporte (opcional, si necesitas más contexto)
    logErrorToApex({
        errorType: 'LWC Error',
        errorMessage: errorMsg,
        context: 'jtQueryViewer.handleExecuteQuery',
        additionalDetails: JSON.stringify({
            selectedConfig: this.selectedConfig,
            bindings: this.bindings
        })
    })
    .catch(() => {
        // Ignorar errores de logging, no deben afectar UX
    });
})
```

Y el método Apex correspondiente:

```apex
@AuraEnabled
public static String logErrorToApex(
    String errorType,
    String errorMessage,
    String context,
    String additionalDetails
) {
    return JT_ErrorLogger.logError(
        errorType,
        errorMessage,
        null, // No exception desde LWC
        context,
        additionalDetails,
        'Medium'
    );
}
```

## Ventajas

1. **Separación de responsabilidades**: `JT_SettingsAuditLog__c` para audit trail, `JT_ErrorLog__c` para errores
2. **Información completa**: Stack trace, contexto, detalles adicionales
3. **No bloquea operaciones**: El logging falla silenciosamente si hay problemas
4. **Facilita soporte**: Información detallada para debugging
5. **Reportes**: Permite crear reportes de errores comunes, usuarios afectados, etc.

## Políticas de Retención

Se recomienda implementar una política de limpieza similar a `JT_SettingsAuditLog__c`:

```apex
// Ejemplo: Limpiar logs de más de 90 días
JT_ErrorLogDomain.deleteOldLogs(90);
```

## Próximos Pasos

1. Integrar `JT_ErrorLogger.logError()` en puntos clave donde se capturan excepciones
2. Crear reportes de errores comunes
3. Implementar política de limpieza automática
4. Considerar crear un componente LWC para visualizar errores (opcional)
