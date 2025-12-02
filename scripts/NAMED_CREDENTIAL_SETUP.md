# Named Credential Setup

## 🚀 Opción 1: Setup Automático (Recomendado)

Ejecuta este script en Developer Console para configurar automáticamente con la URL de tu org:

```apex
// Copy y paste desde: scripts/setup-named-credential-auto.apex
```

O ejecuta desde terminal:

```bash
sf apex run --file scripts/setup-named-credential-auto.apex
```

✅ **Ventajas:**
- Detecta automáticamente la URL del org
- Funciona en cualquier org (dev, sandbox, production)
- No necesitas hardcodear URLs

---

## 🔧 Opción 2: Configuración Manual (UI)

## Paso 1: Crear External Credential

1. **Setup** → Quick Find: `External Credentials`
2. Click **New**
3. Fill in the fields:
   - **Label**: `JT Tooling API External`
   - **Name**: `JT_Tooling_API_External` (auto-generated)
   - **Authentication Protocol**: `No Authentication`
4. Click **Save**

## Paso 2: Crear Named Credential

1. **Setup** → Quick Find: `Named Credentials`
2. Click **New** → Select **New Legacy** (not the default "New")
3. Fill in the fields:
   - **Label**: `JT Tooling API`
   - **Name**: `JT_Tooling_API` (auto-generated)
   - **URL**: `https://therionpolux-dev-ed.my.salesforce.com`
   - **Identity Type**: `Named Principal`
   - **Authentication Protocol**: `No Authentication`
   - **Generate Authorization Header**: ❌ (unchecked)
   - **Allow Merge Fields in HTTP Header**: ❌ (unchecked)
   - **Allow Merge Fields in HTTP Body**: ❌ (unchecked)
4. Click **Save**

## Paso 3: Actualizar código para usar Named Credential

El código actual en `JT_UsageFinder.cls` ya usa session ID directamente:

```apex
String endpoint = URL.getOrgDomainUrl().toExternalForm() +
                  '/services/data/v65.0/tooling/query/?q=' + ...;

HttpRequest req = new HttpRequest();
req.setEndpoint(endpoint);
req.setHeader('Authorization', 'Bearer ' + sessionId);
```

Cambia a:

```apex
String endpoint = 'callout:JT_Tooling_API/services/data/v65.0/tooling/query/?q=' + ...;

HttpRequest req = new HttpRequest();
req.setEndpoint(endpoint);
req.setHeader('Authorization', 'Bearer ' + sessionId);
```

## Verificación

1. **Setup** → Quick Find: `Named Credentials`
2. Verifica que aparezca: `JT_Tooling_API`
3. Click en el nombre para ver detalles
4. Debe mostrar:
   - URL: `https://therionpolux-dev-ed.my.salesforce.com`
   - Authentication Protocol: No Authentication

## Testing

Desde Developer Console, ejecuta:

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:JT_Tooling_API/services/data/v65.0/sobjects');
req.setMethod('GET');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setHeader('Content-Type', 'application/json');

Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Status: ' + res.getStatusCode());
System.debug('Body: ' + res.getBody());
```

Si retorna 200, ¡está funcionando! 🎉

## Alternativa: Named Credential v2 (Modern)

Si quieres usar la versión moderna (Named Credential v2), sigue estos pasos:

### A. Crear External Credential

1. **Setup** → Quick Find: `External Credentials`
2. Click **New**
3. Fill in:
   - **Label**: `JT Tooling API External`
   - **Name**: `JT_Tooling_API_External`
   - **Authentication Protocol**: `No Authentication`
4. Click **Save**

### B. Crear Named Credential (v2)

1. **Setup** → Quick Find: `Named Credentials`
2. Click **New** (selecciona el tipo moderno, NO "New Legacy")
3. Fill in:
   - **Label**: `JT Tooling API`
   - **Name**: `JT_Tooling_API`
   - **URL**: `https://therionpolux-dev-ed.my.salesforce.com`
   - **External Credential**: Select `JT_Tooling_API_External`
   - **Generate Authorization Header**: ❌ (unchecked)
4. Click **Save**

## Notes

- **Legacy vs Modern**: Ambos funcionan, pero Legacy es más simple para este caso
- **No Authentication**: Porque el session ID se pasa manualmente en el código
- **callout:NAME**: El prefijo `callout:` es obligatorio cuando usas Named Credentials

