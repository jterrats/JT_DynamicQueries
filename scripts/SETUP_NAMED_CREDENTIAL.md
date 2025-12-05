# Setup Named Credential - Automated

Este proyecto incluye scripts automatizados para configurar Named Credentials con la URL dinámica de tu org.

## 🚀 Quick Start (1 comando)

```bash
./scripts/setup-org-url.sh && source .env && ./scripts/deploy-with-replacement.sh
```

## 📋 Paso a Paso

### 1️⃣ Detectar URL del Org

```bash
./scripts/setup-org-url.sh
```

**¿Qué hace?**

- Detecta la URL de tu org actual (`sf config get target-org`)
- Crea/actualiza archivo `.env` con `SF_ORG_SQF=https://your-org.my.salesforce.com`
- Exporta la variable de entorno

**Parámetros opcionales:**

```bash
./scripts/setup-org-url.sh my-hub  # Usar org específico
```

### 2️⃣ Source el Environment

```bash
source .env
```

### 3️⃣ Deploy con Replacement

```bash
./scripts/deploy-with-replacement.sh
```

**¿Qué hace?**

- Lee `SF_ORG_SQF` del environment
- Reemplaza `{!$Credential.JT_Tooling_API}` con la URL real
- Deploya el Named Credential al org
- Restaura el archivo original (para que Git no vea cambios)

## 🔧 Para Orgs sin ConnectApi (Developer Edition)

Si tu org no soporta `ConnectApi.NamedCredentials`, configura manualmente:

### Setup → Named Credentials → New Legacy

1. **Label**: `JT Tooling API`
2. **Name**: `JT_Tooling_API`
3. **URL**: `https://your-org.my.salesforce.com` (copia de `.env`)
4. **Identity Type**: `Named Principal`
5. **Authentication Protocol**: `No Authentication`
6. **Generate Authorization Header**: ❌
7. Click **Save**

## 🎯 Verificación

```bash
# Verificar que la env var está set
echo $SF_ORG_SQF

# Verificar Named Credential en org
sf org open --path /lightning/setup/NamedCredential/home
```

## 📝 Arquitectura

```
┌─────────────────────────────────────┐
│  setup-org-url.sh                   │
│  - Detecta URL del org              │
│  - Genera .env con SF_ORG_SQF      │
└─────────┬───────────────────────────┘
          │
          ▼
┌─────────────────────────────────────┐
│  .env                                │
│  SF_ORG_SQF=https://...            │
└─────────┬───────────────────────────┘
          │
          ▼
┌─────────────────────────────────────┐
│  deploy-with-replacement.sh         │
│  - Lee SF_ORG_SQF                   │
│  - Reemplaza pattern en XML        │
│  - Deploya Named Credential        │
│  - Restaura archivo original       │
└─────────────────────────────────────┘
```

## 🔐 Seguridad

- ❌ `.env` NO se trackea en Git (`.gitignore`)
- ✅ `.env.example` SÍ se incluye como template
- ✅ El archivo XML original se restaura después del deploy
- ✅ Git no ve cambios en `JT_Tooling_API.namedCredential-meta.xml`

## 🌍 Multi-Org Support

Para diferentes orgs:

```bash
# Org 1 (dev)
./scripts/setup-org-url.sh my-dev-org
source .env
./scripts/deploy-with-replacement.sh my-dev-org

# Org 2 (staging)
./scripts/setup-org-url.sh my-staging-org
source .env
./scripts/deploy-with-replacement.sh my-staging-org
```

## ⚠️ Troubleshooting

### Error: "SF_ORG_SQF not set"

```bash
# Re-run setup
./scripts/setup-org-url.sh
source .env
```

### Error: "No target org found"

```bash
# Set default org
sf config set target-org <username-or-alias>

# Or pass org explicitly
./scripts/setup-org-url.sh my-org-alias
```

### Error: "Failed to get org URL"

```bash
# Verify authentication
sf org list

# Re-authenticate if needed
sf org login web --alias my-org
```

## 💡 CI/CD Integration

Para usar en GitHub Actions o CI/CD:

```yaml
- name: Setup Named Credential
  run: |
    ./scripts/setup-org-url.sh ci-org
    source .env
    ./scripts/deploy-with-replacement.sh ci-org
  env:
    SF_ORG_SQF: ${{ secrets.SF_ORG_URL }}
```


