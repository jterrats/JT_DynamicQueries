# 🔧 E2E Authentication Troubleshooting

## Problema: Tests van a la página de login

Si ves que el browser se va directo a la página de login, aquí está cómo solucionarlo:

---

## ✅ Solución Rápida

```bash
# 1. Verifica que tienes sesión activa
sf org display

# Si no tienes sesión o expiró, re-autentica:
sf org login web

# 2. Asegura que es la org default
sf config set target-org tu@email.com

# 3. Verifica que el accessToken es válido
sf org display --json | grep accessToken

# 4. Ejecuta los tests
npm run test:e2e
```

---

## 🔍 Por Qué Sucede

### Cookies deben inyectarse ANTES de navegar

```javascript
// ❌ MAL - Navega primero, luego cookies (va al login)
await page.goto(url);
await page.context().addCookies([...]);  // Demasiado tarde

// ✅ BIEN - Cookies primero, luego navega (directo autenticado)
await page.context().addCookies([...]);  // Antes!
await page.goto(url);  // Ya autenticado
```

### Se requieren múltiples cookies

Salesforce Lightning requiere:
- `sid` - Session ID principal
- `sid_Client` - Session ID del cliente

```javascript
await page.context().addCookies([
    {
        name: 'sid',
        value: session.accessToken,
        domain: hostname,
        sameSite: 'None'  // Importante!
    },
    {
        name: 'sid_Client',
        value: session.accessToken,
        domain: hostname,
        sameSite: 'None'  // Importante!
    }
]);
```

---

## 🐛 Debugging

### Paso 1: Verificar sesión del CLI

```bash
sf org display --json
```

Debe mostrar:
```json
{
  "status": 0,
  "result": {
    "accessToken": "00D...",  // ← Debe tener un token válido
    "instanceUrl": "https://...",
    "username": "tu@email.com"
  }
}
```

Si `accessToken` es null o no existe:
```bash
# Re-autentica
sf org login web
```

### Paso 2: Verificar que accessToken no expiró

```bash
# Intenta usar el token
sf org display --target-org tu@email.com
```

Si dice "expired" o "invalid":
```bash
# Re-autentica
sf org login web --set-default
```

### Paso 3: Test manual de autenticación

Crea este archivo de prueba:

```javascript
// test-auth.js
const { chromium } = require('playwright');
const { getSFSession } = require('./tests/e2e/utils/sfAuth');

(async () => {
    const session = getSFSession();
    console.log('Session:', session);

    const browser = await chromium.launch({ headless: false });
    const context = await browser.newContext();
    const page = await context.newPage();

    // Add cookies BEFORE navigation
    await context.addCookies([
        {
            name: 'sid',
            value: session.accessToken,
            domain: new URL(session.instanceUrl).hostname,
            path: '/',
            secure: true,
            sameSite: 'None'
        }
    ]);

    // Navigate
    await page.goto(session.instanceUrl + '/lightning/page/home');

    // Check if authenticated
    const isLoginPage = await page.locator('input[type="password"]')
                                   .isVisible({ timeout: 5000 })
                                   .catch(() => false);

    if (isLoginPage) {
        console.log('❌ FAILED - Still on login page');
    } else {
        console.log('✅ SUCCESS - Authenticated!');
    }

    await page.waitForTimeout(5000);
    await browser.close();
})();
```

Ejecuta:
```bash
node test-auth.js
```

---

## 🔒 Requisitos de Cookies en Salesforce

### httpOnly vs No httpOnly

```javascript
// Lightning requiere httpOnly: false
{
    name: 'sid',
    httpOnly: false,  // ← Debe ser false para Lightning
    secure: true,
    sameSite: 'None'
}
```

### sameSite Policy

```javascript
// IMPORTANTE: Lightning requiere sameSite: None
{
    sameSite: 'None',  // Permite cross-site cookies
    secure: true       // Requerido con sameSite: None
}
```

### Domain Configuration

```javascript
// Usa solo el hostname, sin protocolo
const url = new URL(session.instanceUrl);
{
    domain: url.hostname,  // Ej: "company.my.salesforce.com"
    // NO: "https://company.my.salesforce.com"
}
```

---

## ⚡ Verificación en Tiempo Real

El código actualizado incluye una verificación:

```javascript
// Después de navegar, verifica si estás en login
const isLoginPage = await page.locator('input[type="password"]')
                               .isVisible({ timeout: 2000 })
                               .catch(() => false);

if (isLoginPage) {
    throw new Error('Authentication failed - still on login page');
}

console.log('✅ Authenticated successfully - no login required');
```

