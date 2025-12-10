import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
// Import Custom Labels from Salesforce Translation Workbench (89 labels)
import apexClassLabel from "@salesforce/label/c.JT_jtQueryViewer_apexClass";
import autoDetectedFromQueryLabel from "@salesforce/label/c.JT_jtQueryViewer_autoDetectedFromQuery";
import baseQueryLabel from "@salesforce/label/c.JT_jtQueryViewer_baseQuery";
import bindingsLabel from "@salesforce/label/c.JT_jtQueryViewer_bindings";
import cacheClearedLabel from "@salesforce/label/c.JT_jtQueryViewer_cacheCleared";
import cacheClearedDetailLabel from "@salesforce/label/c.JT_jtQueryViewer_cacheClearedDetail";
import cancelLabel from "@salesforce/label/c.JT_jtQueryViewer_cancel";
import chooseConfigurationLabel from "@salesforce/label/c.JT_jtQueryViewer_chooseConfiguration";
import clearLabel from "@salesforce/label/c.JT_jtQueryViewer_clear";
import clearCacheLabel from "@salesforce/label/c.JT_jtQueryViewer_clearCache";
import clearCacheButtonLabel from "@salesforce/label/c.JT_jtQueryViewer_clearCacheButton";
import clearCacheDescriptionLabel from "@salesforce/label/c.JT_jtQueryViewer_clearCacheDescription";
import clearCacheTitleLabel from "@salesforce/label/c.JT_jtQueryViewer_clearCacheTitle";
import clearCacheWarningLabel from "@salesforce/label/c.JT_jtQueryViewer_clearCacheWarning";
import clearConfigurationsHelpLabel from "@salesforce/label/c.JT_jtQueryViewer_clearConfigurationsHelp";
import clearConfigurationsLabelLabel from "@salesforce/label/c.JT_jtQueryViewer_clearConfigurationsLabel";
import clearRecentHelpLabel from "@salesforce/label/c.JT_jtQueryViewer_clearRecentHelp";
import clearRecentLabelLabel from "@salesforce/label/c.JT_jtQueryViewer_clearRecentLabel";
import clearResultsHelpLabel from "@salesforce/label/c.JT_jtQueryViewer_clearResultsHelp";
import clearResultsLabelLabel from "@salesforce/label/c.JT_jtQueryViewer_clearResultsLabel";
import clearSelectionLabel from "@salesforce/label/c.JT_jtQueryViewer_clearSelection";
import clearUsersHelpLabel from "@salesforce/label/c.JT_jtQueryViewer_clearUsersHelp";
import clearUsersLabelLabel from "@salesforce/label/c.JT_jtQueryViewer_clearUsersLabel";
import codeLabel from "@salesforce/label/c.JT_jtQueryViewer_code";
import createConfigTooltipLabel from "@salesforce/label/c.JT_jtQueryViewer_createConfigTooltip";
import createNewConfigurationLabel from "@salesforce/label/c.JT_jtQueryViewer_createNewConfiguration";
import developerNameLabel from "@salesforce/label/c.JT_jtQueryViewer_developerName";
import developerNameCannotEndWithUnderscoreLabel from "@salesforce/label/c.JT_jtQueryViewer_developerNameCannotEndWithUnderscore";
import developerNameInvalidCharsLabel from "@salesforce/label/c.JT_jtQueryViewer_developerNameInvalidChars";
import developerNameMustStartWithLetterLabel from "@salesforce/label/c.JT_jtQueryViewer_developerNameMustStartWithLetter";
import developerNameNoConsecutiveUnderscoresLabel from "@salesforce/label/c.JT_jtQueryViewer_developerNameNoConsecutiveUnderscores";
import developerNameRequiredLabel from "@salesforce/label/c.JT_jtQueryViewer_developerNameRequired";
import developerNameTooLongLabel from "@salesforce/label/c.JT_jtQueryViewer_developerNameTooLong";
import editConfigurationLabel from "@salesforce/label/c.JT_jtQueryViewer_editConfiguration";
import executeQueryLabel from "@salesforce/label/c.JT_jtQueryViewer_executeQuery";
import executeSystemRunAsLabel from "@salesforce/label/c.JT_jtQueryViewer_executeSystemRunAs";
import executingTestLabel from "@salesforce/label/c.JT_jtQueryViewer_executingTest";
import findingUsageLabel from "@salesforce/label/c.JT_jtQueryViewer_findingUsage";
import foundReferencesLabel from "@salesforce/label/c.JT_jtQueryViewer_foundReferences";
import invalidQueryLabel from "@salesforce/label/c.JT_jtQueryViewer_invalidQuery";
import labelLabel from "@salesforce/label/c.JT_jtQueryViewer_label";
import labelRequiredLabel from "@salesforce/label/c.JT_jtQueryViewer_labelRequired";
import labelTooLongLabel from "@salesforce/label/c.JT_jtQueryViewer_labelTooLong";
import lineLabel from "@salesforce/label/c.JT_jtQueryViewer_line";
import lineNumberLabel from "@salesforce/label/c.JT_jtQueryViewer_lineNumber";
import loadingUsersLabel from "@salesforce/label/c.JT_jtQueryViewer_loadingUsers";
import nameLabel from "@salesforce/label/c.JT_jtQueryViewer_name";
import nextLabel from "@salesforce/label/c.JT_jtQueryViewer_next";
import noParametersRequiredLabel from "@salesforce/label/c.JT_jtQueryViewer_noParametersRequired";
import noReferencesFoundLabel from "@salesforce/label/c.JT_jtQueryViewer_noReferencesFound";
import noResultsLabel from "@salesforce/label/c.JT_jtQueryViewer_noResults";
import noUsageFoundLabel from "@salesforce/label/c.JT_jtQueryViewer_noUsageFound";
import noUsageMessageLabel from "@salesforce/label/c.JT_jtQueryViewer_noUsageMessage";
import objectLabel from "@salesforce/label/c.JT_jtQueryViewer_object";
import objectNameLabel from "@salesforce/label/c.JT_jtQueryViewer_objectName";
import objectNameReadOnlyLabel from "@salesforce/label/c.JT_jtQueryViewer_objectNameReadOnly";
import ofLabel from "@salesforce/label/c.JT_jtQueryViewer_of";
import pageLabel from "@salesforce/label/c.JT_jtQueryViewer_page";
import predefinedBindingsLabel from "@salesforce/label/c.JT_jtQueryViewer_predefinedBindings";
import predefinedBindingsDescLabel from "@salesforce/label/c.JT_jtQueryViewer_predefinedBindingsDesc";
import previousLabel from "@salesforce/label/c.JT_jtQueryViewer_previous";
import queryParametersLabel from "@salesforce/label/c.JT_jtQueryViewer_queryParameters";
import queryPreviewLabel from "@salesforce/label/c.JT_jtQueryViewer_queryPreview";
import queryPreviewTitleLabel from "@salesforce/label/c.JT_jtQueryViewer_queryPreviewTitle";
import recordLabel from "@salesforce/label/c.JT_jtQueryViewer_record";
import recordsLabel from "@salesforce/label/c.JT_jtQueryViewer_records";
import resultsLabel from "@salesforce/label/c.JT_jtQueryViewer_results";
import runAsNoteLabel from "@salesforce/label/c.JT_jtQueryViewer_runAsNote";
import runAsUserLabel from "@salesforce/label/c.JT_jtQueryViewer_runAsUser";
import sandboxOnlyWarningLabel from "@salesforce/label/c.JT_jtQueryViewer_sandboxOnlyWarning";
import saveLabel from "@salesforce/label/c.JT_jtQueryViewer_save";
import searchConfigsPlaceholderLabel from "@salesforce/label/c.JT_jtQueryViewer_searchConfigsPlaceholder";
import searchUsersPlaceholderLabel from "@salesforce/label/c.JT_jtQueryViewer_searchUsersPlaceholder";
import searchingFlowsLabel from "@salesforce/label/c.JT_jtQueryViewer_searchingFlows";
import selectAllLabel from "@salesforce/label/c.JT_jtQueryViewer_selectAll";
import selectConfigurationLabel from "@salesforce/label/c.JT_jtQueryViewer_selectConfiguration";
import selectOptionLabel from "@salesforce/label/c.JT_jtQueryViewer_selectOption";
import selectUserLabel from "@salesforce/label/c.JT_jtQueryViewer_selectUser";
import showingLabel from "@salesforce/label/c.JT_jtQueryViewer_showing";
import toolingAPINoteLabel from "@salesforce/label/c.JT_jtQueryViewer_toolingAPINote";
import setupRequiredLabel from "@salesforce/label/c.JT_jtQueryViewer_setupRequired";
import namedCredentialSetupLabel from "@salesforce/label/c.JT_jtQueryViewer_namedCredentialSetup";
import toolingApiSetupLinkLabel from "@salesforce/label/c.JT_jtQueryViewer_toolingApiSetupLink";
import typeLabel from "@salesforce/label/c.JT_jtQueryViewer_type";
import typeToFilterLabel from "@salesforce/label/c.JT_jtQueryViewer_typeToFilter";
import updateConfigurationLabel from "@salesforce/label/c.JT_jtQueryViewer_updateConfiguration";
import usageModalSubtitleLabel from "@salesforce/label/c.JT_jtQueryViewer_usageModalSubtitle";
import usageModalTitleLabel from "@salesforce/label/c.JT_jtQueryViewer_usageModalTitle";
import validQueryLabel from "@salesforce/label/c.JT_jtQueryViewer_validQuery";
import validSOQLSyntaxLabel from "@salesforce/label/c.JT_jtQueryViewer_validSOQLSyntax";
import whereIsThisUsedLabel from "@salesforce/label/c.JT_jtQueryViewer_whereIsThisUsed";
import whereIsThisUsedTooltipLabel from "@salesforce/label/c.JT_jtQueryViewer_whereIsThisUsedTooltip";

