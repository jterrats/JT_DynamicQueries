# LinkedIn Post - JT Dynamic Queries

## Versión Personal (Recomendada - Tu Voz)

---

¡Hola a todos! Primero que nada, quiero desearles un feliz inicio de 2026 🎉

Durante este año tuve la oportunidad de trabajar en varios proyectos que me llevaron a crear la base de este framework orientado a SOQL. Originalmente pensé en un enfoque **70% para developers y 30% para admins** (puesto que usa la UI de los Custom Metadata Types).

Y no, esta no es la típica solución sobre CMT para queries dinámicos. Esto va un poco más allá.

**Lo que hace diferente a este framework:**

🎨 **UI con UX amigable** - Una interfaz completa que proporciona una experiencia de usuario intuitiva, no solo campos en Custom Metadata

🛡️ **Manejo de errores robusto** - Valida las consultas a la base de datos antes de emplearlas en Apex, ahorrando tiempo de debugging

👤 **Run As User** - Esta es mi funcionalidad favorita. Ahorra tiempo de debug porque imita cómo un usuario de la plataforma tiene acceso a los datos, sin necesidad de cambiar de usuario constantemente

🔍 **Where is this used?** - Una manera genial de saber si las configuraciones se usan en Apex classes o Flows. Perfecto para refactoring y mantenimiento

🌳 **Tree View** - Visualiza relaciones padre-hijo de forma intuitiva, no en tablas planas

📊 **Múltiples formatos** - Tabla, JSON, CSV - copia en el formato que necesites

⚡ **Escala Enterprise** - Maneja 50k+ registros con paginación eficiente

**📦 Instalación en un click:**
GitHub: https://github.com/jterrats/JT_DynamicQueries

**📈 Calidad:**
✅ 84.5% test coverage
✅ 28/28 E2E tests passing
✅ WCAG 2.1 AA compliant
✅ 100% open-source (MIT)

¿Qué feature les gustaría probar primero? 👇

---

#Salesforce #SalesforceDeveloper #OpenSource #SOQL #SalesforceAdmin #Apex #LWC #SalesforceCommunity

---

## Short Version (English - Recommended for LinkedIn Feed)

---

🚀 **Tired of writing the same SOQL queries over and over?**

I just published **JT Dynamic Queries**, an open-source framework for Salesforce that transforms how developers interact with data.

**✨ What makes it different:**

🔍 **Pre-configured**: Define queries in Custom Metadata, execute from anywhere
👤 **Run As User**: Test permissions without switching users
🌳 **Tree View**: Visualize parent-child relationships intuitively
⚡ **Enterprise Scale**: Handles 50k+ records with efficient pagination
📊 **Multiple Views**: Table, JSON, CSV - copy in the format you need
🔒 **Secure by Default**: USER_MODE enforcement, respects FLS and sharing rules

**🎯 Perfect for:**

- Quick data debugging
- Permission and security validation
- Complex relationship analysis
- Data export for documentation

**📦 One-click installation:**
GitHub: https://github.com/jterrats/JT_DynamicQueries

**📈 Stats:**
✅ 84.5% test coverage
✅ 28/28 E2E tests passing
✅ WCAG 2.1 AA compliant
✅ 100% open-source (MIT)

What feature would you like to try first? 👇

---

#Salesforce #SalesforceDeveloper #OpenSource #SOQL #SalesforceAdmin #Apex #LWC #SalesforceCommunity

---

## Versión Larga Personal (Español - Para Artículo)

---

### Transformando el Desarrollo en Salesforce: Presentando JT Dynamic Queries

¡Hola a todos! Primero que nada, quiero desearles un feliz inicio de 2026 🎉

Durante este año tuve la oportunidad de trabajar en varios proyectos que me llevaron a crear la base de este framework orientado a SOQL. Originalmente pensé en un enfoque **70% para developers y 30% para admins** (puesto que usa la UI de los Custom Metadata Types).