Si ves este error, significa que las cookies no funcionaron.

---

## 🎯 Casos Especiales

### Sandbox vs Production

```javascript
// Ambos usan el mismo método
// Sandbox: https://company--dev.sandbox.my.salesforce.com
// Production: https://company.my.salesforce.com

// El domain será diferente pero el proceso es igual
const url = new URL(session.instanceUrl);
{
    domain: url.hostname  // Se ajusta automáticamente
}
```

### Scratch Orgs

```javascript
// Scratch orgs funcionan igual
// URL típica: https://company-dev-ed.scratch.my.salesforce.com
// Domain: company-dev-ed.scratch.my.salesforce.com
```

### Developer Edition

```javascript
// Developer Edition: https://company-dev-ed.my.salesforce.com
// Domain: company-dev-ed.my.salesforce.com
```

---

## 📋 Checklist de Troubleshooting

Cuando veas la página de login, verifica en orden:

- [ ] **Sesión CLI activa**: `sf org display` funciona
- [ ] **AccessToken válido**: No null, no expirado
- [ ] **Org es default**: `sf config get target-org`
- [ ] **Cookies antes de navegar**: Código corregido ✅
- [ ] **httpOnly = false**: Para Lightning
- [ ] **sameSite = None**: Para cross-site
- [ ] **secure = true**: Requerido
- [ ] **Domain correcto**: Solo hostname, sin protocolo

---

## 🚨 Errores Comunes

### Error 1: "accessToken is null"
```bash
# Causa: No hay sesión activa
# Solución:
sf org login web --set-default
```

### Error 2: "Invalid session ID"
```bash
# Causa: Token expiró
# Solución:
sf org login web --set-default
```

### Error 3: "Still redirects to login"
```bash
# Causa: Cookies inyectadas después de navegar
# Solución: Usa código actualizado (cookies ANTES de goto)
```

### Error 4: "CORS errors"
```bash
# Causa: sameSite policy incorrecto
# Solución: sameSite: 'None' con secure: true
```

---

## ✅ Test de Validación

Después de aplicar la solución, deberías ver:

```
🔑 Using SF CLI active session (no login needed)...
✅ Using active session: tu@email.com
📍 Instance: https://yourorg.my.salesforce.com
🔐 Cookies injected, navigating to org...
✅ Authenticated successfully - no login required
📱 Switching to Dynamic Queries app...
```

**NO deberías ver**:
- ❌ Página de login
- ❌ Input de username/password
- ❌ "Login to Salesforce"

---

## 🔧 Código de Referencia

### Implementación Correcta

```javascript
async function injectSFSession(page, session) {
    const url = new URL(session.instanceUrl);

    // 1. PRIMERO: Agrega cookies
    await page.context().addCookies([
        {
            name: 'sid',
            value: session.accessToken,
            domain: url.hostname,
            path: '/',
            httpOnly: false,
            secure: true,
            sameSite: 'None'
        },
        {
            name: 'sid_Client',
            value: session.accessToken,
            domain: url.hostname,
            path: '/',
            httpOnly: false,
            secure: true,
            sameSite: 'None'
        }
    ]);

    // 2. DESPUÉS: Navega (ya autenticado)
    await page.goto(session.instanceUrl + '/lightning/page/home');

    // 3. Verifica que no estás en login
    const isLoginPage = await page.locator('input[type="password"]')
                                   .isVisible({ timeout: 2000 })
                                   .catch(() => false);

    if (isLoginPage) {
        throw new Error('Authentication failed');
    }

    console.log('✅ Authenticated successfully');
}
```

---

## 💡 Pro Tips

1. **Refresca tu sesión regularmente**
   ```bash
   # Cada 2 horas en desarrollo
   sf org login web --set-default
   ```

2. **Usa org alias**
   ```bash
   sf org login web --set-default --alias myorg
   sf config set target-org myorg
   ```

3. **Guarda múltiples orgs**
   ```bash
   sf org list  # Ver todas las orgs guardadas
   sf config set target-org otra@org.com  # Cambiar rápido
   ```

4. **Debug con headed mode**
   ```bash
   npx playwright test --headed
   # Verás exactamente qué página carga
   ```

---

## 📚 Referencias

- [Playwright Authentication](https://playwright.dev/docs/auth)
- [Salesforce Session Management](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/intro_understanding_authentication.htm)
- [SF CLI Commands](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)

---

**Si sigues teniendo problemas**, ejecuta:
```bash
node test-auth.js  # Script de debug manual
```

Y comparte el output para debugging adicional.