// Apex imports
import getConfigurations from "@salesforce/apex/JT_QueryViewerController.getConfigurations";
import extractParameters from "@salesforce/apex/JT_QueryViewerController.extractParameters";
import executeQuery from "@salesforce/apex/JT_QueryViewerController.executeQuery";
import canUseRunAs from "@salesforce/apex/JT_QueryViewerController.canUseRunAs";
import getAllActiveUsers from "@salesforce/apex/JT_QueryViewerController.getAllActiveUsers";
import executeAsUser from "@salesforce/apex/JT_RunAsTestExecutor.executeAsUser";
import getTestResults from "@salesforce/apex/JT_RunAsTestExecutor.getTestResults";
import canUseRunAsTest from "@salesforce/apex/JT_RunAsTestExecutor.canUseRunAsTest";
import isSandboxOrScratch from "@salesforce/apex/JT_MetadataCreator.isSandboxOrScratch";
import getOrgInfo from "@salesforce/apex/JT_MetadataCreator.getOrgInfo";
import createConfiguration from "@salesforce/apex/JT_MetadataCreator.createConfiguration";
import updateConfiguration from "@salesforce/apex/JT_MetadataCreator.updateConfiguration";
// validateQuery now handled by jtConfigModal component directly
// import getProductionEditingSetting from "@salesforce/apex/JT_ProductionSettingsController.getProductionEditingSetting"; // Unused
import updateProductionEditingSetting from "@salesforce/apex/JT_ProductionSettingsController.updateProductionEditingSetting";
import getUsageTrackingSetting from "@salesforce/apex/JT_ProductionSettingsController.getUsageTrackingSetting";
import updateUsageTrackingSetting from "@salesforce/apex/JT_ProductionSettingsController.updateUsageTrackingSetting";
import logUsageSearch from "@salesforce/apex/JT_ProductionSettingsController.logUsageSearch";
import findConfigurationUsage from "@salesforce/apex/JT_UsageFinder.findConfigurationUsage";
import findAllUsagesResilient from "@salesforce/apex/JT_UsageFinder.findAllUsagesResilient";
import assessQueryRisk from "@salesforce/apex/JT_QueryViewerController.assessQueryRisk";
import executeQueryWithBatchProcessing from "@salesforce/apex/JT_QueryViewerController.executeQueryWithBatchProcessing";

export default class JtQueryViewer extends LightningElement {
  @track selectedConfig = "";
  @track baseQuery = "";
  @track bindings = "";
  @track parameters = [];
  @track parameterValues = {};
  @track queryResults = [];
  @track columns = [];
  @track recordCount = 0;
  @track isLoading = false;
  @track hasResults = false;
  @track errorMessage = "";
  @track currentPage = 1;
  @track pageSize = 10;
  @track totalPages = 1;
  @track showError = false;
  @track objectName = "";
  @track viewMode = { table: true, json: false, csv: false };
  @track jsonOutput = "";
  expandedCards = new Set();
  @track showRunAs = false;
  @track queryPreviewData = [];
  @track previewColumns = [];
  @track isLoadingPreview = false;
  @track showPreviewData = false;
  @track previewRecordCount = 0;
  @track previewCurrentPage = 1;
  @track previewPageSize = 3; // Show 3 records at a time
  @track previewTotalPages = 1;
  @track runAsUserId = "";
  @track runAsUserName = "";
  @track userOptions = []; // All active users for combobox
  @track isLoadingUsers = false;
  @track showRunAsTest = false;
  @track isRunningTest = false;
  @track testJobId = "";
  @track testAssertMessage = "";
  @track showTestResults = false;
  @track showCreateModal = false;
  @track isEditMode = false;
  @track canCreateMetadata = false;
  @track configModalMode = "create"; // 'create' | 'edit'
  @track showUsageModal = false;
  @track usageResults = [];
  @track isLoadingUsage = false;
  @track usageServiceErrors = { apex: null, flow: null };
  @track hasPartialUsageResults = false;

  // Debug mode for dropdown styling (disabled - CSS fixed)
  dropdownDebugMode = false;
  @track usageTrackingEnabled = false;
  @track productionOverrideEnabled = false;
  @track isUpdatingSettings = false;
  @track orgInfo = {};
  @track newConfig = {
    label: "",
    developerName: "",
    baseQuery: "",
    bindings: "",
    objectName: ""
  };
  @track originalDevName = ""; // For edit mode
  @track queryValidation = { isValid: false, message: "" };
  @track isSaving = false;
  @track showCacheModal = false;
  @track isLoadingQueryPreview = false;
  @track queryPreviewResults = [];
  @track queryPreviewColumns = [];

  // Query Risk Assessment
  @track showRiskWarningModal = false;
  @track queryRiskAssessment = null;
  @track isAssessingRisk = false;
  @track pendingExecutionMode = "normal"; // 'normal' or 'batch'

  // Store wired results for refreshing
  wiredConfigsResult;
  wiredUsersResult;
  @track developerNameManuallyEdited = false; // Track if user manually edited dev name

  configurationOptions = [];
  wiredConfigurationsResult;
  searchTimeout;
  pollInterval;

