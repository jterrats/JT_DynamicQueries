/**
 * @description Custom labels for jtDocumentation i18n support
 * @author Jaime Terrats
 * @date 2025-12-02
 */

const LOCALE = Intl.DateTimeFormat().resolvedOptions().locale || "en-US";
const LANG = LOCALE.split("-")[0];

const LABELS = {
  en: {
    // Header
    welcomeTitle: "Welcome to Dynamic Query Framework",
    welcomeSubtitle:
      "A metadata-driven SOQL execution framework with built-in security, batch processing, and risk assessment.",
    frameworkPhilosophy: "Framework Philosophy:",
    philosophyText:
      "Provide infrastructure and conventions for configurable queries, not just isolated utilities.",

    // Tabs
    overviewTab: "Overview",
    gettingStartedTab: "Getting Started",
    apiReferenceTab: "API Reference",
    batchProcessingTab: "Batch Processing",
    supportTab: "Support",

    // Overview Section
    overviewTitle: "What is Dynamic Query Framework?",
    overviewDescription:
      "A powerful framework for executing dynamic SOQL queries with metadata-driven configurations.",

    // Getting Started Section
    gettingStartedTitle: "Getting Started",
    installationTitle: "Installation",
    quickStartTitle: "Quick Start",

    // API Reference Section
    apiReferenceTitle: "API Reference",
    publicAPIsTitle: "Public APIs",
    internalFrameworkTitle: "Internal Framework Classes",
    publicAPIsDescription: "These classes are part of the public API:",
    internalDescription: "These classes are for internal framework use only:",

    // Batch Processing Section
    batchProcessingTitle: "Query Risk Assessment & Batch Processing",
    riskLevelsTitle: "Risk Levels",
    riskLevelLow: "Low",
    riskLevelMedium: "Medium",
    riskLevelHigh: "High",
    riskLevelCritical: "Critical",

    // Support Section
    supportTitle: "Need Help?",
    documentationTitle: "Documentation",
    issuesTitle: "Report Issues",
    contributingTitle: "Contributing"
  },
  es: {
    // Header
    welcomeTitle: "Bienvenido a Dynamic Query Framework",
    welcomeSubtitle:
      "Un framework de ejecución SOQL basado en metadatos con seguridad integrada, procesamiento por lotes y evaluación de riesgos.",
    frameworkPhilosophy: "Filosofía del Framework:",
    philosophyText:
      "Proporcionar infraestructura y convenciones para consultas configurables, no solo utilidades aisladas.",

    // Tabs
    overviewTab: "Vista General",
    gettingStartedTab: "Comenzar",
    apiReferenceTab: "Referencia API",
    batchProcessingTab: "Procesamiento por Lotes",
    supportTab: "Soporte",

    // Overview Section
    overviewTitle: "¿Qué es Dynamic Query Framework?",
    overviewDescription:
      "Un framework potente para ejecutar consultas SOQL dinámicas con configuraciones basadas en metadatos.",

    // Getting Started Section
    gettingStartedTitle: "Comenzar",
    installationTitle: "Instalación",
    quickStartTitle: "Inicio Rápido",

    // API Reference Section
    apiReferenceTitle: "Referencia API",
    publicAPIsTitle: "APIs Públicas",
    internalFrameworkTitle: "Clases Internas del Framework",
    publicAPIsDescription: "Estas clases son parte de la API pública:",
    internalDescription:
      "Estas clases son solo para uso interno del framework:",

    // Batch Processing Section
    batchProcessingTitle: "Evaluación de Riesgos y Procesamiento por Lotes",
    riskLevelsTitle: "Niveles de Riesgo",
    riskLevelLow: "Bajo",
    riskLevelMedium: "Medio",
    riskLevelHigh: "Alto",
    riskLevelCritical: "Crítico",

    // Support Section
    supportTitle: "¿Necesitas Ayuda?",
    documentationTitle: "Documentación",
    issuesTitle: "Reportar Problemas",
    contributingTitle: "Contribuir"
  },
  fr: {
    // Header
    welcomeTitle: "Bienvenue dans Dynamic Query Framework",
    welcomeSubtitle:
      "Un framework d'exécution SOQL piloté par les métadonnées avec sécurité intégrée, traitement par lots et évaluation des risques.",
    frameworkPhilosophy: "Philosophie du Framework:",
    philosophyText:
      "Fournir une infrastructure et des conventions pour les requêtes configurables, pas seulement des utilitaires isolés.",

    // Tabs
    overviewTab: "Aperçu",
    gettingStartedTab: "Commencer",
    apiReferenceTab: "Référence API",
    batchProcessingTab: "Traitement par Lots",
    supportTab: "Support",

    // Overview Section
    overviewTitle: "Qu'est-ce que Dynamic Query Framework?",
    overviewDescription:
      "Un framework puissant pour exécuter des requêtes SOQL dynamiques avec des configurations pilotées par les métadonnées.",

    // Getting Started Section
    gettingStartedTitle: "Commencer",
    installationTitle: "Installation",
    quickStartTitle: "Démarrage Rapide",

    // API Reference Section
    apiReferenceTitle: "Référence API",
    publicAPIsTitle: "APIs Publiques",
    internalFrameworkTitle: "Classes Internes du Framework",
    publicAPIsDescription: "Ces classes font partie de l'API publique:",
    internalDescription:
      "Ces classes sont uniquement pour un usage interne du framework:",

    // Batch Processing Section
    batchProcessingTitle: "Évaluation des Risques et Traitement par Lots",
    riskLevelsTitle: "Niveaux de Risque",
    riskLevelLow: "Faible",
    riskLevelMedium: "Moyen",
    riskLevelHigh: "Élevé",
    riskLevelCritical: "Critique",

    // Support Section
    supportTitle: "Besoin d'Aide?",
    documentationTitle: "Documentation",
    issuesTitle: "Signaler des Problèmes",
    contributingTitle: "Contribuer"
  },
  de: {
    // Header
    welcomeTitle: "Willkommen bei Dynamic Query Framework",
    welcomeSubtitle:
      "Ein metadatengesteuertes SOQL-Ausführungs-Framework mit integrierter Sicherheit, Batch-Verarbeitung und Risikobewertung.",
    frameworkPhilosophy: "Framework-Philosophie:",
    philosophyText:
      "Infrastruktur und Konventionen für konfigurierbare Abfragen bereitstellen, nicht nur isolierte Dienstprogramme.",

    // Tabs
    overviewTab: "Übersicht",
    gettingStartedTab: "Erste Schritte",
    apiReferenceTab: "API-Referenz",
    batchProcessingTab: "Batch-Verarbeitung",
    supportTab: "Unterstützung",

    // Overview Section
    overviewTitle: "Was ist Dynamic Query Framework?",
    overviewDescription:
      "Ein leistungsstarkes Framework zur Ausführung dynamischer SOQL-Abfragen mit metadatengesteuerten Konfigurationen.",

    // Getting Started Section
    gettingStartedTitle: "Erste Schritte",
    installationTitle: "Installation",
    quickStartTitle: "Schnellstart",

    // API Reference Section
    apiReferenceTitle: "API-Referenz",
    publicAPIsTitle: "Öffentliche APIs",
    internalFrameworkTitle: "Interne Framework-Klassen",
    publicAPIsDescription: "Diese Klassen sind Teil der öffentlichen API:",
    internalDescription:
      "Diese Klassen sind nur für die interne Framework-Verwendung:",

    // Batch Processing Section
    batchProcessingTitle: "Risikobewertung und Batch-Verarbeitung",
    riskLevelsTitle: "Risikoebenen",
    riskLevelLow: "Niedrig",
    riskLevelMedium: "Mittel",
    riskLevelHigh: "Hoch",
    riskLevelCritical: "Kritisch",

    // Support Section
    supportTitle: "Benötigen Sie Hilfe?",
    documentationTitle: "Dokumentation",
    issuesTitle: "Probleme Melden",
    contributingTitle: "Beitragen"
  }
};

export function getLabels() {
  return LABELS[LANG] || LABELS.en;
}
