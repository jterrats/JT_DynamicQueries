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
    internalDescription: "Estas clases son solo para uso interno del framework:",

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
  }
};

export function getLabels() {
  return LABELS[LANG] || LABELS.en;
}

