/**
 * @description Persona Manager Modal — create, view, and delete RunAs personas.
 * @author Jaime Terrats
 * @fires personaconfigsaved - When a deployment is enqueued after save
 * @fires close - When the modal is dismissed
 */
import { LightningElement, track } from "lwc";
import getPersonaConfigs from "@salesforce/apex/JT_PersonaConfigController.getPersonaConfigs";
import getProfiles from "@salesforce/apex/JT_PersonaConfigController.getProfiles";
import getPermissionSets from "@salesforce/apex/JT_PersonaConfigController.getPermissionSets";
import savePersonaConfig from "@salesforce/apex/JT_PersonaConfigController.savePersonaConfig";
import deletePersonaConfig from "@salesforce/apex/JT_PersonaConfigController.deletePersonaConfig";

const REFRESH_DELAY_MS = 4000;
const PAGE_SIZE = 5;
const TAB_EXISTING = "existing";
const TAB_CREATE = "create";

export default class JtPersonaManager extends LightningElement {
  labels = {
    title: "Manage Personas",
    close: "Close",
    loading: "Loading...",
    saving: "Saving...",
    save: "Save Persona",
    existingPersonas: "Existing Personas",
    createPersona: "Create New Persona",
    noPersonas: "No personas configured. Create your first persona.",
    colLabel: "Label",
    colProfile: "Profile",
    colPermSets: "Permission Sets",
    colSeeAllData: "See All Data",
    colActions: "Actions",
    deletePersona: "Delete persona",
    labelField: "Label",
    labelPlaceholder: "e.g. Sales Rep",
    developerNameField: "Developer Name",
    developerNamePlaceholder: "e.g. Sales_Rep",
    profileField: "Profile",
    profilePlaceholder: "Select a profile...",
    permissionSetsField: "Permission Sets",
    permSetsAvailable: "Available",
    permSetsSelected: "Selected",
    descriptionField: "Description",
    descriptionPlaceholder: "Optional description for this persona",
    deploymentPending:
      "Deployment enqueued — persona will appear after a few seconds. Refresh to see it.",
    errorLabel: "Error",
    yes: "Yes",
    no: "No",
    prevPage: "Previous page",
    nextPage: "Next page"
  };

  // Private reactive state
  @track _personas = [];
  @track _profiles = [];
  @track _permissionSets = [];
  @track _form = {
    label: "",
    developerName: "",
    profileApiName: "",
    permissionSets: [],
    description: ""
  };
  @track _isLoading = false;
  @track _isSaving = false;
  @track _deploymentPending = false;
  @track _error = null;
  @track _deleteError = null;
  @track _activeTab = TAB_EXISTING;
  @track _currentPage = 1;

  _refreshTimeout = null;

  // ── Lifecycle ──────────────────────────────────────────────────────

  connectedCallback() {
    this._isLoading = true;
    Promise.all([getPersonaConfigs(), getProfiles(), getPermissionSets()])
      .then(([personas, profiles, permSets]) => {
        this._personas = this._normalizePersonas(personas || []);
        this._profiles = profiles || [];
        this._permissionSets = permSets || [];
      })
      .catch((error) => {
        this._error = this._extractMessage(
          error,
          "Failed to load persona data."
        );
      })
      .finally(() => {
        this._isLoading = false;
      });
  }

  disconnectedCallback() {
    if (this._refreshTimeout) {
      clearTimeout(this._refreshTimeout);
      this._refreshTimeout = null;
    }
  }

  // ── Tab computed ───────────────────────────────────────────────────

  get isExistingTabActive() {
    return this._activeTab === TAB_EXISTING;
  }

  get isCreateTabActive() {
    return this._activeTab === TAB_CREATE;
  }

  get tabListClass() {
    return this.isExistingTabActive
      ? "slds-tabs_default__item slds-is-active"
      : "slds-tabs_default__item";
  }

  get tabCreateClass() {
    return this.isCreateTabActive
      ? "slds-tabs_default__item slds-is-active"
      : "slds-tabs_default__item";
  }

  get tabExistingPanelClass() {
    return this.isExistingTabActive
      ? "slds-tabs_default__content slds-show"
      : "slds-tabs_default__content slds-hide";
  }

  get tabCreatePanelClass() {
    return this.isCreateTabActive
      ? "slds-tabs_default__content slds-show"
      : "slds-tabs_default__content slds-hide";
  }

  get existingTabIndex() {
    return this.isExistingTabActive ? "0" : "-1";
  }

  get createTabIndex() {
    return this.isCreateTabActive ? "0" : "-1";
  }

  // ── Pagination computed ────────────────────────────────────────────

  get totalPages() {
    return Math.ceil(this._personas.length / PAGE_SIZE);
  }

  get pagedPersonas() {
    const start = (this._currentPage - 1) * PAGE_SIZE;
    return this._personas.slice(start, start + PAGE_SIZE);
  }

  get showPagination() {
    return this._personas.length > PAGE_SIZE;
  }

