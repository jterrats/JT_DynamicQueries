# Análisis de Fallos en Tests E2E

## Resumen Ejecutivo

**Total de tests**: 135
- ✅ **112 pasaron** (83%)
- ❌ **14 fallaron** (10%)
- ⏭️ **9 saltados** (7%)

## 🔍 Análisis de Fallos por Categoría

### 1. "Where is this used?" Feature (6 tests fallidos)

#### Problemas Identificados:

**A. Timeouts en búsqueda de usos**
- Los tests esperan que el modal muestre resultados en 3-5 segundos
- La búsqueda puede tomar más tiempo si:
  - Tooling API está lento
  - Hay muchos Flows en la org
  - La búsqueda en Apex classes es extensa

**B. Cambios en la estructura del modal**
- Los tests buscan texto específico: `/No usages found|not found any usage/i`
- El componente `jtUsageModal` podría haber cambiado los labels o la estructura
- Los selectores pueden haber cambiado después de refactorizaciones

**C. Problemas con Tooling API**
- La funcionalidad depende de Tooling API para buscar Flows
- Si la Named Credential no está configurada o hay problemas de permisos, la búsqueda falla
- Los tests no manejan bien el caso de "partial results"

#### Posibles Causas:

1. **Timing Issues**:
   ```javascript
   await page.waitForTimeout(3000); // Puede no ser suficiente
   ```
   - La búsqueda es asíncrona y puede tomar más tiempo
   - El modal puede mostrar "Searching..." pero los tests no esperan suficiente tiempo

2. **Selectores Cambiados**:
   - Los tests buscan `text=/JT_AccountReportExample/i` pero el texto podría estar en Shadow DOM
   - Los labels podrían haber cambiado después de refactorizaciones

3. **Estado del Modal**:
   - El modal podría estar en estado "loading" cuando los tests verifican resultados
   - No hay verificación explícita de que la búsqueda haya terminado

#### Recomendaciones:

1. Aumentar timeouts en tests de "Where is this used?"
2. Agregar verificaciones explícitas del estado del modal (loading → results)
3. Verificar que Tooling API esté disponible antes de ejecutar tests
4. Manejar mejor el caso de "partial results"

---

### 2. SOQL Operators Validation (5 tests fallidos)

#### Problemas Identificados:

**A. Operadores no soportados**
- Tests esperan errores para `BETWEEN` y `NOT LIKE`
- La validación podría no estar funcionando correctamente
- Los mensajes de error podrían haber cambiado

**B. Validación de resultados**
- Tests esperan resultados específicos pero pueden no estar presentes
- Los datos de prueba podrían no existir en la org

#### Posibles Causas:

1. **Validación de Operadores**:
   - El método `validateSupportedOperators` en `JT_DataSelector` podría no estar lanzando errores correctamente
   - Los mensajes de error podrían haber cambiado

2. **Datos de Prueba**:
   - Los tests asumen que existen datos específicos (Accounts con ciertos nombres, industries, etc.)
   - Si los datos no existen, los tests fallan

#### Recomendaciones:

1. Verificar que `validateSupportedOperators` esté funcionando correctamente
2. Asegurar que los datos de prueba existan antes de ejecutar tests
3. Verificar que los mensajes de error sean los esperados

---

### 3. Tests Básicos de Carga (8 tests fallidos)

#### Problemas Identificados:

**A. Componente no carga**
- `should load the Query Viewer component` - El componente podría no estar visible
- Podría ser un problema de timing o de Shadow DOM

**B. Navegación**
- Los tests podrían estar fallando en la navegación inicial
- El tab "Query Viewer" podría no estar disponible

**C. Autenticación**
- Aunque se usa SF CLI session, podría haber problemas con cookies o permisos

#### Posibles Causas:

1. **Timing Issues**:
   ```javascript
   await page.waitForSelector("c-jt-query-viewer", { timeout: 30000 });
   ```
   - El componente podría tardar más en cargar
   - Shadow DOM podría no estar completamente renderizado

2. **Selectores**:
   - Los selectores podrían haber cambiado después de refactorizaciones
   - Shadow DOM puede hacer que los selectores no funcionen