  // Computed property for labels (cannot call functions at class level)
  // Custom Labels (89 labels from Translation Workbench)
  // Custom Labels (89 labels from Translation Workbench)
  labels = {
    apexClass: apexClassLabel,
    autoDetectedFromQuery: autoDetectedFromQueryLabel,
    baseQuery: baseQueryLabel,
    bindings: bindingsLabel,
    cacheCleared: cacheClearedLabel,
    cacheClearedDetail: cacheClearedDetailLabel,
    cancel: cancelLabel,
    chooseConfiguration: chooseConfigurationLabel,
    clear: clearLabel,
    clearCache: clearCacheLabel,
    clearCacheButton: clearCacheButtonLabel,
    clearCacheDescription: clearCacheDescriptionLabel,
    clearCacheTitle: clearCacheTitleLabel,
    clearCacheWarning: clearCacheWarningLabel,
    clearConfigurationsHelp: clearConfigurationsHelpLabel,
    clearConfigurationsLabel: clearConfigurationsLabelLabel,
    clearRecentHelp: clearRecentHelpLabel,
    clearRecentLabel: clearRecentLabelLabel,
    clearResultsHelp: clearResultsHelpLabel,
    clearResultsLabel: clearResultsLabelLabel,
    clearSelection: clearSelectionLabel,
    clearUsersHelp: clearUsersHelpLabel,
    clearUsersLabel: clearUsersLabelLabel,
    code: codeLabel,
    createConfigTooltip: createConfigTooltipLabel,
    createNewConfiguration: createNewConfigurationLabel,
    developerName: developerNameLabel,
    developerNameCannotEndWithUnderscore:
      developerNameCannotEndWithUnderscoreLabel,
    developerNameInvalidChars: developerNameInvalidCharsLabel,
    developerNameMustStartWithLetter: developerNameMustStartWithLetterLabel,
    developerNameNoConsecutiveUnderscores:
      developerNameNoConsecutiveUnderscoresLabel,
    developerNameRequired: developerNameRequiredLabel,
    developerNameTooLong: developerNameTooLongLabel,
    editConfiguration: editConfigurationLabel,
    executeQuery: executeQueryLabel,
    executeSystemRunAs: executeSystemRunAsLabel,
    executingTest: executingTestLabel,
    findingUsage: findingUsageLabel,
    foundReferences: foundReferencesLabel,
    invalidQuery: invalidQueryLabel,
    label: labelLabel,
    labelRequired: labelRequiredLabel,
    labelTooLong: labelTooLongLabel,
    line: lineLabel,
    lineNumber: lineNumberLabel,
    loadingUsers: loadingUsersLabel,
    name: nameLabel,
    next: nextLabel,
    noParametersRequired: noParametersRequiredLabel,
    noReferencesFound: noReferencesFoundLabel,
    noResults: noResultsLabel,
    noUsageFound: noUsageFoundLabel,
    noUsageMessage: noUsageMessageLabel,
    object: objectLabel,
    objectName: objectNameLabel,
    objectNameReadOnly: objectNameReadOnlyLabel,
    of: ofLabel,
    page: pageLabel,
    predefinedBindings: predefinedBindingsLabel,
    predefinedBindingsDesc: predefinedBindingsDescLabel,
    previous: previousLabel,
    queryParameters: queryParametersLabel,
    queryPreview: queryPreviewLabel,
    queryPreviewTitle: queryPreviewTitleLabel,
    record: recordLabel,
    records: recordsLabel,
    results: resultsLabel,
    runAsNote: runAsNoteLabel,
    runAsUser: runAsUserLabel,
    sandboxOnlyWarning: sandboxOnlyWarningLabel,
    save: saveLabel,
    searchConfigsPlaceholder: searchConfigsPlaceholderLabel,
    searchUsersPlaceholder: searchUsersPlaceholderLabel,
    searchingFlows: searchingFlowsLabel,
    selectAll: selectAllLabel,
    selectConfiguration: selectConfigurationLabel,
    selectOption: selectOptionLabel,
    selectUser: selectUserLabel,
    setupRequired: setupRequiredLabel,
    namedCredentialSetup: namedCredentialSetupLabel,
    toolingApiSetupLink: toolingApiSetupLinkLabel,
    showing: showingLabel,
    toolingAPINote: toolingAPINoteLabel,
    type: typeLabel,
    typeToFilter: typeToFilterLabel,
    updateConfiguration: updateConfigurationLabel,
    usageModalSubtitle: usageModalSubtitleLabel,
    usageModalTitle: usageModalTitleLabel,
    validQuery: validQueryLabel,
    validSOQLSyntax: validSOQLSyntaxLabel,
    whereIsThisUsed: whereIsThisUsedLabel,
    whereIsThisUsedTooltip: whereIsThisUsedTooltipLabel
  };

  // Wire to get all configurations (cacheable for refreshApex)
  @wire(getConfigurations)
  wiredConfigurations(result) {
    this.wiredConfigurationsResult = result;
    const { data } = result;

    if (data) {
      this.configurationOptions = data;
      this.filteredConfigs = [...data]; // Initialize filtered list
      this.showError = false;
    }
  }

  // Wire to check if org allows metadata creation
  @wire(isSandboxOrScratch)
  wiredIsSandbox({ data }) {
    if (data !== undefined) {
      this.canCreateMetadata = data;
    }
  }

  // Wire to get org info
  @wire(getOrgInfo)
  wiredOrgInfo({ data }) {
    if (data) {
      this.orgInfo = data;
      this.canCreateMetadata = data.canCreateMetadata;
      this.productionOverrideEnabled = data.productionOverrideEnabled || false;
    }
  }

  get isProduction() {
    return this.orgInfo && this.orgInfo.isProduction === true;
  }

  // Handle production override toggle
  handleProductionOverrideChange(event) {
    const enabled = event.target.checked;
    this.isUpdatingSettings = true;

    updateProductionEditingSetting({ enabled: enabled })
      .then(() => {
        this.productionOverrideEnabled = enabled;
        this.showSuccessToast(
          enabled
            ? "Production editing enabled. Please refresh the page to see changes."
            : "Production editing disabled. Please refresh the page."
        );

        // Refresh org info
        return refreshApex(this.wiredConfigurationsResult);
      })
      .catch((error) => {
        this.showErrorToast("Error updating settings", error.body?.message);
        // Revert checkbox
        this.productionOverrideEnabled = !enabled;
      })
      .finally(() => {
        this.isUpdatingSettings = false;
      });
  }

  get orgTypeBadge() {
    if (!this.orgInfo) return "";
    const orgType = this.orgInfo.organizationType || "";

    if (this.orgInfo.isSandbox) return "Org Type: Sandbox";
    if (this.orgInfo.isScratch) return "Org Type: Scratch Org";
    if (orgType === "Developer Edition") return "Org Type: Developer Edition";

    // All other orgs are considered production (including Starter/Free)
    return "Org Type: Production";
  }

  get orgTypeBadgeTitle() {
    const orgType = this.orgInfo?.organizationType || "";
    if (this.orgInfo?.isSandbox)
      return "This is a Sandbox environment - metadata editing is allowed";
    if (this.orgInfo?.isScratch)
      return "This is a Scratch Org - metadata editing is allowed";
    if (orgType === "Developer Edition")
      return "This is a Developer Edition org - metadata editing is allowed";
    return "This is a Production environment - metadata editing is restricted";
  }

  // Wire to check if user can use Run As feature
  @wire(canUseRunAs)
  wiredCanUseRunAs({ error, data }) {
    if (data) {
      this.showRunAs = data;
      // Load all users when Run As is available
      if (data && this.userOptions.length === 0) {
        this.loadAllUsers();
      }
    } else if (error) {
      this.showRunAs = false;
    }
  }

  // Wire to check if user can use Run As Test feature
  @wire(canUseRunAsTest)
  wiredCanUseRunAsTest({ error, data }) {
    if (data) {
      this.showRunAsTest = data;
    } else if (error) {
      this.showRunAsTest = false;
    }
  }

