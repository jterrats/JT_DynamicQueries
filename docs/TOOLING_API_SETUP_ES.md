# Guía de Configuración de Tooling API

## 📋 Resumen

Esta guía te ayudará a configurar la **Credencial Nombrada** requerida para las funciones de Tooling API:

- **"¿Dónde se usa esto?"** - Busca referencias de configuración en Flows (1-5 llamadas API)
- **Crear/Editar Configuraciones** - Despliega metadatos personalizados vía Tooling API (2-3 llamadas API)

> **Nota:** La aplicación funciona **sin** Tooling API, pero estas funciones estarán deshabilitadas.

---

## 🎯 Requisitos Previos

- ✅ Acceso de Administrador de Salesforce
- ✅ Org con API habilitada (no disponible en orgs Trial)
- ✅ Permiso para crear Aplicaciones Conectadas

---

## 🔧 Paso 1: Crear una Aplicación Conectada

### 1.1 Navegar a Configuración

1. Haz clic en el ícono **⚙️ Configuración** (arriba a la derecha)
2. En Búsqueda Rápida, busca: **Administrador de Aplicaciones**
3. Haz clic en **Nueva Aplicación Conectada**

### 1.2 Configurar Información Básica

| Campo                              | Valor                            |
| ---------------------------------- | -------------------------------- |
| **Nombre de Aplicación Conectada** | `JT Dynamic Queries Tooling API` |
| **Nombre de API**                  | `JT_Dynamic_Queries_Tooling_API` |
| **Correo de Contacto**             | Tu dirección de correo           |

### 1.3 Habilitar Configuración OAuth

✅ Marca **Habilitar Configuración OAuth**

**URL de Callback:**

```
https://login.salesforce.com/services/oauth2/callback
```

**Ámbitos OAuth Seleccionados:**

- ✅ `Access the identity URL service (id, profile, email, address, phone)`
- ✅ `Manage user data via APIs (api)`
- ✅ `Perform requests at any time (refresh_token, offline_access)`

### 1.4 Guardar y Anotar Credenciales

1. Haz clic en **Guardar**
2. Haz clic en **Continuar**
3. **Copia y guarda de forma segura:**
   - 🔑 **Clave de Consumidor** (Client ID)
   - 🔐 **Secreto de Consumidor** (Haz clic para revelar)

> ⚠️ **Advertencia de Seguridad:** Almacena estas credenciales de forma segura. Las necesitarás en el Paso 2.

---

## 🔐 Paso 2: Configurar Credencial Externa

### 2.1 Navegar a Credenciales Nombradas

1. En Configuración, busca: **Credenciales Nombradas**
2. Haz clic en la pestaña **Credenciales Externas**
3. Encuentra: `JT_Tooling_API_External`
4. Haz clic en **Editar**

### 2.2 Agregar Protocolo de Autenticación

1. Bajo **Principales**, haz clic en **Nuevo**
2. Configura:

| Campo                              | Valor                                        |
| ---------------------------------- | -------------------------------------------- |
| **Etiqueta**                       | `Tooling API OAuth`                          |
| **Nombre**                         | `Tooling_API_OAuth`                          |
| **Protocolo de Autenticación**     | `OAuth 2.0`                                  |
| **Tipo de Flujo de Autenticación** | `Client Credentials with Client Secret Flow` |
| **Ámbito**                         | `api refresh_token`                          |

### 2.3 Agregar Credenciales de Cliente

En la sección **Parámetros de Autenticación**:

| Parámetro              | Valor                                        |
| ---------------------- | -------------------------------------------- |
| **ID de Cliente**      | _Pega la Clave de Consumidor del Paso 1.4_   |
| **Secreto de Cliente** | _Pega el Secreto de Consumidor del Paso 1.4_ |

3. Haz clic en **Guardar**

---

## 🌐 Paso 3: Configurar Credencial Nombrada

### 3.1 Navegar a Credenciales Nombradas

1. En Configuración, haz clic en la pestaña **Credenciales Nombradas**
2. Encuentra: `JT_Tooling_API`
3. Haz clic en **Editar**

### 3.2 Configurar Ajustes

| Campo                        | Valor                                   |
| ---------------------------- | --------------------------------------- |
| **Etiqueta**                 | `JT Tooling API`                        |
| **Nombre**                   | `JT_Tooling_API`                        |
| **URL**                      | `https://[TU_INSTANCIA].salesforce.com` |
| **Credencial Externa**       | `JT_Tooling_API_External`               |
| **Habilitado para Callouts** | ✅ Marcado                              |

**Reemplaza `[TU_INSTANCIA]`** con el My Domain de tu org:

- Ejemplo: `https://miempresa.my.salesforce.com`

3. Haz clic en **Guardar**

---

## ✅ Paso 4: Probar la Configuración

### 4.1 Abrir Dynamic Query Viewer

1. Navega a la aplicación **Dynamic Queries**
2. Ve a la pestaña **Query Viewer**
3. Busca la sección **API Features & Tooling API**

### 4.2 Habilitar Búsqueda "¿Dónde se usa esto?"

1. Marca la casilla: ✅ **Enable "Where is this used?" search**
2. Selecciona una configuración de consulta
3. Haz clic en **Where is this used?**

### 4.3 Resultados Esperados

✅ **Éxito:** Verás:

