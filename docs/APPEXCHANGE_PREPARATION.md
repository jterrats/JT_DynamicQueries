# AppExchange Preparation Guide

## 🎯 AppExchange Requirements

Para subir a AppExchange necesitas:

### 1. **Managed Package** (NO Unlocked Package)
- ✅ **Namespace obligatorio**: Debe estar registrado en Salesforce
- ✅ **Código protegido**: Los usuarios NO pueden modificar tu código
- ✅ **Versionado estricto**: Cada versión debe pasar Security Review
- ✅ **Actualizaciones controladas**: Solo puedes actualizar componentes específicos

### 2. **Security Review**
- ✅ **Code Scan**: Análisis automático de código
- ✅ **Security Questionnaire**: Preguntas sobre seguridad
- ✅ **Documentation Review**: Revisión de documentación
- ✅ **Testing**: Pruebas de funcionalidad

### 3. **Documentación Requerida**
- ✅ **User Guide**: Guía de usuario completa
- ✅ **Installation Guide**: Instrucciones de instalación
- ✅ **Security Documentation**: Documentación de seguridad
- ✅ **API Documentation**: Documentación de APIs públicas

## 🔄 Migración: Unlocked → Managed Package

### Paso 1: Registrar Namespace

1. **Crear DevHub Org** (si no tienes):
   ```bash
   # Crear Developer Edition org
   # https://developer.salesforce.com/signup
   ```

2. **Registrar Namespace**:
   - Setup → Package Manager → Namespace Registry
   - Solicitar namespace (ej: `JT_DynamicQueries` o `JTDynamicQueries`)
   - **Costo**: $0 (pero requiere aprobación de Salesforce)
   - **Tiempo**: 1-3 días hábiles

3. **Verificar disponibilidad**:
   - El namespace debe ser único globalmente
   - No puede contener guiones bajos en algunos casos
   - Recomendado: `JTDynamicQueries` o `JTQueries`

### Paso 2: Actualizar Código para Namespace

#### 2.1 Actualizar `sfdx-project.json`

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "package": "JT_DynamicQueries",
      "versionName": "ver 2.5.0",
      "versionNumber": "2.5.0.NEXT"
    }
  ],
  "name": "JT_DynamicQueries",
  "namespace": "JTDynamicQueries",  // ⚠️ CAMBIAR AQUÍ
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "65.0"
}
```

#### 2.2 Actualizar Custom Objects

**ANTES (sin namespace):**
```apex
JT_RunAsTest_Execution__c
JT_SettingsAuditLog__c
JT_ErrorLog__c
```

**DESPUÉS (con namespace `JTDynamicQueries`):**
```apex
JTDynamicQueries__RunAsTest_Execution__c
JTDynamicQueries__SettingsAuditLog__c
JTDynamicQueries__ErrorLog__c
```

**⚠️ IMPORTANTE**: Los nombres de objetos cambiarán, pero los Developer Names pueden mantenerse si usas `JT_` como prefijo interno.

#### 2.3 Actualizar Custom Metadata Types

**ANTES:**
```apex
JT_DynamicQueryConfiguration__mdt
JT_SystemSettings__mdt
```

**DESPUÉS:**
```apex
JTDynamicQueries__DynamicQueryConfiguration__mdt
JTDynamicQueries__SystemSettings__mdt
```

#### 2.4 Actualizar Apex Classes

**ANTES:**
```apex
public class JT_DataSelector {
    JT_DynamicQueryConfiguration__mdt config = ...
}
```

**DESPUÉS:**
```apex
public class JTDynamicQueries.DataSelector {  // ⚠️ Cambia de _ a .
    JTDynamicQueries__DynamicQueryConfiguration__mdt config = ...
}
```

**O mantener nombres internos:**
```apex
// Si mantienes JT_ como prefijo interno
public class JTDynamicQueries.DataSelector {
    // Pero internamente puedes seguir usando JT_ si lo configuras así
    // Depende de cómo Salesforce maneje el namespace
}
```

#### 2.5 Actualizar Custom Labels

**ANTES:**
```javascript
import label1 from "@salesforce/label/c.JT_jtQueryViewer_executeQuery";
```

**DESPUÉS:**
```javascript
import label1 from "@salesforce/label/c.JTDynamicQueries__JT_jtQueryViewer_executeQuery";
```

#### 2.6 Actualizar Lightning Web Components

**ANTES:**
```html
<c-jt-query-viewer>
```

**DESPUÉS:**
```html
<c-jtdynamicqueries-jt-query-viewer>
```

### Paso 3: Crear Script de Migración

Necesitarás un script que busque y reemplace todas las referencias:

```bash
# Buscar todas las referencias a JT_*
find force-app -type f -name "*.cls" -o -name "*.js" -o -name "*.html" | \
  xargs grep -l "JT_" | \
  while read file; do
    # Reemplazar referencias
    sed -i '' 's/JT_DynamicQueryConfiguration__mdt/JTDynamicQueries__DynamicQueryConfiguration__mdt/g' "$file"
    # ... más reemplazos
  done
