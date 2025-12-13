# Análisis de CSS Custom en componentes LWC

## Resumen ejecutivo
- **Total de componentes con CSS**: 10
- **Líneas de CSS custom**: ~163 clases/reglas custom
- **Oportunidades de mejora**: Alto potencial de reducción mediante SLDS y CSS Hooks

## Componentes analizados

### 1. jtCacheModal (9 líneas)
**Estado**: ✅ Mínimo - Bien optimizado
- Solo 2 clases custom necesarias
- Resto usa SLDS correctamente

### 2. jtConfigModal (55 líneas)
**Oportunidades**:
- `.query-preview-text`: Puede usar SLDS `slds-text-body_small` + `slds-p-around_small` + custom fonts via CSS hooks
- `.preview-results`: Los `!important` indican acoplamiento fuerte - refactorizar
- `.modal-close-button`: Puede usar SLDS button variants

**Recomendación**: Refactorizar 70% del CSS

### 3. jtSearchableCombobox (270 líneas) ⚠️
**Estado**: CRÍTICO - Reimplementa casi todo SLDS
**Problemas**:
- Redefine completamente `.slds-dropdown`, `.slds-listbox`, `.slds-combobox_container`
- Muchos `!important` indican conflictos con SLDS
- Estilos redundantes (colores, tamaños ya definidos en SLDS)

**Recomendación**:
- Usar `lightning-combobox` nativo o `lightning-dual-listbox`
- Si custom, usar CSS Hooks para personalizaciones específicas
- Potencial de reducción: 85%

### 4. jtQueryResults (152 líneas)
**Oportunidades**:
- `.results-container`: Usar SLDS spacing classes
- `.json-content`, `.csv-content`: Consolidar en una clase + modificadores SLDS
- `.desktop-table`, `.mobile-cards`: Usar `slds-show_medium` / `slds-hide_medium`
- Media queries: Reemplazar con SLDS responsive utilities

**Recomendación**: Refactorizar 60% del CSS

### 5. jtQueryViewer (410 líneas) ⚠️
**Estado**: Ya optimizado parcialmente en sesión actual
**Pendiente**:
- Eliminar media queries restantes
- Consolidar clases `.mobile-cards`, `.desktop-table`
- Usar SLDS spacing tokens

### 6. jtDocumentation (28 líneas)
**Estado**: ✅ Bueno - Solo estilos de contenido markdown
- Necesario para renderizar markdown
- Mantener como está

### 7. jtProjectDocs (202 líneas)
**Oportunidades**:
- `.nav-link`: Puede usar `slds-button` con variant
- `.alert-info`, `.alert-warning`, `.alert-success`: Usar `lightning-alert` o SLDS `slds-box slds-theme_*`
- `.toc-grid`: Usar SLDS grid system
- Media queries: Usar SLDS responsive

**Recomendación**: Refactorizar 50% del CSS

### 8. jtSupport (42 líneas)
**Estado**: ✅ Aceptable
- Animaciones custom necesarias (hover, transform)
- Mantener estilos de interacción

### 9. jtParameterInputs (ya optimizado)
**Estado**: ✅ Optimizado en sesión actual

### 10. jtUsageModal (ya optimizado)
**Estado**: ✅ Optimizado en sesión actual

---

## Recomendaciones prioritarias

### 🔴 ALTA PRIORIDAD

#### 1. jtSearchableCombobox - Refactorización completa
**Problema**: Reimplementa SLDS desde cero
**Solución**:
```javascript
// Opción A: Usar componente nativo
<lightning-combobox
  label={label}
  options={options}
  value={value}
  onchange={handleChange}
></lightning-combobox>

// Opción B: CSS Hooks para personalizar SLDS
/* jtSearchableCombobox.css */
:host {
  --slds-c-combobox-dropdown-max-height: 300px;
  --slds-c-combobox-option-padding: 0.75rem 1rem;
}

.slds-combobox_container {
  /* Solo ajustes necesarios */
}
```

**Impacto**: Reducción de ~230 líneas (85%)

#### 2. jtConfigModal - Simplificar con SLDS + Hooks
```css
/* Antes: 15 líneas */
.query-preview-text {
  white-space: pre-wrap;
  word-wrap: break-word;
  font-family: "Courier New", Courier, monospace;
  font-size: 0.8125rem;
  color: #3e3e3c;
  margin: 0;
  padding: 0.75rem;
  background-color: #f3f3f3;
  border: 1px solid #dddbda;
  border-radius: 0.25rem;
  line-height: 1.5;
}

/* Después: HTML + 3 líneas CSS */
<pre class="slds-box slds-text-body_small slds-p-around_small query-preview-text"></pre>

/* CSS */
.query-preview-text {
  font-family: var(--lwc-fontFamilyMonospace, "Courier New", Courier, monospace);
  white-space: pre-wrap;
  word-wrap: break-word;
}
```

