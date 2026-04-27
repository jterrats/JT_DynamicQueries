/**
 * @description Run As Section Component — supports Specific User and Persona modes
 * @author Jaime Terrats
 * @date 2025-11-30
 * @fires userselect - When a real user is selected (Specific User mode)
 * @fires userclear - When user selection is cleared
 * @fires personaselect - When a persona is selected (Persona mode)
 * @fires personaclear - When persona selection is cleared
 * @fires clearselection - When clear button is clicked
 */
import { LightningElement, api } from "lwc";
import runAsUserLabel from "@salesforce/label/c.JT_jtRunAsSection_runAsUser";
import userLabel from "@salesforce/label/c.JT_jtRunAsSection_user";
import noteTextLabel from "@salesforce/label/c.JT_jtRunAsSection_noteText";
import whenSelectUserMessageLabel from "@salesforce/label/c.JT_jtRunAsSection_whenSelectUserMessage";
import selectUserToImpersonateLabel from "@salesforce/label/c.JT_jtRunAsSection_selectUserToImpersonate";
import selectUserPlaceholderLabel from "@salesforce/label/c.JT_jtRunAsSection_selectUserPlaceholder";
import clearSelectionLabel from "@salesforce/label/c.JT_jtRunAsSection_clearSelection";
import executeWithSystemRunAsLabel from "@salesforce/label/c.JT_jtRunAsSection_executeWithSystemRunAs";
import executingTestWithSystemRunAsLabel from "@salesforce/label/c.JT_jtRunAsSection_executingTestWithSystemRunAs";
import loadingUsersLabel from "@salesforce/label/c.JT_jtRunAsSection_loadingUsers";
import loadingUsersAriaLabel from "@salesforce/label/c.JT_jtRunAsSection_loadingUsersAria";
import userImpersonationActionsLabel from "@salesforce/label/c.JT_jtRunAsSection_userImpersonationActions";
import clearSelectedUserLabel from "@salesforce/label/c.JT_jtRunAsSection_clearSelectedUser";
import testExecutionInProgressLabel from "@salesforce/label/c.JT_jtRunAsSection_testExecutionInProgress";

const MODE_USER = "user";
const MODE_PERSONA = "persona";

export default class JtRunAsSection extends LightningElement {
  // Public API — Specific User mode
  @api userOptions = [];
  @api isLoadingUsers = false;
  @api showRunAsTest = false;
  @api isRunningTest = false;

  // Public API — Persona mode
  @api personaOptions = [];
  @api isLoadingPersonas = false;

  _selectedUserId = "";
  _selectedUserName = "";
  _selectedPersonaValue = "";
  _selectedPersonaLabel = "";
  _mode = MODE_USER;
  _modeAnnouncement = "";

  labels = {
    runAsUser: runAsUserLabel,
    user: userLabel,
    noteText: noteTextLabel,
    whenSelectUserMessage: whenSelectUserMessageLabel,
    selectUserToImpersonate: selectUserToImpersonateLabel,
    selectUserPlaceholder: selectUserPlaceholderLabel,
    clearSelection: clearSelectionLabel,
    executeWithSystemRunAs: executeWithSystemRunAsLabel,
    executingTestWithSystemRunAs: executingTestWithSystemRunAsLabel,
    loadingUsers: loadingUsersLabel,
    loadingUsersAria: loadingUsersAriaLabel,
    userImpersonationActions: userImpersonationActionsLabel,
    clearSelectedUser: clearSelectedUserLabel,
    testExecutionInProgress: testExecutionInProgressLabel,
    modeSpecificUser: "Specific User",
    modePersona: "Persona",
    runAsModeToggleAria: "Run As mode selection",
    selectPersonaLabel: "Select a Persona",
    selectPersonaPlaceholder: "Search personas...",
    loadingPersonas: "Loading personas...",
    personaNoteText:
      "Persona mode creates a synthetic user from a Profile + Permission Sets definition. No real named user required."
  };

  // ── selectedUserId ──────────────────────────────────────────────
  @api
  get selectedUserId() {
    return this._selectedUserId;
  }
  set selectedUserId(value) {
    const previous = this._selectedUserId;
    this._selectedUserId = value || "";
    if (previous && !this._selectedUserId) {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(
        () =>
          this.resetCombobox("c-jt-searchable-combobox[name='run-as-user']"),
        0
      );
    }
  }

