# GitHub Secrets Configuration Checklist

## 📋 Required Secrets

Configura estos 4 secrets en: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

---

### 1️⃣ SF_CONSUMER_KEY

**Cómo obtenerlo:**

1. Ir a Salesforce Setup
2. **App Manager** → Buscar "JT CI Runner"
3. Click dropdown (▼) → **View**
4. Copiar el **Consumer Key**

**Formato esperado:**

```
3MVG9...longstring...ABC
```

**⏰ Nota**: Puede tardar 2-10 minutos en aparecer después del deploy.

---

### 2️⃣ SF_JWT_KEY

**Cómo obtenerlo:**

```bash
cat certs/server.key
```

**Formato esperado (incluye BEGIN y END):**

```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAoZH4LbpicefvG5XeOIMUx3Ko+lJmnhCJOF9xWpuTcZOEu937
NnZRRX/fnxEvFmWvV2L5Da9MviltzykEyxE7+cq5XFSuwgknGuWuoE1175PKsrRq
...
(muchas líneas más)
...
-----END RSA PRIVATE KEY-----
```

**⚠️ CRÍTICO**:

- Copiar **TODO** el contenido (incluidas las líneas BEGIN y END)
- NO compartir este key con nadie
- NO commitear en git

---

### 3️⃣ SF_USERNAME

**Valor:**

```
jaime.terrats@gmail.com
```

**Nota**: Este es el username del usuario que ejecutará las E2E en CI.

---

### 4️⃣ SF_INSTANCE_URL

**Valor:**

```
https://therionpolux-dev-ed.my.salesforce.com
```

**Nota**: Sin trailing slash (`/`) al final.

---

## ✅ Verificación de Secrets

Después de configurar los 4 secrets, verifica que:

| Secret Name       | Configured? | Value Preview             |
| ----------------- | ----------- | ------------------------- |
| `SF_CONSUMER_KEY` | ☐           | `3MVG9...`                |
| `SF_JWT_KEY`      | ☐           | `-----BEGIN RSA...`       |
| `SF_USERNAME`     | ☐           | `jaime.terrats@gmail.com` |
| `SF_INSTANCE_URL` | ☐           | `https://therionpolux...` |

---

## 🧪 Test Local antes de Pushear

```bash
# Test JWT auth con tus valores reales
sf org login jwt \
  --client-id YOUR_CONSUMER_KEY \
  --jwt-key-file certs/server.key \
  --username jaime.terrats@gmail.com \
  --set-default \
  --alias ci-test

# Si funciona, verás:
# ✅ Successfully authorized jaime.terrats@gmail.com

# Verificar
sf org display --target-org ci-test

# Test E2E
npm run test:e2e
```

Si el test local funciona, **GitHub Actions funcionará igual**.

---

## 🚀 Trigger CI/CD Pipeline

Una vez configurados los secrets:

```bash
# Commit y push a main (o crea un PR)
git add .
git commit -m "ci: Add GitHub Actions workflow for E2E tests"
git push origin main
```

Monitorea el workflow en: **GitHub** → **Actions** → **E2E Tests on Main Merge**

---

## 🐛 Troubleshooting

### Secret no funciona

1. Verifica que el nombre del secret sea EXACTO (case-sensitive)
2. Re-copia el valor (evita trailing spaces)
3. Para `SF_JWT_KEY`, asegúrate de incluir BEGIN y END

### JWT validation failed

1. Espera 10 minutos después del deploy
2. Verifica que el certificate en la app coincida con `server.crt`
3. Confirma que el Consumer Key sea correcto

### Permission denied

1. Setup → App Manager → JT CI Runner → Manage
2. Permission Sets → Manage Permission Sets
3. Selecciona `JT_Dynamic_Queries_User` → Save

---

## 📅 Recordatorio

**Certificado expira**: December 2, 2027

Crear calendar reminder para rotar certificado 1 mes antes.
