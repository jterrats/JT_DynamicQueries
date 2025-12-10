/**
 * @description Run As Section Component
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Composite Section Component
 * @fires userselect - When user is selected
 * @fires userclear - When user selection is cleared
 * @fires executeasuser - When "Execute with System.runAs" is clicked
 */
import { LightningElement, api, track } from "lwc";

export default class JtRunAsSection extends LightningElement {
  // Public API
  @api userOptions = [];
  @api isLoadingUsers = false;
  @api selectedUserId = "";
  @api selectedUserName = "";
  @api showRunAsTest = false;
  @api isRunningTest = false;

  // Translatable labels
  @api title = "Run As User";
  @api noteText =
    "Select a user to test their permissions. The query will execute with System.runAs() in test context, showing only what that user can see.";
  @api selectUserLabel = "Select User to Impersonate (Optional)";
  @api selectUserPlaceholder =
    "Type to search users... (leave blank to run as current user)";
  @api clearLabel = "Clear Selection";
  @api executeAsUserLabel = "Execute with System.runAs (Test)";
  @api executingTestText = "Executing test with System.runAs()...";
  @api loadingUsersText = "Loading users...";

  // Computed
  get hasSelectedUser() {
    return !!this.selectedUserId;
  }

  get showButtons() {
    return this.hasSelectedUser;
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
    this.handleUserClear();
  }

  handleExecuteAsUser() {
    if (this.hasSelectedUser) {
      this.dispatchEvent(new CustomEvent("executeasuser"));
    }
  }
}
