import { LightningElement, track } from "lwc";

// Import Custom Labels from Salesforce Translation Workbench
import welcomeTitle from "@salesforce/label/c.JT_jtDocumentation_welcomeTitle";
import welcomeSubtitle from "@salesforce/label/c.JT_jtDocumentation_welcomeSubtitle";
import frameworkPhilosophy from "@salesforce/label/c.JT_jtDocumentation_frameworkPhilosophy";
import philosophyText from "@salesforce/label/c.JT_jtDocumentation_philosophyText";
import overviewTab from "@salesforce/label/c.JT_jtDocumentation_overviewTab";
import gettingStartedTab from "@salesforce/label/c.JT_jtDocumentation_gettingStartedTab";
import apiReferenceTab from "@salesforce/label/c.JT_jtDocumentation_apiReferenceTab";
import batchProcessingTab from "@salesforce/label/c.JT_jtDocumentation_batchProcessingTab";
import supportTab from "@salesforce/label/c.JT_jtDocumentation_supportTab";
import overviewTitle from "@salesforce/label/c.JT_jtDocumentation_overviewTitle";
import overviewDescription from "@salesforce/label/c.JT_jtDocumentation_overviewDescription";
import gettingStartedTitle from "@salesforce/label/c.JT_jtDocumentation_gettingStartedTitle";
import installationTitle from "@salesforce/label/c.JT_jtDocumentation_installationTitle";
import quickStartTitle from "@salesforce/label/c.JT_jtDocumentation_quickStartTitle";
import apiReferenceTitle from "@salesforce/label/c.JT_jtDocumentation_apiReferenceTitle";
import publicAPIsTitle from "@salesforce/label/c.JT_jtDocumentation_publicAPIsTitle";
import internalFrameworkTitle from "@salesforce/label/c.JT_jtDocumentation_internalFrameworkTitle";
import publicAPIsDescription from "@salesforce/label/c.JT_jtDocumentation_publicAPIsDescription";
import internalDescription from "@salesforce/label/c.JT_jtDocumentation_internalDescription";
import batchProcessingTitle from "@salesforce/label/c.JT_jtDocumentation_batchProcessingTitle";
import riskLevelsTitle from "@salesforce/label/c.JT_jtDocumentation_riskLevelsTitle";
import riskLevelLow from "@salesforce/label/c.JT_jtDocumentation_riskLevelLow";
import riskLevelMedium from "@salesforce/label/c.JT_jtDocumentation_riskLevelMedium";
import riskLevelHigh from "@salesforce/label/c.JT_jtDocumentation_riskLevelHigh";
import riskLevelCritical from "@salesforce/label/c.JT_jtDocumentation_riskLevelCritical";
import supportTitle from "@salesforce/label/c.JT_jtDocumentation_supportTitle";
import documentationTitle from "@salesforce/label/c.JT_jtDocumentation_documentationTitle";
import issuesTitle from "@salesforce/label/c.JT_jtDocumentation_issuesTitle";
import contributingTitle from "@salesforce/label/c.JT_jtDocumentation_contributingTitle";
import namedCredentialTitle from "@salesforce/label/c.JT_jtDocumentation_namedCredentialTitle";
import namedCredentialIntro from "@salesforce/label/c.JT_jtDocumentation_namedCredentialIntro";
import namedCredentialWhyRequired from "@salesforce/label/c.JT_jtDocumentation_namedCredentialWhyRequired";
import namedCredentialWhyText from "@salesforce/label/c.JT_jtDocumentation_namedCredentialWhyText";
import namedCredentialSetupSteps from "@salesforce/label/c.JT_jtDocumentation_namedCredentialSetupSteps";
import namedCredentialStep1 from "@salesforce/label/c.JT_jtDocumentation_namedCredentialStep1";
import namedCredentialStep2 from "@salesforce/label/c.JT_jtDocumentation_namedCredentialStep2";
import namedCredentialStep3 from "@salesforce/label/c.JT_jtDocumentation_namedCredentialStep3";
import namedCredentialStep4 from "@salesforce/label/c.JT_jtDocumentation_namedCredentialStep4";
import namedCredentialStep5 from "@salesforce/label/c.JT_jtDocumentation_namedCredentialStep5";
import namedCredentialDocsLink from "@salesforce/label/c.JT_jtDocumentation_namedCredentialDocsLink";
import createFirstQueryTitle from "@salesforce/label/c.JT_jtDocumentation_createFirstQueryTitle";

export default class JtDocumentation extends LightningElement {
  @track activeSection = "overview";

  // Custom Labels (imported from Translation Workbench)
  labels = {
    welcomeTitle,
    welcomeSubtitle,
    frameworkPhilosophy,
    philosophyText,
    overviewTab,
    gettingStartedTab,
    apiReferenceTab,
    batchProcessingTab,
    supportTab,
    overviewTitle,
    overviewDescription,
    gettingStartedTitle,
    installationTitle,
    quickStartTitle,
    apiReferenceTitle,
    publicAPIsTitle,
    internalFrameworkTitle,
    publicAPIsDescription,
    internalDescription,
    batchProcessingTitle,
    riskLevelsTitle,
    riskLevelLow,
    riskLevelMedium,
    riskLevelHigh,
    riskLevelCritical,
    supportTitle,
    documentationTitle,
    issuesTitle,
    contributingTitle,
    namedCredentialTitle,
    namedCredentialIntro,
    namedCredentialWhyRequired,
    namedCredentialWhyText,
    namedCredentialSetupSteps,
    namedCredentialStep1,
    namedCredentialStep2,
    namedCredentialStep3,
    namedCredentialStep4,
    namedCredentialStep5,
    namedCredentialDocsLink,
    createFirstQueryTitle
  };

  get sections() {
    return [
      { id: "overview", label: this.labels.overviewTab, icon: "utility:info" },
      {
        id: "getting-started",
        label: this.labels.gettingStartedTab,
        icon: "utility:setup"
      },
      {
        id: "api",
        label: this.labels.apiReferenceTab,
        icon: "utility:apex"
      },
      {
        id: "batch-processing",
        label: this.labels.batchProcessingTab,
        icon: "utility:database"
      },
      {
        id: "support",
        label: this.labels.supportTab,
        icon: "utility:help"
      }
    ];
  }

  get isSectionActive() {
    return (sectionId) => this.activeSection === sectionId;
  }

  get sectionsWithActive() {
    return this.sections.map((section) => ({
      ...section,
      isActive: section.id === this.activeSection,
      className:
        section.id === this.activeSection
          ? "slds-tabs_default__item slds-is-active"
          : "slds-tabs_default__item"
    }));
  }

  handleSectionClick(event) {
    this.activeSection = event.currentTarget.dataset.section;
  }

  // Content getters for each section
  get showOverview() {
    return this.activeSection === "overview";
  }

  get showFeatures() {
    return this.activeSection === "features";
  }

  get showGettingStarted() {
    return this.activeSection === "getting-started";
  }

  get showBatchProcessing() {
    return this.activeSection === "batch-processing";
  }

  get showToolingApi() {
    return this.activeSection === "tooling-api";
  }

  get showAccessibility() {
    return this.activeSection === "accessibility";
  }

  get showArchitecture() {
    return this.activeSection === "architecture";
  }

  get showApi() {
    return this.activeSection === "api";
  }

  get showSupport() {
    return this.activeSection === "support";
  }
}