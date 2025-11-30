/**
 * @description Settings State Manager (Functional Pattern)
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Singleton with reactive properties
 */

class SettingsState {
  constructor() {
    this._usageTrackingEnabled = false;
    this._runAsEnabled = false;
    this._isProduction = false;
    this._productionOverride = false;
    this._orgType = "Unknown";
    this._selectedUserId = null;
    this._selectedUserName = null;
    this._listeners = new Set();
  }

  // Getters
  get usageTrackingEnabled() {
    return this._usageTrackingEnabled;
  }
  get runAsEnabled() {
    return this._runAsEnabled;
  }
  get isProduction() {
    return this._isProduction;
  }
  get orgType() {
    return this._orgType;
  }
  get selectedUserId() {
    return this._selectedUserId;
  }
  get selectedUserName() {
    return this._selectedUserName;
  }

  // Computed values
  get canCreateMetadata() {
    return !this._isProduction || this._productionOverride;
  }

  get showRunAs() {
    return this._runAsEnabled;
  }

  get showUsageTracking() {
    return this._usageTrackingEnabled;
  }

  // Actions
  updateSettings(newSettings) {
    if (newSettings.usageTrackingEnabled !== undefined) {
      this._usageTrackingEnabled = newSettings.usageTrackingEnabled;
    }
    if (newSettings.runAsEnabled !== undefined) {
      this._runAsEnabled = newSettings.runAsEnabled;
    }
    if (newSettings.isProduction !== undefined) {
      this._isProduction = newSettings.isProduction;
    }
    if (newSettings.productionOverride !== undefined) {
      this._productionOverride = newSettings.productionOverride;
    }
    if (newSettings.orgType !== undefined) {
      this._orgType = newSettings.orgType;
    }
    this._notify();
  }

  toggleUsageTracking() {
    this._usageTrackingEnabled = !this._usageTrackingEnabled;
    this._notify();
  }

  selectUser(userId, userName) {
    this._selectedUserId = userId;
    this._selectedUserName = userName;
    this._notify();
  }

  clearSelectedUser() {
    this._selectedUserId = null;
    this._selectedUserName = null;
    this._notify();
  }

  // Observer pattern
  subscribe(listener) {
    this._listeners.add(listener);
    return () => this._listeners.delete(listener);
  }

  _notify() {
    this._listeners.forEach((listener) => listener(this));
  }
}

// Singleton export
export default new SettingsState();
