/**
 * @description Custom labels for i18n support
 * @author Jaime Terrats
 * @date 2025-11-29
 */

const LOCALE = Intl.DateTimeFormat().resolvedOptions().locale || "en-US";
const LANG = LOCALE.split("-")[0];

const LABELS = {
  en: {
    selectConfiguration: "Select Query Configuration",
    chooseConfiguration: "Choose a configuration...",
    runAsUser: "Run As User (Advanced)",
    runAsNote:
      "Note: This validates user permissions but executes with USER_MODE security. Results reflect sharing rules and field-level security.",
    selectUser: "Select User to Impersonate",
    typeToFilter: "Type to filter users...",
    loadingUsers: "Loading users...",
    clear: "Clear",
    executeQuery: "Execute Query",
    executeSystemRunAs: "Execute with System.runAs (Test)",
    executingTest: "Executing test with System.runAs()...",
    queryPreview: "Query Preview:",
    queryParameters: "Query Parameters:",
    predefinedBindings: "Predefined Bindings:",
    predefinedBindingsDesc:
      "This configuration has predefined bindings that will be used automatically.",
    results: "Results",
    records: "records",
    record: "record",
    showing: "Showing",
    of: "of",
    previous: "Previous",
    next: "Next",
    page: "Page",
    createNewConfiguration: "Create New Configuration",
    editConfiguration: "Edit Configuration",
    cancel: "Cancel",
    save: "Save",
    label: "Label",
    // Cache Management
    clearCache: "Clear Cache",
    clearCacheTitle: "Clear Cache & Refresh Data",
    clearCacheDescription:
      "Select which cached data you want to clear. This will force a refresh from the server.",
    clearCacheButton: "Clear Selected",
    clearCacheWarning:
      "Selected data will be cleared and refreshed from the server.",
    clearConfigurationsLabel: "Query Configurations",
    clearConfigurationsHelp:
      "Refresh the list of available query configurations from metadata",
    clearResultsLabel: "Query Results",
    clearResultsHelp: "Clear current query results and reset the view",
    clearUsersLabel: "User List",
    clearUsersHelp: "Refresh the list of active users for Run As functionality",
    clearRecentLabel: "Recent Selections",
    clearRecentHelp:
      "Clear recently selected configurations and user preferences",
    selectAll: "Select All",
    cacheCleared: "Cache cleared successfully",
    cacheClearedDetail: "Cleared: {0}",
    developerName: "Developer Name",
    baseQuery: "Base Query (SOQL)",
    objectName: "Object Name",
    bindings: "Bindings (JSON)",
    validQuery: "Valid Query",
    invalidQuery: "Invalid Query",
    createConfigTooltip:
      "Create a new query configuration with a SOQL query (SELECT fields FROM object WHERE condition), optional bind variables in JSON format, and field mappings.",
    sandboxOnlyWarning:
      "Only available in Sandbox/Scratch/Developer Orgs. Use Setup UI in Production.",
    whereIsThisUsed: "Where is this used?",
    whereIsThisUsedTooltip:
      "Find where this configuration is used in Apex classes and Flows",
    findingUsage: "Searching Apex classes and Flows...",
    usageModalTitle: 'Where is "{0}" used?',
    usageModalSubtitle:
      "Searching Apex classes and Flows for references to this configuration",
    foundReferences: "Found {0} reference(s) in Apex/Flows",
    noUsageFound: "No usage found",
    noUsageMessage:
      "This configuration is not currently referenced in any Apex class or Flow",
    apexClass: "Apex Class",
    lineNumber: "Line #",
    code: "Code",
    objectNameReadOnly: "Automatically extracted from the SOQL query",
    // New component labels (Phase 1-4)
    noResults: "No results found",
    selectOption: "Please select an option",
    noParametersRequired: "No parameters required for this query",
    updateConfiguration: "Update Configuration",
    queryPreviewTitle: "Query Preview",
    autoDetectedFromQuery: "Auto-detected from query",
    toolingAPINote:
      "This creates a Custom Metadata record via Tooling API. The configuration will be immediately available for use.",
    validSOQLSyntax: "Valid SOQL syntax",
    object: "Object",
    searchConfigsPlaceholder: "Type to search configurations...",
    searchUsersPlaceholder:
      "Type to search users... (leave blank to run as current user)",
    clearSelection: "Clear Selection",
    searchingFlows: "Searching Apex classes and Flows...",
    noReferencesFound:
      "This configuration is not currently referenced in any Apex classes or Flows.",
    type: "Type",
    name: "Name",
    line: "Line"
  },
  es: {
    selectConfiguration: "Seleccionar Configuración de Consulta",
    chooseConfiguration: "Elige una configuración...",
    // Cache Management
    clearCache: "Limpiar Caché",
    clearCacheTitle: "Limpiar Caché y Refrescar Datos",
    clearCacheDescription:
      "Selecciona qué datos en caché deseas limpiar. Esto forzará una actualización desde el servidor.",
    clearCacheButton: "Limpiar Seleccionados",
    clearCacheWarning:
      "Los datos seleccionados se limpiarán y actualizarán desde el servidor.",
    clearConfigurationsLabel: "Configuraciones de Consulta",
    clearConfigurationsHelp:
      "Actualizar la lista de configuraciones disponibles desde metadatos",
    clearResultsLabel: "Resultados de Consulta",
    clearResultsHelp: "Limpiar resultados actuales y reiniciar la vista",
    clearUsersLabel: "Lista de Usuarios",
    clearUsersHelp:
      "Actualizar la lista de usuarios activos para funcionalidad Run As",
    clearRecentLabel: "Selecciones Recientes",
    clearRecentHelp:
      "Limpiar configuraciones seleccionadas recientemente y preferencias",
    selectAll: "Seleccionar Todos",
    cacheCleared: "Caché limpiado exitosamente",
    cacheClearedDetail: "Limpiado: {0}",
    runAsUser: "Ejecutar Como Usuario (Avanzado)",
    runAsNote:
      "Nota: Esto valida permisos de usuario pero ejecuta con seguridad USER_MODE. Los resultados reflejan reglas de uso compartido y seguridad a nivel de campo.",
    selectUser: "Seleccionar Usuario a Suplantar",
    typeToFilter: "Escribe para filtrar usuarios...",
    loadingUsers: "Cargando usuarios...",
    clear: "Limpiar",
    executeQuery: "Ejecutar Consulta",
    executeSystemRunAs: "Ejecutar con System.runAs (Prueba)",
    executingTest: "Ejecutando prueba con System.runAs()...",
    queryPreview: "Vista Previa de Consulta:",
    queryParameters: "Parámetros de Consulta:",
    predefinedBindings: "Enlaces Predefinidos:",
    predefinedBindingsDesc:
      "Esta configuración tiene enlaces predefinidos que se usarán automáticamente.",
    results: "Resultados",
    records: "registros",
    record: "registro",
    showing: "Mostrando",
    of: "de",
    previous: "Anterior",
    next: "Siguiente",
    page: "Página",
    createNewConfiguration: "Crear Nueva Configuración",
    editConfiguration: "Editar Configuración",
    cancel: "Cancelar",
    save: "Guardar",
    label: "Etiqueta",
    developerName: "Nombre de Desarrollador",
    baseQuery: "Consulta Base (SOQL)",
    objectName: "Nombre del Objeto",
    bindings: "Enlaces (JSON)",
    validQuery: "Consulta Válida",
    invalidQuery: "Consulta Inválida",
    createConfigTooltip:
      "Crea una nueva configuración de consulta con una consulta SOQL (SELECT campos FROM objeto WHERE condición), variables de enlace opcionales en formato JSON y mapeos de campos.",
    sandboxOnlyWarning:
      "Solo disponible en Sandbox/Scratch/Developer Orgs. Use la UI de Configuración en Producción.",
    whereIsThisUsed: "¿Dónde se usa esto?",
    whereIsThisUsedTooltip:
      "Encuentra dónde se usa esta configuración en código Apex",
    findingUsage: "Buscando en clases Apex...",
    usageModalTitle: '¿Dónde se usa "{0}"?',
    usageModalSubtitle:
      "Buscando referencias a esta configuración en clases Apex",
    foundReferences: "Se encontraron {0} referencia(s) en código Apex",
    noUsageFound: "No se encontró uso",
    noUsageMessage:
      "Esta configuración no está referenciada en ninguna clase Apex actualmente",
    apexClass: "Clase Apex",
    lineNumber: "Línea #",
    code: "Código",
    objectNameReadOnly: "Extraído automáticamente de la consulta SOQL",
    // New component labels (Phase 1-4)
    noResults: "No se encontraron resultados",
    selectOption: "Por favor selecciona una opción",
    noParametersRequired: "No se requieren parámetros para esta consulta",
    updateConfiguration: "Actualizar Configuración",
    queryPreviewTitle: "Vista Previa de Consulta",
    autoDetectedFromQuery: "Auto-detectado de la consulta",
    toolingAPINote:
      "Esto crea un registro de Custom Metadata vía Tooling API. La configuración estará disponible de inmediato.",
    validSOQLSyntax: "Sintaxis SOQL válida",
    object: "Objeto",
    searchConfigsPlaceholder: "Escribe para buscar configuraciones...",
    searchUsersPlaceholder:
      "Escribe para buscar usuarios... (deja en blanco para ejecutar como usuario actual)",
    clearSelection: "Limpiar Selección",
    searchingFlows: "Buscando en clases Apex y Flows...",
    noReferencesFound:
      "Esta configuración no está referenciada en ninguna clase Apex o Flow actualmente.",
    type: "Tipo",
    name: "Nombre",
    line: "Línea"
  },
  fr: {
    selectConfiguration: "Sélectionner la Configuration de Requête",
    chooseConfiguration: "Choisissez une configuration...",
    runAsUser: "Exécuter en tant qu'utilisateur (Avancé)",
    runAsNote:
      "Note: Ceci valide les autorisations utilisateur mais s'exécute avec la sécurité USER_MODE. Les résultats reflètent les règles de partage et la sécurité au niveau du champ.",
    selectUser: "Sélectionner l'utilisateur à imiter",
    typeToFilter: "Tapez pour filtrer les utilisateurs...",
    loadingUsers: "Chargement des utilisateurs...",
    clear: "Effacer",
    executeQuery: "Exécuter la Requête",
    executeSystemRunAs: "Exécuter avec System.runAs (Test)",
    executingTest: "Exécution du test avec System.runAs()...",
    queryPreview: "Aperçu de la Requête:",
    queryParameters: "Paramètres de Requête:",
    predefinedBindings: "Liaisons Prédéfinies:",
    predefinedBindingsDesc:
      "Cette configuration a des liaisons prédéfinies qui seront utilisées automatiquement.",
    results: "Résultats",
    records: "enregistrements",
    record: "enregistrement",
    showing: "Affichage",
    of: "de",
    previous: "Précédent",
    next: "Suivant",
    page: "Page",
    createNewConfiguration: "Créer une Nouvelle Configuration",
    editConfiguration: "Modifier la Configuration",
    cancel: "Annuler",
    save: "Enregistrer",
    label: "Étiquette",
    developerName: "Nom du Développeur",
    baseQuery: "Requête de Base (SOQL)",
    objectName: "Nom de l'Objet",
    bindings: "Liaisons (JSON)",
    validQuery: "Requête Valide",
    invalidQuery: "Requête Invalide",
    createConfigTooltip:
      "Créer une nouvelle configuration de requête avec une requête SOQL (SELECT champs FROM objet WHERE condition), des variables de liaison optionnelles au format JSON et des mappages de champs.",
    sandboxOnlyWarning:
      "Disponible uniquement dans Sandbox/Scratch/Developer Orgs. Utilisez l'interface de configuration en production.",
    whereIsThisUsed: "Où est-ce utilisé?",
    whereIsThisUsedTooltip:
      "Trouver où cette configuration est utilisée dans le code Apex",
    findingUsage: "Recherche dans les classes Apex...",
    usageModalTitle: 'Où "{0}" est-il utilisé?',
    usageModalSubtitle:
      "Recherche de références à cette configuration dans les classes Apex",
    foundReferences: "{0} référence(s) trouvée(s) dans le code Apex",
    noUsageFound: "Aucune utilisation trouvée",
    noUsageMessage:
      "Cette configuration n'est actuellement référencée dans aucune classe Apex",
    apexClass: "Classe Apex",
    lineNumber: "Ligne #",
    code: "Code",
    objectNameReadOnly: "Extrait automatiquement de la requête SOQL",
    // New component labels (Phase 1-4)
    noResults: "Aucun résultat trouvé",
    selectOption: "Veuillez sélectionner une option",
    noParametersRequired: "Aucun paramètre requis pour cette requête",
    updateConfiguration: "Mettre à jour la Configuration",
    queryPreviewTitle: "Aperçu de la Requête",
    autoDetectedFromQuery: "Détecté automatiquement de la requête",
    toolingAPINote:
      "Ceci crée un enregistrement de métadonnées personnalisées via Tooling API. La configuration sera immédiatement disponible.",
    validSOQLSyntax: "Syntaxe SOQL valide",
    object: "Objet",
    searchConfigsPlaceholder: "Tapez pour rechercher des configurations...",
    searchUsersPlaceholder:
      "Tapez pour rechercher des utilisateurs... (laissez vide pour exécuter en tant qu'utilisateur actuel)",
    clearSelection: "Effacer la Sélection",
    searchingFlows: "Recherche dans les classes Apex et Flows...",
    noReferencesFound:
      "Cette configuration n'est actuellement référencée dans aucune classe Apex ou Flow.",
    type: "Type",
    name: "Nom",
    line: "Ligne"
  },
  de: {
    selectConfiguration: "Abfragekonfiguration Auswählen",
    chooseConfiguration: "Wählen Sie eine Konfiguration...",
    runAsUser: "Als Benutzer Ausführen (Erweitert)",
    runAsNote:
      "Hinweis: Dies validiert Benutzerberechtigungen, führt jedoch mit USER_MODE-Sicherheit aus. Ergebnisse spiegeln Freigaberegeln und Feldsicherheit wider.",
    selectUser: "Benutzer zum Imitieren Auswählen",
    typeToFilter: "Tippen Sie zum Filtern von Benutzern...",
    loadingUsers: "Benutzer laden...",
    clear: "Löschen",
    executeQuery: "Abfrage Ausführen",
    executeSystemRunAs: "Mit System.runAs Ausführen (Test)",
    executingTest: "Test mit System.runAs() ausführen...",
    queryPreview: "Abfragevorschau:",
    queryParameters: "Abfrageparameter:",
    predefinedBindings: "Vordefinierte Bindungen:",
    predefinedBindingsDesc:
      "Diese Konfiguration hat vordefinierte Bindungen, die automatisch verwendet werden.",
    results: "Ergebnisse",
    records: "Datensätze",
    record: "Datensatz",
    showing: "Anzeige",
    of: "von",
    previous: "Zurück",
    next: "Weiter",
    page: "Seite",
    createNewConfiguration: "Neue Konfiguration Erstellen",
    editConfiguration: "Konfiguration Bearbeiten",
    cancel: "Abbrechen",
    save: "Speichern",
    label: "Bezeichnung",
    developerName: "Entwicklername",
    baseQuery: "Basisabfrage (SOQL)",
    objectName: "Objektname",
    bindings: "Bindungen (JSON)",
    validQuery: "Gültige Abfrage",
    invalidQuery: "Ungültige Abfrage",
    createConfigTooltip:
      "Erstellen Sie eine neue Abfragekonfiguration mit einer SOQL-Abfrage (SELECT Felder FROM Objekt WHERE Bedingung), optionalen Bind-Variablen im JSON-Format und Feldzuordnungen.",
    sandboxOnlyWarning:
      "Nur verfügbar in Sandbox/Scratch/Developer Orgs. Verwenden Sie die Setup-Oberfläche in der Produktion.",
    whereIsThisUsed: "Wo wird dies verwendet?",
    whereIsThisUsedTooltip:
      "Finden Sie heraus, wo diese Konfiguration im Apex-Code verwendet wird",
    findingUsage: "Suche in Apex-Klassen...",
    usageModalTitle: 'Wo wird "{0}" verwendet?',
    usageModalSubtitle:
      "Suche nach Verweisen auf diese Konfiguration in Apex-Klassen",
    foundReferences: "{0} Verweis(e) im Apex-Code gefunden",
    noUsageFound: "Keine Verwendung gefunden",
    noUsageMessage:
      "Diese Konfiguration wird derzeit in keiner Apex-Klasse referenziert",
    apexClass: "Apex-Klasse",
    lineNumber: "Zeile #",
    code: "Code",
    objectNameReadOnly: "Automatisch aus der SOQL-Abfrage extrahiert",
    // New component labels (Phase 1-4)
    noResults: "Keine Ergebnisse gefunden",
    selectOption: "Bitte wählen Sie eine Option",
    noParametersRequired: "Keine Parameter für diese Abfrage erforderlich",
    updateConfiguration: "Konfiguration Aktualisieren",
    queryPreviewTitle: "Abfragevorschau",
    autoDetectedFromQuery: "Automatisch aus der Abfrage erkannt",
    toolingAPINote:
      "Dies erstellt einen Custom Metadata-Datensatz über Tooling API. Die Konfiguration wird sofort verfügbar sein.",
    validSOQLSyntax: "Gültige SOQL-Syntax",
    object: "Objekt",
    searchConfigsPlaceholder: "Tippen Sie, um Konfigurationen zu suchen...",
    searchUsersPlaceholder:
      "Tippen Sie, um Benutzer zu suchen... (leer lassen, um als aktueller Benutzer auszuführen)",
    clearSelection: "Auswahl Löschen",
    searchingFlows: "Suche in Apex-Klassen und Flows...",
    noReferencesFound:
      "Diese Konfiguration wird derzeit in keiner Apex-Klasse oder Flow referenziert.",
    type: "Typ",
    name: "Name",
    line: "Zeile"
  }
};

export function getLabels() {
  return LABELS[LANG] || LABELS["en"];
}

export function getLabel(key) {
  const labels = getLabels();
  return labels[key] || LABELS.en[key] || key;
}