  // Load all active users for dropdown (called once)
  loadAllUsers() {
    this.isLoadingUsers = true;
    getAllActiveUsers()
      .then((users) => {
        this.userOptions = users.map((user) => ({
          label: user.label,
          value: user.value
        }));
      })
      .catch((error) => {
        this.showErrorToast(
          "Error Loading Users",
          error.body?.message || "Failed to load users"
        );
        this.userOptions = [];
      })
      .finally(() => {
        this.isLoadingUsers = false;
      });
  }

  get hasConfigurations() {
    return this.configurationOptions && this.configurationOptions.length > 0;
  }

  get hasParameters() {
    return this.parameters && this.parameters.length > 0;
  }

  get queryPreview() {
    if (!this.baseQuery) return "";
    return this.baseQuery;
  }

  // Load query preview data (max 5 records)
  loadQueryPreview() {
    if (!this.selectedConfig) {
      this.showPreviewData = false;
      return;
    }

    this.isLoadingPreview = true;
    this.showPreviewData = false;

    // Build bindings JSON
    let bindingsToSend;
    if (this.hasBindings && !this.hasParameters) {
      bindingsToSend = this.bindings;
    } else if (this.hasParameters) {
      bindingsToSend = JSON.stringify(this.parameterValues);
    } else {
      bindingsToSend = null;
    }

    executeQueryPreview({
      devName: this.selectedConfig,
      bindingsJson: bindingsToSend,
      queryOverride: null
    })
      .then((result) => {
        if (result.success && result.recordCount > 0) {
          this.queryPreviewData = result.records;
          this.previewRecordCount = result.recordCount;
          this.showPreviewData = true;

          // Build columns
          if (result.fields && result.fields.length > 0) {
            this.previewColumns = result.fields.map((field) => ({
              label: this.formatLabel(field),
              fieldName: field,
              type: this.getFieldType(field)
            }));
          }

          // Calculate pagination
          this.previewTotalPages = Math.ceil(
            this.previewRecordCount / this.previewPageSize
          );
          this.previewCurrentPage = 1;
        } else {
          this.showPreviewData = false;
          this.queryPreviewData = [];
        }
      })
      .catch(() => {
        this.showPreviewData = false;
        this.queryPreviewData = [];
      })
      .finally(() => {
        this.isLoadingPreview = false;
      });
  }

  // Preview pagination getters
  get previewPaginatedData() {
    const start = (this.previewCurrentPage - 1) * this.previewPageSize;
    const end = start + this.previewPageSize;
    return this.queryPreviewData.slice(start, end);
  }

  get showPreviewPagination() {
    return this.previewRecordCount > this.previewPageSize;
  }

  get previewHasPrevious() {
    return this.previewCurrentPage > 1;
  }

  get previewHasNext() {
    return this.previewCurrentPage < this.previewTotalPages;
  }

  get previewPageInfo() {
    return `Page ${this.previewCurrentPage} of ${this.previewTotalPages} (${this.previewRecordCount} records)`;
  }

  // Preview pagination handlers
  handlePreviewPrevious() {
    if (this.previewHasPrevious) {
      this.previewCurrentPage--;
    }
  }

  handlePreviewNext() {
    if (this.previewHasNext) {
      this.previewCurrentPage++;
    }
  }

  get hasBindings() {
    return this.bindings && this.bindings.trim() !== "";
  }

  get showResults() {
    return this.hasResults && !this.isLoading;
  }

  // Phase 1 Refactor: Removed obsolete getters (moved to jtSearchableCombobox)

  get recordCountLabel() {
    return this.recordCount !== 1 ? this.labels.records : this.labels.record;
  }

  // View mode computed properties
  get isTableView() {
    return this.viewMode.table ? "brand" : "neutral";
  }

  get isJsonView() {
    return this.viewMode.json ? "brand" : "neutral";
  }

  get isCsvView() {
    return this.viewMode.csv ? "brand" : "neutral";
  }

  // Pagination computed properties
  get paginatedResults() {
    if (!this.queryResults || this.queryResults.length === 0) {
      return [];
    }
    const start = (this.currentPage - 1) * this.pageSize;
    const end = start + this.pageSize;

    // Enhance results for mobile cards and table
    return this.queryResults.slice(start, end).map((row, index) => {
      const rowNumber = start + index + 1;
      const displayName = row.Name || row.Id || `Record ${rowNumber}`;
      const isExpanded = this.expandedCards.has(row.Id);

      // Pre-compute cell values for template (LWC doesn't support computed property access)
      const cells = this.columns.map((col) => ({
        key: col.fieldName,
        label: col.label,
        value: row[col.fieldName] || ""
      }));

      return {
        ...row,
        _rowNumber: rowNumber,
        _displayName: displayName,
        _expanded: isExpanded,
        _expandIcon: isExpanded
          ? "utility:chevrondown"
          : "utility:chevronright",
        _expandLabel: isExpanded ? "Collapse" : "Expand",
        _cells: cells
      };
    });
  }

  get showPagination() {
    return this.recordCount > this.pageSize;
  }

  get isFirstPage() {
    return this.currentPage === 1;
  }

  get isLastPage() {
    return this.currentPage >= this.totalPages;
  }

  get firstRecordIndex() {
    return this.queryResults.length > 0
      ? (this.currentPage - 1) * this.pageSize + 1
      : 0;
  }

  get lastRecordIndex() {
    const last = this.currentPage * this.pageSize;
    return last > this.recordCount ? this.recordCount : last;
  }

  get currentPageDisplay() {
    return `${this.labels.page} ${this.currentPage} / ${this.totalPages}`;
  }

  // Pagination handlers
  handlePreviousPage() {
    if (this.currentPage > 1) {
      this.currentPage--;
    }
  }

