/**
 * @description JT Query State Manager (Functional Pattern)
 * @author Jaime Terrats
 * @date 2025-11-30
 * @pattern Singleton with reactive properties
 * @note Ready to migrate to createStateManager() when Beta is GA
 * @deprecated This component is currently UNUSED. Consider deletion.
 */

// Reactive state container (singleton)
class JtQueryState {
  constructor() {
    this._selectedConfig = null;
    this._parameters = {};
    this._results = null;
    this._isLoading = false;
    this._error = null;
    this._activeView = "table";
    this._expandedCards = new Set();
    this._listeners = new Set();
  }

  // Getters (immutable access)
  get selectedConfig() {
    return this._selectedConfig;
  }
  get parameters() {
    return { ...this._parameters };
  }
  get results() {
    return this._results;
  }
  get isLoading() {
    return this._isLoading;
  }
  get error() {
    return this._error;
  }
  get activeView() {
    return this._activeView;
  }
  get expandedCards() {
    return new Set(this._expandedCards);
  }

  // Computed properties
  get hasResults() {
    return this._results !== null && this._results.length > 0;
  }

  get hasError() {
    return this._error !== null;
  }

  get canExecute() {
    return this._selectedConfig !== null && !this._isLoading;
  }

  get recordCount() {
    return this._results?.length || 0;
  }

  // Actions (mutations)
  selectConfig(config) {
    this._selectedConfig = config;
    this._parameters = {};
    this._results = null;
    this._error = null;
    this._notify();
  }

  updateParameter(name, value) {
    this._parameters = { ...this._parameters, [name]: value };
    this._notify();
  }

  updateParameters(newParams) {
    this._parameters = { ...this._parameters, ...newParams };
    this._notify();
  }

  setLoading(loading) {
    this._isLoading = loading;
    this._notify();
  }

  setResults(data) {
    this._results = data;
    this._error = null;
    this._isLoading = false;
    this._notify();
  }

  setError(errorMessage) {
    this._error = errorMessage;
    this._results = null;
    this._isLoading = false;
    this._notify();
  }

  resetQuery() {
    this._selectedConfig = null;
    this._parameters = {};
    this._results = null;
    this._error = null;
    this._isLoading = false;
    this._notify();
  }

  changeView(view) {
    if (["table", "json", "csv"].includes(view)) {
      this._activeView = view;
      this._notify();
    }
  }

  toggleCard(cardId) {
    if (this._expandedCards.has(cardId)) {
      this._expandedCards.delete(cardId);
    } else {
      this._expandedCards.add(cardId);
    }
    this._notify();
  }

  clearExpandedCards() {
    this._expandedCards = new Set();
    this._notify();
  }

  // Observer pattern for reactivity
  subscribe(listener) {
    this._listeners.add(listener);
    return () => this._listeners.delete(listener);
  }

  _notify() {
    this._listeners.forEach((listener) => listener(this));
  }
}

// Singleton export
export default new JtQueryState();
