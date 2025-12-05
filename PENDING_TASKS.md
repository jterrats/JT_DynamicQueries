# 📋 Tareas Pendientes - JT Dynamic Queries v2.0

## ✅ **COMPLETADAS (Hasta ahora)**

### 🏗️ **Arquitectura & Refactoring**

- ✅ Refactor de `jtQueryViewer` a componentes modulares (6 componentes)
- ✅ Shadow DOM CSS fix para componentes hijos
- ✅ Labels i18n (EN, ES, FR, DE) con sistema modular
- ✅ Patrón de microservicios resiliente (fault isolation)
- ✅ Servicios independientes: Apex + Flow search

### 🔒 **Seguridad & Performance**

- ✅ PMD/ESLint security scan completado
- ✅ USER_MODE en SOQL queries
- ✅ FLS/CRUD checks en controllers
- ✅ ApexDoc comments en clases principales
- ✅ Audit logging para cambios críticos

### 🧪 **Testing**

- ✅ Apex test coverage (inicial)
- ✅ E2E tests con Playwright
- ✅ Test de "Run As User" con System.runAs()

### 🎨 **UI/UX**

- ✅ Responsive design (desktop + mobile)
- ✅ WCAG 2.1 AA accessibility
- ✅ Pagination en resultados (10 per page)
- ✅ Toggle views: Table/JSON/CSV
- ✅ "Where is this used?" con fault isolation

---

## 🚧 **PENDIENTES**

### 1️⃣ **Testing (CRÍTICO para AppExchange)**

**Prioridad:** 🔴 ALTA

#### Apex Test Coverage

- [ ] **JT_UsageFinder.cls** - Agregar tests para:
  - `findInApexClassesService()` - Success case
  - `findInFlowsService()` - Success & failure cases
  - `findAllUsagesResilient()` - Aggregation logic
  - `isToolingAPIAvailable()` - Named Credential checks

- [ ] **JT_QueryViewerController.cls** - Completar coverage:
  - [ ] Casos edge de parámetros dinámicos
  - [ ] Validación de SOQL injection
  - [ ] Error handling en extractParameters

- [ ] **JT_ProductionSettingsController.cls** - Verificar:
  - [ ] Audit log creation sin permisos
  - [ ] Usage tracking toggle
  - [ ] Production override scenarios

#### E2E Tests

- [ ] **Test resilient services:**
  - [ ] Escenario: Named Credential no configurada → Muestra solo Apex
  - [ ] Escenario: Tooling API error → Muestra warning + partial results
  - [ ] Escenario: Ambos servicios exitosos → Muestra total

- [ ] **Test responsive design:**
  - [ ] Mobile view (expandable cards)
  - [ ] Desktop view (table)
  - [ ] Toggle views (Table/JSON/CSV)

---

### 2️⃣ **Documentación (CRÍTICO para AppExchange)**

**Prioridad:** 🔴 ALTA

#### Docs faltantes:

- [ ] **Setup Guide** - Named Credential para Tooling API
- [ ] **User Guide** - Screenshots/videos de features
- [ ] **Admin Guide** - Permission Set, Custom Settings, Audit Log
- [ ] **Developer Guide** - API reference, extensibility
- [ ] **Release Notes** - Changelog para v2.0
- [ ] **Troubleshooting** - Common errors y soluciones

#### GitHub Pages:

- [ ] Configurar Jekyll
- [ ] Agregar videos de E2E tests
- [ ] Documentación multi-idioma
- [ ] API reference interactivo

---

### 3️⃣ **Named Credential Setup (CRÍTICO)**

**Prioridad:** 🔴 ALTA

- [ ] **Crear guía paso a paso:**
  1. Connected App setup
  2. Named Credential configuration
  3. Permission Set assignment
  4. Validation tests

- [ ] **Agregar script de validación:**

  ```apex
  // Anonymous Apex para verificar setup
  Boolean isConfigured = JT_UsageFinder.isToolingAPIAvailable();
  System.debug('Tooling API Ready: ' + isConfigured);
  ```

- [ ] **UI indicator:**
  - Badge en app mostrando "Tooling API: ✓ Ready" o "⚠️ Not Configured"
  - Link directo a documentación de setup

---

### 4️⃣ **Performance & Scalability**

**Prioridad:** 🟡 MEDIA

- [ ] **Apex Cursors** - Implementar cuando salga de Beta:

  ```apex
  // TODO: Replace with Database.getCursor() when available in API v66+
  public static void processLargeResults(String configName) {
    Database.Cursor<SObject> cursor = Database.getCursor(query);
    while (cursor.hasNext()) {
      // Process in chunks
    }
  }
  ```

- [ ] **Platform Cache** - Optimizar queries frecuentes:
  - [ ] Cache de configurations (5 min TTL)
  - [ ] Cache de user list (10 min TTL)
  - [ ] Cache de usage search results (1 hour TTL)

- [ ] **Queueable Apex** - Para "Where is this used?" en orgs grandes:
  - [ ] Background processing para 500+ Apex classes
  - [ ] Progress indicator en LWC
  - [ ] Email notification cuando completa

---

### 5️⃣ **Features Adicionales (AppExchange Enhancement)**

**Prioridad:** 🟢 BAJA (Nice to Have)

#### Reports & Dashboards

