import { LightningElement, track } from "lwc";
import { getLabels } from "./labels";

export default class JtDocumentation extends LightningElement {
  @track activeSection = "overview";

  get labels() {
    return getLabels();
  }

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
}
