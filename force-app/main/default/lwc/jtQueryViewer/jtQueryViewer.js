import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getLabels } from './labels';
import getConfigurations from '@salesforce/apex/JT_QueryViewerController.getConfigurations';
import extractParameters from '@salesforce/apex/JT_QueryViewerController.extractParameters';
import executeQuery from '@salesforce/apex/JT_QueryViewerController.executeQuery';
import canUseRunAs from '@salesforce/apex/JT_QueryViewerController.canUseRunAs';
import getAllActiveUsers from '@salesforce/apex/JT_QueryViewerController.getAllActiveUsers';
import executeAsUser from '@salesforce/apex/JT_RunAsTestExecutor.executeAsUser';
import getTestResults from '@salesforce/apex/JT_RunAsTestExecutor.getTestResults';
import canUseRunAsTest from '@salesforce/apex/JT_RunAsTestExecutor.canUseRunAsTest';
import isSandboxOrScratch from '@salesforce/apex/JT_MetadataCreator.isSandboxOrScratch';
import getOrgInfo from '@salesforce/apex/JT_MetadataCreator.getOrgInfo';
import createConfiguration from '@salesforce/apex/JT_MetadataCreator.createConfiguration';
import updateConfiguration from '@salesforce/apex/JT_MetadataCreator.updateConfiguration';
import validateQuery from '@salesforce/apex/JT_MetadataCreator.validateQuery';
import getProductionEditingSetting from '@salesforce/apex/JT_ProductionSettingsController.getProductionEditingSetting';
import updateProductionEditingSetting from '@salesforce/apex/JT_ProductionSettingsController.updateProductionEditingSetting';
import findConfigurationUsage from '@salesforce/apex/JT_UsageFinder.findConfigurationUsage';

export default class JtQueryViewer extends LightningElement {
    @track selectedConfig = '';
    @track configSearchTerm = '';
    @track showConfigDropdown = false;
    @track filteredConfigs = [];
    @track baseQuery = '';
    @track bindings = '';
    @track parameters = [];
    @track parameterValues = {};
    @track queryResults = [];
    @track columns = [];
    @track recordCount = 0;
    @track isLoading = false;
    @track hasResults = false;
    @track errorMessage = '';
    @track currentPage = 1;
    @track pageSize = 10;
    @track totalPages = 1;
    @track showError = false;
    @track objectName = '';
    @track showRunAs = false;
    @track runAsUserId = '';
    @track runAsUserName = '';
    @track userSearchTerm = '';
    @track showUserDropdown = false;
    @track filteredUsers = [];
    @track allUsers = []; // All active users loaded once
    @track isLoadingUsers = false;
    @track showRunAsTest = false;
    @track isRunningTest = false;
    @track testJobId = '';
    @track testAssertMessage = '';
    @track showTestResults = false;
    @track showCreateModal = false;
    @track isEditMode = false;
    @track canCreateMetadata = false;
    @track showUsageModal = false;
    @track usageResults = [];
    @track isLoadingUsage = false;
    @track productionOverrideEnabled = false;
    @track isUpdatingSettings = false;
    @track orgInfo = {};
    @track newConfig = {
        label: '',
        developerName: '',
        baseQuery: '',
        bindings: '',
        objectName: ''
    };
    @track originalDevName = ''; // For edit mode
    @track queryValidation = { isValid: false, message: '' };
    @track isSaving = false;

