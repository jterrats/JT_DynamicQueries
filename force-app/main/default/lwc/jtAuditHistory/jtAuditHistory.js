import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class JtAuditHistory extends NavigationMixin(LightningElement) {
    connectedCallback() {
        // Navigate to the object's list view
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'JT_SettingsAuditLog__c',
                actionName: 'list'
            },
            state: {
                filterName: 'Recent'
            }
        });
    }
}

