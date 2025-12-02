# 🔧 Apex Development Flow

## Flujo para Cambios que Involucran Apex

Cuando tus cambios incluyen **Apex classes, controllers, o métodos `@AuraEnabled`**, sigue este flujo:

```
Modificar → Unit Test Apex → Deploy → Run Apex Tests → Success? → E2E : Fix & Reiterar
```

---

## 📋 Paso a Paso

### 1️⃣ Modificar Código

```apex
// Ejemplo: Agregar método executeQueryPreview
@AuraEnabled
public static QueryResult executeQueryPreview(
  String devName,
  String bindingsJson
) {
  // Implementation
}
```

### 2️⃣ Escribir/Actualizar Unit Test Apex

```apex
@isTest
static void testExecuteQueryPreview() {
  // Arrange
  String devName = 'Test_Record';
  String bindings = '{"accountType": "Customer"}';

  // Act
  Test.startTest();
  QueryResult result = JT_QueryViewerController.executeQueryPreview(
    devName,
    bindings
  );
  Test.stopTest();

  // Assert
  System.assertEquals(true, result.success);
  System.assert(result.recordCount <= 5);
}
```

**⚠️ IMPORTANTE:** No puedes pasar al siguiente paso sin este test!

### 3️⃣ Deploy Cambios a Org

```bash
# Deploy to target org
sf project deploy start --target-org <alias>

# Wait for deployment to complete
# Check for errors
```

**Si hay errores de deploy:** Fix → Redeploy → Repeat

### 4️⃣ Run Apex Tests del Proyecto

```bash
# Run ALL local tests in org
sf apex run test --target-org <alias> \
  --test-level RunLocalTests \
  --result-format human \
  --code-coverage
```

**Verifica:**

```
✅ All tests pass?
  → Proceed to step 5

❌ Some tests fail?
  → Go to step 5 (Review Errors)
```

### 5️⃣ Decisión: Success o Error?

#### ✅ Si ALL Tests Pass:

```bash
# Coverage: 84.5% ✓
# Pass Rate: 100% ✓
# No failures ✓

# → Proceed to E2E tests (Step 6)
```

#### ❌ Si Hay Errores:

```bash
# 1. Revisar errores en consola
sf apex get test --test-run-id <id>

# 2. Identificar qué falló
# - Assertion failure?
# - Exception thrown?
# - Null pointer?
# - Governor limit?

# 3. Corregir el código
# - Fix Apex class
# - Fix unit test
# - Add null checks
# - Handle edge cases

# 4. Reiterar desde paso 3 (Deploy)
sf project deploy start
sf apex run test --test-level RunLocalTests

# Repeat until ALL tests pass ✓
```

### 6️⃣ Run E2E Tests (Solo después de Apex tests passing)

```bash
# E2E tests run against deployed code in org
npm run test:e2e

# Verify:
# ✅ 14/14 tests pass
# ✅ Videos generated
```

### 7️⃣ Review E2E Videos

```bash
# Open videos folder
open test-results/

# Watch ALL .webm files
# Validate:
# - UI looks correct
# - No visual glitches
# - Parameters work
# - Bindings correct
```

### 8️⃣ Manual Validation in Org

```bash
# Login to org
# Navigate to Query Viewer
# Test the specific scenario:
# 1. Select configuration with parameters
# 2. Enter parameter values (accountType: "Customer", industry: "Tech")
# 3. Click Execute
# 4. Verify results returned
# 5. Check console for errors
```

### 9️⃣ Commit (Solo después de TODO lo anterior)

```bash
git add -A
git commit -m "feat(apex): Add executeQueryPreview method

✨ Feature: Query preview with data
✅ Apex Tests: 2/2 pass in org
✅ E2E Tests: 14/14 pass
✅ Manual Test: Verified in org
✅ Coverage: 84.5%

Error-Driven:
- Error: Method not found
- Fix: Created @AuraEnabled method
- Error: List no rows
- Fix: Added LIMIT 1
- All tests pass ✓"

git push origin main
```

---

## 🔄 Flujo Completo (Diagrama)