  handleNextPage() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
    }
  }

  resetPagination() {
    this.currentPage = 1;
    this.totalPages = Math.ceil(this.recordCount / this.pageSize);
  }

  // Handle configuration selection
  // Phase 1 Refactor: Config dropdown logic moved to jtSearchableCombobox

  // Phase 1 Refactor: Updated to use generic combobox event
  handleConfigSelect(event) {
    const { value, data } = event.detail; // label unused

    this.selectedConfig = value;
    this.baseQuery = data.baseQuery;
    this.bindings = data.bindings;
    this.objectName = data.objectName;

    // Only extract parameters if bindings are NOT predefined
    if (!this.hasBindings) {
      this.extractQueryParameters();
    } else {
      // Clear parameters if bindings are predefined
      this.parameters = [];
      this.parameterValues = {};
    }

    this.resetResults();

    // 🐛 FIX: Don't auto-execute preview - wait for user to enter parameters or click Execute
    // this.loadQueryPreview(); // REMOVED - only execute on parameter change or Execute click
  }

  // Phase 1 Refactor: Clear configuration
  handleConfigClear() {
    this.selectedConfig = null;
    this.baseQuery = "";
    this.bindings = null;
    this.objectName = "";
    this.parameters = [];
    this.parameterValues = {};
    this.resetResults();
  }

  // Extract parameters from the query
  extractQueryParameters() {
    if (this.baseQuery) {
      extractParameters({ query: this.baseQuery })
        .then((result) => {
          this.parameters = result.map((param) => ({
            name: param,
            label: param, // Use exact parameter name from SOQL
            value: ""
          }));
          this.parameterValues = {};
        })
        .catch((error) => {
          this.showErrorToast(
            "Error extracting parameters",
            error.body?.message
          );
        });
    }
  }

  // Format parameter name to readable label (still used for table columns)
  formatLabel(paramName) {
    return paramName
      .replace(/([A-Z])/g, " $1")
      .replace(/_/g, " ")
      .replace(/^\w/, (c) => c.toUpperCase())
      .trim();
  }

  // Phase 2 Refactor: Updated to use jtParameterInputs event
  handleParameterChange(event) {
    const { paramName, value, allValues } = event.detail;

    // 🛡️ CRITICAL FIX: Validate allValues exists
    // This prevents native 'change' event from overwriting with undefined
    if (!allValues || typeof allValues !== "object") {
      return; // Early exit - ignore native change events
    }

    this.parameterValues = allValues;
  }

  // Handle user selection from dropdown
  // Phase 1 Refactor: User dropdown logic moved to jtSearchableCombobox

  // Phase 1 Refactor: Updated to use generic combobox event
  handleUserSelect(event) {
    const { value, label } = event.detail;

    this.runAsUserId = value;
    this.runAsUserName = label;
  }

  // Phase 1 Refactor: Clear user selection (from combobox)
  handleUserClear() {
    this.handleClearRunAs();
  }

  // Clear Run As user
  handleClearRunAs() {
    this.runAsUserId = "";
    this.runAsUserName = "";
  }

  // Execute query with true System.runAs (test context)
  handleExecuteAsUserTest() {
    if (!this.selectedConfig) {
      this.showErrorToast(
        "Configuration Required",
        "Please select a configuration first."
      );
      return;
    }

    if (!this.runAsUserId) {
      this.showErrorToast("User Required", "Please select a user to run as.");
      return;
    }

    this.isRunningTest = true;
    this.showError = false;
    this.resetResults();
    this.testAssertMessage = "";

    // Build bindings JSON
    let bindingsToSend = this.buildBindingsJson();

    executeAsUser({
      userId: this.runAsUserId,
      configName: this.selectedConfig,
      bindingsJson: bindingsToSend
    })
      .then((result) => {
        if (result.success) {
          this.testJobId = result.jobId;
          // Don't show toast here - only show final result to avoid stacking
          // Start polling for results
          this.startPollingTestResults();
        } else {
          this.showError = true;
          this.errorMessage = result.errorMessage;
          this.showErrorToast("Test Execution Error", result.errorMessage);
          this.isRunningTest = false;
        }
      })
      .catch((error) => {
        this.showError = true;
        this.errorMessage = error.body?.message || "Unknown error occurred";
        this.showErrorToast("Execution Error", this.errorMessage);
        this.isRunningTest = false;
      });
  }

  // Build bindings JSON helper
  buildBindingsJson() {
    if (this.hasBindings && !this.hasParameters) {
      // Config has predefined bindings
      return this.bindings;
    } else if (this.hasParameters) {
      // Has dynamic parameters
      const paramValues = this.parameterValues || {};
      const hasAnyValues = Object.keys(paramValues).some(
        (key) =>
          paramValues[key] !== "" &&
          paramValues[key] !== null &&
          paramValues[key] !== undefined
      );

      // ⚠️ VALIDATION: Don't overwrite config bindings with empty values
      if (!hasAnyValues && this.hasBindings) {
        // Parameters empty → Fall back to config bindings
        return this.bindings;
      } else if (!hasAnyValues) {
        // No values at all → Empty JSON
        return JSON.stringify({});
      } else {
        // Has values → Use them
        return JSON.stringify(paramValues);
      }
    }
    return null;
  }

  // Start polling for test results
  startPollingTestResults() {
    let pollCount = 0;
    const maxPolls = 30; // 60 seconds max (2 sec intervals)

    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.pollInterval = setInterval(() => {
      pollCount++;

      getTestResults({ userId: this.runAsUserId })
        .then((result) => {
          if (result.success !== undefined) {
            // Results are ready
            clearInterval(this.pollInterval);
            this.handleTestResults(result);
          } else if (pollCount >= maxPolls) {
            // Timeout
            clearInterval(this.pollInterval);
            this.isRunningTest = false;
            this.showErrorToast(
              "Timeout",
              "Test execution timed out after 60 seconds."
            );
          }
          // Keep polling if no results yet
        })
        .catch((error) => {
          clearInterval(this.pollInterval);
          this.isRunningTest = false;
          this.showErrorToast("Polling Error", error.body?.message);
        });
    }, 2000); // Poll every 2 seconds
  }

  // Handle test results
  handleTestResults(result) {
    this.isRunningTest = false;
    this.testAssertMessage = result.assertMessage || "";

    if (result.success) {
      // Parse and display results
      this.processTestQueryResults(result);

      let successMsg = `Test Passed: Found ${result.recordCount} record(s)`;
      if (result.runAsUserName) {
        successMsg += ` (Ran as: ${result.runAsUserName})`;
      }
      if (result.executionTime) {
        successMsg += ` in ${result.executionTime}ms`;
      }

      this.showSuccessToast(successMsg);
    } else {
      this.showError = true;
      this.errorMessage = result.errorMessage || "Test execution failed";
      this.showErrorToast("Test Failed", this.errorMessage);
    }
  }

  // Process test query results for display
  processTestQueryResults(result) {
    this.recordCount = result.recordCount || 0;

    // Always build columns (even with 0 records)
    const fields =
      result.fields ||
      (result.records && result.records.length > 0
        ? Object.keys(result.records[0])
        : []);

    if (fields.length > 0) {
      this.columns = fields.map((field) => ({
        label: this.formatLabel(field),
        fieldName: field,
        type: this.getFieldType(field)
      }));
    }

    if (this.recordCount > 0 && result.records) {
      // Transform records for datatable
      this.queryResults = result.records.map((record, index) => {
        const row = { Id: record.Id || `temp_${index}` };
        fields.forEach((field) => {
          row[field] = record[field];
        });
        return row;
      });

      this.hasResults = true;
      this.showTestResults = true;
      this.resetPagination(); // Initialize pagination
    } else {
      // Show empty table with columns
      this.queryResults = [];
      this.hasResults = true; // Show table even with 0 results
      this.showTestResults = true; // Show section
      this.resetPagination();
      // Don't show "No Results" toast - the success toast already indicates record count
    }
  }

  // Show create configuration modal
  handleShowCreateModal() {
    this.configModalMode = "create";
    this.showCreateModal = true;
    this.resetNewConfig();
  }

  // Show edit configuration modal
  handleShowEditModal() {
    if (!this.selectedConfig) {
      this.showErrorToast(
        "No Configuration Selected",
        "Please select a configuration to edit."
      );
      return;
    }

    // Load current configuration data
    const currentConfig = this.configurationOptions.find(
      (cfg) => cfg.value === this.selectedConfig
    );

    if (!currentConfig) {
      this.showErrorToast(
        "Configuration Not Found",
        "Could not find the selected configuration. Please refresh and try again."
      );
      return;
    }

    // Prepare config data
    this.newConfig = {
      label: currentConfig.label,
      developerName: currentConfig.value,
      baseQuery: currentConfig.baseQuery,
      bindings: currentConfig.bindings,
      objectName: currentConfig.objectName
    };

    this.originalDevName = currentConfig.value; // Save original dev name for update
    this.developerNameManuallyEdited = true; // Prevent auto-generation in edit mode

    // Set modal mode and show it
    this.configModalMode = "edit";
    this.showCreateModal = true;

    // Wait for modal to render, then set config
    setTimeout(() => {
      const modal = this.refs.configModal;
      if (modal) {
        modal.setConfig(this.newConfig);
      }
    }, 100);
  }

  // Hide create/edit configuration modal
  handleCloseCreateModal() {
    this.showCreateModal = false;
    this.resetNewConfig();
    this.configModalMode = "create";
  }

  // Reset new configuration form
  resetNewConfig() {
    this.newConfig = {
      label: "",
      developerName: "",
      baseQuery: "",
      bindings: "",
      objectName: ""
    };
    this.queryValidation = { isValid: false, message: "" };
    this.developerNameManuallyEdited = false;
    this.queryPreviewResults = [];
    this.queryPreviewColumns = [];
    this.isLoadingQueryPreview = false;
    this.originalDevName = ""; // Reset for edit mode
  }

  // Show usage modal
  handleShowUsageModal() {
    if (!this.selectedConfig) {
      this.showErrorToast(
        "No Configuration Selected",
        "Please select a configuration first"
      );
      return;
    }

    this.showUsageModal = true;
    this.isLoadingUsage = true;
    this.usageResults = [];
    this.usageServiceErrors = { apex: null, flow: null };
    this.hasPartialUsageResults = false;

    // 🎯 Call resilient orchestrator (fault-isolated services)
    findAllUsagesResilient({ configName: this.selectedConfig })
      .then((aggregated) => {
        this.isLoadingUsage = false;

        // Aggregate all successful results
        this.usageResults = aggregated.allResults || [];
        this.hasPartialUsageResults = aggregated.hasPartialResults;

        // Track service errors
        if (!aggregated.apexService.success) {
          this.usageServiceErrors.apex = aggregated.apexService.error;
          this.showWarningToast(
            "Apex Search Failed",
            aggregated.apexService.error
          );
        } else if (aggregated.apexService.data.length > 0) {
          this.showInfoToast(
            "Apex Search",
            `Found ${aggregated.apexService.data.length} reference(s) in Apex`
          );
        }

        if (!aggregated.flowService.success) {
          this.usageServiceErrors.flow = aggregated.flowService.error;
          this.showWarningToast(
            "Flow Search Failed",
            aggregated.flowService.error
          );
        } else if (aggregated.flowService.data.length > 0) {
          this.showInfoToast(
            "Flow Search",
            `Found ${aggregated.flowService.data.length} reference(s) in Flows`
          );
        }

        // Show partial results warning
        if (this.hasPartialUsageResults) {
          this.showWarningToast(
            "Partial Results",
            `Showing ${this.usageResults.length} available result(s). Some searches failed.`
          );
        } else if (this.usageResults.length === 0) {
          this.showInfoToast(
            "No References Found",
            "This configuration is not currently used in Apex or Flows."
          );
        }

        // Log the usage search for audit purposes
        logUsageSearch({
          configName: this.selectedConfig,
          resultCount: this.usageResults.length
        }).catch(() => {
          // Don't fail if logging fails - silent error
        });
      })
      .catch((error) => {
        this.showErrorToast(
          "Search Error",
          error.body?.message || "Failed to execute search orchestrator"
        );
        this.isLoadingUsage = false;
      });
  }

  // Helper: Show info toast
  showInfoToast(title, message) {
    // ✅ Clear previous toast to avoid stacking
    if (this._toastTimeout) {
      clearTimeout(this._toastTimeout);
    }

    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: "info",
        mode: "dismissible"
      })
    );

    this._toastTimeout = setTimeout(() => {
      this._toastTimeout = null;
    }, 3000);
  }

  // Helper: Show warning toast
  showWarningToast(title, message) {
    // ✅ Clear previous toast to avoid stacking
    if (this._toastTimeout) {
      clearTimeout(this._toastTimeout);
    }

    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: "warning",
        mode: "dismissible"
      })
    );

    this._toastTimeout = setTimeout(() => {
      this._toastTimeout = null;
    }, 3000);
  }

  // Close usage modal
  handleCloseUsageModal() {
    this.showUsageModal = false;
    this.usageResults = [];
  }

  // ============================================
  // Cache Management
  // ============================================
  handleOpenCacheModal() {
    this.showCacheModal = true;
    // Call open() on the modal after it renders
    requestAnimationFrame(() => {
      const modal = this.refs.cacheModal;
      if (modal) {
        modal.open();
      }
    });
  }

  handleCloseCacheModal() {
    // Close the modal child component first
    const modal = this.refs.cacheModal;
    if (modal) {
      modal.close();
    }
    // Then hide it from parent
    this.showCacheModal = false;
  }

  async handleClearCache(event) {
    const { configurations, results, users, recent } = event.detail;
    const cleared = [];

    try {
      // Clear configurations
      if (configurations) {
        await refreshApex(this.wiredConfigurationsResult);
        cleared.push(this.labels.clearConfigurationsLabel);
      }

      // Clear results
      if (results) {
        this.queryResults = [];
        this.hasResults = false;
        this.recordCount = 0;
        this.currentPage = 1;
        this.jsonOutput = "";
        cleared.push(this.labels.clearResultsLabel);
      }

      // Clear users
      if (users) {
        this.userOptions = [];
        await this.loadUsers(true); // Force refresh
        cleared.push(this.labels.clearUsersLabel);
      }

      // Clear recent selections
      if (recent) {
        this.selectedConfig = "";
        this.baseQuery = "";
        this.parameters = [];
        this.parameterValues = {};
        this.runAsUserId = "";
        this.runAsUserName = "";
        cleared.push(this.labels.clearRecentLabel);
      }

      // Show success toast
      if (cleared.length > 0) {
        const message = `${this.labels.cacheCleared}: ${this.labels.cacheClearedDetail.replace("{0}", cleared.join(", "))}`;
        this.showSuccessToast(message);
      }

      // Close modal after clearing
      this.handleCloseCacheModal();
    } catch (error) {
      this.showErrorToast(
        "Error",
        "Error clearing cache: " + error.body.message
      );
    }
  }

  get hasUsageResults() {
    return this.usageResults && this.usageResults.length > 0;
  }

  get selectedConfigEmpty() {
    return !this.selectedConfig;
  }

  get usageColumns() {
    return [
      {
        label: "Name",
        fieldName: "className",
        type: "text",
        wrapText: false
      },
      {
        label: "Type",
        fieldName: "metadataType",
        type: "text",
        initialWidth: 120
      },
      {
        label: "Line #",
        fieldName: "lineNumber",
        type: "number",
        initialWidth: 80
      },
      { label: "Code", fieldName: "codeLine", type: "text", wrapText: true }
    ];
  }

  // Handle new config input changes
  handleNewConfigChange(event) {
    const field = event.target.dataset.field;
    this.newConfig[field] = event.target.value;

    // Track if developer name was manually edited
    if (field === "developerName") {
      this.developerNameManuallyEdited = true;
    }

    // Auto-generate developer name from label (only if not manually edited)
    if (field === "label" && !this.developerNameManuallyEdited) {
      this.newConfig.developerName = event.target.value
        .replace(/[^a-zA-Z0-9]/g, "_")
        .replace(/^([^a-zA-Z])/, "Config_$1")
        .substring(0, 40); // Salesforce API name limit
    }

    // Note: Query validation now handled directly by jtConfigModal component
  }

  // Handle query preview event from modal (Modal now handles validation & preview)
  handleQueryPreview(event) {
    const { records, fields, recordCount } = event.detail;

    this.queryPreviewResults = records || [];
    
    if (fields && fields.length > 0) {
      this.queryPreviewColumns = fields.map((field) => ({
        label: this.formatLabel(field),
        fieldName: field,
        type: this.getFieldType(field)
      }));
    } else {
      this.queryPreviewColumns = [];
    }

    console.log("✅ Query preview updated from modal:", recordCount, "records");
  }

  // Save configuration (create or update)
  handleSaveConfiguration() {
    // Validate required fields
    if (
      !this.newConfig.label ||
      !this.newConfig.developerName ||
      !this.newConfig.baseQuery
    ) {
      this.showErrorToast(
        "Validation Error",
        "Label, Developer Name, and Base Query are required."
      );
      return;
    }

    if (!this.queryValidation.isValid) {
      this.showErrorToast(
        "Invalid Query",
        "Please fix the query syntax before saving."
      );
      return;
    }

    this.isSaving = true;

    const configData = {
      label: this.newConfig.label,
      developerName: this.newConfig.developerName,
      baseQuery: this.newConfig.baseQuery,
      bindings: this.newConfig.bindings,
      objectName: this.newConfig.objectName
    };

    // Choose create or update based on mode
    const saveMethod =
      this.configModalMode === "edit"
        ? updateConfiguration({
            originalDevName: this.originalDevName,
            ...configData
          })
        : createConfiguration(configData);

    const actionLabel = this.configModalMode === "edit" ? "Updated" : "Created";

    saveMethod
      .then((result) => {
        if (result.success) {
          this.showSuccessToast(`Configuration ${actionLabel}`, result.message);
          this.handleCloseCreateModal();

          // Refresh the configurations list using refreshApex
          return refreshApex(this.wiredConfigurationsResult);
        }
        this.showErrorToast(`${actionLabel} Failed`, result.errorMessage);
        return Promise.resolve();
      })
      .then(() => {
        // After refresh, show info toast
        this.showInfoToast(
          "List Updated",
          "Configuration list has been refreshed."
        );
      })
      .catch((error) => {
        this.showErrorToast(
          "Error",
          error.body?.message ||
            `Failed to ${this.configModalMode} configuration`
        );
      })
      .finally(() => {
        this.isSaving = false;
      });
  }

  // Disconnect polling on component destroy
  connectedCallback() {
    this.loadUsageTrackingSetting();
  }

  disconnectedCallback() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
    }
  }

  /**
   * @description Error boundary - Handles errors from child components
   * @param {Error} error - The error object
   * @param {String} stack - The error stack trace (unused in production)
   */
  errorCallback(error) {
    // Show user-friendly error without breaking the entire UI
    this.showWarningToast(
      "Component Error",
      `A component encountered an error: ${error.message}. Other features remain functional.`
    );
  }

  // Load usage tracking setting
  async loadUsageTrackingSetting() {
    try {
      this.usageTrackingEnabled = await getUsageTrackingSetting();
    } catch {
      this.usageTrackingEnabled = false;
    }
  }

  // Handle usage tracking toggle
  async handleUsageTrackingChange(event) {
    const enabled = event.target.checked;
    this.isUpdatingSettings = true;

    try {
      const success = await updateUsageTrackingSetting({ enabled });
      if (success) {
        this.usageTrackingEnabled = enabled;
        this.showSuccessToast(
          enabled ? "Usage tracking enabled" : "Usage tracking disabled"
        );
      }
    } catch (error) {
      this.showErrorToast(
        "Update Failed",
        error.body?.message || "Failed to update usage tracking setting"
      );
      // Revert checkbox
      event.target.checked = !enabled;
    } finally {
      this.isUpdatingSettings = false;
    }
  }

  // Computed property for showing usage link
  get showUsageLink() {
    return this.selectedConfig && this.usageTrackingEnabled;
  }

  // Computed property for showing edit button
  get showEditConfigButton() {
    return this.canCreateMetadata && this.selectedConfig;
  }

  // Navigate to Documentation tab
  handleGoToDocumentation(event) {
    event.preventDefault();
    // Navigate to Documentation tab in the app
    // This will use the NavigationMixin in a future enhancement
    // For now, show a toast with instructions
    this.showInfoToast(
      "Tooling API Setup",
      "Please check the Documentation tab for Tooling API configuration instructions."
    );
  }

  // Execute the query (entry point with risk assessment)
  handleExecuteQuery() {
    // ✅ FIX: Disable button IMMEDIATELY to prevent multiple clicks
    this.isLoading = true;

    if (!this.selectedConfig) {
      this.isLoading = false; // Re-enable if validation fails
      this.showErrorToast(
        "Configuration Required",
        "Please select a configuration first."
      );
      return;
    }

    // 🎯 SMART ROUTING: If runAsUserId is selected, use System.runAs() flow
    if (this.runAsUserId) {
      this.isLoading = false; // 🐛 FIX: Reset spinner - handleExecuteAsUserTest uses its own spinner (isRunningTest)
      this.handleExecuteAsUserTest(); // Use test class with System.runAs()
      return;
    }

    // 🚨 RISK ASSESSMENT: Check if query is dangerous before executing
    this.assessQueryRiskAndExecute();
  }

  // Assess query risk and show warning if necessary
  assessQueryRiskAndExecute() {
    this.isAssessingRisk = true;
    // Note: isLoading already set to true in handleExecuteQuery

    // Build bindings JSON (same logic as before)
    const bindingsToSend = this.buildBindingsJson();

    assessQueryRisk({
      devName: this.selectedConfig,
      bindingsJson: bindingsToSend
    })
      .then((assessment) => {
        this.queryRiskAssessment = assessment;

        // If critical risk (>50K) → MUST use batch processing
        if (assessment.isCriticalRisk) {
          this.showRiskWarningModal = true;
          this.pendingExecutionMode = "batch"; // Force batch mode
        }
        // If high risk (>10K) → Recommend batch processing
        else if (assessment.isHighRisk || assessment.recommendBatchProcessing) {
          this.showRiskWarningModal = true;
          this.pendingExecutionMode = "batch"; // Suggest batch mode
        }
        // Low risk → Execute normally
        else {
          this.executeQueryNormal();
        }
      })
      .catch(() => {
        // If assessment fails, proceed with caution (execute normally)
        this.executeQueryNormal();
      })
      .finally(() => {
        this.isAssessingRisk = false;
      });
  }

  // Build bindings JSON (extracted from handleExecuteQuery)
  buildBindingsJson() {
    let bindingsToSend;

    if (this.hasBindings && !this.hasParameters) {
      // Use bindings from configuration
      bindingsToSend = this.bindings;
    } else if (this.hasParameters) {
      // Use parameter values entered by user
      const paramValues = this.parameterValues || {};
      const hasAnyValues = Object.keys(paramValues).some(
        (key) =>
          paramValues[key] !== "" &&
          paramValues[key] !== null &&
          paramValues[key] !== undefined
      );

      if (!hasAnyValues && this.hasBindings) {
        // Parameters are empty but config has bindings → Use config bindings
        bindingsToSend = this.bindings;
      } else if (!hasAnyValues && !this.hasBindings) {
        // No values and no config bindings → Send empty object
        bindingsToSend = JSON.stringify({});
      } else {
        // Has values → Use parameter values
        bindingsToSend = JSON.stringify(paramValues);
      }
    } else {
      bindingsToSend = null;
    }

    return bindingsToSend;
  }

  // Execute query normally (without batch processing)
  executeQueryNormal() {
    // Note: isLoading already set to true in handleExecuteQuery
    this.showError = false;
    this.resetResults();

    const bindingsToSend = this.buildBindingsJson();

    executeQuery({
      devName: this.selectedConfig,
      bindingsJson: bindingsToSend,
      runAsUserId: this.runAsUserId || null
    })
      .then((result) => {
        if (result.success) {
          this.processQueryResults(result);
          let successMsg = `Found ${result.recordCount} record(s)`;
          if (result.runAsUserName) {
            successMsg += ` (Run As: ${result.runAsUserName})`;
          }
          this.showSuccessToast(successMsg);
        } else {
          this.showError = true;
          this.errorMessage = result.errorMessage;
          this.showErrorToast("Query Error", result.errorMessage);
        }
      })
      .catch((error) => {
        this.showError = true;
        this.errorMessage = error.body?.message || "Unknown error occurred";
        this.showErrorToast("Execution Error", this.errorMessage);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  // Execute query with batch processing (for large result sets)
  executeQueryWithBatches() {
    // Note: isLoading already set to true in handleExecuteQuery
    this.showError = false;
    this.resetResults();

    const bindingsToSend = this.buildBindingsJson();

    executeQueryWithBatchProcessing({
      devName: this.selectedConfig,
      bindingsJson: bindingsToSend,
      batchSize: 200 // Process 200 records at a time
    })
      .then((result) => {
        if (result.success) {
          this.processQueryResults(result);
          // 🐛 BUG: This creates duplicate toast with normal processQueryResults
          // this.showSuccessToast(
          //   `Found ${result.recordCount} record(s) (Batch Processing)`
          // );
        } else {
          this.showError = true;
          this.errorMessage = result.errorMessage;
          this.showErrorToast("Query Error", result.errorMessage);
        }
      })
      .catch((error) => {
        this.showError = true;
        this.errorMessage = error.body?.message || "Unknown error occurred";
        this.showErrorToast("Execution Error", this.errorMessage);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  // Handle risk warning modal actions
  handleProceedWithBatch() {
    this.showRiskWarningModal = false;
    this.executeQueryWithBatches();
  }

  handleProceedNormal() {
    this.showRiskWarningModal = false;
    this.executeQueryNormal();
  }

  handleCancelExecution() {
    this.showRiskWarningModal = false;
    this.isLoading = false;
    this.showInfoToast("Execution Cancelled", "Query execution was cancelled.");
  }

  // Process query results for datatable
  processQueryResults(result) {
    this.recordCount = result.recordCount;

    // Always build columns (even with 0 records)
    if (result.fields && result.fields.length > 0) {
      this.columns = result.fields.map((field) => ({
        label: this.formatLabel(field),
        fieldName: field,
        type: this.getFieldType(field)
      }));
    }

    if (result.recordCount > 0) {
      // ✅ Pass records as-is to preserve child relationships
      this.queryResults = result.records;

      this.hasResults = true;
      this.resetPagination(); // Initialize pagination
      this.showSuccessToast(`Found ${result.recordCount} record(s)`);
    } else {
      // Show empty table with columns
      this.queryResults = [];
      this.hasResults = true; // Changed: show table even with 0 results
      this.resetPagination();
      this.showInfoToast("No Results", "Query returned no records.");
    }
  }

  // Determine field type for datatable
  getFieldType(fieldName) {
    const lowerField = fieldName.toLowerCase();
    if (lowerField === "id" || lowerField.endsWith("id")) return "text";
    if (lowerField.includes("date") || lowerField.includes("time"))
      return "date";
    if (lowerField.includes("email")) return "email";
    if (lowerField.includes("phone")) return "phone";
    if (lowerField.includes("url") || lowerField.includes("website"))
      return "url";
    if (lowerField.includes("amount") || lowerField.includes("price"))
      return "currency";
    return "text";
  }

  // Reset results
  resetResults() {
    this.queryResults = [];
    this.columns = [];
    this.recordCount = 0;
    this.hasResults = false;
    this.showError = false;
    this.errorMessage = "";
    this.expandedCards.clear();
    this.viewMode = { table: true, json: false, csv: false };
  }

  // Handle view mode change (Table/JSON/CSV)
  handleViewChange(event) {
    const view = event.currentTarget.dataset.view;
    this.viewMode = {
      table: view === "table",
      json: view === "json",
      csv: view === "csv"
    };

    if (view === "json") {
      this.generateJsonOutput();
    } else if (view === "csv") {
      // CSV view is just a download prompt, no generation here
      this.jsonOutput = "";
    }
  }

  // Handle card expand/collapse toggle
  handleCardToggle(event) {
    const recordId = event.currentTarget.dataset.id;
    if (this.expandedCards.has(recordId)) {
      this.expandedCards.delete(recordId);
    } else {
      this.expandedCards.add(recordId);
    }
    // Force re-render of paginated results
    this.queryResults = [...this.queryResults];
  }

  // Generate JSON output
  generateJsonOutput() {
    try {
      const output = {
        metadata: {
          totalRecords: this.recordCount,
          fields: this.columns.map((col) => col.fieldName),
          objectType: this.objectName || "Unknown",
          exportDate: new Date().toISOString()
        },
        records: this.queryResults
      };
      this.jsonOutput = JSON.stringify(output, null, 2);
    } catch (error) {
      this.showErrorToast("JSON Error", "Failed to generate JSON output");
      this.jsonOutput = "{}";
    }
  }

  // Copy JSON to clipboard
  handleCopyJson() {
    if (navigator.clipboard && this.jsonOutput) {
      navigator.clipboard
        .writeText(this.jsonOutput)
        .then(() => {
          this.showSuccessToast("JSON copied to clipboard");
        })
        .catch(() => {
          this.showErrorToast(
            "Copy Failed",
            "Could not copy JSON to clipboard"
          );
        });
    }
  }

  // Download CSV
  handleDownloadCsv() {
    try {
      if (!this.queryResults || this.queryResults.length === 0) {
        this.showErrorToast("No Data", "No records to export");
        return;
      }

      // Generate CSV content
      const headers = this.columns.map((col) => col.label).join(",");
      const rows = this.queryResults.map((row) => {
        return this.columns
          .map((col) => {
            const value = row[col.fieldName] || "";
            // Escape commas and quotes in CSV
            const escaped = String(value).replace(/"/g, '""');
            return `"${escaped}"`;
          })
          .join(",");
      });
      const csvContent = [headers, ...rows].join("\n");

      // Create and download file
      const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
      const link = document.createElement("a");
      const url = URL.createObjectURL(blob);
      link.setAttribute("href", url);
      link.setAttribute(
        "download",
        `query_results_${new Date().getTime()}.csv`
      );
      link.style.visibility = "hidden";
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      this.showSuccessToast("CSV downloaded successfully");
    } catch (error) {
      this.showErrorToast("CSV Error", "Failed to generate CSV file");
    }
  }

  // Toast notifications with screen reader announcements
  showSuccessToast(message) {
    // ✅ Clear previous toast to avoid stacking
    if (this._toastTimeout) {
      clearTimeout(this._toastTimeout);
    }

    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message: message,
        variant: "success",
        mode: "dismissible"
      })
    );

    this._toastTimeout = setTimeout(() => {
      this._toastTimeout = null;
    }, 3000);

    this.announceToScreenReader(`Success: ${message}`);
  }

  showErrorToast(title, message) {
    // ✅ Clear previous toast to avoid stacking
    if (this._toastTimeout) {
      clearTimeout(this._toastTimeout);
    }

    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: "error",
        mode: "dismissible"
      })
    );

    this._toastTimeout = setTimeout(() => {
      this._toastTimeout = null;
    }, 3000);

    this.announceToScreenReader(`Error: ${title}. ${message}`, true);
  }

  showInfoToast(title, message) {
    // ✅ Clear previous toast to avoid stacking
    if (this._toastTimeout) {
      clearTimeout(this._toastTimeout);
    }

    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: "info",
        mode: "dismissible"
      })
    );

    this._toastTimeout = setTimeout(() => {
      this._toastTimeout = null;
    }, 3000);

    this.announceToScreenReader(`${title}: ${message}`);
  }

  // Announce to screen readers
  announceToScreenReader(message) {
    this.srAnnouncement = message;
    // Clear after announcement to allow repeat announcements
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      this.srAnnouncement = "";
    }, 100);
  }
}
