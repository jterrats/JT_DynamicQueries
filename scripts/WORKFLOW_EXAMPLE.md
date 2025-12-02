# Workflow Example: Multi-Org Deployment

## 🎯 Escenario: Cambiar entre Orgs

### Org 1: Developer (therionpolux-dev-ed)
```bash
# Cambiar a org dev
sf config set target-org my-dev-org

# Setup y deploy automático
./scripts/setup-org-url.sh
# 🌐 Org URL: https://therionpolux-dev-ed.my.salesforce.com

source .env && ./scripts/deploy-with-replacement.sh
# ✅ Named Credential deployed con: therionpolux-dev-ed.my.salesforce.com
```

### Org 2: Sandbox (company-staging.sandbox)
```bash
# Cambiar a org sandbox
sf config set target-org my-staging-sandbox

# Setup y deploy automático
./scripts/setup-org-url.sh
# 🌐 Org URL: https://company--staging.sandbox.my.salesforce.com

source .env && ./scripts/deploy-with-replacement.sh
# ✅ Named Credential deployed con: company--staging.sandbox.my.salesforce.com
```

### Org 3: Production (company.my)
```bash
# Cambiar a org production
sf config set target-org my-prod-org

# Setup y deploy automático
./scripts/setup-org-url.sh
# 🌐 Org URL: https://company.my.salesforce.com

source .env && ./scripts/deploy-with-replacement.sh
# ✅ Named Credential deployed con: company.my.salesforce.com
```

## 🔄 Flujo Automático

```
┌─────────────────────────────────────────────────────────────┐
│ Git Repository (Código Fuente)                               │
│                                                               │
│ JT_Tooling_API.namedCredential-meta.xml                     │
│ <endpoint>{!$Credential.JT_Tooling_API}</endpoint>          │
│                         ↓                                     │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Scripts detect target-org URL                                │
│                                                               │
│ sf org display --target-org XXX --json                       │
│ → https://org-specific-url.my.salesforce.com                │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Temporary file created (deployment only)                     │
│                                                               │
│ JT_Tooling_API.namedCredential-meta.xml                     │
│ <endpoint>https://org-specific-url.my.salesforce.com</endpoint>│
│                         ↓                                     │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Deployment to target-org                                     │
│                                                               │
│ sf project deploy start ...                                  │
│ ✅ Named Credential configured for THIS org                  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ Original file restored (Git unchanged)                       │
│                                                               │
│ JT_Tooling_API.namedCredential-meta.xml                     │
│ <endpoint>{!$Credential.JT_Tooling_API}</endpoint>          │
└─────────────────────────────────────────────────────────────┘
```

## 📝 Ventajas del Approach

### ✅ Con Scripts (Placeholder)
- 📦 **Un mismo código** funciona en todos los orgs
- 🔄 **Auto-detecta** la URL del org actual
- 🛡️ **Git limpio** (no hay cambios locales)
- 🚀 **Deploy rápido** a cualquier org
- 🎯 **Siempre correcto** (no hay chance de error)

### ❌ Sin Scripts (Hardcoded)
- 📦 **Código específico** por org (no escalable)
- 🔄 **Manual** (cambiar XML cada vez)
- 🛡️ **Git sucio** (merge conflicts)
- 🚀 **Deploy lento** (editar → commit → push)
- 🎯 **Error-prone** (fácil olvidar cambiar)

## 🎬 Demo Completo

```bash
# Terminal 1: Dev Org
cd /path/to/JT_DynamicQueries

# Switch to dev
sf config set target-org my-dev
./scripts/setup-org-url.sh && source .env && ./scripts/deploy-with-replacement.sh

# Test in dev
sf org open --path /lightning/n/modules/c/jtQueryViewer

# Terminal 2: Staging Org
cd /path/to/JT_DynamicQueries

# Switch to staging
sf config set target-org my-staging
./scripts/setup-org-url.sh && source .env && ./scripts/deploy-with-replacement.sh

# Test in staging
sf org open --path /lightning/n/modules/c/jtQueryViewer

# Git status: CLEAN (no changes)
git status
# On branch main
# nothing to commit, working tree clean ✅
```

## 🔐 Seguridad

El placeholder `{!$Credential.JT_Tooling_API}` en Git es **seguro**:
- ❌ No expone URLs de orgs reales
- ✅ Compatible con repos públicos de GitHub
- ✅ Cada org tiene su propia URL en runtime
- ✅ No hay secrets en el código

## 🌍 Use Case: Open Source Project

Si publicas el proyecto en GitHub:
1. Los usuarios clonen el repo
2. Ejecutan `./scripts/setup-org-url.sh`
3. El script detecta **su org** automáticamente
4. Deploy funciona para **su org**, no la tuya

**Sin placeholder**: Tendrían tu URL hardcodeada (therionpolux-dev-ed) ❌  
**Con placeholder**: Auto-detecta su org ✅

