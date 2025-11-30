import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAuditLogs from '@salesforce/apex/JT_ProductionSettingsController.getAuditLogs';
import { getLabels } from './labels';

export default class JtAuditHistory extends LightningElement {
    @track auditLogs = [];
    @track error;
    wiredLogsResult;
    labels = getLabels();

    get columns() {
        return [
            { 
                label: this.labels.dateTime, 
                fieldName: 'JT_Timestamp__c', 
                type: 'date',
                typeAttributes: {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: false
                },
                sortable: true,
                initialWidth: 180
            },
            { 
                label: this.labels.action, 
                fieldName: 'JT_Action__c', 
                type: 'text',
                cellAttributes: {
                    class: { fieldName: 'actionClass' }
                },
                initialWidth: 120
            },
            { 
                label: this.labels.changedBy, 
                fieldName: 'changedByName', 
                type: 'text',
                initialWidth: 200
            },
            { 
                label: this.labels.username, 
                fieldName: 'JT_ChangedByUsername__c', 
                type: 'text',
                initialWidth: 250
            },
            { 
                label: this.labels.orgType, 
                fieldName: 'JT_OrgType__c', 
                type: 'text',
                initialWidth: 150
            },
            { 
                label: this.labels.ipAddress, 
                fieldName: 'JT_IPAddress__c', 
                type: 'text',
                initialWidth: 150
            }
        ];
    }

    @wire(getAuditLogs)
    wiredLogs(result) {
        this.wiredLogsResult = result;
        const { data, error } = result;

        if (data) {
            this.auditLogs = data.map(log => ({
                ...log,
                changedByName: log.JT_ChangedByUsername__c,
                actionClass: log.JT_Action__c === 'Enabled' ? 'slds-text-color_success' : 'slds-text-color_error'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.auditLogs = [];
        }
    }

    get hasLogs() {
        return this.auditLogs && this.auditLogs.length > 0;
    }

    get logCount() {
        return this.auditLogs ? this.auditLogs.length : 0;
    }

    handleRefresh() {
        refreshApex(this.wiredLogsResult);
    }
}

