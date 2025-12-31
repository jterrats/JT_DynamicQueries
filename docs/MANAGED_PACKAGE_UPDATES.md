# Managed Package Updates - Distribution Model

## ❌ Actualizaciones NO Automáticas

**IMPORTANTE**: Los Managed Packages en Salesforce **NO se actualizan automáticamente**. Los usuarios deben instalar manualmente cada nueva versión.

## 🔄 Cómo Funcionan las Actualizaciones

### 1. Proceso de Actualización

```
Desarrollador crea nueva versión
    ↓
Publica en AppExchange
    ↓
Usuarios reciben NOTIFICACIÓN (no instalación automática)
    ↓
Usuarios deciden CUÁNDO actualizar
    ↓
Instalan manualmente desde AppExchange o Setup
```

### 2. Notificaciones a Usuarios

Salesforce puede notificar a los usuarios sobre nuevas versiones disponibles:

- **Email notifications**: Si el usuario está suscrito
- **In-App notifications**: En Setup → Installed Packages
- **AppExchange listing**: Muestra "Update Available"

Pero **NO instala automáticamente**.

### 3. Instalación Manual Requerida

Los usuarios deben:

1. **Ir a Setup → Installed Packages**
2. **Ver la nueva versión disponible**
3. **Hacer clic en "Upgrade"**
4. **Revisar cambios** (Salesforce muestra qué cambió)
5. **Confirmar actualización**

O desde AppExchange:

1. **Ir al listing de tu app**
2. **Ver "Update Available"**
3. **Hacer clic en "Get It Now"**
4. **Instalar la nueva versión**

## 📊 Ventajas y Desventajas

### ✅ Ventajas del Modelo Manual

1. **Control del Usuario**:
   - Los usuarios deciden cuándo actualizar
   - Pueden probar en sandbox primero
   - Pueden revisar cambios antes de actualizar

2. **Menos Riesgo**:
   - Evita actualizaciones que rompan integraciones
   - Permite testing antes de producción
   - Los usuarios pueden esperar a que otros prueben primero

3. **Transparencia**:
   - Los usuarios ven exactamente qué cambió
   - Pueden revisar release notes
   - Pueden prepararse para cambios breaking

### ❌ Desventajas del Modelo Manual

1. **Fragmentación de Versiones**:
   - Algunos usuarios en v2.5.0
   - Otros en v2.4.0
   - Otros en v2.3.0
   - Dificulta soporte

2. **Usuarios Desactualizados**:
   - Algunos usuarios nunca actualizan
   - Pueden tener bugs conocidos
   - No reciben nuevas features

3. **Soporte Complejo**:
   - Debes soportar múltiples versiones
   - Debes documentar cambios entre versiones
   - Más complejo para debugging

## 🎯 Estrategias para Facilitar Actualizaciones

### 1. Versionado Semántico

