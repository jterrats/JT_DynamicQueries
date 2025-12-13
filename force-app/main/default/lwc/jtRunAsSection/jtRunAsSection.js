/**
 * @description Run As Section Component
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Composite Section Component
 * @fires userselect - When user is selected
 * @fires userclear - When user selection is cleared
 * @fires executeasuser - When "Execute with System.runAs" is clicked
 */
import { LightningElement, api } from "lwc";
// Import Custom Labels
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

export default class JtRunAsSection extends LightningElement {
  // Public API
  @api userOptions = [];
  @api isLoadingUsers = false;
  _selectedUserId = "";
  _selectedUserName = "";
  @api showRunAsTest = false;
  @api isRunningTest = false;

  // Custom Labels
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
    testExecutionInProgress: testExecutionInProgressLabel
  };

  // Handle selectedUserId changes to reset combobox when cleared
  @api
  get selectedUserId() {
    return this._selectedUserId;
  }

  set selectedUserId(value) {
    const previousValue = this._selectedUserId;
    this._selectedUserId = value || "";

    // If value was cleared (had value before, now empty), reset the combobox
    // Use setTimeout to ensure DOM is ready
    if (previousValue && !this._selectedUserId) {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(() => {
        this.resetCombobox();
      }, 0);
    }
  }

  @api
  get selectedUserName() {
    return this._selectedUserName;
  }

  set selectedUserName(value) {
    this._selectedUserName = value || "";
  }

  // Computed
  get hasSelectedUser() {
    return !!this._selectedUserId;
  }

  get showButtons() {
    return this.hasSelectedUser;
  }

  get isComboboxDisabled() {
    return this.isLoadingUsers || this.isRunningTest;
  }

  // Event Handlers
  handleUserSelect(event) {
    const { value, label } = event.detail;

    this.dispatchEvent(
      new CustomEvent("userselect", {
        detail: { value, label }
      })
    );
  }

  handleUserClear() {
    this.dispatchEvent(new CustomEvent("userclear"));
  }

  handleClearSelection() {
    // Reset the combobox first (before dispatching events)
    // This ensures the combobox UI is cleared immediately
    this.resetCombobox();

    // Dispatch both events to ensure parent component clears all data
    this.dispatchEvent(new CustomEvent("userclear"));
    this.dispatchEvent(new CustomEvent("clearselection"));
  }

  // Reset the combobox component
  resetCombobox() {
    const combobox = this.template.querySelector('c-jt-searchable-combobox');
    if (combobox && typeof combobox.reset === 'function') {
      combobox.reset();
    }
  }

  handleExecuteAsUser() {
    if (this.hasSelectedUser) {
      this.dispatchEvent(new CustomEvent("executeasuser"));
    }
  }
}