  get isPrevDisabled() {
    return this._currentPage <= 1;
  }

  get isNextDisabled() {
    return this._currentPage >= this.totalPages;
  }

  get paginationInfo() {
    const start = (this._currentPage - 1) * PAGE_SIZE + 1;
    const end = Math.min(this._currentPage * PAGE_SIZE, this._personas.length);
    return `${start}–${end} of ${this._personas.length}`;
  }

  // ── Other computed ─────────────────────────────────────────────────

  get hasPersonas() {
    return this._personas && this._personas.length > 0;
  }

  get saveDisabled() {
    return (
      this._isSaving ||
      !this._form.label ||
      !this._form.developerName ||
      !this._form.profileApiName
    );
  }

  // ── Tab Handlers ───────────────────────────────────────────────────

  handleTabExisting() {
    this._activeTab = TAB_EXISTING;
  }

  handleTabCreate() {
    this._activeTab = TAB_CREATE;
  }

  // ── Pagination Handlers ────────────────────────────────────────────

  handlePrevPage() {
    if (this._currentPage > 1) {
      this._currentPage -= 1;
    }
  }

  handleNextPage() {
    if (this._currentPage < this.totalPages) {
      this._currentPage += 1;
    }
  }

  // ── Field Change Handlers ──────────────────────────────────────────

  handleLabelChange(event) {
    const value = event.target.value;
    this._form = {
      ...this._form,
      label: value,
      developerName: this._generateDeveloperName(value)
    };
  }

  handleDeveloperNameChange(event) {
    this._form = { ...this._form, developerName: event.target.value };
  }

  handleProfileChange(event) {
    this._form = { ...this._form, profileApiName: event.detail.value };
  }

  handlePermissionSetsChange(event) {
    this._form = { ...this._form, permissionSets: event.detail.value };
  }

  handleDescriptionChange(event) {
    this._form = { ...this._form, description: event.target.value };
  }

  // ── Save ───────────────────────────────────────────────────────────

  handleSave() {
    if (this.saveDisabled) {
      return;
    }
    this._isSaving = true;
    this._error = null;
    this._deploymentPending = false;

    savePersonaConfig({ configJson: JSON.stringify(this._form) })
      .then((result) => {
        if (result && result.success) {
          this._deploymentPending = true;
          this._resetForm();
          this.dispatchEvent(
            new CustomEvent("personaconfigsaved", {
              detail: { deploymentId: result.deploymentId }
            })
          );
          // eslint-disable-next-line @lwc/lwc/no-async-operation
          this._refreshTimeout = setTimeout(() => {
            this.refreshPersonaList();
            this._refreshTimeout = null;
          }, REFRESH_DELAY_MS);
        } else {
          this._error =
            (result && result.errorMessage) || "Save failed. Please try again.";
        }
      })
      .catch((error) => {
        this._error = this._extractMessage(
          error,
          "An error occurred while saving."
        );
      })
      .finally(() => {
        this._isSaving = false;
      });
  }

  // ── Delete ─────────────────────────────────────────────────────────

  handleDelete(event) {
    const developerName = event.currentTarget.dataset.developerName;
    if (!developerName) {
      return;
    }
    this._deleteError = null;

    deletePersonaConfig({ developerName })
      .then((result) => {
        if (result && result.success) {
          this.refreshPersonaList();
        } else {
          this._deleteError =
            (result && result.errorMessage) ||
            "Delete failed. Please try again.";
        }
      })
      .catch((error) => {
        this._deleteError = this._extractMessage(
          error,
          "An error occurred while deleting."
        );
      });
  }

  // ── Close ──────────────────────────────────────────────────────────

  handleClose() {
    this.dispatchEvent(new CustomEvent("close"));
  }

  // ── Refresh ────────────────────────────────────────────────────────

  refreshPersonaList() {
    getPersonaConfigs()
      .then((personas) => {
        this._personas = this._normalizePersonas(personas || []);
        // Reset to page 1 whenever the list is refreshed
        this._currentPage = 1;
      })
      .catch((error) => {
        this._deleteError = this._extractMessage(
          error,
          "Failed to refresh persona list."
        );
      });
  }

  // ── Private Helpers ────────────────────────────────────────────────

  _generateDeveloperName(label) {
    if (!label) {
      return "";
    }
    return label.replace(/[^a-zA-Z0-9]/g, "_").substring(0, 40);
  }

  _normalizePersonas(personas) {
    return personas.map((p) => ({
      ...p,
      permissionSetsDisplay: Array.isArray(p.permissionSets)
        ? p.permissionSets.join(", ")
        : p.permissionSets || ""
    }));
  }

  _extractMessage(error, fallback) {
    if (!error) {
      return fallback;
    }
    if (error.body && error.body.message) {
      return error.body.message;
    }
    if (error.message) {
      return error.message;
    }
    return fallback;
  }

  _resetForm() {
    this._form = {
      label: "",
      developerName: "",
      profileApiName: "",
      permissionSets: [],
      description: ""
    };
  }
}
