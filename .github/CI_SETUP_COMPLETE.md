# ✅ CI/CD Setup - Complete

## Status: External Client App Deployed

La **External Client App** para JWT authentication está deployada en la org.

---

## 📦 Archivos Deployados (NO trackeados en repo)

1. ✅ `JT_CI_Runner.eca-meta.xml` (ExternalClientApplication)
2. ✅ `JT_CI_RunnerGlobal.ecaGlblOauth-meta.xml` (Global OAuth Settings)
3. ✅ `JT_CI_RunnerOAuth.ecaOauth-meta.xml` (OAuth Settings)

**Nota**: Estos archivos fueron **borrados del repo local** según `.forceignore` y `.gitignore`.

---

## 🔐 Certificado Generado

📅 **Válido hasta**: December 2, 2027 (2 años)

**Ubicación**: `certs/server.key` y `certs/server.crt` (NO trackeados en git)

```bash
# Ver certificado
cat certs/server.crt

# Ver private key (para GitHub Secrets)
cat certs/server.key
```

---

## 📋 Pasos Siguientes (Manual)

### 1. Obtener Consumer Key

1. Ir a: **Setup** → **App Manager**
2. Buscar: **JT CI Runner**
3. Click en dropdown (▼) → **View**
4. **Copiar el Consumer Key** (aparecerá en 2-10 minutos)

### 2. Configurar GitHub Secrets

**Settings** → **Secrets** → **Actions** → **New repository secret**

| Secret Name       | Value                           | Cómo obtenerlo                                  |
| ----------------- | ------------------------------- | ----------------------------------------------- |
| `SF_CONSUMER_KEY` | Consumer Key                    | Paso 1                                          |
| `SF_JWT_KEY`      | Contenido de `certs/server.key` | `cat certs/server.key`                          |
| `SF_USERNAME`     | Tu email de Salesforce          | `jaime.terrats@gmail.com`                       |
| `SF_INSTANCE_URL` | URL de la org                   | `https://therionpolux-dev-ed.my.salesforce.com` |

### 3. Habilitar la App para tu Usuario

**Setup** → **App Manager** → **JT CI Runner** → **Manage**

- Scroll a **Permission Sets**
- **Manage Permission Sets**
- Seleccionar: `JT_Dynamic_Queries_User`
- **Save**

### 4. Test JWT Auth Localmente

```bash
# Reemplaza YOUR_CONSUMER_KEY con el key real
sf org login jwt \
  --client-id YOUR_CONSUMER_KEY \
  --jwt-key-file certs/server.key \
  --username jaime.terrats@gmail.com \
  --set-default \
  --alias ci-test

# Verificar
sf org display --target-org ci-test

# Test E2E
npm run test:e2e
```

### 5. Configurar Policies (después de 10 minutos)

**Setup** → **App Manager** → **JT CI Runner** → **Edit Policies**

- **Permitted Users**: `Admin approved users are pre-authorized`
- **IP Relaxation**: `Relax IP restrictions`
- **Refresh Token**: `Refresh token is valid until revoked`

---

## 🚀 GitHub Actions Workflow

El workflow **ya está configurado** en `.github/workflows/e2e-on-merge.yml`:

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

**Trigger**: Cada merge a `main` o PR

**Jobs**:

1. ✅ Deploy a org
2. ✅ Run Apex tests
3. ✅ Run E2E tests
4. ✅ Upload artifacts (videos, screenshots)

---

## 📄 Archivos Relacionados

- `.github/workflows/e2e-on-merge.yml` - GitHub Actions workflow
- `.github/CI_SETUP.md` - Guía completa de setup
- `certs/server.key` - Private key (NO trackear)
- `certs/server.crt` - Certificate (NO trackear)
- `.forceignore` - Ignora sync de External Client App
- `.gitignore` - Ignora certificates y keys

---

## 🔒 Security

✅ Certificado NO está en git
✅ Private key NO está en git
✅ Consumer Key NO está en git
✅ External Client App NO está en git
✅ Solo en GitHub Secrets (encriptados)

---

## 📅 Recordatorios

- **Rotación de certificado**: Diciembre 2, 2027 (crear calendar reminder)
- **Review de permisos**: Cada 6 meses
- **Audit logs**: Revisar accesos de CI user mensualmente
