# 🔍 Cómo Reproducir los Errores Detectados en las Pruebas E2E

## 📋 Resumen de Errores Detectados

Las pruebas E2E detectaron que **3 configuraciones están mostrando el modal de riesgo (>50k registros)** cuando no deberían, ya que solo hay datos provisionados (menos de 20 registros).

### Errores Detectados:
1. ❌ **Multiple_IN_Operators** - Modal de riesgo aparece (99,999 registros estimados)
2. ❌ **LIKE_Patterns_Mix** - Modal de riesgo aparece (99,999 registros estimados)
3. ❌ **All_Comparison_Operators** - Modal de riesgo aparece (99,999 registros estimados)
4. ✅ **Complex_Mixed_Operators** - ✅ Pasó correctamente (encontró 7 registros)

---

## 🚀 Método 1: Ejecutar las Pruebas E2E (Automático)

### Paso 1: Asegurar que hay datos provisionados

```bash
# Ejecutar el script de provisionamiento de datos
cd /Users/jterrats/dev/JT_DynamicQueries
sf apex run --file scripts/provision-test-data.apex
```

### Paso 2: Ejecutar las pruebas E2E específicas

```bash
# Ejecutar solo las pruebas que fallaron
npm run test:e2e -- tests/e2e/soqlOperatorsValidation.spec.js

# O ejecutar en modo headed (ver el browser)
npm run test:e2e:headed -- tests/e2e/soqlOperatorsValidation.spec.js

# O ejecutar en modo UI interactivo
npm run test:e2e:ui -- tests/e2e/soqlOperatorsValidation.spec.js
```

### Paso 3: Revisar los resultados

Los tests fallarán con mensajes como:
```
Error: Query Risk Warning appeared unexpectedly - query would return >50,000 records.
Modal: ⚠️ Query Risk Warning... Estimated Records:99999
```

---

## 🖥️ Método 2: Reproducir Manualmente en la UI

### Configuración 1: Multiple IN Operators

1. **Abrir Dynamic Query Framework** en Salesforce
2. **Seleccionar configuración**: "Multiple IN Operators"
3. **Llenar parámetros**:
   - `validIndustries`: `Technology, Healthcare`
   - `accountTypes`: `Customer - Direct, Customer - Channel`
   - `validStates`: `WA, CA`
4. **Hacer clic en "Execute Query"**
5. **❌ Resultado esperado**: Debería aparecer el modal de riesgo con "Estimated Records: 99999"

### Configuración 2: LIKE Patterns Mixed

1. **Seleccionar configuración**: "LIKE Patterns Mixed"
2. **Llenar parámetros**:
   - `startsWith`: `StartsWith%`
   - `endsWith`: `%Test`
   - `websitePattern`: `%https://%`
   - `phonePattern`: `%555-%`
   - `descriptionKeyword`: `%test company%`
3. **Hacer clic en "Execute Query"**
4. **❌ Resultado esperado**: Debería aparecer el modal de riesgo con "Estimated Records: 99999"

### Configuración 3: All Comparison Operators

1. **Seleccionar configuración**: "All Comparison Operators"
2. **Llenar parámetros**:
   - `exactRevenue`: `1000000`
   - `notEqualRevenue`: `999999`
   - `lessThanRevenue`: `2000000`
   - `lessThanOrEqual`: `1000000`
   - `greaterThanRevenue`: `500000`
   - `greaterThanOrEqual`: `1000000`
   - `notEqualEmployees`: `999`
3. **Hacer clic en "Execute Query"**
4. **❌ Resultado esperado**: Debería aparecer el modal de riesgo con "Estimated Records: 99999"

### Configuración 4: Complex Mixed Operators (✅ Esta funciona)

1. **Seleccionar configuración**: "Complex Mixed Operators"
2. **Llenar parámetros**:
   - `industries`: `Technology, Healthcare`
   - `excludedType`: `Competitor`
   - `minRevenue`: `100000`
   - `maxRevenue`: `100000000`
   - `namePattern`: `%Acme%`
   - `industryPattern`: `%Tech%`
   - `minEmployees`: `10`
   - `maxEmployees`: `100`
   - `excludedCountries`: `Test Country`
3. **Hacer clic en "Execute Query"**
4. **✅ Resultado esperado**: Debería ejecutar correctamente y mostrar resultados (no modal de riesgo)

---

## 🔍 Método 3: Revisar Console Logs del Browser

### Durante las pruebas E2E (modo headed):

```bash
# Ejecutar en modo headed para ver el browser
npm run test:e2e:headed -- tests/e2e/soqlOperatorsValidation.spec.js
```

