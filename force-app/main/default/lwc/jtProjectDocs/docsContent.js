/**
 * @description Multi-language documentation content
 * @author Jaime Terrats
 * @date 2025-11-29
 */

const LOCALE = Intl.DateTimeFormat().resolvedOptions().locale || "en-US";
const LANG = LOCALE.split("-")[0];

const DOCS = {
  en: {
    title: "Dynamic Query Viewer - Documentation",
    tableOfContents: "Table of Contents",
    overview: {
      title: "Overview",
      description:
        "Dynamic Query Viewer is a powerful Salesforce Lightning component that enables users to execute predefined SOQL queries with dynamic parameters and advanced security features.",
      content: `
                <p><strong>Key Benefits:</strong></p>
                <ul>
                    <li>Execute predefined queries securely with USER_MODE enforcement</li>
                    <li>Dynamic parameter binding for flexible queries</li>
                    <li>Run As functionality for permission testing</li>
                    <li>Metadata-driven configuration</li>
                    <li>Multi-language support (English, Spanish, French, German)</li>
                    <li>Responsive design for mobile and desktop</li>
                </ul>
            `
    },
    features: {
      title: "Features",
      content: `
                <h3>1. Query Execution</h3>
                <ul>
                    <li><strong>Predefined Configurations:</strong> Select from custom metadata-based query configurations</li>
                    <li><strong>Dynamic Parameters:</strong> Automatically generates input fields for query bind variables</li>
                    <li><strong>Query Preview:</strong> See the query before execution</li>
                    <li><strong>Pagination:</strong> Automatically paginates results when more than 10 records</li>
                    <li><strong>Empty State Handling:</strong> Shows table structure even with 0 results</li>
                </ul>

                <h3>2. Run As User (Advanced)</h3>
                <ul>
                    <li><strong>User Impersonation:</strong> Test queries in the context of other users</li>
                    <li><strong>System.runAs Test:</strong> True impersonation using Apex test context</li>
                    <li><strong>Permission Validation:</strong> Verifies sharing rules and field-level security</li>
                    <li><strong>User Dropdown:</strong> Client-side filtered dropdown with all active users</li>
                </ul>

                <h3>3. Metadata Creation (Sandbox Only)</h3>
                <ul>
                    <li><strong>Create Configurations:</strong> Add new query configurations via UI</li>
                    <li><strong>Edit Configurations:</strong> Modify existing configurations</li>
                    <li><strong>SOQL Validation:</strong> Real-time query validation</li>
                    <li><strong>Production Safeguard:</strong> Feature disabled in production orgs</li>
                </ul>

                <h3>4. Internationalization</h3>
                <ul>
                    <li>Supports English, Spanish, French, and German</li>
                    <li>Automatic locale detection from browser</li>
                    <li>Fallback to English for unsupported locales</li>
                </ul>
            `
    },
    usage: {
      title: "How to Use",
      content: `
                <h3>Basic Query Execution</h3>
                <ol>
                    <li><strong>Select Configuration:</strong> Choose a predefined query from the dropdown</li>
                    <li><strong>Enter Parameters:</strong> Fill in any required parameters (if applicable)</li>
                    <li><strong>Execute:</strong> Click "Execute Query" button</li>
                    <li><strong>View Results:</strong> Results appear in a paginated table</li>
                </ol>

                <div class="alert-info">
                    <p><strong>Tip:</strong> If a configuration has predefined bindings, you'll see an info message and won't need to enter parameters manually.</p>
                </div>

                <h3>Using Run As Feature</h3>
                <ol>
                    <li><strong>Verify Access:</strong> Ensure you have "Modify All Data" or "View All Data" permission</li>
                    <li><strong>Select User:</strong> Type to filter and select a user from the dropdown</li>
                    <li><strong>Execute as User:</strong> Click "Execute Query" (for USER_MODE) or "Execute with System.runAs (Test)" for true impersonation</li>
                    <li><strong>View Results:</strong> Results reflect the selected user's permissions</li>
                </ol>

                <div class="alert-warning">
                    <p><strong>Note:</strong> System.runAs executes in a test context and may take longer due to asynchronous processing.</p>
                </div>

                <h3>Creating New Configurations (Sandbox Only)</h3>
                <ol>
                    <li><strong>Click "Create New Configuration":</strong> Opens the configuration modal</li>
                    <li><strong>Fill Details:</strong>
                        <ul>
                            <li>Label: Display name for the configuration</li>
                            <li>Developer Name: API name (auto-generated from label)</li>
                            <li>Base Query: Your SOQL query</li>
                            <li>Bindings (optional): JSON object with parameter values</li>
                        </ul>
                    </li>
                    <li><strong>Validate:</strong> Query is validated in real-time</li>
                    <li><strong>Save:</strong> Configuration is deployed via Tooling API</li>
                </ol>
            `
    },
    configuration: {
      title: "Configuration",
      content: `
                <h3>Custom Metadata Type: JT_DynamicQueryConfiguration__mdt</h3>
                <p>Query configurations are stored as Custom Metadata records with the following fields:</p>

                <table>
                    <thead>
                        <tr>
                            <th>Field</th>
                            <th>Type</th>
                            <th>Description</th>
                            <th>Required</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>Label</td>
                            <td>Text</td>
                            <td>Display name shown in the dropdown</td>
                            <td>Yes</td>
                        </tr>
                        <tr>
                            <td>DeveloperName</td>
                            <td>Text</td>
                            <td>API name for the configuration</td>
                            <td>Yes</td>
                        </tr>
                        <tr>
                            <td>JT_BaseQuery__c</td>
                            <td>Long Text Area</td>
                            <td>SOQL query with bind variables (e.g., :accountId)</td>
                            <td>Yes</td>
                        </tr>
                        <tr>
                            <td>JT_Bindings__c</td>
                            <td>Long Text Area</td>
                            <td>JSON object with parameter values (e.g., {"accountId": "001..."})</td>
                            <td>No</td>
                        </tr>
                        <tr>
                            <td>JT_ObjectName__c</td>
                            <td>Text</td>
                            <td>Object name (auto-populated from query)</td>
                            <td>No</td>
                        </tr>
                    </tbody>
                </table>

                <h3>Example Configuration</h3>
                <pre>
Label: Account Contacts
Developer Name: Account_Contacts
Base Query: SELECT Id, Name, Email, Phone FROM Contact WHERE AccountId = :accountId
Bindings: {"accountId": "0015g00000XXXXXX"}
Object Name: Contact
                </pre>

                <div class="alert-success">
                    <p><strong>Best Practice:</strong> Use descriptive labels and developer names for easy identification.</p>
                </div>
            `
    },
    runAs: {
      title: "Run As User Feature",
      content: `
                <h3>Understanding Run As</h3>
                <p>The Run As feature allows administrators to test queries in the context of other users, validating:</p>
                <ul>
                    <li>Sharing rules (OWD, sharing rules, manual shares)</li>
                    <li>Field-level security (FLS)</li>
                    <li>Object permissions (CRUD)</li>
                    <li>Record type access</li>
                </ul>

                <h3>Two Execution Modes</h3>

                <h4>1. Execute Query (USER_MODE)</h4>
                <p>Standard execution with USER_MODE security. This validates user permissions but doesn't use System.runAs().</p>
                <ul>
                    <li><strong>Pros:</strong> Fast, synchronous execution</li>
                    <li><strong>Cons:</strong> Limited to current user context with USER_MODE enforcement</li>
                </ul>

                <h4>2. Execute with System.runAs (Test)</h4>
                <p>True impersonation using System.runAs() in a test context.</p>
                <ul>
                    <li><strong>Pros:</strong> Full impersonation, accurate permission testing</li>
                    <li><strong>Cons:</strong> Asynchronous (uses Platform Cache), slower execution</li>
                </ul>

                <h3>Architecture</h3>
                <pre>
1. LWC calls JT_RunAsTestExecutor.executeAsUser()
2. Parameters stored in Platform Cache
3. JT_GenericRunAsTest enqueued (Test.startTest)
4. System.runAs() executes query
5. Results serialized to JSON and cached
6. LWC polls getTestResults() until ready
7. Results displayed in datatable
                </pre>

                <div class="alert-warning">
                    <p><strong>Permissions Required:</strong> User must have "Modify All Data" OR "View All Data" permission to use Run As.</p>
                </div>
            `
    },
    metadata: {
      title: "Metadata Creation",
      content: `
                <h3>Creating Configurations via UI</h3>
                <p>In sandbox and scratch orgs, you can create and edit configurations directly from the UI.</p>

                <h3>Production Safeguard</h3>
                <p>The "Create New Configuration" button is <strong>automatically hidden in production orgs</strong> to prevent accidental metadata modifications.</p>
                <p><strong>Detection Logic:</strong></p>
                <pre>
Apex: Organization.IsSandbox OR TrialExpirationDate != null
E2E Tests: instanceUrl.includes('sandbox')
                </pre>

                <h3>Validation Rules</h3>
                <ul>
                    <li><strong>Label:</strong> Must not be blank</li>
                    <li><strong>Developer Name:</strong> Must not be blank, auto-sanitized</li>
                    <li><strong>Base Query:</strong> Must be valid SOQL, starts with SELECT</li>
                    <li><strong>Bindings:</strong> Optional, must be valid JSON if provided</li>
                </ul>

                <h3>Tooling API Deployment</h3>
                <p>Configurations are deployed via the Tooling API as CustomMetadata records:</p>
                <pre>
POST /services/data/v65.0/tooling/sobjects/CustomMetadata
{
    "FullName": "JT_DynamicQueryConfiguration.{DeveloperName}",
    "Metadata": {
        "label": "{Label}",
        "values": [
            { "field": "JT_BaseQuery__c", "value": "{BaseQuery}" },
            { "field": "JT_Bindings__c", "value": "{Bindings}" },
            { "field": "JT_ObjectName__c", "value": "{ObjectName}" }
        ]
    }
}
                </pre>

                <div class="alert-info">
                    <p><strong>Refresh Behavior:</strong> After creating a configuration, the dropdown automatically refreshes using refreshApex().</p>
                </div>
            `
    },
    security: {
      title: "Security & Permissions",
      content: `
                <h3>Permission Set: JT_Dynamic_Queries</h3>
                <p>Users need the JT_Dynamic_Queries permission set to access the application.</p>

                <h4>Grants Access To:</h4>
                <ul>
                    <li>Apex Classes: JT_DataSelector, JT_QueryViewerController, JT_RunAsTestExecutor, JT_MetadataCreator, JT_GenericRunAsTest</li>
                    <li>Custom Metadata: JT_DynamicQueryConfiguration__mdt</li>
                    <li>Custom App: JT_Dynamic_Queries</li>
                </ul>

                <h3>Query Security</h3>
                <p>All queries execute with <code>WITH USER_MODE</code> to enforce:</p>
                <ul>
                    <li>Object-level security (CRUD)</li>
                    <li>Field-level security (FLS)</li>
                    <li>Sharing rules</li>
                </ul>

                <h3>Singleton Pattern</h3>
                <p>JT_DataSelector implements a singleton pattern with static caching:</p>
                <pre>
private static JT_DataSelector instance;
private static Map&lt;String, JT_DynamicQueryConfiguration__mdt&gt; configCache;

public static JT_DataSelector getInstance() {
    if (instance == null) {
        instance = new JT_DataSelector();
    }
    return instance;
}
                </pre>

                <h3>Code Quality</h3>
                <ul>
                    <li><strong>PMD Scan:</strong> 0 violations</li>
                    <li><strong>ESLint:</strong> 0 violations</li>
                    <li><strong>Apex Test Coverage:</strong> 84.5% average (exceeds 75% requirement)</li>
                    <li><strong>ApexDoc:</strong> All public methods documented</li>
                </ul>
            `
    },
    troubleshooting: {
      title: "Troubleshooting",
      content: `
                <h3>Common Issues</h3>

                <h4>1. "No configurations found"</h4>
                <p><strong>Cause:</strong> No Custom Metadata records exist or user doesn't have access.</p>
                <p><strong>Solution:</strong></p>
                <ul>
                    <li>Create at least one JT_DynamicQueryConfiguration__mdt record</li>
                    <li>Assign the JT_Dynamic_Queries permission set</li>
                </ul>

                <h4>2. "Insufficient permissions to use Run As feature"</h4>
                <p><strong>Cause:</strong> User doesn't have required permissions.</p>
                <p><strong>Solution:</strong> User needs either "Modify All Data" or "View All Data" permission.</p>

                <h4>3. "Query returned no records" (but should have results)</h4>
                <p><strong>Cause:</strong> Sharing rules or FLS blocking access.</p>
                <p><strong>Solution:</strong></p>
                <ul>
                    <li>Verify user has access to the object</li>
                    <li>Check sharing settings</li>
                    <li>Use Run As to test with different users</li>
                </ul>

                <h4>4. "Create New Configuration" button not visible</h4>
                <p><strong>Cause:</strong> This is expected behavior in production orgs.</p>
                <p><strong>Solution:</strong> Use Setup → Custom Metadata Types in production, or work in a sandbox.</p>

                <h4>5. Pagination not showing</h4>
                <p><strong>Cause:</strong> Query returned 10 or fewer records.</p>
                <p><strong>Solution:</strong> Pagination only appears when more than 10 results exist. This is by design.</p>

                <h4>6. User dropdown is empty</h4>
                <p><strong>Cause:</strong> No other active users in the org, or Run As permission issue.</p>
                <p><strong>Solution:</strong></p>
                <ul>
                    <li>Ensure there are other active users in the org</li>
                    <li>Verify Run As permissions</li>
                    <li>Note: Current user is automatically excluded from the list</li>
                </ul>

                <div class="alert-info">
                    <p><strong>Debug Tip:</strong> Check the browser console (F12) for JavaScript errors and review Salesforce debug logs for Apex errors.</p>
                </div>
            `
    },
    api: {
      title: "API Reference",
      content: `
                <h3>Apex Classes</h3>

                <h4>JT_DataSelector</h4>
                <pre>
// Get singleton instance
JT_DataSelector selector = JT_DataSelector.getInstance();

// Example 1: Use predefined bindings from metadata
List&lt;SObject&gt; records = JT_DataSelector.getRecords('ConfigName', true);

// Example 2: Override with custom bindings from Apex
Map&lt;String, Object&gt; bindings = new Map&lt;String, Object&gt;{
    'accountId' => '0015g00000XXXXXX',
    'status' => 'Active'
};
List&lt;SObject&gt; records = JT_DataSelector.getRecords('ConfigName', true, bindings);

// Example 3: Mix predefined + runtime bindings
// Metadata has: {"accountType": "Customer"}
// Apex adds: {"region": "North America"}
// Final query uses BOTH sets of bindings
Map&lt;String, Object&gt; additionalBindings = new Map&lt;String, Object&gt;{
    'region' => 'North America',
    'createdDate' => Date.today().addMonths(-1)
};
List&lt;SObject&gt; records = JT_DataSelector.getRecords('MixedConfig', true, additionalBindings);
// Query example: SELECT Id, Name FROM Account WHERE Type = :accountType AND Region__c = :region

// Example 4: Invocable method (for Flows/Agentforce)
// Access via Flow Builder or Agentforce Agent Builder as an Apex Action
                </pre>

                <div class="alert-info">
                    <p><strong>Tip:</strong> When you pass bindings from Apex, they are merged with the predefined bindings from metadata.
                    If the same key exists in both, the Apex-provided value takes precedence.</p>
                </div>

                <h4>JT_QueryViewerController</h4>
                <pre>
// Get all configurations
@AuraEnabled(cacheable=true)
public static List&lt;ConfigurationOption&gt; getConfigurations()

// Execute query
@AuraEnabled
public static QueryResult executeQuery(
    String devName,
    String bindingsJson,
    String runAsUserId
)

// Get all active users
@AuraEnabled(cacheable=true)
public static List&lt;UserOption&gt; getAllActiveUsers()

// Extract parameters from query
@AuraEnabled(cacheable=true)
public static List&lt;String&gt; extractParameters(String query)
                </pre>

                <h4>JT_RunAsTestExecutor</h4>
                <pre>
// Execute query with System.runAs
@AuraEnabled
public static TestExecutionResult executeAsUser(
    String userId,
    String configName,
    String bindingsJson
)

// Get test results (polling)
@AuraEnabled
public static TestExecutionResult getTestResults(String userId)
                </pre>

                <h4>JT_MetadataCreator</h4>
                <pre>
// Create new configuration
@AuraEnabled
public static MetadataCreationResult createConfiguration(
    String label,
    String developerName,
    String baseQuery,
    String bindings,
    String objectName
)

// Update existing configuration
@AuraEnabled
public static MetadataCreationResult updateConfiguration(
    String originalDevName,
    String label,
    String baseQuery,
    String bindings,
    String objectName
)

// Check if sandbox/scratch
@AuraEnabled(cacheable=true)
public static Boolean isSandboxOrScratch()

// Validate SOQL query
@AuraEnabled
public static QueryValidationResult validateQuery(String query)
                </pre>

                <h3>LWC Components</h3>

                <h4>jtQueryViewer</h4>
                <p>Main query execution component with features:</p>
                <ul>
                    <li>Configuration selection</li>
                    <li>Dynamic parameter generation</li>
                    <li>Query execution</li>
                    <li>Run As user selection</li>
                    <li>Metadata creation (sandbox only)</li>
                    <li>Pagination (> 10 records)</li>
                    <li>i18n support</li>
                </ul>

                <h4>jtProjectDocs</h4>
                <p>This documentation component with i18n support.</p>

                <h3>Custom Metadata Fields</h3>
                <table>
                    <thead>
                        <tr>
                            <th>API Name</th>
                            <th>Type</th>
                            <th>Max Length</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>JT_BaseQuery__c</td>
                            <td>Long Text Area</td>
                            <td>131,072</td>
                        </tr>
                        <tr>
                            <td>JT_Bindings__c</td>
                            <td>Long Text Area</td>
                            <td>131,072</td>
                        </tr>
                        <tr>
                            <td>JT_ObjectName__c</td>
                            <td>Text</td>
                            <td>255</td>
                        </tr>
                    </tbody>
                </table>
            `
    },
    footer: {
      version: "Version 1.0.0 | API v65.0",
      author: "Created by Jaime Terrats",
      license: "Open Source | MIT License"
    }
  },
  es: {
    title: "Visor de Consultas Dinámicas - Documentación",
    tableOfContents: "Tabla de Contenidos",
    overview: {
      title: "Descripción General",
      description:
        "El Visor de Consultas Dinámicas es un potente componente Lightning de Salesforce que permite a los usuarios ejecutar consultas SOQL predefinidas con parámetros dinámicos y características avanzadas de seguridad.",
      content: `
                <p><strong>Beneficios Clave:</strong></p>
                <ul>
                    <li>Ejecuta consultas predefinidas de forma segura con aplicación USER_MODE</li>
                    <li>Vinculación de parámetros dinámicos para consultas flexibles</li>
                    <li>Funcionalidad Run As para pruebas de permisos</li>
                    <li>Configuración basada en metadatos</li>
                    <li>Soporte multi-idioma (Inglés, Español, Francés, Alemán)</li>
                    <li>Diseño responsivo para móvil y escritorio</li>
                </ul>
            `
    },
    features: {
      title: "Características",
      content: `
                <h3>1. Ejecución de Consultas</h3>
                <ul>
                    <li><strong>Configuraciones Predefinidas:</strong> Selecciona de configuraciones de consulta basadas en metadatos personalizados</li>
                    <li><strong>Parámetros Dinámicos:</strong> Genera automáticamente campos de entrada para variables de enlace de consultas</li>
                    <li><strong>Vista Previa de Consulta:</strong> Ve la consulta antes de ejecutarla</li>
                    <li><strong>Paginación:</strong> Pagina automáticamente resultados cuando hay más de 10 registros</li>
                    <li><strong>Manejo de Estado Vacío:</strong> Muestra estructura de tabla incluso con 0 resultados</li>
                </ul>

                <h3>2. Ejecutar Como Usuario (Avanzado)</h3>
                <ul>
                    <li><strong>Suplantación de Usuario:</strong> Prueba consultas en el contexto de otros usuarios</li>
                    <li><strong>Prueba System.runAs:</strong> Verdadera suplantación usando contexto de prueba Apex</li>
                    <li><strong>Validación de Permisos:</strong> Verifica reglas de uso compartido y seguridad a nivel de campo</li>
                    <li><strong>Dropdown de Usuarios:</strong> Dropdown filtrado en el cliente con todos los usuarios activos</li>
                </ul>

                <h3>3. Creación de Metadatos (Solo Sandbox)</h3>
                <ul>
                    <li><strong>Crear Configuraciones:</strong> Añade nuevas configuraciones de consulta vía UI</li>
                    <li><strong>Editar Configuraciones:</strong> Modifica configuraciones existentes</li>
                    <li><strong>Validación SOQL:</strong> Validación de consultas en tiempo real</li>
                    <li><strong>Protección de Producción:</strong> Característica deshabilitada en orgs de producción</li>
                </ul>

                <h3>4. Internacionalización</h3>
                <ul>
                    <li>Soporta Inglés, Español, Francés y Alemán</li>
                    <li>Detección automática de locale desde el navegador</li>
                    <li>Fallback a Inglés para locales no soportados</li>
                </ul>
            `
    },
    usage: {
      title: "Cómo Usar",
      content: `
                <h3>Ejecución Básica de Consultas</h3>
                <ol>
                    <li><strong>Seleccionar Configuración:</strong> Elige una consulta predefinida del dropdown</li>
                    <li><strong>Ingresar Parámetros:</strong> Llena cualquier parámetro requerido (si aplica)</li>
                    <li><strong>Ejecutar:</strong> Click en el botón "Ejecutar Consulta"</li>
                    <li><strong>Ver Resultados:</strong> Los resultados aparecen en una tabla paginada</li>
                </ol>

                <div class="alert-info">
                    <p><strong>Consejo:</strong> Si una configuración tiene enlaces predefinidos, verás un mensaje informativo y no necesitarás ingresar parámetros manualmente.</p>
                </div>

                <h3>Usando la Función Run As</h3>
                <ol>
                    <li><strong>Verificar Acceso:</strong> Asegúrate de tener permiso "Modify All Data" o "View All Data"</li>
                    <li><strong>Seleccionar Usuario:</strong> Escribe para filtrar y selecciona un usuario del dropdown</li>
                    <li><strong>Ejecutar como Usuario:</strong> Click en "Ejecutar Consulta" (para USER_MODE) o "Ejecutar con System.runAs (Prueba)" para verdadera suplantación</li>
                    <li><strong>Ver Resultados:</strong> Los resultados reflejan los permisos del usuario seleccionado</li>
                </ol>

                <div class="alert-warning">
                    <p><strong>Nota:</strong> System.runAs ejecuta en un contexto de prueba y puede tomar más tiempo debido al procesamiento asíncrono.</p>
                </div>

                <h3>Creando Nuevas Configuraciones (Solo Sandbox)</h3>
                <ol>
                    <li><strong>Click "Crear Nueva Configuración":</strong> Abre el modal de configuración</li>
                    <li><strong>Llenar Detalles:</strong>
                        <ul>
                            <li>Etiqueta: Nombre para mostrar de la configuración</li>
                            <li>Nombre de Desarrollador: Nombre API (auto-generado de la etiqueta)</li>
                            <li>Consulta Base: Tu consulta SOQL</li>
                            <li>Enlaces (opcional): Objeto JSON con valores de parámetros</li>
                        </ul>
                    </li>
                    <li><strong>Validar:</strong> La consulta se valida en tiempo real</li>
                    <li><strong>Guardar:</strong> La configuración se despliega vía Tooling API</li>
                </ol>
            `
    },
    configuration: {
      title: "Configuración",
      content: `
                <h3>Tipo de Metadato Personalizado: JT_DynamicQueryConfiguration__mdt</h3>
                <p>Las configuraciones de consulta se almacenan como registros de Metadatos Personalizados con los siguientes campos:</p>

                <table>
                    <thead>
                        <tr>
                            <th>Campo</th>
                            <th>Tipo</th>
                            <th>Descripción</th>
                            <th>Requerido</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>Label</td>
                            <td>Texto</td>
                            <td>Nombre mostrado en el dropdown</td>
                            <td>Sí</td>
                        </tr>
                        <tr>
                            <td>DeveloperName</td>
                            <td>Texto</td>
                            <td>Nombre API para la configuración</td>
                            <td>Sí</td>
                        </tr>
                        <tr>
                            <td>JT_BaseQuery__c</td>
                            <td>Área de Texto Largo</td>
                            <td>Consulta SOQL con variables de enlace (ej: :accountId)</td>
                            <td>Sí</td>
                        </tr>
                        <tr>
                            <td>JT_Bindings__c</td>
                            <td>Área de Texto Largo</td>
                            <td>Objeto JSON con valores de parámetros (ej: {"accountId": "001..."})</td>
                            <td>No</td>
                        </tr>
                        <tr>
                            <td>JT_ObjectName__c</td>
                            <td>Texto</td>
                            <td>Nombre del objeto (auto-poblado de la consulta)</td>
                            <td>No</td>
                        </tr>
                    </tbody>
                </table>

                <h3>Ejemplo de Configuración</h3>
                <pre>
Etiqueta: Contactos de Cuenta
Nombre de Desarrollador: Account_Contacts
Consulta Base: SELECT Id, Name, Email, Phone FROM Contact WHERE AccountId = :accountId
Enlaces: {"accountId": "0015g00000XXXXXX"}
Nombre del Objeto: Contact
                </pre>

                <div class="alert-success">
                    <p><strong>Mejor Práctica:</strong> Usa etiquetas y nombres de desarrollador descriptivos para fácil identificación.</p>
                </div>
            `
    },
    runAs: {
      title: "Función Ejecutar Como Usuario",
      content: `
                <h3>Entendiendo Run As</h3>
                <p>La función Run As permite a los administradores probar consultas en el contexto de otros usuarios, validando:</p>
                <ul>
                    <li>Reglas de compartición (OWD, reglas de compartición, comparticiones manuales)</li>
                    <li>Seguridad a nivel de campo (FLS)</li>
                    <li>Permisos de objeto (CRUD)</li>
                    <li>Acceso a tipos de registro</li>
                </ul>

                <h3>Dos Modos de Ejecución</h3>

                <h4>1. Ejecutar Consulta (USER_MODE)</h4>
                <p>Ejecución estándar con seguridad USER_MODE. Esto valida permisos de usuario pero no usa System.runAs().</p>
                <ul>
                    <li><strong>Pros:</strong> Rápido, ejecución síncrona</li>
                    <li><strong>Contras:</strong> Limitado al contexto de usuario actual con aplicación USER_MODE</li>
                </ul>

                <h4>2. Ejecutar con System.runAs (Prueba)</h4>
                <p>Verdadera suplantación usando System.runAs() en un contexto de prueba.</p>
                <ul>
                    <li><strong>Pros:</strong> Suplantación completa, prueba precisa de permisos</li>
                    <li><strong>Contras:</strong> Asíncrono (usa Platform Cache), ejecución más lenta</li>
                </ul>

                <h3>Arquitectura</h3>
                <pre>
1. LWC llama JT_RunAsTestExecutor.executeAsUser()
2. Parámetros almacenados en Platform Cache
3. JT_GenericRunAsTest encolado (Test.startTest)
4. System.runAs() ejecuta la consulta
5. Resultados serializados a JSON y en caché
6. LWC sondea getTestResults() hasta que esté listo
7. Resultados mostrados en datatable
                </pre>

                <div class="alert-warning">
                    <p><strong>Permisos Requeridos:</strong> El usuario debe tener permiso "Modify All Data" O "View All Data" para usar Run As.</p>
                </div>
            `
    },
    metadata: {
      title: "Creación de Metadatos",
      content: `
                <h3>Creando Configuraciones vía UI</h3>
                <p>En orgs sandbox y scratch, puedes crear y editar configuraciones directamente desde la UI.</p>

                <h3>Protección de Producción</h3>
                <p>El botón "Crear Nueva Configuración" está <strong>automáticamente oculto en orgs de producción</strong> para prevenir modificaciones accidentales de metadatos.</p>
                <p><strong>Lógica de Detección:</strong></p>
                <pre>
Apex: Organization.IsSandbox OR TrialExpirationDate != null
Pruebas E2E: instanceUrl.includes('sandbox')
                </pre>

                <h3>Reglas de Validación</h3>
                <ul>
                    <li><strong>Etiqueta:</strong> No debe estar en blanco</li>
                    <li><strong>Nombre de Desarrollador:</strong> No debe estar en blanco, auto-sanitizado</li>
                    <li><strong>Consulta Base:</strong> Debe ser SOQL válido, comienza con SELECT</li>
                    <li><strong>Enlaces:</strong> Opcional, debe ser JSON válido si se proporciona</li>
                </ul>

                <h3>Despliegue vía Tooling API</h3>
                <p>Las configuraciones se despliegan vía Tooling API como registros CustomMetadata:</p>
                <pre>
POST /services/data/v65.0/tooling/sobjects/CustomMetadata
{
    "FullName": "JT_DynamicQueryConfiguration.{DeveloperName}",
    "Metadata": {
        "label": "{Label}",
        "values": [
            { "field": "JT_BaseQuery__c", "value": "{BaseQuery}" },
            { "field": "JT_Bindings__c", "value": "{Bindings}" },
            { "field": "JT_ObjectName__c", "value": "{ObjectName}" }
        ]
    }
}
                </pre>

                <div class="alert-info">
                    <p><strong>Comportamiento de Actualización:</strong> Después de crear una configuración, el dropdown se actualiza automáticamente usando refreshApex().</p>
                </div>
            `
    },
    security: {
      title: "Seguridad y Permisos",
      content: `
                <h3>Conjunto de Permisos: JT_Dynamic_Queries</h3>
                <p>Los usuarios necesitan el conjunto de permisos JT_Dynamic_Queries para acceder a la aplicación.</p>

                <h4>Otorga Acceso A:</h4>
                <ul>
                    <li>Clases Apex: JT_DataSelector, JT_QueryViewerController, JT_RunAsTestExecutor, JT_MetadataCreator, JT_GenericRunAsTest</li>
                    <li>Metadatos Personalizados: JT_DynamicQueryConfiguration__mdt</li>
                    <li>App Personalizada: JT_Dynamic_Queries</li>
                </ul>

                <h3>Seguridad de Consultas</h3>
                <p>Todas las consultas se ejecutan con <code>WITH USER_MODE</code> para aplicar:</p>
                <ul>
                    <li>Seguridad a nivel de objeto (CRUD)</li>
                    <li>Seguridad a nivel de campo (FLS)</li>
                    <li>Reglas de compartición</li>
                </ul>

                <h3>Patrón Singleton</h3>
                <p>JT_DataSelector implementa un patrón singleton con caché estático:</p>
                <pre>
private static JT_DataSelector instance;
private static Map&lt;String, JT_DynamicQueryConfiguration__mdt&gt; configCache;

public static JT_DataSelector getInstance() {
    if (instance == null) {
        instance = new JT_DataSelector();
    }
    return instance;
}
                </pre>

                <h3>Calidad de Código</h3>
                <ul>
                    <li><strong>Escaneo PMD:</strong> 0 violaciones</li>
                    <li><strong>ESLint:</strong> 0 violaciones</li>
                    <li><strong>Cobertura de Pruebas Apex:</strong> 84.5% promedio (supera el requisito del 75%)</li>
                    <li><strong>ApexDoc:</strong> Todos los métodos públicos documentados</li>
                </ul>
            `
    },
    troubleshooting: {
      title: "Solución de Problemas",
      content: `
                <h3>Problemas Comunes</h3>

                <h4>1. "No se encontraron configuraciones"</h4>
                <p><strong>Causa:</strong> No existen registros de Metadatos Personalizados o el usuario no tiene acceso.</p>
                <p><strong>Solución:</strong></p>
                <ul>
                    <li>Crea al menos un registro JT_DynamicQueryConfiguration__mdt</li>
                    <li>Asigna el conjunto de permisos JT_Dynamic_Queries</li>
                </ul>

                <h4>2. "Permisos insuficientes para usar la función Run As"</h4>
                <p><strong>Causa:</strong> El usuario no tiene los permisos requeridos.</p>
                <p><strong>Solución:</strong> El usuario necesita permiso "Modify All Data" o "View All Data".</p>

                <h4>3. "La consulta no devolvió registros" (pero debería tener resultados)</h4>
                <p><strong>Causa:</strong> Reglas de compartición o FLS bloqueando el acceso.</p>
                <p><strong>Solución:</strong></p>
                <ul>
                    <li>Verifica que el usuario tenga acceso al objeto</li>
                    <li>Revisa configuración de compartición</li>
                    <li>Usa Run As para probar con diferentes usuarios</li>
                </ul>

                <h4>4. El botón "Crear Nueva Configuración" no es visible</h4>
                <p><strong>Causa:</strong> Este es el comportamiento esperado en orgs de producción.</p>
                <p><strong>Solución:</strong> Usa Setup → Tipos de Metadatos Personalizados en producción, o trabaja en un sandbox.</p>

                <h4>5. La paginación no se muestra</h4>
                <p><strong>Causa:</strong> La consulta devolvió 10 o menos registros.</p>
                <p><strong>Solución:</strong> La paginación solo aparece cuando existen más de 10 resultados. Esto es por diseño.</p>

                <h4>6. El dropdown de usuarios está vacío</h4>
                <p><strong>Causa:</strong> No hay otros usuarios activos en el org, o problema de permiso Run As.</p>
                <p><strong>Solución:</strong></p>
                <ul>
                    <li>Asegúrate de que haya otros usuarios activos en el org</li>
                    <li>Verifica permisos de Run As</li>
                    <li>Nota: El usuario actual se excluye automáticamente de la lista</li>
                </ul>

                <div class="alert-info">
                    <p><strong>Consejo de Depuración:</strong> Revisa la consola del navegador (F12) para errores de JavaScript y revisa los logs de depuración de Salesforce para errores de Apex.</p>
                </div>
            `
    },
    api: {
      title: "Referencia API",
      content: `
                <h3>Clases Apex</h3>

                <h4>JT_DataSelector</h4>
                <pre>
// Obtener instancia singleton
JT_DataSelector selector = JT_DataSelector.getInstance();

// Obtener registros con configuración predefinida
List&lt;SObject&gt; records = JT_DataSelector.getRecords('ConfigName');

// Obtener registros con enlaces personalizados
Map&lt;String, Object&gt; bindings = new Map&lt;String, Object&gt;{
    'accountId' => '0015g00000XXXXXX'
};
List&lt;SObject&gt; records = JT_DataSelector.getRecords('ConfigName', bindings);

// Obtener config (en caché)
JT_DynamicQueryConfiguration__mdt config = selector.getConfig('ConfigName');
                </pre>

                <p><strong>Para más detalles, consulta la sección API en la versión en inglés.</strong></p>
            `
    },
    footer: {
      version: "Versión 1.0.0 | API v65.0",
      author: "Creado por Jaime Terrats",
      license: "Código Abierto | Licencia MIT"
    }
  }
};