3. **Permisos**:
   - El usuario de prueba podría no tener los permisos necesarios
   - El Permission Set podría no estar asignado

#### Recomendaciones:

1. Aumentar timeouts para carga de componentes
2. Verificar que los selectores sean correctos después de refactorizaciones
3. Asegurar que el Permission Set esté asignado antes de ejecutar tests
4. Agregar más logging para debugging

---

### 4. GitHub Pages Tests (3 tests fallidos)

#### Problemas Identificados:

- Tests de documentación estática
- No relacionados con las refactorizaciones de código
- Probablemente problemas con la configuración de GitHub Pages o links rotos

#### Recomendaciones:

- Revisar manualmente los links en la documentación
- Verificar que GitHub Pages esté configurado correctamente

---

## 🎯 Acciones Recomendadas (Prioridad)

### Alta Prioridad

1. **Revisar "Where is this used?" Feature**:
   - Verificar que `JT_UsageFinder.findConfigurationUsage` esté funcionando
   - Aumentar timeouts en tests
   - Agregar mejor manejo de estados (loading, error, success)

2. **Verificar Validación de Operadores**:
   - Revisar `JT_DataSelector.validateSupportedOperators`
   - Asegurar que los mensajes de error sean los esperados

3. **Mejorar Tests de Carga**:
   - Aumentar timeouts
   - Agregar verificaciones más robustas de carga de componentes
   - Verificar permisos antes de ejecutar tests

### Media Prioridad

4. **Revisar Selectores**:
   - Verificar que los selectores en tests coincidan con la estructura actual del DOM
   - Considerar usar `data-testid` attributes para selectores más estables

5. **Mejorar Manejo de Errores**:
   - Agregar mejor logging en tests para debugging
   - Capturar screenshots cuando fallan tests

### Baja Prioridad

6. **GitHub Pages**:
   - Revisar manualmente los links
   - Actualizar documentación si es necesario

---

## 🔧 Cambios Recientes que Podrían Afectar Tests

### Refactorizaciones Realizadas:

1. **JT_MetadataCreator**: Extracción de métodos helper
   - No debería afectar tests e2e directamente

2. **JT_QueryViewerController**: Extracción de métodos helper
   - Podría afectar si los métodos públicos cambiaron
   - Verificar que `executeQuery`, `executeQueryPreview` sigan funcionando igual

3. **JT_RunAsTestEnqueuer**: Extracción de manejo de excepciones
   - No debería afectar tests e2e

4. **JT_RunAsTestExecutor**: Centralización de cache operations
   - Podría afectar tests de "Run As User" si hay problemas con cache

5. **JT_DataSelector**: Extracción de métodos helper
   - Podría afectar validación de operadores si `validateSupportedOperators` cambió

### Verificaciones Necesarias:

1. ✅ Verificar que métodos públicos no hayan cambiado
2. ✅ Verificar que mensajes de error sigan siendo los mismos
3. ✅ Verificar que la lógica de negocio no haya cambiado
4. ⚠️ Verificar timing y timeouts en tests

---

## 📝 Notas para Mañana

1. **Ejecutar tests individualmente** para identificar patrones
2. **Revisar logs de Salesforce** para ver errores del lado del servidor
3. **Verificar estado de Tooling API** y Named Credentials
4. **Revisar datos de prueba** - asegurar que existan los datos necesarios
5. **Capturar screenshots** cuando los tests fallen para debugging visual

---

## 🐛 Posibles Bugs a Investigar

1. **Modal de "Where is this used?" no muestra resultados**:
   - Verificar que `JT_UsageFinder.findConfigurationUsage` retorne datos
   - Verificar que el componente LWC reciba y muestre los datos correctamente

2. **Validación de operadores no funciona**:
   - Verificar que `validateSupportedOperators` detecte BETWEEN y NOT LIKE
   - Verificar que los mensajes de error sean los esperados

3. **Componente no carga**:
   - Verificar permisos del usuario
   - Verificar que el componente esté desplegado correctamente
   - Verificar que no haya errores de JavaScript en la consola

