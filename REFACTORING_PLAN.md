# Plan de Refactorización: jtQueryViewer.js

## Análisis Actual

- **Tamaño**: 2243 líneas
- **Métodos**: 99 métodos/propiedades
- **Problemas identificados**:
  1. Métodos de toast duplicados (ya existen en `jtUtils.js`)
  2. Lógica de modales mezclada con lógica de negocio
  3. Lógica de paginación duplicada (preview y resultados principales)
  4. Método `getFieldType` duplicado (ya existe en `jtUtils.js`)
  5. Muchos getters que podrían simplificarse
  6. Lógica de ejecución de queries muy larga

## Plan de Refactorización (Priorizado)

### Fase 1: Eliminar Código Duplicado (Alto Impacto, Bajo Riesgo)

1. **Reemplazar métodos de toast locales con `jtUtils`**
   - Eliminar: `showSuccessToast`, `showErrorToast`, `showInfoToast`, `showWarningToast`
   - Reemplazar todas las llamadas (57 ocurrencias) con funciones de `jtUtils`
   - **Ahorro estimado**: ~100 líneas

2. **Eliminar `getFieldType` duplicado**
   - Ya existe en `jtUtils.js`
   - Reemplazar llamadas locales
   - **Ahorro estimado**: ~15 líneas

### Fase 2: Extraer Lógica de Paginación (Medio Impacto, Medio Riesgo)

3. **Crear componente `jtPagination` o utilidad**
   - Extraer lógica de paginación (preview y resultados)
   - Métodos: `handlePreviousPage`, `handleNextPage`, `resetPagination`, getters relacionados
   - **Ahorro estimado**: ~150 líneas

### Fase 3: Extraer Lógica de Modales (Medio Impacto, Medio Riesgo)

4. **Crear servicio de gestión de modales**
   - Extraer: `handleOpenCacheModal`, `handleCloseCacheModal`, `handleShowCreateModal`, `handleShowEditModal`, `handleCloseUsageModal`
   - Centralizar estado de modales
   - **Ahorro estimado**: ~100 líneas

### Fase 4: Simplificar Getters (Bajo Impacto, Bajo Riesgo)

5. **Consolidar getters relacionados**
   - Agrupar getters de paginación, vista, estado
   - Usar computed properties donde sea posible
   - **Ahorro estimado**: ~50 líneas

### Fase 5: Extraer Lógica de Ejecución de Queries (Alto Impacto, Alto Riesgo)

6. **Crear componente `jtQueryExecutor`**
   - Extraer: `executeQueryNormal`, `executeQueryWithBatches`, `assessQueryRiskAndExecute`
   - Manejar toda la lógica de ejecución y resultados
   - **Ahorro estimado**: ~300 líneas

## Métricas Esperadas Post-Refactorización

- **Líneas reducidas**: ~715 líneas (32% reducción)
- **Métodos reducidos**: ~30 métodos (30% reducción)
- **Mantenibilidad**: Significativamente mejorada
- **Testabilidad**: Mejorada (componentes más pequeños y enfocados)

## Orden de Ejecución Recomendado

1. ✅ Fase 1 (ya iniciado)
2. Fase 2
3. Fase 3
4. Fase 4
5. Fase 5 (requiere más análisis)

## Notas

- Cada fase debe incluir tests
- Hacer commits incrementales después de cada fase
- Validar funcionalidad después de cada cambio
