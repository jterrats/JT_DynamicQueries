# 🧪 E2E Tests - Playwright

## ⚡ Quick Start (NO LOGIN REQUIRED)

Los tests usan tu **sesión activa del SF CLI** - ¡no necesitas hacer login manual!

```bash
# 1. Asegúrate de tener una sesión activa del SF CLI
sf org list

# 2. Ejecuta los tests (usan la sesión automáticamente)
npm run test:e2e

# 3. Modo interactivo (ver el browser)
npm run test:e2e:ui
```

---

## 🔑 Autenticación Automática

### Cómo Funciona

Los tests **NO requieren login manual**. Usan la sesión ya autenticada del SF CLI:

```javascript
// 1. Obtiene la sesión activa del CLI
const session = getSFSession(); // sf org display --json

// 2. Inyecta el accessToken directamente
await page.context().addCookies([
  {
    name: "sid",
    value: session.accessToken, // ← Token del CLI
    domain: salesforceUrl
  }
]);

// 3. Navega directo a la org (ya autenticado)
await page.goto(session.instanceUrl);
```

### Beneficios

✅ **Sin login manual** - Usa la sesión del CLI
✅ **Más rápido** - Salta el flujo de login
✅ **Más confiable** - No depende de credenciales en código
✅ **Más seguro** - No almacena passwords
✅ **Multi-org** - Cambia con `sf config set target-org`

---

## 📋 Pre-requisitos

### 1. Node.js y npm instalados

```bash
node --version  # v18 o superior
npm --version
```

### 2. Dependencias instaladas

```bash
npm install --legacy-peer-deps
npx playwright install chromium
```

### 3. Sesión activa del SF CLI

```bash
# Ver orgs disponibles
sf org list

# Cambiar org default si es necesario
sf config set target-org myusername@example.com

# Verificar sesión activa
sf org display
```

**Importante**: Los tests usarán automáticamente la org configurada como default.

---

## 🚀 Ejecutar Tests

### Todos los tests (headless)

```bash
npm run test:e2e
```

### Con UI visible (headed mode)

```bash
npm run test:e2e:ui
```

### Test específico

```bash
npx playwright test tests/e2e/queryViewer.spec.js
```

### Con debug

```bash
npx playwright test --debug
```

### Ver reporte después de ejecución

```bash
npx playwright show-report
```

---

## 📊 Tests Incluidos

### 15 Escenarios E2E

1. ✅ **Load Component** - Carga del LWC
2. ✅ **Load Configurations** - Carga de configuraciones
3. ✅ **Select Config & Preview** - Selección y preview
4. ✅ **Execute Query** - Ejecución y resultados
5. ✅ **Dynamic Parameters** - Parámetros dinámicos
6. ✅ **Error Handling** - Manejo de errores
7. ✅ **Tab Navigation** - Navegación entre tabs
8. ✅ **Run As User Section** - Sección Run As
9. ✅ **Search Run As User** - Búsqueda de usuarios
10. ✅ **Execute with Run As** - Ejecución con Run As
11. ✅ **Production Safeguard** - Validación Prod/Sandbox
12. ✅ **Open/Close Modal** - Modal de creación
13. ✅ **Validate Fields** - Validación de campos
14. ✅ **Create Configuration** - Crear config + refreshApex
15. ✅ **Invalid SOQL** - Manejo de SOQL inválido

---

## 🔧 Configuración

### playwright.config.js

```javascript
module.exports = {
  testDir: "./tests/e2e",
  timeout: 60000,
  retries: 1,
  workers: 1, // Un worker para evitar conflictos
  use: {
    baseURL: "https://login.salesforce.com",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    trace: "on-first-retry"
  }
};
```

### utils/sfAuth.js

```javascript
// Obtiene sesión del SF CLI (NO login manual)
function getSFSession() {
  const orgInfo = execSync("sf org display --json");
  return {
    instanceUrl: result.instanceUrl,
    accessToken: result.accessToken, // ← Token del CLI
    username: result.username
  };
}

// Inyecta sesión directamente
async function injectSFSession(page, session) {
  await page.context().addCookies([
    {
      name: "sid",
      value: session.accessToken,
      domain: new URL(session.instanceUrl).hostname
    }
  ]);
}
```

---

## 🎯 Cambiar de Org

### Para probar en diferente org:

