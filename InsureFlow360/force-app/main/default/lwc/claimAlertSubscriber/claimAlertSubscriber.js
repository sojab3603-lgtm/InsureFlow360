import { LightningElement, wire, track } from 'lwc';
import { subscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import ClaimAlertChannel from '@salesforce/messageChannel/ClaimAlertChannel__c';

export default class ClaimAlertSubscriber extends LightningElement {
    @track receivedAlerts = [];
    @track isLoading = false;
    @track error = null;

    @wire(MessageContext)
    messageContext;

    subscription = null;

    connectedCallback() {
        this.subscribeToMessages();
    }

    disconnectedCallback() {
        if (this.subscription) {
            this.subscription.unsubscribe();
            this.subscription = null;
        }
    }

    subscribeToMessages() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                ClaimAlertChannel,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    handleMessage(message) {
        if (message) {
            // Create a new alert entry with timestamp
            const alert = {
                id: Date.now() + Math.random(), // Unique ID for list rendering
                claimId: message.claimId,
                claimName: message.claimName,
                claimAmount: message.claimAmount,
                fraudStatus: message.fraudStatus,
                fraudScore: message.fraudScore,
                eventType: message.eventType,
                timestamp: new Date().toLocaleTimeString(),
                isNew: true,
                riskIcon: this.getRiskIcon(message.fraudStatus),
                riskIconClass: this.getRiskIconClass(message.fraudStatus)
            };

            // Add to the beginning of the list
            this.receivedAlerts = [alert, ...this.receivedAlerts];

            // Keep only the last 50 alerts
            if (this.receivedAlerts.length > 50) {
                this.receivedAlerts = this.receivedAlerts.slice(0, 50);
            }

            // Remove "new" badge after 3 seconds
            setTimeout(() => {
                const index = this.receivedAlerts.findIndex(a => a.id === alert.id);
                if (index >= 0) {
                    const updatedAlerts = [...this.receivedAlerts];
                    updatedAlerts[index].isNew = false;
                    this.receivedAlerts = updatedAlerts;
                }
            }, 3000);
        }
    }

    handleClear() {
        this.receivedAlerts = [];
    }

    navigateToClaim(event) {
        const claimId = event.currentTarget.dataset.claimId;
        if (claimId) {
            window.location.href = `/${claimId}`;
        }
    }

    getRiskIconClass(fraudStatus) {
        return fraudStatus === 'High Risk' ? 'risk-high' : 
               fraudStatus === 'Medium Risk' ? 'risk-medium' : 'risk-low';
    }

    getRiskIcon(fraudStatus) {
        return fraudStatus === 'High Risk' ? 'utility:warning' : 
               fraudStatus === 'Medium Risk' ? 'utility:info' : 'utility:success';
    }

    get alertCount() {
        return this.receivedAlerts.length;
    }

    get newAlertCount() {
        return this.receivedAlerts.filter(a => a.isNew).length;
    }
}