Y no, esta no es la típica solución sobre CMT para queries dinámicos. Esto va un poco más allá.

**El Problema:**
Como desarrolladores de Salesforce, todos hemos estado ahí: escribiendo las mismas queries SOQL una y otra vez, cambiando de usuario para probar permisos, o luchando con relaciones complejas en tablas planas.

**La Solución:**
Después de meses de desarrollo y testing, estoy emocionado de compartir **JT Dynamic Queries** - un framework open-source que transforma cómo trabajamos con datos en Salesforce.

**Lo que hace diferente:**

No es solo Custom Metadata Types. Es una **interfaz completa** que proporciona una experiencia de usuario amigable, con manejo robusto de errores que valida las consultas antes de emplearlas en Apex.

**🔍 Características Principales:**

1. **Run As User** ⭐ (Mi funcionalidad favorita)
   - Prueba permisos en tiempo real sin cambiar de usuario
   - Valida FLS, CRUD y sharing rules
   - Dos modos: USER_MODE y System.runAs
   - Ahorra horas de debugging

2. **Where is this used?**
   - Descubre si las configuraciones se usan en Apex classes o Flows
   - Perfecto para refactoring y mantenimiento
   - Integración con Tooling API

3. **UI con UX Amigable**
   - No solo Custom Metadata Types
   - Interfaz completa con validación en tiempo real
   - Manejo robusto de errores antes de ejecutar en Apex

4. **Tree View para Relaciones**
   - Visualiza relaciones padre-hijo de forma intuitiva
   - Expand/collapse para navegar datos complejos
   - No más tablas planas

5. **Escala Enterprise**
   - Paginación basada en cursor
   - Maneja 50k+ registros eficientemente
   - Sin dolores de cabeza con límites de gobernador

6. **Múltiples Formatos de Exportación**
   - Vista Tabla: Para análisis rápido
   - Vista JSON: Para integraciones
   - Vista CSV: Para Excel/Sheets
   - Copy to clipboard con fallback

**📊 Quality & Testing:**

- ✅ 84.5% Apex test coverage
- ✅ 28/28 E2E tests passing (Playwright)
- ✅ WCAG 2.1 AA compliant
- ✅ 723 unit tests
- ✅ Automated CI/CD with GitHub Actions

**🚀 Casos de Uso:**

- **Debugging Rápido**: Queries pre-configuradas para escenarios comunes
- **Testing de Seguridad**: Valida modelos de permisos sin cambiar usuarios
- **Análisis de Datos**: Exporta datos en el formato que necesites
- **Colaboración en Equipo**: Comparte configuraciones validadas
- **Refactoring**: Encuentra dónde se usan tus configuraciones antes de cambiar código

**💡 Por qué Open Source:**

Creo que las mejores herramientas nacen de la comunidad. Este proyecto está diseñado para crecer con feedback real de desarrolladores que enfrentan los mismos desafíos diarios.

**📦 Instalación:**

Un solo click con el botón "Deploy to Salesforce" o clona el repo y despliega manualmente.

GitHub: https://github.com/jterrats/JT_DynamicQueries
Documentación: https://jterrats.github.io/JT_DynamicQueries/

**🤝 Contribuciones:**

Pull requests, issues y feedback son bienvenidos. Este es un proyecto vivo que mejora con cada contribución.

¿Qué les parece? ¿Qué feature les gustaría probar primero? Déjenme saber en los comentarios 👇

---

## Long Version (English - For LinkedIn Article)

---

### Transforming Salesforce Development: Introducing JT Dynamic Queries

As Salesforce developers, we've all been there: writing the same SOQL queries repeatedly, switching users to test permissions, or struggling with complex relationships in flat tables.

**The Problem:**

- Repetitive code for common queries
- Difficulty validating permissions without switching users
- Lack of visibility into parent-child relationships
- Governor limit headaches when handling large volumes