    configurationOptions = [];
    wiredConfigurationsResult;
    searchTimeout;
    pollInterval;
    labels = getLabels();

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
                    ? 'Production editing enabled. Please refresh the page to see changes.'
                    : 'Production editing disabled. Please refresh the page.'
                );

                // Refresh org info
                return refreshApex(this.wiredConfigurationsResult);
            })
            .catch(error => {
                this.showErrorToast('Error updating settings', error.body?.message);
                // Revert checkbox
                this.productionOverrideEnabled = !enabled;
            })
            .finally(() => {
                this.isUpdatingSettings = false;
            });
    }

    get orgTypeBadge() {
        if (!this.orgInfo) return '';
        const orgType = this.orgInfo.organizationType || '';

        if (this.orgInfo.isSandbox) return 'Sandbox';
        if (this.orgInfo.isScratch) return 'Scratch Org';
        if (orgType === 'Developer Edition') return 'Developer';

        // All other orgs are considered production (including Starter/Free)
        return 'Production';
    }

    get orgTypeBadgeTitle() {
        return `This is a ${this.orgTypeBadge} environment - metadata editing is allowed`;
    }

    // Wire to check if user can use Run As feature
    @wire(canUseRunAs)
    wiredCanUseRunAs({ error, data }) {
        if (data) {
            this.showRunAs = data;
            // Load all users when Run As is available
            if (data && this.allUsers.length === 0) {
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
            .then(users => {
                this.allUsers = users.map(user => ({
                    label: user.label,
                    value: user.value
                }));
                this.filteredUsers = [...this.allUsers]; // Initialize filtered list
            })
            .catch(error => {
                this.showErrorToast('Error Loading Users', error.body?.message || 'Failed to load users');
                this.allUsers = [];
                this.filteredUsers = [];
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
        if (!this.baseQuery) return '';
        return this.baseQuery;
    }

    get hasBindings() {
        return this.bindings && this.bindings.trim() !== '';
    }

    get showResults() {
        return this.hasResults && !this.isLoading;
    }

    get configComboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.showConfigDropdown ? 'slds-is-open' : ''}`;
    }

    get userComboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.showUserDropdown ? 'slds-is-open' : ''}`;
    }

    get hasFilteredConfigs() {
        return this.filteredConfigs && this.filteredConfigs.length > 0;
    }

    get hasFilteredUsers() {
        return this.filteredUsers && this.filteredUsers.length > 0;
    }

    get recordCountLabel() {
        return this.recordCount !== 1 ? this.labels.records : this.labels.record;
    }

    // Pagination computed properties
    get paginatedResults() {
        if (!this.queryResults || this.queryResults.length === 0) {
            return [];
        }
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.queryResults.slice(start, end);
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
        return this.queryResults.length > 0 ? ((this.currentPage - 1) * this.pageSize) + 1 : 0;
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
    // Configuration dropdown handlers
    handleConfigInput(event) {
        this.configSearchTerm = event.target.value;
        this.filterConfigs();
        this.showConfigDropdown = true;
    }

    handleConfigFocus() {
        this.filterConfigs();
        this.showConfigDropdown = true;
    }

    handleConfigBlur() {
        // Delay to allow click on option
        setTimeout(() => {
            this.showConfigDropdown = false;
        }, 200);
    }

    handleConfigToggle() {
        this.showConfigDropdown = !this.showConfigDropdown;
        if (this.showConfigDropdown) {
            this.filterConfigs();
        }
    }

    filterConfigs() {
        const term = (this.configSearchTerm || '').toLowerCase();
        if (!this.configurationOptions || this.configurationOptions.length === 0) {
            this.filteredConfigs = [];
            return;
        }
        
        if (!term) {
            this.filteredConfigs = [...this.configurationOptions];
        } else {
            this.filteredConfigs = this.configurationOptions.filter(opt =>
                opt.label && opt.label.toLowerCase().includes(term)
            );
        }
    }

    handleConfigSelect(event) {
        const value = event.currentTarget.dataset.value;
        const selected = this.configurationOptions.find(opt => opt.value === value);

        if (selected) {
            this.selectedConfig = selected.value;
            this.configSearchTerm = selected.label;
            this.showConfigDropdown = false;

            this.baseQuery = selected.baseQuery;
            this.bindings = selected.bindings;
            this.objectName = selected.objectName;

            // Only extract parameters if bindings are NOT predefined
            if (!this.hasBindings) {
                this.extractQueryParameters();
            } else {
                // Clear parameters if bindings are predefined
                this.parameters = [];
                this.parameterValues = {};
            }

            this.resetResults();
        }
    }

    // Extract parameters from the query
    extractQueryParameters() {
        if (this.baseQuery) {
            extractParameters({ query: this.baseQuery })
                .then(result => {
                    console.log('Extracted parameters:', result);
                    this.parameters = result.map(param => ({
                        name: param,
                        label: param, // Use exact parameter name from SOQL
                        value: ''
                    }));
                    this.parameterValues = {};
                    console.log('Parameters array:', this.parameters);
                })
                .catch(error => {
                    console.error('Error extracting parameters:', error);
                    this.showErrorToast('Error extracting parameters', error.body?.message);
                });
        }
    }

    // Format parameter name to readable label
    formatLabel(paramName) {
        return paramName
            .replace(/([A-Z])/g, ' $1')
            .replace(/_/g, ' ')
            .replace(/^\w/, c => c.toUpperCase())
            .trim();
    }

    // Handle parameter input change
    handleParameterChange(event) {
        const paramName = event.target.dataset.param;
        this.parameterValues[paramName] = event.target.value;
    }

    // Handle user selection from dropdown
    // User dropdown handlers
    handleUserInput(event) {
        this.userSearchTerm = event.target.value;
        this.filterUsers();
        this.showUserDropdown = true;
    }

    handleUserFocus() {
        this.filterUsers();
        this.showUserDropdown = true;
    }

    handleUserBlur() {
        // Delay to allow click on option
        setTimeout(() => {
            this.showUserDropdown = false;
        }, 200);
    }

    handleUserToggle() {
        this.showUserDropdown = !this.showUserDropdown;
        if (this.showUserDropdown) {
            this.filterUsers();
        }
    }

    filterUsers() {
        const term = (this.userSearchTerm || '').toLowerCase();
        if (!this.allUsers || this.allUsers.length === 0) {
            this.filteredUsers = [];
            return;
        }
        
        if (!term) {
            this.filteredUsers = [...this.allUsers];
        } else {
            this.filteredUsers = this.allUsers.filter(user =>
                user.label && user.label.toLowerCase().includes(term)
            );
        }
    }

    handleUserSelect(event) {
        const value = event.currentTarget.dataset.value;
        const selected = this.allUsers.find(u => u.value === value);

        if (selected) {
            this.runAsUserId = selected.value;
            this.runAsUserName = selected.label;
            this.userSearchTerm = selected.label;
            this.showUserDropdown = false;
        }
    }

    // Clear Run As user
    handleClearRunAs() {
        this.runAsUserId = '';
        this.runAsUserName = '';
    }

    // Execute query with true System.runAs (test context)
    handleExecuteAsUserTest() {
        if (!this.selectedConfig) {
            this.showErrorToast('Configuration Required', 'Please select a configuration first.');
            return;
        }

        if (!this.runAsUserId) {
            this.showErrorToast('User Required', 'Please select a user to run as.');
            return;
        }

        this.isRunningTest = true;
        this.showError = false;
        this.resetResults();
        this.testAssertMessage = '';

        // Build bindings JSON
        let bindingsToSend = this.buildBindingsJson();

        executeAsUser({
            userId: this.runAsUserId,
            configName: this.selectedConfig,
            bindingsJson: bindingsToSend
        })
            .then(result => {
                if (result.success) {
                    this.testJobId = result.jobId;
                    this.showInfoToast(
                        'Test Execution Started',
                        result.message || 'Polling for results...'
                    );
                    // Start polling for results
                    this.startPollingTestResults();
                } else {
                    this.showError = true;
                    this.errorMessage = result.errorMessage;
                    this.showErrorToast('Test Execution Error', result.errorMessage);
                    this.isRunningTest = false;
                }
            })
            .catch(error => {
                this.showError = true;
                this.errorMessage = error.body?.message || 'Unknown error occurred';
                this.showErrorToast('Execution Error', this.errorMessage);
                this.isRunningTest = false;
            });
    }

    // Build bindings JSON helper
    buildBindingsJson() {
        if (this.hasBindings && !this.hasParameters) {
            return this.bindings;
        } else if (this.hasParameters) {
            return JSON.stringify(this.parameterValues);
        }
        return null;
    }

    // Start polling for test results
    startPollingTestResults() {
        let pollCount = 0;
        const maxPolls = 30; // 60 seconds max (2 sec intervals)

        this.pollInterval = setInterval(() => {
            pollCount++;

            getTestResults({ userId: this.runAsUserId })
                .then(result => {
                    if (result.success !== undefined) {
                        // Results are ready
                        clearInterval(this.pollInterval);
                        this.handleTestResults(result);
                    } else if (pollCount >= maxPolls) {
                        // Timeout
                        clearInterval(this.pollInterval);
                        this.isRunningTest = false;
                        this.showErrorToast('Timeout', 'Test execution timed out after 60 seconds.');
                    }
                    // Keep polling if no results yet
                })
                .catch(error => {
                    clearInterval(this.pollInterval);
                    this.isRunningTest = false;
                    this.showErrorToast('Polling Error', error.body?.message);
                });
        }, 2000); // Poll every 2 seconds
    }

    // Handle test results
    handleTestResults(result) {
        this.isRunningTest = false;
        this.testAssertMessage = result.assertMessage || '';

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
            this.errorMessage = result.errorMessage || 'Test execution failed';
            this.showErrorToast('Test Failed', this.errorMessage);
        }
    }

    // Process test query results for display
    processTestQueryResults(result) {
        this.recordCount = result.recordCount || 0;

        // Always build columns (even with 0 records)
        const fields = result.fields || (result.records && result.records.length > 0 ? Object.keys(result.records[0]) : []);

        if (fields.length > 0) {
            this.columns = fields.map(field => ({
                label: this.formatLabel(field),
                fieldName: field,
                type: this.getFieldType(field)
            }));
        }

        if (this.recordCount > 0 && result.records) {
            // Transform records for datatable
            this.queryResults = result.records.map((record, index) => {
                const row = { Id: record.Id || `temp_${index}` };
                fields.forEach(field => {
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
            this.hasResults = true; // Changed: show table even with 0 results
            this.showTestResults = true; // Changed: show section
            this.resetPagination();
            this.showInfoToast('No Results', 'Test query returned no records.');
        }
    }

    // Show create configuration modal
    handleShowCreateModal() {
        this.showCreateModal = true;
        this.resetNewConfig();
    }

    // Hide create configuration modal
    handleCloseCreateModal() {
        this.showCreateModal = false;
        this.resetNewConfig();
    }

    // Reset new configuration form
    resetNewConfig() {
        this.newConfig = {
            label: '',
            developerName: '',
            baseQuery: '',
            bindings: '',
            objectName: ''
        };
        this.queryValidation = { isValid: false, message: '' };
    }

    // Show usage modal
    handleShowUsageModal() {
        if (!this.selectedConfig) {
            this.showErrorToast('No Configuration Selected', 'Please select a configuration first');
            return;
        }

        this.showUsageModal = true;
        this.isLoadingUsage = true;
        this.usageResults = [];

        findConfigurationUsage({ configName: this.selectedConfig })
            .then(results => {
                this.usageResults = results;
                this.isLoadingUsage = false;
            })
            .catch(error => {
                this.showErrorToast('Error Finding Usage', error.body?.message || 'Failed to find configuration usage');
                this.isLoadingUsage = false;
            });
    }

    // Close usage modal
    handleCloseUsageModal() {
        this.showUsageModal = false;
        this.usageResults = [];
    }

    get hasUsageResults() {
        return this.usageResults && this.usageResults.length > 0;
    }

    get selectedConfigEmpty() {
        return !this.selectedConfig;
    }

    get usageColumns() {
        return [
            { label: 'Apex Class', fieldName: 'className', type: 'text', wrapText: false },
            { label: 'Line #', fieldName: 'lineNumber', type: 'number', initialWidth: 80 },
            { label: 'Code', fieldName: 'codeLine', type: 'text', wrapText: true }
        ];
    }

    // Handle new config input changes
    handleNewConfigChange(event) {
        const field = event.target.dataset.field;
        this.newConfig[field] = event.target.value;

        // Auto-generate developer name from label
        if (field === 'label' && !this.newConfig.developerName) {
            this.newConfig.developerName = event.target.value
                .replace(/[^a-zA-Z0-9]/g, '_')
                .replace(/^([^a-zA-Z])/, 'Config_$1');
        }

        // Validate query when it changes
        if (field === 'baseQuery') {
            this.validateQuerySyntax();
        }
    }

    // Validate query syntax
    validateQuerySyntax() {
        if (!this.newConfig.baseQuery) {
            this.queryValidation = { isValid: false, message: '' };
            return;
        }

        validateQuery({ query: this.newConfig.baseQuery })
            .then(result => {
                this.queryValidation = result;
                if (result.isValid && result.objectName) {
                    this.newConfig.objectName = result.objectName;
                }
            })
            .catch(error => {
                this.queryValidation = {
                    isValid: false,
                    message: error.body?.message || 'Invalid SOQL query. Please check syntax and try again.'
                };
            });
    }

    // Save new configuration
    handleSaveConfiguration() {
        // Validate required fields
        if (!this.newConfig.label || !this.newConfig.developerName || !this.newConfig.baseQuery) {
            this.showErrorToast('Validation Error', 'Label, Developer Name, and Base Query are required.');
            return;
        }

        if (!this.queryValidation.isValid) {
            this.showErrorToast('Invalid Query', 'Please fix the query syntax before saving.');
            return;
        }

        this.isSaving = true;

        createConfiguration({
            label: this.newConfig.label,
            developerName: this.newConfig.developerName,
            baseQuery: this.newConfig.baseQuery,
            bindings: this.newConfig.bindings,
            objectName: this.newConfig.objectName
        })
            .then(result => {
                if (result.success) {
                    this.showSuccessToast('Configuration Created', result.message);
                    this.handleCloseCreateModal();

                    // Refresh the configurations list using refreshApex
                    return refreshApex(this.wiredConfigurationsResult);
                } else {
                    this.showErrorToast('Creation Failed', result.errorMessage);
                }
            })
            .then(() => {
                // After refresh, show info toast
                this.showInfoToast('List Updated', 'Configuration list has been refreshed.');
            })
            .catch(error => {
                this.showErrorToast('Error', error.body?.message || 'Failed to create configuration');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    // Disconnect polling on component destroy
    disconnectedCallback() {
        if (this.pollInterval) {
            clearInterval(this.pollInterval);
        }
    }

    // Execute the query
    handleExecuteQuery() {
        if (!this.selectedConfig) {
            this.showErrorToast('Configuration Required', 'Please select a configuration first.');
            return;
        }

        this.isLoading = true;
        this.showError = false;
        this.resetResults();

        // Build bindings JSON
        let bindingsToSend;
        if (this.hasBindings && !this.hasParameters) {
            // Use bindings from configuration
            bindingsToSend = this.bindings;
        } else if (this.hasParameters) {
            // Use parameter values entered by user
            bindingsToSend = JSON.stringify(this.parameterValues);
        } else {
            bindingsToSend = null;
        }

        executeQuery({
            devName: this.selectedConfig,
            bindingsJson: bindingsToSend,
            runAsUserId: this.runAsUserId || null
        })
            .then(result => {
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
                    this.showErrorToast('Query Error', result.errorMessage);
                }
            })
            .catch(error => {
                this.showError = true;
                this.errorMessage = error.body?.message || 'Unknown error occurred';
                this.showErrorToast('Execution Error', this.errorMessage);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Process query results for datatable
    processQueryResults(result) {
        this.recordCount = result.recordCount;

        // Always build columns (even with 0 records)
        if (result.fields && result.fields.length > 0) {
            this.columns = result.fields.map(field => ({
                label: this.formatLabel(field),
                fieldName: field,
                type: this.getFieldType(field)
            }));
        }

        if (result.recordCount > 0) {
            // Transform records for datatable
            this.queryResults = result.records.map(record => {
                const row = { Id: record.Id };
                result.fields.forEach(field => {
                    row[field] = record[field];
                });
                return row;
            });

            this.hasResults = true;
            this.resetPagination(); // Initialize pagination
            this.showSuccessToast(`Found ${result.recordCount} record(s)`);
        } else {
            // Show empty table with columns
            this.queryResults = [];
            this.hasResults = true; // Changed: show table even with 0 results
            this.resetPagination();
            this.showInfoToast('No Results', 'Query returned no records.');
        }
    }

    // Determine field type for datatable
    getFieldType(fieldName) {
        const lowerField = fieldName.toLowerCase();
        if (lowerField === 'id' || lowerField.endsWith('id')) return 'text';
        if (lowerField.includes('date') || lowerField.includes('time')) return 'date';
        if (lowerField.includes('email')) return 'email';
        if (lowerField.includes('phone')) return 'phone';
        if (lowerField.includes('url') || lowerField.includes('website')) return 'url';
        if (lowerField.includes('amount') || lowerField.includes('price')) return 'currency';
        return 'text';
    }

    // Reset results
    resetResults() {
        this.queryResults = [];
        this.columns = [];
        this.recordCount = 0;
        this.hasResults = false;
        this.showError = false;
        this.errorMessage = '';
    }

    // Toast notifications with screen reader announcements
    showSuccessToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        }));
        this.announceToScreenReader(`Success: ${message}`);
    }

    showErrorToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
            mode: 'sticky'
        }));
        this.announceToScreenReader(`Error: ${title}. ${message}`, true);
    }

    showInfoToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'info'
        }));
        this.announceToScreenReader(`${title}: ${message}`);
    }

    // Announce to screen readers
    announceToScreenReader(message, assertive = false) {
        this.srAnnouncement = message;
        // Clear after announcement to allow repeat announcements
        setTimeout(() => {
            this.srAnnouncement = '';
        }, 100);
    }
}