### En el browser, abrir DevTools (F12) y revisar:

1. **Console tab** - Buscar logs que empiecen con `🔍`:
   - `🔍 buildBindingsJson: Raw parameterValues`
   - `🔍 buildBindingsJson: Processed values`
   - `🔍 buildBindingsJson: Final JSON string`
   - `🔍 assessQueryRiskAndExecute: bindingsToSend`
   - `🔍 processParameterValues: Processing key=...`

2. **Network tab** - Buscar llamadas a `assessQueryRisk`:
   - Ver el `bindingsJson` que se está enviando
   - Ver la respuesta del servidor

---

## 📊 Método 4: Configurar Trace Flags para Debug Logs

### Paso 1: Obtener tu User ID

```bash
sf org display --json | grep -o '"id":"[^"]*"' | head -1
```

### Paso 2: Crear Trace Flag

```bash
# Reemplaza USER_ID con tu ID del paso anterior
sf data create record --sobject TraceFlag --values "TracedEntityId=USER_ID ApexCode=DEBUG ApexProfiling=DEBUG Callout=DEBUG Database=DEBUG System=DEBUG Validation=DEBUG Visualforce=DEBUG Workflow=DEBUG LogType=DEVELOPER_LOG StartDate=$(date -u +%Y-%m-%dT%H:%M:%S.000Z) ExpirationDate=$(date -u -v+1d +%Y-%m-%dT%H:%M:%S.000Z)"
```

### Paso 3: Ejecutar las pruebas E2E

```bash
npm run test:e2e -- tests/e2e/soqlOperatorsValidation.spec.js
```

### Paso 4: Obtener los logs

```bash
# Listar logs disponibles
sf apex list log

# Obtener el log más reciente (reemplaza LOG_ID)
sf apex get log --log-id LOG_ID > debug-log.txt

# Buscar errores del COUNT query
grep -i "COUNT query failed\|replaceBindVariables\|assessQueryRisk" debug-log.txt
```

---

## 🐛 Qué Buscar en los Logs

### En los Debug Logs de Apex, buscar:

1. **Errores del COUNT query**:
   ```
   COUNT query failed: ...
   ```

2. **Valores de bindings antes del reemplazo**:
   ```
   🔍 replaceBindVariables: key=..., value=..., type=...
   ```

3. **Query final después del reemplazo**:
   ```
   🔍 replaceBindVariables: final query=...
   ```

4. **Errores de conversión de tipos**:
   ```
   🔍 convertBindingValueForQuery: Failed to convert...
   ```

### En los Console Logs del Browser, buscar:

1. **Parámetros que se están enviando**:
   ```javascript
   🔍 buildBindingsJson: Final JSON string {"param1":"value1",...}
   ```

2. **Valores procesados**:
   ```javascript
   🔍 processParameterValues: Final processed object {...}
   ```

---

## 🔧 Debugging Rápido

### Verificar que los datos están provisionados:

```bash
# Ejecutar query directa en Salesforce para verificar datos
sf data query --query "SELECT COUNT() FROM Account WHERE Industry IN ('Technology', 'Healthcare') AND Type != 'Competitor'"
```

### Verificar bindings en el LWC:

1. Abrir Dynamic Query Framework en Salesforce
2. Abrir DevTools (F12)
3. En Console, ejecutar:
   ```javascript
   // Ver el estado del componente
   document.querySelector('c-jt-query-viewer').__debugInfo
   ```

---

## 📝 Notas Importantes

- **El problema**: El COUNT query está fallando y asignando `estimatedCount = 99999` cuando debería retornar < 20 registros
- **Causa probable**: Los bindings no se están aplicando correctamente antes de ejecutar el COUNT query
- **Configuraciones afectadas**: Multiple_IN_Operators, LIKE_Patterns_Mix, All_Comparison_Operators
- **Configuración que funciona**: Complex_Mixed_Operators (encontró 7 registros correctamente)

---

## ✅ Checklist para Reproducir

- [ ] Datos provisionados ejecutados (`sf apex run --file scripts/provision-test-data.apex`)
- [ ] Pruebas E2E ejecutadas (`npm run test:e2e -- tests/e2e/soqlOperatorsValidation.spec.js`)
- [ ] Errores confirmados (3 pruebas fallan con modal de riesgo)
- [ ] Reproducción manual en UI (modal aparece con 99,999 registros)
- [ ] Console logs del browser revisados (bindings se están enviando)
- [ ] Trace flags configurados (opcional, para debug logs de Apex)