**Impacto**: Reducción de ~40 líneas (70%)

### 🟡 MEDIA PRIORIDAD

#### 3. jtQueryResults - Responsive con SLDS
```html
<!-- Antes: CSS media queries -->
<div class="desktop-table">...</div>
<div class="mobile-cards">...</div>

<!-- Después: SLDS responsive utilities -->
<div class="slds-show_medium slds-hide">...</div>
<div class="slds-hide_medium">...</div>
```

```css
/* Eliminar */
@media (min-width: 48rem) {
  .desktop-table { display: block; }
  .mobile-cards { display: none; }
}

/* Mantener solo estilos de estructura */
.desktop-table { overflow-x: auto; }
```

**Impacto**: Reducción de ~90 líneas (60%)

#### 4. jtProjectDocs - Alerts con SLDS
```html
<!-- Antes: CSS custom -->
<div class="alert-info">...</div>

<!-- Después: SLDS -->
<div class="slds-box slds-theme_info slds-m-around_medium">...</div>
```

```css
/* Eliminar 3 clases x 5 líneas = 15 líneas */
.alert-info { ... }
.alert-warning { ... }
.alert-success { ... }
```

**Impacto**: Reducción de ~100 líneas (50%)

---

## CSS Hooks - Guía de implementación

### Qué son los CSS Hooks de SLDS
Tokens CSS personalizables para componentes SLDS sin sobrescribir estilos.

### Ejemplo: Personalizar lightning-button
```css
:host {
  --slds-c-button-brand-color-background: #ff6b6b;
  --slds-c-button-brand-color-border: #ff6b6b;
  --slds-c-button-spacing-block-start: 0.5rem;
  --slds-c-button-spacing-block-end: 0.5rem;
}
```

### Hooks más útiles para el proyecto

#### Spacing
```css
:host {
  --slds-c-card-spacing-block: 1rem;
  --slds-c-card-spacing-inline: 1.5rem;
}
```

#### Typography
```css
:host {
  --slds-c-heading-font-size: 1.25rem;
  --slds-c-body-font-family: "SF Pro", system-ui;
}
```

#### Colors
```css
:host {
  --slds-c-input-color-border: #dddbda;
  --slds-c-input-color-background: #ffffff;
  --slds-c-input-color-border-focus: #1589ee;
}
```

---

## Plan de acción recomendado

### Fase 1: Componentes críticos (Sprint 1)
1. **jtSearchableCombobox**: Reemplazar o refactorizar completamente
   - Evaluar si `lightning-combobox` cubre casos de uso
   - Si no, implementar con CSS Hooks
   - **Ahorro estimado**: 230 líneas

2. **jtConfigModal**: Simplificar con SLDS
   - Usar `slds-box`, `slds-p-*`, `slds-m-*`
   - Consolidar clases de preview
   - **Ahorro estimado**: 40 líneas

### Fase 2: Componentes medios (Sprint 2)
3. **jtQueryResults**: Responsive SLDS
   - Reemplazar media queries
   - Usar `slds-show/hide` utilities
   - **Ahorro estimado**: 90 líneas

4. **jtProjectDocs**: SLDS components
   - Alerts con `slds-box slds-theme_*`
   - Nav links con `slds-button`
   - **Ahorro estimado**: 100 líneas

### Fase 3: Optimización final (Sprint 3)
5. **jtQueryViewer**: Finalizar optimización
6. **Linting y validación**: Code Analyzer
7. **Documentación**: CSS Hooks usados

---

## Métricas de éxito

| Métrica | Actual | Meta | Mejora |
|---------|--------|------|--------|
| Líneas CSS custom | ~1,100 | ~450 | -60% |
| Media queries | 15 | 0 | -100% |
| Clases custom | 163 | ~65 | -60% |
| Uso de !important | 85 | ~15 | -82% |
| Componentes optimizados | 3/10 | 10/10 | 100% |

---

## Referencias

### CSS Hooks documentation
- [SLDS Styling Hooks](https://www.lightningdesignsystem.com/platforms/lightning/styling-hooks/)
- [LWC CSS Best Practices](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.create_components_css)

### SLDS Utilities
- [Spacing](https://www.lightningdesignsystem.com/utilities/spacing/)
- [Sizing](https://www.lightningdesignsystem.com/utilities/sizing/)
- [Text](https://www.lightningdesignsystem.com/utilities/text/)
- [Visibility](https://www.lightningdesignsystem.com/utilities/visibility/)

### Lightning Components
- [lightning-combobox](https://developer.salesforce.com/docs/component-library/bundle/lightning-combobox)
- [lightning-button](https://developer.salesforce.com/docs/component-library/bundle/lightning-button)
- [lightning-card](https://developer.salesforce.com/docs/component-library/bundle/lightning-card)

