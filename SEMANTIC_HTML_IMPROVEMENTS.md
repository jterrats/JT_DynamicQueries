# 🎯 Mejoras de HTML Semántico - Plan de Implementación

## 📋 Objetivo

Asegurar que todos los IDs, names, data-attributes y clases CSS en los LWC sean:
- **Semánticos**: Describen claramente su propósito
- **No ambiguos**: Únicos y específicos al contexto
- **Testeables**: Fáciles de seleccionar en E2E tests
- **Mantenibles**: Fáciles de entender para desarrolladores

---

## 🔍 Análisis de Componentes

### ✅ **jtSearchableCombobox** - MEJORAR

**Problemas actuales:**
```html
<input id="combobox-input" />        <!-- ❌ Genérico -->
<div id="listbox-id" />               <!-- ❌ No descriptivo -->
```

**Mejoras propuestas:**
```html
<input
  id="searchable-combobox-input"
  data-testid="searchable-combobox-input"
  name="{contextualName}"            <!-- Pasado como prop -->
  aria-label="{label}"
/>
<div
  id="searchable-combobox-listbox"
  data-testid="searchable-combobox-dropdown"
  role="listbox"
/>
```

**Beneficios:**
- Tests E2E pueden usar: `page.locator('[data-testid="config-selector-input"]')`
- Único en el contexto del componente padre

---

### ✅ **jtParameterInputs** - MEJORAR

**Estado actual:**
```html
<lightning-input data-param="{param.name}" />
```

**Mejoras propuestas:**
```html
<lightning-input
  data-param="{param.name}"
  data-testid="query-parameter-{param.name}"
  name="query-parameter-{param.name}"
  aria-label="Query parameter: {param.label}"
/>
```

**Beneficios:**
- Tests pueden seleccionar parámetros específicos: `page.locator('[data-testid="query-parameter-accountName"]')`

---

### ✅ **jtExecuteButton** - MEJORAR

**Problema actual:**
- No hay identificadores específicos más allá del label

**Mejoras propuestas:**
```html
<lightning-button
  data-testid="execute-query-button"
  name="execute-query"
  aria-label="Execute selected query configuration"
/>
```

---

### ✅ **jtCacheModal** - MEJORAR

**Problemas actuales:**
```html
<lightning-input label="Query Configurations" />  <!-- ❌ Solo label -->
<button class="slds-button slds-button_brand" /> <!-- ❌ No ID -->
```

**Mejoras propuestas:**
```html
<lightning-input
  type="checkbox"
  data-testid="cache-option-configurations"
  name="cache-option-configurations"
  label="Query Configurations"
/>

<button
  data-testid="cache-clear-button"
  name="clear-cache"
  aria-label="Clear selected cache options"
/>
```

**Beneficios:**
- Tests: `page.locator('[data-testid="cache-option-configurations"]').check()`
- Tests: `page.locator('[data-testid="cache-clear-button"]').click()`

---

### ✅ **jtQueryViewer** - MEJORAR

**Problemas actuales:**
```html
<!-- View toggle buttons -->
<lightning-button data-view="table" />    <!-- ⚠️  Podría mejorarse -->
<lightning-button data-view="json" />
<lightning-button data-view="csv" />

<!-- Pagination -->
<lightning-button icon-name="utility:chevronleft" />  <!-- ❌ No ID -->
<lightning-button icon-name="utility:chevronright" /> <!-- ❌ No ID -->

<!-- Mobile cards -->
<article class="slds-card" data-id={row.Id} />  <!-- ⚠️  Mejora menor -->
```

**Mejoras propuestas:**
```html
<!-- View toggle buttons -->
<lightning-button
  data-view="table"
  data-testid="results-view-toggle-table"
  name="results-view-table"
  aria-label="View results as table"
/>

<!-- Pagination -->
<lightning-button
  data-testid="pagination-previous"
  name="pagination-previous"
  icon-name="utility:chevronleft"
  aria-label="Go to previous page"
/>

<!-- Mobile cards -->
<article
  class="slds-card mobile-result-card"
  data-testid="result-card-{row.Id}"
  data-row-id="{row.Id}"
/>

<!-- Clear Cache Button -->
<lightning-button
  data-testid="header-clear-cache-button"
  name="clear-cache"
  aria-label="Open cache management modal"
/>

<!-- Create Config Button -->
<lightning-button
  data-testid="header-create-config-button"
  name="create-configuration"
  aria-label="Create new query configuration"
/>
```

---

### ✅ **jtRunAsSection** - MEJORAR

**Mejoras propuestas:**
```html
<c-jt-searchable-combobox
  data-testid="run-as-user-selector"
  name="run-as-user"
/>

<lightning-button
  data-testid="run-as-clear-button"
  name="run-as-clear"
/>

<lightning-button
  data-testid="run-as-execute-button"
  name="run-as-execute"
/>
```

---

### ✅ **jtConfigModal** - MEJORAR

