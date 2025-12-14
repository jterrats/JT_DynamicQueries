# Plan de Refactorización: jtQueryViewer.js

## Estado Actual
- **Líneas de código**: 2,289
- **Métodos**: 55
- **Console.log/error/warn**: 60
- **Imports de Custom Labels**: 89 individuales

## Redundancias Identificadas

### 1. Console.log Statements (60 encontrados)
- Muchos son de debug temporal que deberían eliminarse
- Algunos son útiles pero deberían estar detrás de un flag de debug
- **Acción**: Eliminar debug temporal, mantener solo logs críticos

### 2. Manejo de Errores Duplicado
- Patrón repetido de extracción de mensajes de error:
  ```javascript
  error.body?.message ||
  error.body?.pageErrors?.[0]?.message ||
  error.body?.output?.errors?.[0]?.message ||
  error.message ||
  fallback
  ```
- **Acción**: Extraer a función helper `extractErrorMessage(error, fallback)` en jtUtils

### 3. Validaciones Repetidas
- Validación de `configToUse` null/undefined
- Validación de campos requeridos (label, developerName, baseQuery)
- Validación de query syntax
- **Acción**: Extraer funciones de validación a helpers

### 4. Lógica de Polling
- `startPollingTestResults()` tiene lógica compleja que podría reutilizarse
- **Acción**: Crear función helper genérica `pollUntilComplete()` en jtUtils

### 5. Custom Labels
- 89 imports individuales
- Ya existe `getLabels()` en jtUtils pero no se está usando
- **Acción**: Usar `getLabels()` para simplificar imports

## Plan de Refactorización

### Fase 1: Limpieza Inmediata
1. ✅ Eliminar console.log de debug temporal
2. ✅ Extraer `extractErrorMessage()` a jtUtils
3. ✅ Extraer funciones de validación a helpers

### Fase 2: Simplificación
4. ✅ Usar `getLabels()` para Custom Labels
5. ✅ Extraer lógica de polling a helper genérico
6. ✅ Consolidar manejo de errores

### Fase 3: Optimización
7. ✅ Revisar métodos largos y dividirlos
8. ✅ Identificar y extraer lógica común

## Métricas Objetivo
- Reducir a ~1,800 líneas (reducción del 21%)
- Reducir console.log a <10 (solo críticos)
- Simplificar imports de labels

