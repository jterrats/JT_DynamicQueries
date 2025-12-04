# Cross-Platform Deployment Solution

## ❓ Problema Original

Los scripts `.sh` (Bash) **NO funcionan** en Windows nativo (CMD/PowerShell):

```bash
./scripts/smart-deploy.sh
# ❌ Windows CMD: 'bash' is not recognized as an internal or external command
# ❌ PowerShell: Cannot be loaded because running scripts is disabled
```

## ✅ Solución: Node.js Cross-Platform

Creamos `smart-deploy.js` que funciona en **todos** los sistemas operativos:

| Platform           | `.sh` (Bash) | `.js` (Node.js) | Status          |
| ------------------ | ------------ | --------------- | --------------- |
| Windows CMD        | ❌           | ✅              | **FUNCIONA**    |
| Windows PowerShell | ❌           | ✅              | **FUNCIONA**    |
| Windows Git Bash   | ✅           | ✅              | Ambos funcionan |
| Windows WSL        | ✅           | ✅              | Ambos funcionan |
| macOS              | ✅           | ✅              | Ambos funcionan |
| Linux              | ✅           | ✅              | Ambos funcionan |
| GitHub Actions     | ✅           | ✅              | Ambos funcionan |

## 🚀 Uso

### Comando Rápido (Cross-Platform)

```bash
npm run deploy:named-credential
```

### Comando Directo (Cross-Platform)

```bash
node scripts/smart-deploy.js
```

### Script Shell (Unix/Linux/Mac/Git Bash)

```bash
./scripts/smart-deploy.sh
```

## 🎯 Ventajas de la Versión Node.js

1. **✅ Zero Dependencies Externas**
   - No requiere `bash`, `jq`, `sed`, `awk`
   - Solo requiere Node.js (ya instalado por Salesforce DX)

2. **✅ Error Handling Robusto**
   - Try/catch/finally para cleanup
   - Mensajes de error claros
   - Exit codes apropiados

3. **✅ Auto-Cleanup**
   - Siempre restaura archivo original
   - No deja archivos temporales
   - Safe para Git

4. **✅ Compatible con CI/CD**
   - Funciona en GitHub Actions
   - Funciona en Jenkins
   - Funciona en GitLab CI
   - Funciona en Azure DevOps

## 📊 Comparación Técnica

| Feature               | Bash Script  | Node.js Script |
| --------------------- | ------------ | -------------- |
| Windows CMD support   | ❌           | ✅             |
| PowerShell support    | ❌           | ✅             |
| Unix/Linux support    | ✅           | ✅             |
| External dependencies | `jq`, `bash` | Solo Node.js   |
| Error handling        | Basic        | Advanced       |
| Auto-cleanup          | Manual       | Automático     |
| JSON parsing          | Via `jq`     | Nativo         |
| File operations       | `sed`, `awk` | Nativo         |

## 🔧 Implementación

### Node.js Version (`smart-deploy.js`)

```javascript
// ✅ Parse JSON nativo
const orgData = JSON.parse(orgDisplayResult);

// ✅ File operations nativas
fs.writeFileSync(ncPath, updatedContent, "utf-8");

// ✅ Error handling robusto
try {
  // Deploy
} finally {
  // ALWAYS cleanup
  fs.writeFileSync(ncPath, originalContent, "utf-8");
}
```

### Bash Version (`smart-deploy.sh`)

```bash
# ❌ Requiere jq externo
CURRENT_URL=$(sf org display --json | jq -r '.result.instanceUrl')

# ❌ Error handling básico
set -e

# ❌ Cleanup manual
trap "cleanup" EXIT
```

## 💡 Recomendación

### Para Desarrollo Local

**Si usas Windows**: `npm run deploy:named-credential` (Node.js)

**Si usas Mac/Linux**: Cualquiera de las dos opciones funciona

### Para CI/CD

Ambas opciones funcionan, pero **Node.js es más portable** entre diferentes runners.

## 🔄 Migración

Si ya usas scripts `.sh`:

```bash
# Antes (solo Unix/Mac/Git Bash)
./scripts/smart-deploy.sh

# Ahora (funciona en TODOS los sistemas)
npm run deploy:named-credential
```

No hay cambios en funcionalidad, solo mejor compatibilidad.

## 🧪 Testing

Para verificar que funciona en tu sistema:

```bash
# Test 1: Verifica que Node.js esté disponible
node --version
# Debe mostrar: v24.x.x o superior

# Test 2: Ejecuta el script
npm run deploy:named-credential

# Expected output:
# ✅ Org URL matches cached value
# ✅ Named Credential deployed successfully
```

## 📝 Notas Técnicas

### Por qué los `.sh` no funcionan en Windows

1. **CMD no tiene Bash**: Windows usa CMD/PowerShell, no Bash
2. **Diferentes ejecutables**: `ls`, `cat`, `grep` no existen en Windows
3. **Path separators**: Windows usa `\`, Unix usa `/`
4. **Line endings**: Windows usa CRLF, Unix usa LF

### Por qué Node.js SÍ funciona

1. **Cross-platform runtime**: Node.js funciona igual en todos los OS
2. **APIs unificadas**: `fs`, `path`, `child_process` abstraen las diferencias
3. **Ya instalado**: Salesforce DX requiere Node.js
4. **No dependencies**: Usa solo APIs nativas de Node.js

## 🎓 Recursos

- [Node.js File System API](https://nodejs.org/api/fs.html)
- [Node.js Child Process API](https://nodejs.org/api/child_process.html)
- [Cross-Platform Node.js Best Practices](https://nodejs.org/en/docs/guides/writing-cross-platform-code/)
