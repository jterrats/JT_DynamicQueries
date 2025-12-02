import { LightningElement, track } from "lwc";

export default class JtDocumentation extends LightningElement {
  @track activeSection = "overview";

  sections = [
    { id: "overview", label: "Overview", icon: "utility:info" },
    { id: "features", label: "Features", icon: "utility:like" },
    { id: "getting-started", label: "Getting Started", icon: "utility:setup" },
    {
      id: "batch-processing",
      label: "Batch Processing",
      icon: "utility:database"
    },
    { id: "tooling-api", label: "Tooling API Setup", icon: "utility:settings" },
    {
      id: "accessibility",
      label: "Accessibility",
      icon: "utility:touch_action"
    },
    { id: "architecture", label: "Architecture", icon: "utility:record" },
    { id: "api", label: "API Reference", icon: "utility:apex" }
  ];

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