```
✓ Búsqueda en Apex: Completa
✓ Búsqueda en Flows: Completa
Se encontraron X referencias en clases Apex
Se encontraron Y referencias en Flows
```

❌ **Error:** Verás:

```
⚠️ Búsqueda en Flows: Fallida
Error: Credencial Nombrada no configurada
```

---

## 🐛 Solución de Problemas

### Problema 1: "Credencial Nombrada no encontrada"

**Causa:** La Credencial Nombrada `JT_Tooling_API` no existe o está deshabilitada.

**Solución:**

1. Verifica que la Credencial Nombrada existe en Configuración
2. Asegúrate de que **Habilitado para Callouts** esté marcado
3. Redespliega los metadatos:
   ```bash
   sf project deploy start --source-dir force-app/main/default/namedCredentials
   ```

### Problema 2: "Credenciales de Cliente Inválidas"

**Causa:** Las credenciales de la Aplicación Conectada son incorrectas o han expirado.

**Solución:**

1. Ve a **Administrador de Aplicaciones** → Encuentra tu Aplicación Conectada
2. Haz clic en **Ver** → Verifica la **Clave de Consumidor**
3. Si es necesario, reinicia el **Secreto de Consumidor**
4. Actualiza la Credencial Externa con las nuevas credenciales

### Problema 3: "Límite de API excedido"

**Causa:** Las llamadas a Tooling API consumen los límites diarios de API.

**Solución:**

1. Verifica el uso de API en Configuración → **Resumen del Sistema**
2. Considera deshabilitar "¿Dónde se usa esto?" temporalmente
3. Programa búsquedas durante horas de bajo uso

### Problema 4: "Privilegios insuficientes"

**Causa:** El usuario no tiene acceso API o permisos requeridos.

**Solución:**

1. Verifica que el usuario tenga el permiso **API Habilitada**
2. Asegúrate de que el usuario tenga el conjunto de permisos `JT_Dynamic_Queries`
3. Verifica que el perfil de usuario permita acceso API

---

## 📊 Referencia de Consumo de API

| Funcionalidad                 | Llamadas API por Operación                    |
| ----------------------------- | --------------------------------------------- |
| **¿Dónde se usa? (Apex)**     | 0 (sin API, usa SOQL en `ApexClass`)          |
| **¿Dónde se usa? (Flows)**    | 1-5 (consulta Tooling API)                    |
| **Crear Nueva Configuración** | 2-3 (despliegue de metadatos vía Tooling API) |
| **Editar Configuración**      | 2-3 (despliegue de metadatos vía Tooling API) |

**Límite Diario:** Varía según la edición del org (típicamente 15,000-100,000 llamadas/día)

---

## 🔒 Mejores Prácticas de Seguridad

### ✅ HACER:

- ✅ Usar una Aplicación Conectada dedicada para esta integración
- ✅ Rotar el Secreto de Consumidor periódicamente (cada 90 días)
- ✅ Usar una cuenta de servicio (no usuario personal) para OAuth
- ✅ Habilitar restricciones de IP en la Aplicación Conectada (si es posible)
- ✅ Auditar el uso de API vía Configuración → Uso de API

### ❌ NO HACER:

- ❌ Compartir Clave/Secreto de Consumidor en texto plano (Slack, correo)
- ❌ Hacer commit de credenciales en control de versiones
- ❌ Usar la misma Aplicación Conectada para múltiples integraciones
- ❌ Otorgar más ámbitos OAuth de los necesarios

---

## 📚 Recursos Adicionales

- [Documentación de Credenciales Nombradas de Salesforce](https://help.salesforce.com/s/articleView?id=sf.named_credentials_about.htm)
- [Guía del Desarrollador de Tooling API](https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/)
- [Flujo OAuth 2.0 JWT Bearer](https://help.salesforce.com/s/articleView?id=sf.remoteaccess_oauth_jwt_flow.htm)

---

## 🆘 ¿Necesitas Ayuda?

Si encuentras problemas no cubiertos en esta guía:

1. **Revisa Logs:** Configuración → Registros de Depuración (habilitar para usuario API)
2. **Revisa Auditoría:** Configuración → Ver Registro de Auditoría de Configuración
3. **Abre un Issue:** [GitHub Issues](https://github.com/YOUR_REPO/issues)
4. **Soporte de la Comunidad:** [Comunidad Trailblazer de Salesforce](https://trailhead.salesforce.com/trailblazer-community)

---

## 📝 Lista de Verificación de Referencia Rápida

- [ ] Paso 1: Crear Aplicación Conectada
  - [ ] Anotar Clave de Consumidor
  - [ ] Anotar Secreto de Consumidor
- [ ] Paso 2: Configurar Credencial Externa
  - [ ] Agregar Protocolo de Autenticación (OAuth 2.0)
  - [ ] Agregar Credenciales de Cliente
- [ ] Paso 3: Configurar Credencial Nombrada
  - [ ] Establecer URL correcta (My Domain)
  - [ ] Vincular a Credencial Externa
- [ ] Paso 4: Probar Configuración
  - [ ] Habilitar toggle "¿Dónde se usa esto?"
  - [ ] Verificar resultados de búsqueda

---

**¡Configuración Completa!** 🎉 Tu integración de Tooling API está ahora configurada y lista para usar.


