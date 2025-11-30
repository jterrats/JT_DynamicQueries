/**
 * @description Cache Management Modal Component
 * @author Jaime Terrats
 * @date 2025-11-30
 *
 * Allows users to selectively clear different types of cache
 */
import { LightningElement, api } from 'lwc';

export default class JtCacheModal extends LightningElement {
  @api labels = {};

  // Cache options
  clearConfigurations = false;
  clearResults = false;
  clearUsers = false;
  clearRecent = false;

  // Modal state
  isOpen = false;

  @api
  open() {
    this.isOpen = true;
  }

  @api
  close() {
    this.isOpen = false;
    this.resetSelections();
  }

  resetSelections() {
    this.clearConfigurations = false;
    this.clearResults = false;
    this.clearUsers = false;
    this.clearRecent = false;
  }

  // Computed
  get hasSelections() {
    return this.clearConfigurations ||
           this.clearResults ||
           this.clearUsers ||
           this.clearRecent;
  }

  get allSelected() {
    return this.clearConfigurations &&
           this.clearResults &&
           this.clearUsers &&
           this.clearRecent;
  }

  // Event handlers
  handleConfigChange(event) {
    this.clearConfigurations = event.target.checked;
  }

  handleResultsChange(event) {
    this.clearResults = event.target.checked;
  }

  handleUsersChange(event) {
    this.clearUsers = event.target.checked;
  }

  handleRecentChange(event) {
    this.clearRecent = event.target.checked;
  }

  handleSelectAll() {
    const selectAll = !this.allSelected;
    this.clearConfigurations = selectAll;
    this.clearResults = selectAll;
    this.clearUsers = selectAll;
    this.clearRecent = selectAll;
  }

  handleCancel() {
    this.close();
  }

  handleClear() {
    // Dispatch event with selections
    const detail = {
      configurations: this.clearConfigurations,
      results: this.clearResults,
      users: this.clearUsers,
      recent: this.clearRecent
    };

    this.dispatchEvent(new CustomEvent('clearcache', { detail }));
    this.close();
  }

  // Keyboard accessibility
  handleKeyDown(event) {
    if (event.key === 'Escape') {
      this.handleCancel();
    }
  }
}