- [ ] **Report Type:** Usage Statistics
  - Fields: Config Name, # of Uses, Last Used Date, Used By
  - Filters: Object Type, Metadata Type

- [ ] **Dashboard:** JT Dynamic Queries Analytics
  - Widget 1: Most Used Configurations
  - Widget 2: Unused Configurations (cleanup candidates)
  - Widget 3: Usage Over Time
  - Widget 4: Tooling API Call Consumption

#### Metadata Export/Import

- [ ] **Export configurations to JSON**
  - Download all configs as backup
  - Use case: Migration between orgs

- [ ] **Import configurations from JSON**
  - Upload JSON file
  - Validate before import
  - Conflict resolution (overwrite/skip)

#### Schedule Query Execution

- [ ] **Schedulable Apex** para queries recurrentes:
  ```apex
  global class JT_ScheduledQueryExecutor implements Schedulable {
    // Execute query daily/weekly
    // Store results in Custom Object
    // Send email digest
  }
  ```

#### Apex Actions for Agentforce

- [x] ✅ `@InvocableMethod` ya implementado
- [ ] **Agregar más actions:**
  - `validateConfiguration()` - Check if config exists & is valid
  - `getConfigurationMetadata()` - Return object info, field list
  - `countResults()` - Return only count without full data

---

### 6️⃣ **Internationalization (i18n) Completo**

**Prioridad:** 🟡 MEDIA

- [ ] **Agregar más idiomas:**
  - [ ] Italiano (IT)
  - [ ] Japonés (JA)
  - [ ] Portugués (PT)
  - [ ] Chino Simplificado (ZH)

- [ ] **Custom Labels** para strings hardcodeados:
  - [ ] Error messages
  - [ ] Button labels
  - [ ] Help text
  - [ ] Toast messages

---

### 7️⃣ **Security Enhancements**

**Prioridad:** 🟡 MEDIA

- [ ] **CSRF Token** para Tooling API calls
- [ ] **Rate Limiting** para "Where is this used?" searches
- [ ] **IP Whitelisting** check para producción
- [ ] **Field-Level Encryption** support para campos sensibles
- [ ] **Audit Trail** completo:
  - [ ] Track query executions
  - [ ] Track configuration changes
  - [ ] Track "Run As User" usage
  - [ ] Retention policy (90 days default)

---

### 8️⃣ **AppExchange Listing**

**Prioridad:** 🔴 ALTA (cuando todo esté listo)

#### Pre-requisitos:

- [ ] **Code coverage ≥ 85%** (actualmente ~70%)
- [ ] **Security review passed** (PMD/ESLint clean ✅)
- [ ] **Documentation complete** (pendiente)
- [ ] **Demo video** (< 3 minutos)
- [ ] **Screenshots** (5-8 imágenes de alta calidad)
- [ ] **Support email/portal** configurado

#### Listing content:

- [ ] **Product description** (300-500 words)
- [ ] **Key features list** (bullets)
- [ ] **Use cases** (3-5 scenarios)
- [ ] **Pricing model** decision:
  - Free tier?
  - Per-user pricing?
  - Per-org flat rate?
  - Freemium (basic free, advanced paid)?

---

## 🎯 **Roadmap Sugerido**

### **Sprint 1 (Próxima semana)** - AppExchange Readiness

1. ✅ Completar Apex test coverage → 85%
2. ✅ Named Credential setup guide completo
3. ✅ Crear demo video (screencast)
4. ✅ Screenshots de todas las features

### **Sprint 2** - Documentación

1. Setup Guide completo
2. User Guide con ejemplos
3. Troubleshooting guide
4. GitHub Pages setup

### **Sprint 3** - Testing Final

1. E2E tests para microservicios
2. Security review checklist
3. Performance testing (1000+ records)
4. UAT con usuarios beta

### **Sprint 4** - AppExchange Submission

1. Listing content
2. Pricing model
3. Support setup
4. Submit para review

---

## 📊 **Métricas Actuales**

| Métrica            | Actual      | Objetivo AppExchange | Status |
| ------------------ | ----------- | -------------------- | ------ |
| **Apex Coverage**  | ~70%        | ≥85%                 | 🟡     |
| **LWC Components** | 7           | -                    | ✅     |
| **Translations**   | 4 idiomas   | 4+                   | ✅     |
| **E2E Tests**      | 5 scenarios | 10+                  | 🟡     |
| **Documentation**  | Parcial     | Completa             | 🟡     |
| **Security Scan**  | ✅ Clean    | Clean                | ✅     |
| **Demo Video**     | ❌          | ✓                    | ❌     |

---

## 💡 **Sugerencias de Priorización**

### **Si el objetivo es AppExchange RÁPIDO:**

1. Test coverage → 85%
2. Named Credential guide
3. Demo video + screenshots
4. Submit (defer otros features)

### **Si el objetivo es PRODUCTO COMPLETO:**

1. Test coverage + E2E completo
2. Documentación exhaustiva
3. Performance optimizations
4. Features adicionales (Reports, Export/Import)
5. Submit cuando esté maduro

---

## 🤝 **Siguiente Paso Sugerido**

**Opción A:** Completar test coverage ahora (1-2 horas)
**Opción B:** Setup Named Credential guide primero (30 min)
**Opción C:** Demo video para validar UX (1 hora)

**¿Qué prefieres atacar primero?**