**The Solution:**
After months of development and testing, I'm excited to share **JT Dynamic Queries** - an open-source framework that transforms how we work with data in Salesforce.

**🔍 Key Features:**

1. **Metadata-Driven Architecture**
   - Define queries in Custom Metadata Types
   - Reuse configurations across the org
   - No hardcoded queries

2. **Run As User Testing**
   - Test permissions in real-time
   - Validate FLS, CRUD, and sharing rules
   - Two modes: USER_MODE and System.runAs

3. **Tree View for Relationships**
   - Visualize parent-child relationships
   - Intuitive expand/collapse
   - Perfect for complex data structures

4. **Enterprise-Scale Performance**
   - Cursor-based pagination
   - Handles 50k+ records efficiently
   - No governor limit headaches

5. **Multiple Export Formats**
   - Table View: For quick analysis
   - JSON View: For integrations
   - CSV View: For Excel/Sheets
   - Copy to clipboard with fallback

**🚀 Use Cases:**

- **Debugging**: Pre-configured queries for common scenarios
- **Security Testing**: Validate permission models without switching users
- **Data Analysis**: Export data in the format you need
- **Team Collaboration**: Share validated configurations

**💡 Why Open Source:**

I believe the best tools come from the community. This project is designed to grow with real feedback from developers facing the same daily challenges.

**📦 Installation:**

One click with the "Deploy to Salesforce" button or clone the repo and deploy manually.

GitHub: https://github.com/jterrats/JT_DynamicQueries
Documentation: https://jterrats.github.io/JT_DynamicQueries/

**🤝 Contributions:**

Pull requests, issues, and feedback are welcome. This is a living project that improves with every contribution.

What do you think? What feature would you like to see first? Let me know in the comments 👇

---

#Salesforce #SalesforceDeveloper #OpenSource #SOQL #SalesforceAdmin #Apex #LWC #SalesforceCommunity #DevOps #SalesforceArchitecture

---

## Technical Version (For Developer Groups)

---

**🎯 For Salesforce developers seeking efficiency:**

I just open-sourced **JT Dynamic Queries** - a metadata-driven framework for SOQL execution with:

**Architecture:**

- Custom Metadata Types for configuration
- Modular LWC (8 specialized components)
- USER_MODE enforcement by default
- Cursor-based pagination for large datasets

**Technical Features:**

- Dynamic parameter binding with validation
- Run As User with System.runAs for real testing
- Tree view with lazy loading for child relationships
- CSV export with intelligent flattening
- Tooling API integration for "Where is this used?"

**Testing:**

- 723 Apex unit tests (98% pass rate)
- 113+ Playwright E2E tests (100% pass rate)
- Automated CI/CD pipeline
- Visual regression testing

**Tech Stack:**

- Apex 65.0
- Lightning Web Components
- Playwright for E2E
- GitHub Actions for CI/CD

Repo: https://github.com/jterrats/JT_DynamicQueries

Feedback and contributions welcome! 🚀

---

#SalesforceDeveloper #Apex #LWC #SalesforceArchitecture #OpenSource #SalesforceDX

---

## Publishing Tips:

1. **Best time**: Tuesday-Thursday, 8-10 AM or 12-1 PM (local time)
2. **Include image**: Project screenshot or animated GIF
3. **Engagement**: Respond to all comments within the first 24 hours
4. **Hashtags**: Use 3-5 relevant hashtags, no more
5. **Call-to-action**: End with a question to generate conversation

## Suggested Images:

- Main interface screenshot
- "Query Execution" GIF (01-query-execution.gif)
- "Run As User" GIF (06-run-as-user.gif)
- Architecture diagram (if available)

## Links to Include:

- GitHub: https://github.com/jterrats/JT_DynamicQueries
- Documentation: https://jterrats.github.io/JT_DynamicQueries/
- Deploy Button: https://githubsfdeploy.herokuapp.com?owner=jterrats&repo=JT_DynamicQueries&ref=main