Usa [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
2.5.0
```

- **MAJOR** (2.x.x): Breaking changes - usuarios deben revisar cuidadosamente
- **MINOR** (x.5.x): Nuevas features - generalmente seguro actualizar
- **PATCH** (x.x.0): Bug fixes - muy seguro actualizar

### 2. Release Notes Detallados

Proporciona release notes claros:

```markdown
## Version 2.5.0

### 🆕 New Features
- Improved GIF capture script
- Enhanced Run As User flow

### 🐛 Bug Fixes
- Fixed GIF paths in GitHub Pages
- Fixed query risk warning logic

### ⚠️ Breaking Changes
- None

### 📋 Migration Notes
- No action required
- All existing configurations remain compatible
```

### 3. Upgrade Paths Claros

Documenta cómo actualizar:

```markdown
## Upgrading from 2.4.0 to 2.5.0

1. Backup your Custom Metadata configurations
2. Go to Setup → Installed Packages
3. Click "Upgrade" next to JT Dynamic Queries
4. Review changes
5. Click "Upgrade" to confirm
6. Verify configurations still work
```

### 4. Notificaciones Proactivas

- **Email a usuarios registrados**: Cuando hay nueva versión
- **In-app notifications**: Mostrar banner en tu app
- **Documentation updates**: Actualizar docs con nueva versión

### 5. Testing en Sandbox Primero

Anima a usuarios a:
- Probar actualizaciones en sandbox primero
- Validar que sus configuraciones siguen funcionando
- Reportar problemas antes de actualizar producción

## 🔍 Alternativas para "Actualización Automática"

### Opción 1: Managed Package con Auto-Update (No Disponible)

**❌ NO EXISTE** en Salesforce. Los Managed Packages siempre requieren instalación manual.

### Opción 2: Unlocked Package (Diferente Modelo)

Los **Unlocked Packages** también requieren instalación manual, pero:
- Los usuarios pueden modificar código
- Pueden hacer sus propios cambios
- Más difícil de actualizar (conflictos con modificaciones)

### Opción 3: Metadata API Updates (Complejo)

Podrías crear un sistema que:
- Detecte versiones desactualizadas
- Ofrezca actualización desde tu app
- Use Metadata API para actualizar componentes

**⚠️ Limitaciones**:
- Muy complejo de implementar
- Requiere permisos especiales
- Puede fallar si usuario modificó código
- No recomendado para Managed Packages

### Opción 4: Hybrid Approach (Recomendado)

**Estrategia Dual**:

1. **Managed Package** (AppExchange):
   - Para usuarios que quieren estabilidad
   - Actualizaciones manuales controladas
   - Código protegido

2. **Unlocked Package** (GitHub):
   - Para usuarios que quieren personalizar
   - Pueden hacer sus propios updates desde Git
   - Más flexible

## 📈 Mejores Prácticas

### 1. Versionado Consistente

```json
{
  "versionNumber": "2.5.0.NEXT",
  "versionName": "ver 2.5.0"
}
```

### 2. Release Notes en Cada Versión

- Qué cambió
- Por qué cambió
- Cómo afecta a usuarios
- Pasos de migración (si aplica)

### 3. Compatibilidad Hacia Atrás

- **MAJOR versions**: Pueden tener breaking changes
- **MINOR versions**: Deben ser compatibles hacia atrás
- **PATCH versions**: Solo bug fixes, 100% compatibles

### 4. Comunicación con Usuarios

- **Email list**: Para notificaciones de versiones
- **GitHub Releases**: Para release notes
- **In-app messaging**: Para anuncios importantes

### 5. Testing de Actualización

Antes de publicar:
- ✅ Probar upgrade desde versión anterior
- ✅ Verificar que configuraciones existentes funcionan
- ✅ Validar que no hay pérdida de datos
- ✅ Probar en diferentes tipos de orgs

## 🔧 Scripts Útiles

### Verificar Versiones Instaladas

```apex
// Apex para detectar versión instalada
SELECT SubscriberPackageVersionId,
       SubscriberPackageVersion.Name,
       SubscriberPackageVersion.MajorVersion,
       SubscriberPackageVersion.MinorVersion,
       SubscriberPackageVersion.PatchVersion
FROM InstalledSubscriberPackage
WHERE SubscriberPackage.NamespacePrefix = 'JTDynamicQueries'
```

### Notificar Usuarios de Nueva Versión

```javascript
// LWC para mostrar banner de actualización disponible
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UpdateNotification extends LightningElement {
    connectedCallback() {
        // Check current version vs latest available
        // Show banner if update available
    }
}
```

## 📚 Referencias

- [Salesforce Package Versioning](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_versioning.htm)
- [AppExchange Distribution](https://developer.salesforce.com/docs/atlas.en-us.appexchange.meta/appexchange/appexchange_distribution.htm)
- [Package Upgrade Best Practices](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_upgrade.htm)

## ✅ Conclusión

**Los Managed Packages NO se actualizan automáticamente**, pero esto es una **característica, no un bug**:

- ✅ Da control a los usuarios
- ✅ Permite testing antes de producción
- ✅ Evita actualizaciones que rompan cosas
- ✅ Transparencia sobre cambios

**Tu responsabilidad como desarrollador**:
- Hacer actualizaciones fáciles de instalar
- Proporcionar release notes claros
- Mantener compatibilidad hacia atrás cuando sea posible
- Comunicar proactivamente sobre nuevas versiones

