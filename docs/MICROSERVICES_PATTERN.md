# Microservices Pattern en Salesforce

## Arquitectura Resiliente para "Where is this used?"

### 🎯 **Problema Actual**

```apex
@AuraEnabled
public static List<UsageResult> findConfigurationUsage(String configName) {
  try {
    results.addAll(findInApexClasses(configName));  // ✅ No usa Tooling API
    results.addAll(findInFlows(configName));         // ❌ Usa Tooling API
    return results;
  } catch (Exception e) {
    throw new AuraHandledException('Error finding usage: ' + e.getMessage());
  }
}
```

**❌ Si Tooling API falla → TODO falla (pierdes resultados de Apex también)**

---

## ✅ **Solución: Servicios Independientes (Fault Isolation)**

### **1. Backend: Apex con Servicios Separados**

```apex
/**
 * @description Wrapper for service responses with fault isolation
 */
public class ServiceResponse {
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String error { get; set; }
    @AuraEnabled public List<UsageResult> data { get; set; }
    @AuraEnabled public String serviceName { get; set; }
}

/**
 * @description Aggregated response from multiple services
 */
public class AggregatedUsageResponse {
    @AuraEnabled public ServiceResponse apexService { get; set; }
    @AuraEnabled public ServiceResponse flowService { get; set; }
    @AuraEnabled public Boolean hasPartialResults { get; set; }
    @AuraEnabled public Integer totalResults { get; set; }
}

/**
 * 🎯 SERVICE 1: Apex Class Search (No dependencies)
 */
@AuraEnabled(cacheable=false)
public static ServiceResponse findInApexClassesService(String configName) {
    ServiceResponse response = new ServiceResponse();
    response.serviceName = 'Apex Classes';

    try {
        response.data = findInApexClasses(configName);
        response.success = true;
    } catch (Exception e) {
        response.success = false;
        response.error = e.getMessage();
        response.data = new List<UsageResult>();
    }

    return response;
}

/**
 * 🎯 SERVICE 2: Flow Search (Requires Tooling API + Named Credential)
 */
@AuraEnabled(cacheable=false)
public static ServiceResponse findInFlowsService(String configName) {
    ServiceResponse response = new ServiceResponse();
    response.serviceName = 'Flows';

    try {
        // Check if Tooling API is available
        if (!isToolingAPIAvailable()) {
            response.success = false;
            response.error = 'Tooling API Named Credential not configured';
            response.data = new List<UsageResult>();
            return response;
        }

        response.data = findInFlows(configName);
        response.success = true;
    } catch (System.CalloutException e) {
        response.success = false;
        response.error = 'Named Credential error: ' + e.getMessage();
        response.data = new List<UsageResult>();
    } catch (Exception e) {
        response.success = false;
        response.error = 'Flow search error: ' + e.getMessage();
        response.data = new List<UsageResult>();
    }

    return response;
}

/**
 * 🎯 ORCHESTRATOR: Calls both services and aggregates results
 */
@AuraEnabled(cacheable=false)
public static AggregatedUsageResponse findAllUsages(String configName) {
    AggregatedUsageResponse aggregated = new AggregatedUsageResponse();

    // Call services independently (parallel conceptually)
    aggregated.apexService = findInApexClassesService(configName);
    aggregated.flowService = findInFlowsService(configName);

    // Calculate metrics
    Integer apexCount = aggregated.apexService.success ? aggregated.apexService.data.size() : 0;
    Integer flowCount = aggregated.flowService.success ? aggregated.flowService.data.size() : 0;
    aggregated.totalResults = apexCount + flowCount;

    // Partial results flag
    aggregated.hasPartialResults =
        (aggregated.apexService.success && !aggregated.flowService.success) ||
        (!aggregated.apexService.success && aggregated.flowService.success);

    return aggregated;
}

/**
 * Helper: Check if Tooling API is configured
 */
private static Boolean isToolingAPIAvailable() {
    try {
        List<NamedCredential> nc = [
            SELECT Id
            FROM NamedCredential
            WHERE DeveloperName = 'JT_Tooling_API'
            LIMIT 1
        ];
        return !nc.isEmpty();
    } catch (Exception e) {
        return false;
    }
}
```

---

### **2. Frontend: LWC con Llamadas Paralelas**

