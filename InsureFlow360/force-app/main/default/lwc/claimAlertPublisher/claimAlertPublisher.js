import { LightningElement, wire, track } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import ClaimAlertChannel from '@salesforce/messageChannel/ClaimAlertChannel__c';
import getFraudAlerts from '@salesforce/apex/ClaimSelector.getFraudAlerts';
import { refreshApex } from '@salesforce/apex';

export default class ClaimAlertPublisher extends LightningElement {
    @track fraudAlerts = [];
    @track isLoading = false;
    @track error = null;

    @wire(MessageContext)
    messageContext;

    fraudAlertsData;

    @wire(getFraudAlerts)
    wiredFraudAlerts(result) {
        this.fraudAlertsData = result;
        const { error, data } = result;
        if (data) {
            this.fraudAlerts = data;
            this.error = null;
        } else if (error) {
            this.error = error.body.message;
            console.error('Error fetching fraud alerts:', error);
        }
    }

    handlePublishAlert(event) {
        const alert = event.currentTarget.dataset;
        const claim = this.fraudAlerts.find(c => c.Id === alert.claimId);

        if (claim) {
            const message = {
                claimId: claim.Id,
                claimName: claim.Name,
                claimAmount: claim.Claim_Amount__c,
                fraudStatus: claim.Fraud_Status__c,
                fraudScore: claim.Fraud_Score__c,
                eventType: 'alert'
            };

            publish(this.messageContext, ClaimAlertChannel, message);

            // Show confirmation
            this.dispatchEvent(
                new CustomEvent('messagepublished', {
                    detail: { message }
                })
            );
        }
    }

    handlePublishAllAlerts() {
        this.fraudAlerts.forEach(claim => {
            const message = {
                claimId: claim.Id,
                claimName: claim.Name,
                claimAmount: claim.Claim_Amount__c,
                fraudStatus: claim.Fraud_Status__c,
                fraudScore: claim.Fraud_Score__c,
                eventType: 'alert'
            };

            publish(this.messageContext, ClaimAlertChannel, message);
        });

        this.dispatchEvent(
            new CustomEvent('messagepublished', {
                detail: { count: this.fraudAlerts.length }
            })
        );
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

    get alertCount() {
        return this.fraudAlerts.length;
    }
}
