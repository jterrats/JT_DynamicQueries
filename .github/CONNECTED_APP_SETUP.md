# Connected App Setup for CI/CD

Para que la autenticación JWT funcione en GitHub Actions, la Connected App debe estar configurada correctamente:

## ✅ Checklist de Connected App

### 1. OAuth Settings

- [x] Enable OAuth Settings: **Activado**
- [x] Enable for Device Flow: **NO requerido**
- [x] Callback URL: `http://localhost:1717/OauthRedirect` (puede ser cualquier URL)

### 2. OAuth Scopes Requeridos

- [x] Access the identity URL service (id, profile, email, address, phone)
- [x] Access unique user identifiers (openid)
- [x] Full access (full)
- [x] Perform requests at any time (refresh_token, offline_access)

### 3. Digital Certificate

- [x] Use digital signatures: **Activado**
- [x] Certificate uploaded: El certificado público (`.crt`) correspondiente a la llave privada (`SF_JWT_KEY`)

### 4. Policies

- [x] Permitted Users: **Admin approved users are pre-authorized**
- [x] IP Relaxation: **Relax IP restrictions** (importante para CI/CD)
- [x] Refresh Token Policy: **Refresh token is valid until revoked**

### 5. Manage Profiles/Permission Sets

- Agregar el perfil/permission set del usuario `SF_USERNAME` a la Connected App

## 🔧 Comando para generar el certificado (si no existe)

```bash
# Generar llave privada
openssl genrsa -out server.key 2048

# Generar certificado público
openssl req -new -x509 -key server.key -out server.crt -days 365

# Ver contenido de la llave privada (para SF_JWT_KEY secret)
cat server.key

# Subir server.crt a la Connected App
```

## 🧪 Probar autenticación localmente

```bash
# Escribir la llave
echo "$SF_JWT_KEY" > server.key
chmod 600 server.key

# Probar autenticación
sf org login jwt \
  --client-id YOUR_CONSUMER_KEY \
  --jwt-key-file server.key \
  --username YOUR_USERNAME \
  --instance-url https://login.salesforce.com \
  --set-default

# Verificar
sf org display
```

## 🐛 Debugging

Si la autenticación falla, verificar:

1. **Consumer Key correcto**: Debe ser el Client ID de la Connected App
2. **Username correcto**: Usuario que tiene acceso a la Connected App
3. **Certificado coincide**: La llave privada (`SF_JWT_KEY`) debe corresponder al certificado público subido a la Connected App
4. **IP Relaxation**: Debe estar en "Relax IP restrictions" para permitir conexiones desde GitHub Actions
5. **Usuario pre-autorizado**: El usuario debe estar en la lista de perfiles/permission sets permitidos

## 📋 Referencias

- [Salesforce JWT Bearer Flow](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_jwt_flow.htm)
- [SF CLI JWT Auth](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_org_commands_unified.htm#cli_reference_org_login_jwt_unified)