  @api
  get selectedUserName() {
    return this._selectedUserName;
  }
  set selectedUserName(value) {
    this._selectedUserName = value || "";
  }

  // ── Computed ────────────────────────────────────────────────────
  get isModeUser() {
    return this._mode === MODE_USER;
  }
  get isModePersona() {
    return this._mode === MODE_PERSONA;
  }

  get modeButtonClassUser() {
    return (
      "slds-button slds-button_neutral" +
      (this._mode === MODE_USER ? " slds-button_brand" : "")
    );
  }
  get modeButtonClassPersona() {
    return (
      "slds-button slds-button_neutral" +
      (this._mode === MODE_PERSONA ? " slds-button_brand" : "")
    );
  }

  get modeAnnouncement() {
    return this._modeAnnouncement;
  }

  get activeNoteText() {
    return this._mode === MODE_PERSONA
      ? this.labels.personaNoteText
      : this.labels.noteText;
  }

  get hasSelectedUser() {
    return !!this._selectedUserId;
  }
  get hasSelectedPersona() {
    return !!this._selectedPersonaValue;
  }
  get hasSelection() {
    return this._mode === MODE_USER
      ? this.hasSelectedUser
      : this.hasSelectedPersona;
  }

  get showButtons() {
    return this.hasSelection;
  }
  get showLoadingUsers() {
    return this._mode === MODE_USER && this.isLoadingUsers;
  }
  get isComboboxDisabled() {
    return (
      this.isRunningTest ||
      (this._mode === MODE_USER && this.isLoadingUsers) ||
      (this._mode === MODE_PERSONA && this.isLoadingPersonas)
    );
  }

  // ── Mode handlers ───────────────────────────────────────────────
  handleModeUser() {
    if (this._mode === MODE_USER) return;
    this._mode = MODE_USER;
    this._modeAnnouncement = "Switched to Specific User mode";
    this._selectedPersonaValue = "";
    this._selectedPersonaLabel = "";
    this.dispatchEvent(new CustomEvent("personaclear"));
    this.dispatchEvent(
      new CustomEvent("modechange", { detail: { mode: MODE_USER } })
    );
  }
  handleModePersona() {
    if (this._mode === MODE_PERSONA) return;
    this._mode = MODE_PERSONA;
    this._modeAnnouncement = "Switched to Persona mode";
    this._selectedUserId = "";
    this._selectedUserName = "";
    this.dispatchEvent(new CustomEvent("userclear"));
    this.dispatchEvent(
      new CustomEvent("modechange", { detail: { mode: MODE_PERSONA } })
    );
  }

  // ── Specific User handlers ──────────────────────────────────────
  handleUserSelect(event) {
    const { value, label } = event.detail;
    this.dispatchEvent(
      new CustomEvent("userselect", { detail: { value, label } })
    );
  }
  handleUserClear() {
    this.dispatchEvent(new CustomEvent("userclear"));
  }

  // ── Persona handlers ────────────────────────────────────────────
  handlePersonaSelect(event) {
    const { value, label } = event.detail;
    this._selectedPersonaValue = value;
    this._selectedPersonaLabel = label;
    this.dispatchEvent(
      new CustomEvent("personaselect", { detail: { value, label } })
    );
  }
  handlePersonaClear() {
    this._selectedPersonaValue = "";
    this._selectedPersonaLabel = "";
    this.dispatchEvent(new CustomEvent("personaclear"));
  }

  // ── Clear selection ─────────────────────────────────────────────
  handleClearSelection() {
    if (this._mode === MODE_USER) {
      this.resetCombobox("c-jt-searchable-combobox[name='run-as-user']");
      this.dispatchEvent(new CustomEvent("userclear"));
    } else {
      this._selectedPersonaValue = "";
      this._selectedPersonaLabel = "";
      this.resetCombobox("c-jt-searchable-combobox[name='run-as-persona']");
      this.dispatchEvent(new CustomEvent("personaclear"));
    }
    this.dispatchEvent(new CustomEvent("clearselection"));
  }

  resetCombobox(selector) {
    const combobox = this.template.querySelector(selector);
    if (combobox && typeof combobox.reset === "function") {
      combobox.reset();
    }
  }

  handleExecuteAsUser() {
    if (this.hasSelectedUser) {
      this.dispatchEvent(new CustomEvent("executeasuser"));
    }
  }
}