```bash
# 1. Ver orgs disponibles
sf org list

# 2. Cambiar org default
sf config set target-org myorg@example.com

# 3. Ejecutar tests (usarán la nueva org)
npm run test:e2e
```

**Los tests automáticamente usarán la nueva org sin cambios en el código.**

---

## 📸 Screenshots y Videos

### En fallas, Playwright guarda:

```
test-results/
├── screenshots/
│   └── test-failed-1.png
├── videos/
│   └── test-1.webm
└── traces/
    └── test-1.zip
```

### Ver trace (debugging visual):

```bash
npx playwright show-trace test-results/test-1.zip
```

---

## 🐛 Debugging

### 1. Modo Debug (paso a paso)

```bash
npx playwright test --debug
```

### 2. Inspector de Playwright

```bash
PWDEBUG=1 npx playwright test
```

### 3. Console logs

```bash
npx playwright test --reporter=line
```

### 4. Ver el browser (headed)

```bash
npx playwright test --headed
```

---

## ⚠️ Troubleshooting

### Error: "No default org found"

```bash
# Solución: Configura una org default
sf config set target-org myuser@example.com
sf org display  # Verifica que funciona
```

### Error: "Timeout waiting for selector"

```bash
# Causa: La org puede estar lenta o el componente no cargó
# Solución: Aumenta timeout en playwright.config.js
timeout: 90000  # 90 segundos
```

### Tests fallan en CI/CD

```bash
# Solución: Asegura que SF CLI está instalado y autenticado
sf org login jwt --client-id $CLIENT_ID \
                  --jwt-key-file server.key \
                  --username $USERNAME \
                  --instance-url $INSTANCE_URL
```

### Error: "Cannot find module @playwright/test"

```bash
# Solución: Reinstala dependencias
npm install --legacy-peer-deps
npx playwright install chromium
```

---

## 🎓 Mejores Prácticas

### 1. ✅ Usa la sesión del CLI

```javascript
// BIEN: Usa getSFSession()
const session = getSFSession();

// MAL: Hardcodear credenciales
const session = { username: "hardcoded@example.com" };
```

### 2. ✅ Un worker para evitar conflictos

```javascript
// playwright.config.js
workers: 1; // Tests corren secuencialmente
```

### 3. ✅ Espera específica, no genérica

```javascript
// BIEN: Espera específica
await page.waitForSelector("c-jt-query-viewer");

// MAL: Timeout fijo
await page.waitForTimeout(5000);
```

### 4. ✅ Maneja timeouts gracefully

```javascript
// Catch timeout errors
await page
  .waitForSelector(".optional-element", { timeout: 3000 })
  .catch(() => console.log("Optional element not found"));
```

---

## 📚 Recursos

### Documentación

- [Playwright Docs](https://playwright.dev)
- [SF CLI Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)
- [E2E Test Scenarios](./E2E_TEST_SCENARIOS.md)

### Comandos útiles

```bash
# Ver ayuda de Playwright
npx playwright --help

# Listar tests disponibles
npx playwright test --list

# Ejecutar test específico por nombre
npx playwright test -g "should load the Query Viewer"

# Generar código de test (Codegen)
npx playwright codegen https://yourorg.lightning.force.com
```

---

## ✅ Checklist Pre-Test

- [ ] SF CLI instalado (`sf --version`)
- [ ] Org autenticada (`sf org display`)
- [ ] Org configurada como default (`sf config set target-org`)
- [ ] Node.js instalado (`node --version`)
- [ ] Dependencias instaladas (`npm install`)
- [ ] Chromium instalado (`npx playwright install chromium`)
- [ ] App desplegada en la org
- [ ] PermissionSet asignado al usuario

---

## 🎉 Ventajas de Este Setup

```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║  ⚡ VENTAJAS DE USAR SF CLI SESSION                       ║
║                                                           ║
║  ✅ Sin login manual                                      ║
║  ✅ Sin credenciales hardcoded                            ║
║  ✅ Multi-org con un solo comando                         ║
║  ✅ Más rápido (salta login UI)                          ║
║  ✅ Más seguro (usa tokens del CLI)                       ║
║  ✅ Works en CI/CD con JWT auth                           ║
║  ✅ Fácil de mantener                                     ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

---

**¡Happy Testing!** 🚀

Si tienes problemas, revisa [E2E_TEST_SCENARIOS.md](./E2E_TEST_SCENARIOS.md) para más detalles sobre cada test.
