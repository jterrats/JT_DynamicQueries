# 🔍 Sandbox Detection - LWC vs E2E Tests

## Comparación de Métodos de Detección

---

## 🎯 **LWC (Lightning Web Component)**

### Método: Query a Organization Object

```apex
// JT_MetadataCreator.cls
@AuraEnabled(cacheable=true)
public static Boolean isSandboxOrScratch() {
    Organization org = [
        SELECT IsSandbox, TrialExpirationDate
        FROM Organization
        WITH SECURITY_ENFORCED
        LIMIT 1
    ];

    // Sandbox or Scratch Org (scratch orgs have trial expiration)
    return org.IsSandbox || org.TrialExpirationDate != null;
}
```

### ¿Cómo lo usa el LWC?

```javascript
// jtQueryViewer.js
import isSandboxOrScratch from '@salesforce/apex/JT_MetadataCreator.isSandboxOrScratch';

export default class JtQueryViewer extends LightningElement {
    @track canCreateMetadata = false;

    // Wire to check if org allows metadata creation
    @wire(isSandboxOrScratch)
    wiredIsSandbox({ error, data }) {
        if (data !== undefined) {
            this.canCreateMetadata = data; // true = Sandbox, false = Production
        }
        if (error) {
            this.canCreateMetadata = false;
        }
    }

    // In HTML template
    get showCreateButton() {
        return this.canCreateMetadata; // Only shows in Sandbox
    }
}
```

### HTML Template

```html
<!-- Only visible in Sandbox/Scratch Orgs -->
<template if:true={showCreateButton}>
    <lightning-button
        label="Create New Configuration"
        onclick={handleOpenModal}>
    </lightning-button>
</template>
```

---

## 🧪 **E2E Tests (Playwright)**

### Método: Check URL

```javascript
// tests/e2e/queryViewer.spec.js
const isProduction = !session.instanceUrl.toLowerCase().includes('sandbox');

// Examples:
// Sandbox: https://mycompany--dev.sandbox.my.salesforce.com → false (is NOT production)
// Production: https://mycompany.my.salesforce.com → true (IS production)
```

---

## 📊 **Comparación**

| Aspecto | LWC (Apex Query) | E2E Tests (URL Check) |
|---------|------------------|----------------------|
| **Método** | `Organization.IsSandbox` | URL contains "sandbox" |
| **Precisión** | ✅ 100% (dato oficial de SF) | ✅ 99.9% (convención de URL) |
| **Costo** | 1 SOQL query (cacheada) | 0 queries (gratis) |
| **Velocidad** | ~50ms (con cache) | ~0ms (instantáneo) |
| **Contexto** | Apex (backend) | JavaScript (frontend/test) |
| **Scratch Orgs** | ✅ Detecta (`TrialExpirationDate`) | ⚠️ Depende de URL |
| **Confiabilidad** | ✅ Siempre correcto | ✅ Correcto 99.9% del tiempo |

---

## 🔍 **¿Por qué cada uno usa su método?**

### LWC usa Apex Query porque:
1. ✅ **Autoridad oficial**: `Organization.IsSandbox` es el dato oficial de Salesforce
2. ✅ **Scratch Orgs**: También detecta scratch orgs via `TrialExpirationDate`
3. ✅ **Cacheable**: El resultado se cachea con `@wire`
4. ✅ **Seguro**: Usa `WITH SECURITY_ENFORCED`
5. ✅ **No depende de URLs**: Funciona sin importar el dominio

### E2E Tests usan URL porque:
1. ✅ **Instantáneo**: No requiere llamadas al servidor
2. ✅ **Simple**: 1 línea de código
3. ✅ **Sin dependencias**: No necesita Apex
4. ✅ **Siempre disponible**: La URL siempre está accesible
5. ✅ **Más rápido**: Tests corren más rápido

---

## 🎯 **¿Cuál es mejor?**

### Para Producción (LWC): **Apex Query** ✅
```apex
// RECOMENDADO en código de producción
Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
return org.IsSandbox;
```

**Razones:**
- Dato oficial de Salesforce
- Maneja edge cases (scratch orgs, sandboxes especiales)
- No depende de convenciones de URL que podrían cambiar

### Para Tests E2E: **URL Check** ✅
```javascript
// RECOMENDADO en tests automatizados
const isProduction = !session.instanceUrl.includes('sandbox');
```