```javascript
// jtQueryViewer.js

async handleShowUsageModal() {
    this.showUsageModal = true;
    this.isLoadingUsage = true;
    this.usageErrors = { apex: null, flow: null };

    try {
        // Call orchestrator (or call both services in parallel)
        const result = await findAllUsages({ configName: this.selectedConfig });

        // Process Apex results
        if (result.apexService.success) {
            this.usageResults = [...result.apexService.data];
            this.showInfoToast('Apex Search', `Found ${result.apexService.data.length} references in Apex`);
        } else {
            this.usageErrors.apex = result.apexService.error;
            this.showWarningToast('Apex Search Failed', result.apexService.error);
        }

        // Process Flow results
        if (result.flowService.success) {
            this.usageResults = [...this.usageResults, ...result.flowService.data];
            this.showInfoToast('Flow Search', `Found ${result.flowService.data.length} references in Flows`);
        } else {
            this.usageErrors.flow = result.flowService.error;
            this.showWarningToast('Flow Search Failed', result.flowService.error);
        }

        // Show partial results warning if needed
        if (result.hasPartialResults) {
            this.showWarningToast(
                'Partial Results',
                'Some searches failed. Showing available results only.'
            );
        }

        // Log usage if tracking enabled
        if (this.usageTrackingEnabled) {
            await logUsageSearch({
                configName: this.selectedConfig,
                apexSuccess: result.apexService.success,
                flowSuccess: result.flowService.success,
                totalResults: result.totalResults
            });
        }

    } catch (error) {
        this.showErrorToast('Search Error', error.body?.message);
    } finally {
        this.isLoadingUsage = false;
    }
}
```

---

### **3. UI: Mostrar Estado por Servicio**

```html
<!-- jtUsageModal.html -->
<template if:true="{hasPartialResults}">
  <div
    class="slds-notify slds-notify_alert slds-alert_warning slds-m-bottom_small"
  >
    <lightning-icon icon-name="utility:warning" size="x-small"></lightning-icon>
    <strong>Partial Results:</strong> Some searches failed.

    <!-- Apex Status -->
    <div class="slds-m-top_xx-small">
      <lightning-icon
        icon-name="{apexStatusIcon}"
        size="xx-small"
        variant="{apexStatusVariant}"
      ></lightning-icon>
      <span>Apex Classes: {apexStatusText}</span>
      <template if:true="{apexError}">
        <span class="slds-text-color_error"> - {apexError}</span>
      </template>
    </div>

    <!-- Flow Status -->
    <div class="slds-m-top_xx-small">
      <lightning-icon
        icon-name="{flowStatusIcon}"
        size="xx-small"
        variant="{flowStatusVariant}"
      ></lightning-icon>
      <span>Flows: {flowStatusText}</span>
      <template if:true="{flowError}">
        <span class="slds-text-color_error"> - {flowError}</span>
      </template>
    </div>
  </div>
</template>
```

---

## 🎯 **Ventajas de esta Arquitectura**

| Aspecto                   | Antes ❌                  | Después ✅                          |
| ------------------------- | ------------------------- | ----------------------------------- |
| **Fault Isolation**       | Un error rompe todo       | Servicios independientes            |
| **Partial Results**       | Todo o nada               | Muestra lo que funciona             |
| **Error Visibility**      | Error genérico            | Error específico por servicio       |
| **User Experience**       | Frustración total         | Resultados útiles aunque algo falle |
| **Debugging**             | Difícil identificar causa | Claro qué servicio falló            |
| **Dependency Management** | Tooling API obligatorio   | Tooling API opcional                |

---

## 📊 **Escenarios Cubiertos**

### ✅ **Escenario 1: Todo funciona**

```
Apex Service: ✅ 5 results
Flow Service: ✅ 2 results
Total: 7 results
```

### ⚠️ **Escenario 2: Named Credential no configurada**

```
Apex Service: ✅ 5 results
Flow Service: ❌ "Named Credential not configured"
Total: 5 results (Partial)
```

### ⚠️ **Escenario 3: Tooling API mal formado**

```
Apex Service: ✅ 5 results
Flow Service: ❌ "JSON parse error"
Total: 5 results (Partial)
```

### ⚠️ **Escenario 4: Error en Apex (raro pero posible)**

```
Apex Service: ❌ "Query exception"
Flow Service: ✅ 2 results
Total: 2 results (Partial)
```

### ❌ **Escenario 5: Todo falla (muy raro)**

```
Apex Service: ❌ "Error"
Flow Service: ❌ "Error"
Total: 0 results
UI: "No results available. Both searches failed."
```

---

## 🚀 **Implementación Progresiva**

### **Fase 1: Backend Refactor (30 min)**

- ✅ Crear `ServiceResponse` wrapper
- ✅ Separar métodos `@AuraEnabled`
- ✅ Agregar `isToolingAPIAvailable()` check

### **Fase 2: Frontend Adaptation (20 min)**

- ✅ Llamar nuevo método `findAllUsages`
- ✅ Manejar respuestas parciales
- ✅ Mostrar warnings específicos

### **Fase 3: UI Enhancement (15 min)**

- ✅ Badges de estado por servicio
- ✅ Tooltips explicativos
- ✅ Iconos de success/error

---

## 🎓 **Lecciones Aplicables a Otros Features**

Este patrón se puede aplicar a:

- ✅ Multi-org queries (dev/qa/prod)
- ✅ External API integrations (weather, stocks, etc.)
- ✅ Batch operations con retry logic
- ✅ Platform events + callouts híbridos

**Salesforce SÍ soporta "microservicios" conceptuales!** 💪
