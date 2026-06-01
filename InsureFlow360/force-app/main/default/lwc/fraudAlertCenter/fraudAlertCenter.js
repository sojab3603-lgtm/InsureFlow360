import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFraudAlerts from '@salesforce/apex/ClaimSelector.getFraudAlerts';
import updateClaimFraudStatus from '@salesforce/apex/ClaimService.updateClaimFraudStatus';

export default class FraudAlertCenter extends LightningElement {
    @track fraudAlerts = [];
    @track isLoading = false;
    @track error = null;
    @track selectedAlerts = [];
    @track filterStatus = 'all'; // all, high, medium

    fraudAlertsData;

    // Wire Apex method to fetch fraud alerts
    @wire(getFraudAlerts)
    wiredFraudAlerts(result) {
        this.fraudAlertsData = result;
        const { error, data } = result;
        if (data) {
            const enhancedAlerts = data.map(alert => ({
                ...alert,
                riskIcon: this.getRiskIcon(alert.Fraud_Status__c),
                riskClass: this.getRiskClass(alert.Fraud_Status__c),
                isSelected: false
            }));
            this.fraudAlerts = this.applyFilter(enhancedAlerts);
            this.error = null;
        } else if (error) {
            this.error = error.body.message;
            console.error('Error fetching fraud alerts:', error);
        }
    }

    applyFilter(data) {
        if (this.filterStatus === 'all') {
            return data;
        } else if (this.filterStatus === 'high') {
            return data.filter(alert => alert.Fraud_Status__c === 'High Risk');
        } else if (this.filterStatus === 'medium') {
            return data.filter(alert => alert.Fraud_Status__c === 'Medium Risk');
        }
        return data;
    }

    handleFilterChange(event) {
        this.filterStatus = event.detail.value;
        const enhancedAlerts = this.fraudAlertsData.data.map(alert => ({
            ...alert,
            riskIcon: this.getRiskIcon(alert.Fraud_Status__c),
            riskClass: this.getRiskClass(alert.Fraud_Status__c),
            isSelected: this.selectedAlerts.includes(alert.Id)
        }));
        this.fraudAlerts = this.applyFilter(enhancedAlerts);
    }

    handleSelectAlert(event) {
        const claimId = event.currentTarget.dataset.claimId;
        let updatedSelected = [];
        this.fraudAlerts = this.fraudAlerts.map(alert => {
            if (alert.Id === claimId) {
                alert.isSelected = !alert.isSelected;
            }
            if (alert.isSelected) {
                updatedSelected.push(alert.Id);
            }
            return alert;
        });
        this.selectedAlerts = updatedSelected;
    }

    handleReviewAlert(event) {
        const claimId = event.currentTarget.dataset.claimId;
        window.location.href = `/${claimId}`;
    }

    handleBulkAction(event) {
        const action = event.currentTarget.dataset.action;
        if (this.selectedAlerts.length === 0) {
            this.error = 'Please select at least one alert to perform an action';
            return;
        }

        this.isLoading = true;
        updateClaimFraudStatus({
            claimIds: this.selectedAlerts,
            status: action
        }).then(() => {
            this.selectedAlerts = [];
            return refreshApex(this.fraudAlertsData);
        }).then(() => {
            this.isLoading = false;
            this.showNotification('Success', `${action} action completed`, 'success');
        }).catch(error => {
            this.error = error.body.message;
            this.isLoading = false;
        });
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.fraudAlertsData).then(() => {
            this.isLoading = false;
        }).catch(error => {
            this.error = error.body.message;
            this.isLoading = false;
        });
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    get alertCount() {
        return this.fraudAlerts.length;
    }

    get selectAllChecked() {
        return this.selectedAlerts.length === this.fraudAlerts.length && 
               this.fraudAlerts.length > 0;
    }

    handleSelectAll(event) {
        if (event.target.checked) {
            this.selectedAlerts = this.fraudAlerts.map(alert => alert.Id);
        } else {
            this.selectedAlerts = [];
        }
    }

    getRiskClass(fraudStatus) {
        return fraudStatus === 'High Risk' ? 'risk-high' : 
               fraudStatus === 'Medium Risk' ? 'risk-medium' : 'risk-low';
    }

    getRiskIcon(fraudStatus) {
        return fraudStatus === 'High Risk' ? 'utility:warning' : 
               fraudStatus === 'Medium Risk' ? 'utility:info' : 'utility:success';
    }

    get filterOptions() {
        return [
            { label: 'All Alerts', value: 'all' },
            { label: 'High Risk', value: 'high' },
            { label: 'Medium Risk', value: 'medium' }
        ];
    }
}