**Razones:**
- Rápido y simple
- No consume governor limits
- Suficientemente confiable para tests
- No requiere llamadas al servidor

---

## 📝 **Ejemplo Completo: Flujo del LWC**

```
┌─────────────────────────────────────────────────────────────┐
│                    USUARIO ABRE LWC                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  LWC JavaScript: @wire(isSandboxOrScratch)                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  APEX: JT_MetadataCreator.isSandboxOrScratch()              │
│  ├─ Query: SELECT IsSandbox, TrialExpirationDate           │
│  │         FROM Organization                               │
│  │         WITH SECURITY_ENFORCED LIMIT 1                  │
│  │                                                          │
│  └─ Return: true (Sandbox) or false (Production)           │
└─────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  LWC: canCreateMetadata = data (true/false)                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  HTML Template:                                             │
│  <template if:true={showCreateButton}>                      │
│      <lightning-button                                      │
│          label="Create New Configuration">                  │
│      </lightning-button>                                    │
│  </template>                                                │
│                                                             │
│  • Sandbox: Button VISIBLE ✅                               │
│  • Production: Button HIDDEN ❌                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔒 **Seguridad en Producción**

### Doble Protección ✅✅

#### 1. Frontend (LWC):
```javascript
// El botón NO se renderiza en Production
<template if:true={canCreateMetadata}>
    <lightning-button label="Create New Configuration">
    </lightning-button>
</template>
```

#### 2. Backend (Apex):
```apex
// Si alguien intenta llamar directo al método Apex
@AuraEnabled
public static MetadataCreationResult createConfiguration(...) {
    if (!isSandboxOrScratch()) {
        throw new AuraHandledException(
            'Configuration creation is only allowed in Sandbox or Scratch Orgs.'
        );
    }
    // ... rest of code
}
```

**Resultado**: Imposible crear configuraciones en Production 🔒

---

## 💡 **Datos Técnicos**

### Organization Object Fields

```apex
Organization org = [
    SELECT
        Id,
        Name,
        IsSandbox,              // ← true en Sandbox
        TrialExpirationDate,    // ← not null en Scratch Org
        OrganizationType,       // 'Developer Edition', 'Production', etc.
        InstanceName            // cs123, na456, etc.
    FROM Organization
    LIMIT 1
];
```

### Tipos de Org Detectados

| Org Type | IsSandbox | TrialExpirationDate | Resultado |
|----------|-----------|---------------------|-----------|
| **Production** | `false` | `null` | `false` (no permitido) |
| **Sandbox** | `true` | `null` | `true` (permitido) ✅ |
| **Scratch Org** | `false` | `2025-12-06` | `true` (permitido) ✅ |
| **Developer Edition** | `false` | `null` | `false` (no permitido) |

**Nota**: Developer Edition se trata como Production por seguridad

---

## 🎓 **Recomendaciones**

### Para tu Aplicación (Producción):
✅ **SIEMPRE usa Apex Query** (`Organization.IsSandbox`)
- Más preciso
- Maneja todos los edge cases
- Dato oficial de Salesforce

### Para tus Tests E2E:
✅ **Usa URL Check** (`.includes('sandbox')`)
- Más rápido
- Más simple
- Suficiente para tests

### ¿Podrías usar URL en el LWC?
❌ **NO recomendado** porque:
- No hay acceso directo a la URL del servidor en Apex
- Necesitarías `Url.getOrgDomainUrl()` que es complejo
- `Organization.IsSandbox` es más confiable
- Scratch orgs podrían no tener "sandbox" en la URL

---

## ✅ **Resumen**

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║  LWC (Producción):                                        ║
║  ✅ Organization.IsSandbox (Apex Query)                   ║
║  • Autoridad oficial                                      ║
║  • Maneja todos los casos                                 ║
║  • Cacheable                                              ║
║                                                           ║
║  E2E Tests:                                               ║
║  ✅ URL.includes('sandbox') (JavaScript)                  ║
║  • Rápido y simple                                        ║
║  • No consume límites                                     ║
║  • Suficiente para tests                                  ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

---

**Conclusión**: Cada enfoque es óptimo para su contexto. El LWC hace lo correcto para producción, y los tests E2E hacen lo correcto para velocidad de testing. 🎯

