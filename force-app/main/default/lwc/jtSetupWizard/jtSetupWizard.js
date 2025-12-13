import { LightningElement, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import checkCompleteSetup from "@salesforce/apex/JT_SetupWizardController.checkCompleteSetup";
import testToolingAPIConnection from "@salesforce/apex/JT_SetupWizardController.testToolingAPIConnection";
import getOrgUrl from "@salesforce/apex/JT_SetupWizardController.getOrgUrl";
// Import Custom Labels
import toolingApiSetupWizardLabel from "@salesforce/label/c.JT_jtSetupWizard_toolingApiSetupWizard";
import checkingSetupStatusLabel from "@salesforce/label/c.JT_jtSetupWizard_checkingSetupStatus";
import setupCompleteLabel from "@salesforce/label/c.JT_jtSetupWizard_setupComplete";
import toolingApiAccessibleLabel from "@salesforce/label/c.JT_jtSetupWizard_toolingApiAccessible";
import setupRequiredLabel from "@salesforce/label/c.JT_jtSetupWizard_setupRequired";
import completeStepsBelowLabel from "@salesforce/label/c.JT_jtSetupWizard_completeStepsBelow";
import setupStepsLabel from "@salesforce/label/c.JT_jtSetupWizard_setupSteps";
import configureLabel from "@salesforce/label/c.JT_jtSetupWizard_configure";
import refreshStatusLabel from "@salesforce/label/c.JT_jtSetupWizard_refreshStatus";
import viewDocumentationLabel from "@salesforce/label/c.JT_jtSetupWizard_viewDocumentation";

export default class JtSetupWizard extends NavigationMixin(LightningElement) {
  @track setupSteps = [];
  @track allStepsComplete = false;
  @track isLoading = true;
  @track orgUrl = "";

  // Custom Labels
  labels = {
    toolingApiSetupWizard: toolingApiSetupWizardLabel,
    checkingSetupStatus: checkingSetupStatusLabel,
    setupComplete: setupCompleteLabel,
    toolingApiAccessible: toolingApiAccessibleLabel,
    setupRequired: setupRequiredLabel,
    completeStepsBelow: completeStepsBelowLabel,
    setupSteps: setupStepsLabel,
    configure: configureLabel,
    refreshStatus: refreshStatusLabel,
    viewDocumentation: viewDocumentationLabel
  };

  connectedCallback() {
    this.loadSetupStatus();
    this.loadOrgUrl();
  }

  loadSetupStatus() {
    this.isLoading = true;
    checkCompleteSetup()
      .then((result) => {
        this.setupSteps = result.steps || [];
        this.allStepsComplete = result.allStepsComplete || false;
        this.isLoading = false;
      })
      .catch((error) => {
        console.error("Error loading setup status:", error);
        this.isLoading = false;
        this.showError("Failed to load setup status: " + error.body?.message);
      });
  }

  loadOrgUrl() {
    getOrgUrl()
      .then((url) => {
        this.orgUrl = url;
      })
      .catch((error) => {
        console.error("Error loading org URL:", error);
      });
  }

  handleRefresh() {
    this.loadSetupStatus();
  }

  handleNavigateToSetup(event) {
    const setupUrl = event.currentTarget.dataset.url;
    if (setupUrl) {
      this[NavigationMixin.Navigate]({
        type: "standard__webPage",
        attributes: {
          url: setupUrl
        }
      });
    }
  }

  handleViewDocs() {
    this[NavigationMixin.Navigate]({
      type: "standard__navItemPage",
      attributes: {
        apiName: "JT_Project_Docs"
      }
    });
  }

  showError(message) {
    // You can enhance this with toast notifications
    console.error(message);
  }
}