**Mejoras propuestas:**
```html
<lightning-input
  data-testid="config-label-input"
  name="config-label"
  label="Label"
/>

<lightning-textarea
  data-testid="config-query-input"
  name="config-base-query"
  label="SOQL Query"
/>

<lightning-button
  data-testid="config-save-button"
  name="save-configuration"
/>
```

---

## 🎯 Convención de Nombres

### **data-testid Pattern:**
```
{componentContext}-{element}-{type}

Ejemplos:
- "config-selector-input"
- "query-parameter-accountName"
- "execute-query-button"
- "cache-option-configurations"
- "pagination-previous"
- "results-view-toggle-table"
```

### **name Pattern:**
```
{function}-{detail}

Ejemplos:
- "execute-query"
- "clear-cache"
- "create-configuration"
- "run-as-user"
- "query-parameter-accountName"
```

### **ID Pattern (si es necesario):**
```
{componentName}-{element}-{uniqueId}

Ejemplos:
- "searchable-combobox-input"
- "cache-modal-heading"
- "execute-button-status"
```

---

## 📊 Prioridad de Implementación

### **Alta Prioridad (Crítico para E2E)**

1. ✅ **jtSearchableCombobox** - Usado en múltiples lugares
2. ✅ **jtExecuteButton** - Acción principal
3. ✅ **jtParameterInputs** - Entrada de datos crítica
4. ✅ **jtCacheModal** - Tests de cache management

### **Media Prioridad**

5. ✅ **jtQueryViewer** - Componente principal
6. ✅ **jtRunAsSection** - Feature importante

### **Baja Prioridad**

7. ⚠️ **jtConfigModal** - Menos usado en tests
8. ⚠️ **jtQueryResults** - Ya tiene estructura clara
9. ⚠️ **jtUsageModal** - Read-only modal

---

## 🚀 Implementación

### Paso 1: Agregar `data-testid` a componentes reutilizables

Componentes que RECIBEN `data-testid` como prop:
- `c-jt-searchable-combobox`
- `c-jt-execute-button`
- `c-jt-parameter-inputs`

### Paso 2: Agregar `data-testid` a elementos en componentes padre

Componentes que USAN los reutilizables con `data-testid` específico:
- `c-jt-query-viewer`
- `c-jt-cache-modal`
- `c-jt-run-as-section`

### Paso 3: Actualizar tests E2E

Cambiar de:
```javascript
page.locator('lightning-button').filter({ hasText: /Execute/i })
```

A:
```javascript
page.locator('[data-testid="execute-query-button"]')
```

---

## ✅ Beneficios

1. **Tests E2E más robustos**: No dependen de texto que puede cambiar con i18n
2. **Selectores más rápidos**: `data-testid` es más rápido que filtros de texto
3. **Código más mantenible**: Nombres claros facilitan debugging
4. **Accesibilidad mejorada**: ARIA labels más específicos
5. **Menos fallos por ambigüedad**: Selectores únicos evitan "strict mode violations"

---

## 📝 Checklist de Implementación

### jtSearchableCombobox
- [ ] Agregar prop `dataTestId`
- [ ] Agregar prop `name`
- [ ] Usar en input: `data-testid="{dataTestId}-input"`
- [ ] Usar en dropdown: `data-testid="{dataTestId}-dropdown"`
- [ ] Usar en options: `data-testid="{dataTestId}-option-{value}"`

### jtExecuteButton
- [ ] Agregar prop `dataTestId`
- [ ] Agregar prop `name`
- [ ] Default: `data-testid="execute-query-button"`

### jtParameterInputs
- [ ] Agregar `data-testid` a cada input
- [ ] Pattern: `query-parameter-{paramName}`

### jtCacheModal
- [ ] Agregar `data-testid` a cada checkbox
- [ ] Agregar `data-testid` a botones
- [ ] Agregar `data-testid` al select all

### jtQueryViewer
- [ ] Agregar `data-testid` a view toggle buttons
- [ ] Agregar `data-testid` a pagination buttons
- [ ] Agregar `data-testid` a header actions
- [ ] Pasar `data-testid` a componentes hijos

### jtRunAsSection
- [ ] Pasar `data-testid` a searchable combobox
- [ ] Agregar `data-testid` a botones

---

## 🎉 Resultado Esperado

**Antes:**
```javascript
// Test frágil
const button = page.locator('lightning-button').filter({ hasText: /Execute/i });
```

**Después:**
```javascript
// Test robusto
const button = page.locator('[data-testid="execute-query-button"]');
```

**Antes:**
```javascript
// Selector ambiguo
const combobox = page.locator('c-jt-query-viewer lightning-combobox');
// Error: found 2 elements ❌
```

**Después:**
```javascript
// Selector específico
const configSelector = page.locator('[data-testid="config-selector-input"]');
const userSelector = page.locator('[data-testid="run-as-user-selector-input"]');
// ✅ No ambiguity
```

---

**Fecha de creación**: 1 Diciembre 2024
**Status**: 🚧 En Progreso

