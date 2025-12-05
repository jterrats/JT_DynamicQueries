# Sistema de Traducciones - Arquitectura

## Estado Actual

### **✅ Lo que YA tiene traducciones**

1. **Custom Objects**
   - `JT_DynamicQueryConfiguration__mdt`
   - `JT_DynamicQuerySettings__c`
   - `JT_SettingsAuditLog__c`
   - 📍 Ubicación: `force-app/main/default/objectTranslations/`
   - 🌍 Idiomas: de, en_US, es_MX, fr, it, ja, pt_BR, zh_CN

2. **LWC con labels.js**
   - `jtQueryViewer` → tiene `labels.js` con i18n completo
   - `jtProjectDocs` → tiene `docsContent.js` con multi-idioma
   - `jtSupport` → tiene `labels.js`

## ❌ Lo que FALTA traducir (Nuevos Componentes)

### **Componentes Fase 1-4**

```
jtSearchableCombobox
├── "Type to search..."
├── "Please select an option"
└── "No results found"

jtParameterInputs
├── "Query Parameters"
└── "No parameters required for this query"

jtExecuteButton
└── "Execute Query" (configurable via @api)

jtConfigModal
├── "Create New Configuration"
├── "Edit Configuration"
├── "Save Configuration"
├── "Update Configuration"
├── "Label", "Developer Name", "Base Query (SOQL)"
├── "Object Name", "Bindings (JSON)"
├── "Valid SOQL syntax", "Object:"
├── "Query Preview"
├── "Auto-detected from query"
├── "Only available in Sandbox/Scratch/Developer Orgs..."
└── "Note: This creates a Custom Metadata record via Tooling API..."

jtUsageModal
├── "Where is ... used?"
├── "Found X reference(s)"
├── "No usage found"
├── "Searching Apex classes and Flows..."
└── "This configuration is not currently referenced..."

jtRunAsSection
├── "Run As User (Advanced)"
├── "Select User to Impersonate (Optional)"
├── "Note: This validates user permissions..."
├── "Clear Selection"
├── "Execute with System.runAs (Test)"
└── "Executing test with System.runAs()..."
```

---

## 🎯 **Estrategias de Traducción**

### **Opción A: Labels.js (Recomendado) ✅**

**Pros:**

- ✅ Fácil de mantener
- ✅ Type-safe (JS constants)
- ✅ No requiere metadata deploy
- ✅ Carga rápida (bundle)

**Cons:**

- ❌ No usa Custom Labels de Salesforce
- ❌ Requiere código en cada componente

**Estructura:**

```javascript
// jtSearchableCombobox/labels.js
import { getUserLocale } from "c/utils";

const LABELS = {
  en_US: {
    placeholder: "Type to search...",
    noResults: "No results found",
    selectOption: "Please select an option"
  },
  es_MX: {
    placeholder: "Escribe para buscar...",
    noResults: "No se encontraron resultados",
    selectOption: "Por favor selecciona una opción"
  }
  // ... otros idiomas
};

export default function getLabels() {
  const locale = getUserLocale();
  return LABELS[locale] || LABELS.en_US;
}
```

### **Opción B: Custom Labels (Salesforce Native) ⚠️**

**Pros:**

- ✅ Native Salesforce
- ✅ Administradores pueden editar sin código
- ✅ Centralizado

**Cons:**

- ❌ Más lento (API calls)
- ❌ Requiere metadata deploy
- ❌ ~100+ labels para todos los componentes
- ❌ No type-safe

**Implementación:**

```xml
<!-- force-app/main/default/labels/CustomLabels.labels-meta.xml -->
<CustomLabels>
  <labels>
    <fullName>JT_SearchPlaceholder</fullName>
    <language>en_US</language>
    <protected>false</protected>
    <shortDescription>Search placeholder</shortDescription>
    <value>Type to search...</value>
  </labels>
  <!-- ... repetir para cada label y locale -->
</CustomLabels>
```

```javascript
// En el componente
import SEARCH_PLACEHOLDER from "@salesforce/label/c.JT_SearchPlaceholder";

export default class JtSearchableCombobox extends LightningElement {
  label = {
    placeholder: SEARCH_PLACEHOLDER
  };
}
```

### **Opción C: Híbrido (Componentes genéricos con @api) 🎯**

**Mejor de ambos mundos:**

```javascript
// jtSearchableCombobox.js
export default class JtSearchableCombobox extends LightningElement {
  @api placeholder = "Type to search...";
  @api noResultsText = "No results found";
  @api errorText = "Please select an option";

  // El componente padre pasa los labels traducidos
}
```

**Uso:**

```html
<!-- jtQueryViewer.html -->
<c-jt-searchable-combobox
  placeholder="{labels.searchConfigs}"
  no-results-text="{labels.noResults}"
  error-text="{labels.selectOption}"
></c-jt-searchable-combobox>
```

---

## 📝 **Recomendación Final**

### **Estrategia Recomendada: Opción C (Híbrido)**

**Por qué:**

1. ✅ **Componentes genéricos** → No hardcodean textos
2. ✅ **Flexible** → Puede usar labels.js O custom labels
3. ✅ **DRY** → Un solo lugar para traducir (jtQueryViewer/labels.js)
4. ✅ **Performance** → No múltiples imports de custom labels
5. ✅ **Maintainable** → Fácil de actualizar

**Implementación:**

```javascript
// jtQueryViewer/labels.js (EXTENDER EXISTENTE)
export const COMPONENT_LABELS = {
  en_US: {
    // jtSearchableCombobox
    searchPlaceholder: "Type to search...",
    noResults: "No results found",
    selectOption: "Please select an option",

    // jtParameterInputs
    queryParameters: "Query Parameters",
    noParametersRequired: "No parameters required for this query",

    // jtConfigModal
    createTitle: "Create New Configuration",
    editTitle: "Edit Configuration",
    saveButton: "Save Configuration",
    updateButton: "Update Configuration"

    // ... etc
  },
  es_MX: {
    searchPlaceholder: "Escribe para buscar...",
    noResults: "No se encontraron resultados",
    selectOption: "Por favor selecciona una opción"
    // ...
  }
  // ... otros idiomas
};
```

---

## 🚀 **Plan de Implementación**

### **Fase 1: Extender labels.js existente** ✅

1. Agregar labels para componentes nuevos a `jtQueryViewer/labels.js`
2. Pasar labels vía `@api` a componentes hijos
3. ~2 horas de trabajo

### **Fase 2: Custom Labels (opcional, futuro)**

1. Migrar a Custom Labels si se requiere administración por no-devs
2. ~5 horas de trabajo + testing

---

## 📊 **Comparativa de Costo**

| Estrategia        | Tiempo Impl | Lines of Code | Performance | Maintainability |
| ----------------- | ----------- | ------------- | ----------- | --------------- |
| **labels.js**     | 2h          | +200          | ⚡⚡⚡      | ⭐⭐⭐⭐        |
| **Custom Labels** | 5h          | +500 (XML)    | ⚡          | ⭐⭐⭐          |
| **Híbrido (Rec)** | 2h          | +150          | ⚡⚡⚡      | ⭐⭐⭐⭐⭐      |

---

## ✅ **Status Actual**

```
✅ CSS Dropdown - Fixed (deployed)
⏳ Traducciones - Pendiente de implementar
📝 Recomendación - Híbrido con labels.js
```

**Próximo paso:** ¿Proceder con implementación de labels híbridos?
