# Scripts - Named Credential Setup

## 🎯 Problema a Resolver

Named Credentials necesitan la URL del org. Cada org tiene una URL diferente:
- Dev: `https://therionpolux-dev-ed.my.salesforce.com`
- Sandbox: `https://company--staging.sandbox.my.salesforce.com`
- Production: `https://company.my.salesforce.com`

**❌ Si harcodeas la URL**, solo funciona en UN org.

**✅ Con estos scripts**, funciona en CUALQUIER org automáticamente.

## 🚀 Quick Start

### Opción 1: Manual (Run cada vez que cambies org)

```bash
# Cambiar org
sf config set target-org my-sandbox

# Setup y deploy
./scripts/setup-org-url.sh
source .env
./scripts/deploy-with-replacement.sh
```

### Opción 2: Smart Deploy (Auto-detecta cambios)

```bash
# Cambiar org
sf config set target-org my-sandbox

# Smart deploy (detecta que cambió el org y actualiza automáticamente)
./scripts/smart-deploy.sh
```

### Opción 3: Shell Aliases (Más conveniente)

```bash
# Setup ONE TIME
./scripts/deploy-alias.sh
source ~/.zshrc  # or ~/.bashrc

# Después solo:
sf config set target-org my-sandbox
jt-deploy  # 🚀 Auto!
```

## 📁 Scripts Disponibles

### `setup-org-url.sh`
Detecta la URL del org actual y genera `.env`

```bash
./scripts/setup-org-url.sh [org-alias]
```

**Output:**
- Crea/actualiza `.env` con `SF_ORG_SQF=https://...`
- Exporta variable de entorno

### `deploy-with-replacement.sh`
Deploya Named Credential con string replacement

```bash
source .env
./scripts/deploy-with-replacement.sh [org-alias]
```

**Qué hace:**
1. Lee `SF_ORG_SQF` del environment
2. Crea temp file con URL real
3. Deploya a Salesforce
4. Restaura archivo original

### `smart-deploy.sh` ⭐
Deploy inteligente que auto-detecta cambios de org

```bash
./scripts/smart-deploy.sh [org-alias]
```

**Qué hace:**
1. Detecta URL del org actual
2. Compara con URL cacheada en `.env`
3. Si cambió, ejecuta `setup-org-url.sh` automáticamente
4. Deploya Named Credential
5. ✅ Siempre correcto!

### `deploy-alias.sh`
Setup de aliases para tu shell

```bash
./scripts/deploy-alias.sh
```

**Agrega a tu shell:**
- `jt-setup` → Shortcut para setup
- `jt-deploy` → Shortcut para smart deploy

## 🔄 Flujo de Trabajo

### Desarrollo Local

```bash
# Día 1: Dev Org
sf config set target-org my-dev
jt-deploy

# Día 2: Sandbox
sf config set target-org my-sandbox
jt-deploy  # Auto-detecta cambio ✅

# Día 3: Production
sf config set target-org my-prod
jt-deploy  # Auto-detecta cambio ✅
```

### CI/CD

```yaml
# .github/workflows/deploy.yml
- name: Deploy Named Credential
  run: |
    ./scripts/setup-org-url.sh ci-org
    source .env
    ./scripts/deploy-with-replacement.sh ci-org
```

## 🐛 Troubleshooting

### "SF_ORG_SQF not set"

```bash
# Re-run setup
./scripts/setup-org-url.sh
source .env
```

### "Org URL mismatch"

```bash
# Esto es NORMAL si cambiaste de org
# smart-deploy.sh lo arregla automáticamente
./scripts/smart-deploy.sh
```

### "No target org found"

```bash
# Set default org
sf config set target-org <username-or-alias>
```

## 📊 Comparación de Approaches

| Approach | Auto-detect | Escalable | Git Clean | Effort |
|----------|-------------|-----------|-----------|--------|
| Hardcoded URL | ❌ | ❌ | ❌ | Low |
| Manual setup script | ❌ | ✅ | ✅ | Medium |
| Smart deploy | ✅ | ✅ | ✅ | Low |
| Shell aliases | ✅ | ✅ | ✅ | **Lowest** |

## 💡 Recomendación

Para **desarrollo local**: Usa `deploy-alias.sh` + `jt-deploy`  
Para **CI/CD**: Usa `setup-org-url.sh` + `deploy-with-replacement.sh`

## 🔐 Seguridad

- ❌ `.env` NO se trackea en Git
- ✅ Placeholder `{!$Credential.JT_Tooling_API}` es seguro para repos públicos
- ✅ Cada org tiene su propia URL en runtime
- ✅ No hay secrets expuestos

