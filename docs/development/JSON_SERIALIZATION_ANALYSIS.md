# Análisis de Impacto: Refactorización de Serialización JSON

## Estado Actual

### ✅ Ya Usan Serialización JSON Estándar (Correcto)

1. **JT_QueryViewerController.executeQuery** (línea 107-108)

   ```apex
   String recordsJson = JSON.serialize(sobjectRecords);
   result.records = (List<Object>) JSON.deserializeUntyped(recordsJson);
   ```

   - ✅ Correcto: Preserva relaciones anidadas
   - ✅ Usado por: Ejecución principal de queries

2. **JT_QueryViewerController.executeQueryWithBatchProcessing** (línea 736-737)

   ```apex
   String recordsJson = JSON.serialize(sobjectRecords);
   result.records = (List<Object>) JSON.deserializeUntyped(recordsJson);
   ```

   - ✅ Correcto: Preserva relaciones anidadas
   - ✅ Usado por: Procesamiento por lotes

3. **JT_GenericRunAsTest.storeResults** (línea 481)

   ```apex
   List<Object> serializedRecords = JT_QueryViewerController.serializeRecordsForLWC(queryResult.records);
   ```

   - ✅ Correcto: Usa método helper centralizado
   - ✅ Usado por: Run As User feature

4. **JT_RunAsTestExecutor.getTestResults** (línea 443)

   ```apex
   result.records = (List<Object>) resultMap.get('records');
   ```

   - ✅ Correcto: Deserializa desde JSON almacenado
   - ✅ Usado por: Recuperación de resultados de tests

### ⚠️ Asignación Directa Sin Serializar (Potencial Problema)

1. **JT_QueryViewerController.executeQueryPreview** (línea 234)

   ```apex
   result.records = records; // List<SObject> asignado directamente
   ```

   - ⚠️ **Problema**: Asigna `List<SObject>` directamente sin serializar
   - **Impacto**: Si hay relaciones anidadas en el preview, podrían no funcionar correctamente
   - **Riesgo**: Medio - Solo afecta preview (LIMIT 5), no producción
   - **Uso**: Preview de queries en modal de creación

2. **JT_GenericRunAsTest.executeRunAsTest** (línea 303)

   ```apex
   result.records = records; // List<SObject> asignado directamente
   ```

   - ⚠️ **Problema**: Asigna directamente, pero se corrige en `storeResults`
   - **Impacto**: Bajo - Se serializa antes de guardar en Debug Log
   - **Riesgo**: Muy bajo - Solo afecta estructura interna temporal
   - **Uso**: Estructura interna de test, se serializa antes de persistir

## Análisis de Riesgo de Refactorización

### Escenario 1: Refactorizar `executeQueryPreview`

**Cambio requerido:**

```apex
// Antes:
result.records = records;

// Después:
result.records = serializeRecordsForLWC(records);
```

**Riesgo:**

- **Alto**: Este método se usa en el modal de creación para preview en tiempo real
- **Impacto**: Si hay un bug, afectaría la funcionalidad crítica de preview
- **Testing**: Requiere probar con queries que tienen relaciones anidadas
- **Beneficio**: Bajo - El preview normalmente no tiene relaciones anidadas (LIMIT 5)

**Recomendación**: ⚠️ **NO REFACTORIZAR** - El riesgo supera el beneficio

### Escenario 2: Refactorizar `executeRunAsTest`

**Cambio requerido:**

```apex
// Antes:
result.records = records;

// Después:
result.records = serializeRecordsForLWC(records);
```

**Riesgo:**

- **Bajo**: Los records se serializan correctamente en `storeResults` antes de persistir
- **Impacto**: Mínimo - Solo afecta estructura temporal interna
- **Testing**: Ya está probado que funciona correctamente
- **Beneficio**: Mínimo - Ya se serializa donde importa

**Recomendación**: ✅ **OPCIONAL** - Puede hacerse pero no es crítico

## Conclusión

### Estado Actual: ✅ **SUFICIENTEMENTE BUENO**

1. **Métodos críticos ya usan serialización correcta:**
   - `executeQuery` ✅
   - `executeQueryWithBatchProcessing` ✅
   - `storeResults` ✅
   - `getTestResults` ✅

2. **Métodos con asignación directa:**
   - `executeQueryPreview`: Riesgo alto de refactorizar, beneficio bajo
   - `executeRunAsTest`: Ya se serializa donde importa

3. **Método helper centralizado existe:**
   - `JT_QueryViewerController.serializeRecordsForLWC()` ✅
   - Ya está siendo usado donde es crítico

### Recomendación Final

**NO REFACTORIZAR** - El riesgo de romper funcionalidad crítica (preview) supera el beneficio mínimo.

**Razones:**

1. Los métodos críticos ya usan serialización correcta
2. El preview (`executeQueryPreview`) funciona correctamente para casos normales
3. El cambio requeriría testing exhaustivo de relaciones anidadas
4. El beneficio es mínimo (solo afecta preview con relaciones anidadas, caso raro)

**Alternativa:** Si en el futuro se encuentra un bug específico con relaciones anidadas en preview, entonces sí refactorizar ese método específico.