```mermaid
graph TD
    A[1. Modificar Código Apex<br/>- Add method<br/>- Change logic<br/>- Fix bug] --> B[2. Escribir Unit Test Apex<br/>- @isTest method<br/>- Arrange → Act → Assert<br/>- Test happy path + edge cases]

    B --> C[3. Deploy to Org<br/>sf project deploy start]

    C --> D{Deploy Success?}
    D -->|❌ NO| E[Fix Deploy Error]
    E --> C

    D -->|✅ YES| F[4. Run Apex Tests in Org<br/>sf apex run test --test-level RunLocalTests]

    F --> G{Tests Pass?}

    G -->|❌ FAIL| H[5. Review Errors<br/>- Read stack trace<br/>- Identify root cause]
    H --> I[6. Corregir<br/>- Fix Apex code<br/>- Update test]
    I --> J[7. Reiterar<br/>Back to Step 3]
    J --> C

    G -->|✅ PASS| K[8. Run E2E Tests<br/>npm run test:e2e<br/>against deployed code]

    K --> L[9. Review E2E Videos<br/>- Watch .webm files<br/>- Validate UI/UX<br/>- Check for visual issues]

    L --> M[10. Manual Validation in Org<br/>- Test scenarios manually<br/>- Check console for errors<br/>- Verify expected behavior]

    M --> N[11. ✅ Commit & Push<br/>git add -A<br/>git commit -m "..."<br/>git push origin main]

    style A fill:#e1f5ff
    style B fill:#fff4e1
    style C fill:#ffe1f5
    style F fill:#e1ffe1
    style G fill:#fff9e1
    style K fill:#e1e1ff
    style N fill:#d4edda
```

---

## 🎯 Ejemplo Real: Bug del Binding

### Error Actual:

```
Key 'accountType' does not exist in the bindMap
```

### EDD Flow:

#### Step 1: Modificar

Ya modificamos para agregar debug logging

#### Step 2: Unit Test Apex

Ya existe: `testExecuteQuery()` en `JT_QueryViewerController_Test`

#### Step 3: Deploy

```bash
sf project deploy start
```

#### Step 4: Run Apex Tests

```bash
sf apex run test --test-level RunLocalTests
```

**Resultado esperado:**

- ✅ All pass → Proceed to E2E
- ❌ Fail → Review error, fix, redeploy

#### Step 5-7: Si Falla

```bash
# Review error
sf apex get test --test-run-id <id>

# Error might say:
# "Variable does not exist: accountType"
# → Fix: Ensure parameter name matches exactly

# Or:
# "List has no rows"
# → Fix: Add LIMIT 1 to query

# Or:
# "JSON parse exception"
# → Fix: Validate JSON format
```

#### Step 8: E2E Tests

```bash
npm run test:e2e
```

#### Step 9: Review Videos

```bash
open test-results/
# Watch video where parameter is entered
# See if accountType appears in console logs
```

#### Step 10: Manual Test

```bash
# Login to org
# Open Query Viewer
# Open Browser Console (F12)
# Select configuration with parameters
# Enter accountType: "Customer"
# Enter industry: "Technology"
# Click Execute
# READ CONSOLE LOGS:
#   📝 this.parameterValues: {"accountType": "Customer", "industry": "Technology"}
#   🔍 Keys in parameterValues: ["accountType", "industry"]
#   ✅ Stringified bindings: {"accountType":"Customer","industry":"Technology"}
```

**Los logs nos dirán exactamente dónde se pierde el binding!**

---

## 🚨 Common Apex Errors & Fixes

### Error 1: "Variable does not exist: paramName"

```apex
// ❌ Problem: Parameter name mismatch
WHERE Type = :type  // Query uses 'type'
// But binding has 'accountType'

// ✅ Fix: Match parameter names exactly
WHERE Type = :accountType  // Now matches binding
```

### Error 2: "List has no rows for assignment"

```apex
// ❌ Problem: Query returns no results
config = [SELECT ... WHERE DeveloperName = :devName];

// ✅ Fix: Add LIMIT 1
config = [SELECT ... WHERE DeveloperName = :devName LIMIT 1];
```

### Error 3: "Unexpected parameter in SOQL"

```apex
// ❌ Problem: Binding not in map
Database.queryWithBinds(query, bindings, ...)
// bindings = {} (empty)

// ✅ Fix: Ensure bindings populated
Map<String, Object> bindings = String.isNotBlank(bindingsJson)
  ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
  : new Map<String, Object>();
```

---

## 💡 Key Insight

**Para cambios de Apex:**

- ❌ Local Dev NO ayuda (no soporta @AuraEnabled)
- ✅ DEBES deployar para probar
- ✅ Unit tests Apex son críticos
- ✅ Error-Driven: Deja que errores de Apex test te guíen

**El debug logging que agregamos revelará exactamente dónde está el problema del binding!**

---

## 🎯 Next Steps

1. Deploy este código con debug logging
2. Open browser console
3. Test el escenario
4. Leer console logs
5. El error nos dirá el fix exacto
6. Fix → Redeploy → Retest → Commit

**EDD en acción: El error es tu guía!** 🚀