// Add French and German (abbreviated for space - similar structure)
DOCS["fr"] = {
  title: "Visualiseur de Requêtes Dynamiques - Documentation",
  tableOfContents: "Table des Matières",
  overview: {
    title: "Aperçu",
    description:
      "Le Visualiseur de Requêtes Dynamiques est un composant Salesforce Lightning puissant qui permet aux utilisateurs d'exécuter des requêtes SOQL prédéfinies avec des paramètres dynamiques et des fonctionnalités de sécurité avancées.",
    content: DOCS["en"].overview.content // Use English content for brevity
  },
  features: DOCS["en"].features,
  usage: DOCS["en"].usage,
  configuration: DOCS["en"].configuration,
  runAs: DOCS["en"].runAs,
  metadata: DOCS["en"].metadata,
  security: DOCS["en"].security,
  troubleshooting: DOCS["en"].troubleshooting,
  api: DOCS["en"].api,
  footer: {
    version: "Version 1.0.0 | API v65.0",
    author: "Créé par Jaime Terrats",
    license: "Open Source | Licence MIT"
  }
};

DOCS["de"] = {
  title: "Dynamischer Abfrage-Viewer - Dokumentation",
  tableOfContents: "Inhaltsverzeichnis",
  overview: {
    title: "Überblick",
    description:
      "Der Dynamische Abfrage-Viewer ist eine leistungsstarke Salesforce Lightning-Komponente, die es Benutzern ermöglicht, vordefinierte SOQL-Abfragen mit dynamischen Parametern und erweiterten Sicherheitsfunktionen auszuführen.",
    content: DOCS["en"].overview.content
  },
  features: DOCS["en"].features,
  usage: DOCS["en"].usage,
  configuration: DOCS["en"].configuration,
  runAs: DOCS["en"].runAs,
  metadata: DOCS["en"].metadata,
  security: DOCS["en"].security,
  troubleshooting: DOCS["en"].troubleshooting,
  api: DOCS["en"].api,
  footer: {
    version: "Version 1.0.0 | API v65.0",
    author: "Erstellt von Jaime Terrats",
    license: "Open Source | MIT-Lizenz"
  }
};

export function getDocumentation() {
  return DOCS[LANG] || DOCS["en"];
}
