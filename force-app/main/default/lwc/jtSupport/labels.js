/**
 * @description Custom labels for Support component i18n
 * @author Jaime Terrats
 * @date 2025-11-30
 */

const LOCALE = Intl.DateTimeFormat().resolvedOptions().locale || "en-US";
const LANG = LOCALE.split("-")[0];

const LABELS = {
  en: {
    title: "Support & Help",
    welcomeTitle: "Welcome to Support",
    welcomeMessage:
      "Need help or want to report an issue? We're here to assist you. All support requests are managed through our GitHub repository for transparency and community collaboration.",
    githubIntegration: "GitHub Integration",
    githubDescription:
      "This project is open-source and hosted on GitHub. You can view the code, report issues, and contribute to the project.",
    githubRepo: "Repository",
    reportBug: "Report a Bug",
    reportBugDescription: "Found a bug? Let us know so we can fix it.",
    reportBugButton: "Report Bug",
    viewIssues: "View Issues",
    viewIssuesDescription:
      "Browse existing issues and see what's being worked on.",
    viewIssuesButton: "View All Issues",
    featureRequest: "Feature Request",
    featureRequestDescription:
      "Have an idea? Suggest a new feature or improvement.",
    featureRequestButton: "Request Feature",
    additionalResources: "Additional Resources",
    documentation: "Documentation",
    documentationDescription:
      "Check the Documentation tab for complete guides and API reference",
    tutorials: "Video Tutorials",
    tutorialsDescription: "Coming soon - Video guides and walkthroughs",
    community: "Community Forum",
    communityDescription:
      "Join discussions and connect with other users on GitHub Discussions",
    directContact: "Direct Contact",
    contactEmail: "jaime.terrats@gmail.com",
    responseTime: "We typically respond within 24-48 hours"
  },
  es: {
    title: "Soporte y Ayuda",
    welcomeTitle: "Bienvenido a Soporte",
    welcomeMessage:
      "¿Necesitas ayuda o quieres reportar un problema? Estamos aquí para asistirte. Todas las solicitudes de soporte se gestionan a través de nuestro repositorio de GitHub para transparencia y colaboración comunitaria.",
    githubIntegration: "Integración con GitHub",
    githubDescription:
      "Este proyecto es de código abierto y está alojado en GitHub. Puedes ver el código, reportar problemas y contribuir al proyecto.",
    githubRepo: "Repositorio",
    reportBug: "Reportar un Error",
    reportBugDescription:
      "¿Encontraste un error? Háznoslo saber para que podamos solucionarlo.",
    reportBugButton: "Reportar Error",
    viewIssues: "Ver Problemas",
    viewIssuesDescription:
      "Explora problemas existentes y ve en qué estamos trabajando.",
    viewIssuesButton: "Ver Todos los Problemas",
    featureRequest: "Solicitar Función",
    featureRequestDescription:
      "¿Tienes una idea? Sugiere una nueva función o mejora.",
    featureRequestButton: "Solicitar Función",
    additionalResources: "Recursos Adicionales",
    documentation: "Documentación",
    documentationDescription:
      "Consulta la pestaña Documentación para guías completas y referencia API",
    tutorials: "Tutoriales en Video",
    tutorialsDescription: "Próximamente - Guías en video y tutoriales",
    community: "Foro de la Comunidad",
    communityDescription:
      "Únete a discusiones y conéctate con otros usuarios en GitHub Discussions",
    directContact: "Contacto Directo",
    contactEmail: "jaime.terrats@gmail.com",
    responseTime: "Generalmente respondemos en 24-48 horas"
  },
  fr: {
    title: "Support et Aide",
    welcomeTitle: "Bienvenue au Support",
    welcomeMessage:
      "Besoin d'aide ou vous souhaitez signaler un problème ? Nous sommes là pour vous aider. Toutes les demandes de support sont gérées via notre dépôt GitHub pour la transparence et la collaboration communautaire.",
    githubIntegration: "Intégration GitHub",
    githubDescription:
      "Ce projet est open-source et hébergé sur GitHub. Vous pouvez voir le code, signaler des problèmes et contribuer au projet.",
    githubRepo: "Dépôt",
    reportBug: "Signaler un Bug",
    reportBugDescription:
      "Vous avez trouvé un bug ? Faites-le nous savoir pour que nous puissions le corriger.",
    reportBugButton: "Signaler un Bug",
    viewIssues: "Voir les Problèmes",
    viewIssuesDescription:
      "Parcourez les problèmes existants et voyez ce sur quoi nous travaillons.",
    viewIssuesButton: "Voir Tous les Problèmes",
    featureRequest: "Demande de Fonctionnalité",
    featureRequestDescription:
      "Vous avez une idée ? Suggérez une nouvelle fonctionnalité ou amélioration.",
    featureRequestButton: "Demander une Fonctionnalité",
    additionalResources: "Ressources Supplémentaires",
    documentation: "Documentation",
    documentationDescription:
      "Consultez l'onglet Documentation pour des guides complets et une référence API",
    tutorials: "Tutoriels Vidéo",
    tutorialsDescription: "Bientôt disponible - Guides vidéo et tutoriels",
    community: "Forum Communautaire",
    communityDescription:
      "Rejoignez les discussions et connectez-vous avec d'autres utilisateurs sur GitHub Discussions",
    directContact: "Contact Direct",
    contactEmail: "jaime.terrats@gmail.com",
    responseTime: "Nous répondons généralement dans les 24-48 heures"
  },
  de: {
    title: "Support und Hilfe",
    welcomeTitle: "Willkommen beim Support",
    welcomeMessage:
      "Benötigen Sie Hilfe oder möchten Sie ein Problem melden? Wir sind hier, um Ihnen zu helfen. Alle Support-Anfragen werden über unser GitHub-Repository verwaltet, um Transparenz und Community-Zusammenarbeit zu gewährleisten.",
    githubIntegration: "GitHub-Integration",
    githubDescription:
      "Dieses Projekt ist Open-Source und auf GitHub gehostet. Sie können den Code einsehen, Probleme melden und zum Projekt beitragen.",
    githubRepo: "Repository",
    reportBug: "Bug Melden",
    reportBugDescription:
      "Haben Sie einen Bug gefunden? Lassen Sie es uns wissen, damit wir ihn beheben können.",
    reportBugButton: "Bug Melden",
    viewIssues: "Probleme Anzeigen",
    viewIssuesDescription:
      "Durchsuchen Sie vorhandene Probleme und sehen Sie, woran gearbeitet wird.",
    viewIssuesButton: "Alle Probleme Anzeigen",
    featureRequest: "Feature-Anfrage",
    featureRequestDescription:
      "Haben Sie eine Idee? Schlagen Sie eine neue Funktion oder Verbesserung vor.",
    featureRequestButton: "Feature Anfragen",
    additionalResources: "Zusätzliche Ressourcen",
    documentation: "Dokumentation",
    documentationDescription:
      "Siehe Dokumentations-Tab für vollständige Anleitungen und API-Referenz",
    tutorials: "Video-Tutorials",
    tutorialsDescription: "Demnächst - Video-Anleitungen und Tutorials",
    community: "Community-Forum",
    communityDescription:
      "Nehmen Sie an Diskussionen teil und vernetzen Sie sich mit anderen Benutzern auf GitHub Discussions",
    directContact: "Direkter Kontakt",
    contactEmail: "jaime.terrats@gmail.com",
    responseTime: "Wir antworten in der Regel innerhalb von 24-48 Stunden"
  }
};

export function getLabels() {
  return LABELS[LANG] || LABELS["en"];
}

export function getLabel(key) {
  const labels = getLabels();
  return labels[key] || LABELS["en"][key] || key;
}


