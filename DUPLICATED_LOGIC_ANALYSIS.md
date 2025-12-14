# Análisis de Lógica Duplicada en Componentes LWC

## Componentes Analizados

### 1. jtQueryViewer.js (2,290 líneas)
- **Estado**: Parcialmente refactorizado
- **Lógica duplicada encontrada**:
  - ✅ **Consolidado**: Manejo de errores (ahora usa `extractErrorMessage` de jtUtils)
  - ⚠️ **Pendiente**: 60 console.log/error/warn (muchos de debug temporal)
  - ⚠️ **Pendiente**: 89 imports individuales de Custom Labels
  - ⚠️ **Pendiente**: Validaciones repetidas que podrían extraerse

### 2. jtConfigModal.js (583 líneas)
- **Lógica duplicada encontrada**:
  - ⚠️ Manejo de errores (línea 515): `error.body?.message` - debería usar `extractErrorMessage`
  - ⚠️ Validaciones de developer name similares a jtQueryViewer
  - ✅ Usa funciones de jtUtils para validación (`validateDeveloperName`, `validateLabel`)

### 3. jtQueryResults.js
- ✅ Ya usa funciones de jtUtils (`formatLabel`, `getFieldType`)
- ✅ Manejo de errores consolidado

### 4. jtSetupWizard.js
- Manejo de errores básico, no crítico

## Resumen de Lógica Duplicada

### Manejo de Errores
- **Antes**: Patrón repetido en múltiples componentes:
  ```javascript
  error.body?.message || error.body?.pageErrors?.[0]?.message || ...
  ```
- **Ahora**: Consolidado en `extractErrorMessage()` de jtUtils
- **Pendiente**: Actualizar `jtConfigModal.js` para usar `extractErrorMessage`

### Validaciones
- **Duplicado**: Validaciones de campos requeridos en múltiples lugares
- **Oportunidad**: Extraer funciones helper para validaciones comunes

### Console.log Statements
- **jtQueryViewer.js**: 60 console.log/error/warn
- **Acción**: Eliminar debug temporal, mantener solo logs críticos

## Próximos Pasos Recomendados

1. ✅ **Completado**: Consolidar manejo de errores con `extractErrorMessage`
2. ⚠️ **Pendiente**: Actualizar `jtConfigModal.js` para usar `extractErrorMessage`
3. ⚠️ **Pendiente**: Eliminar console.log de debug temporal
4. ⚠️ **Pendiente**: Simplificar imports de Custom Labels (si es posible)