```

## 📋 Checklist Pre-AppExchange

### Código
- [ ] Namespace registrado y configurado
- [ ] Todas las referencias actualizadas
- [ ] Code coverage > 75% (tienes 84.5% ✅)
- [ ] 0 PMD violations (tienes 0 ✅)
- [ ] 0 ESLint errors (tienes 0 ✅)
- [ ] Todos los tests pasando (tienes 118+ E2E ✅)

### Seguridad
- [ ] No hardcoded credentials
- [ ] Input validation en todos los inputs
- [ ] SOQL injection prevention (tienes ✅)
- [ ] FLS/CRUD enforcement (tienes USER_MODE ✅)
- [ ] Error handling sin exponer información sensible

### Documentación
- [ ] User Guide completo
- [ ] Installation Guide
- [ ] Security Documentation
- [ ] API Documentation
- [ ] Screenshots/Videos de la aplicación

### Testing
- [ ] Unit tests para todas las clases públicas
- [ ] E2E tests para flujos principales
- [ ] Security tests
- [ ] Performance tests

## 🚀 Proceso de AppExchange

### 1. Preparar Managed Package

```bash
# Crear Managed Package (requiere namespace)
sf package create \
    --name JT_DynamicQueries \
    --description "Dynamic Query Framework" \
    --type Managed \
    --namespace JTDynamicQueries

# Crear versión
sf package version create \
    --package JT_DynamicQueries \
    --installation-key-bypass \
    --wait 10 \
    --code-coverage
```

### 2. Security Review

1. **Submit para Security Review**:
   - AppExchange Partner Portal
   - Llenar Security Questionnaire
   - Subir documentación

2. **Code Scan**:
   - Salesforce ejecuta análisis automático
   - Revisa vulnerabilidades
   - Puede requerir cambios

3. **Documentation Review**:
   - Revisan tu documentación
   - Verifican claridad y completitud

### 3. Listing en AppExchange

1. **Crear Listing**:
   - Título y descripción
   - Screenshots/Videos
   - Categorías
   - Pricing (Free/Paid)

2. **Aprobar Listing**:
   - Revisión de contenido
   - Verificación de branding
   - Aprobación final

## ⚠️ Consideraciones Importantes

### 1. Cambios Irreversibles

Una vez que creas un Managed Package con namespace:
- ❌ **NO puedes cambiar el namespace**
- ❌ **NO puedes convertir a Unlocked Package**
- ❌ **NO puedes eliminar componentes fácilmente**

### 2. Versionado Estricto

- Cada versión debe pasar Security Review
- No puedes hacer cambios menores sin review
- Las actualizaciones son más lentas

### 3. Actualizaciones NO Automáticas

**⚠️ IMPORTANTE**: Los Managed Packages **NO se actualizan automáticamente**.

- Los usuarios deben instalar manualmente cada nueva versión
- Reciben notificaciones pero deben hacer clic en "Upgrade"
- Puedes tener usuarios en diferentes versiones simultáneamente
- Debes soportar múltiples versiones

**Ventajas**:
- ✅ Usuarios tienen control sobre cuándo actualizar
- ✅ Pueden probar en sandbox primero
- ✅ Evita actualizaciones que rompan integraciones

**Desventajas**:
- ❌ Fragmentación de versiones (algunos usuarios desactualizados)
- ❌ Debes mantener compatibilidad hacia atrás
- ❌ Soporte más complejo (múltiples versiones)

Ver [Managed Package Updates Guide](./MANAGED_PACKAGE_UPDATES.md) para detalles completos.

### 3. Limitaciones de Managed Package

- Los usuarios NO pueden modificar código
- Algunas funcionalidades están restringidas
- Más difícil de debuggear en orgs de clientes

## 🎯 Recomendación: Estrategia Híbrida

### Opción 1: Dos Packages (Recomendado)

1. **Unlocked Package** (sin namespace):
   - Para usuarios que quieren personalizar
   - Instalación rápida
   - Sin Security Review

2. **Managed Package** (con namespace):
   - Para AppExchange
   - Código protegido
   - Con Security Review

**Ventaja**: Cubres ambos casos de uso

### Opción 2: Solo Managed Package

- ✅ AppExchange ready
- ✅ Código protegido
- ❌ Usuarios no pueden personalizar
- ❌ Más complejo de mantener

## 📚 Recursos

- [AppExchange Partner Portal](https://partners.salesforce.com/)
- [Security Review Guide](https://developer.salesforce.com/docs/atlas.en-us.appexchange.meta/appexchange/appexchange_security_review.htm)
- [Managed Package Development](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_dev_reg_namespace.htm)
- [Namespace Registry](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_dev_reg_namespace.htm)

## ✅ Próximos Pasos

1. **Decidir namespace**: `JTDynamicQueries` o similar
2. **Registrar namespace** en Salesforce
3. **Crear branch de migración**: `feature/appexchange-namespace`
4. **Ejecutar migración** con script automatizado
5. **Probar exhaustivamente** en scratch org
6. **Crear Managed Package** de prueba
7. **Iniciar Security Review**

¿Quieres que cree el script de migración y actualice la configuración?

