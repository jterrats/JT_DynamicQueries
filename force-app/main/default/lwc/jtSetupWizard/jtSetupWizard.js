import { LightningElement, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import checkCompleteSetup from "@salesforce/apex/JT_SetupWizardController.checkCompleteSetup";
import testToolingAPIConnection from "@salesforce/apex/JT_SetupWizardController.testToolingAPIConnection";
import getOrgUrl from "@salesforce/apex/JT_SetupWizardController.getOrgUrl";

export default class JtSetupWizard extends NavigationMixin(LightningElement) {
  @track setupSteps = [];
  @track allStepsComplete = false;
  @track isLoading = true;
  @track orgUrl = "";

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
