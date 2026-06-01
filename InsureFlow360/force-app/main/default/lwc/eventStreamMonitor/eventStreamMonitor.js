import { LightningElement, track, wire } from 'lwc';
import { subscribe, unsubscribe, onError, isEmpEnabled } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';

const CLAIM_ALERT_CHANNEL = '/event/Claim_Alert__e';

export default class EventStreamMonitor extends LightningElement {
    @track eventStream = [];
    @track isConnected = false;
    @track isLoading = false;
    @track error = null;
    @track maxEvents = 50;

    subscription = null;

    connectedCallback() {
        this.initializeEventStream();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    initializeEventStream() {
        this.isLoading = true;
        
        isEmpEnabled().then(empEnabled => {
            if (empEnabled) {
                this.handleSubscribe();
            } else {
                this.error = 'EMP API is not enabled in this org';
                this.isLoading = false;
            }
        }).catch(error => {
            this.error = 'Error checking EMP status: ' + error.body.message;
            this.isLoading = false;
        });

        // Register error listener
        onError(error => {
            this.error = 'EMP API error: ' + JSON.stringify(error);
            console.error('EMP API error:', error);
        });
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('Event received:', response);
            
            const alertType = response.data.payload.Alert_Type__c;
            const event = {
                id: response.data.payload.CreatedDate || new Date().toISOString(),
                claimId: response.data.payload.Claim_Id__c,
                fraudScore: response.data.payload.Fraud_Score__c,
                alertType: alertType,
                message: response.data.payload.Message__c,
                timestamp: new Date(response.data.payload.CreatedDate || Date.now()).toLocaleString(),
                alertIcon: this.getAlertIcon(alertType),
                alertIconClass: this.getAlertIconClass(alertType)
            };

            // Add new event to the beginning of the stream
            this.eventStream = [event, ...this.eventStream];

            // Keep only the last maxEvents
            if (this.eventStream.length > this.maxEvents) {
                this.eventStream = this.eventStream.slice(0, this.maxEvents);
            }
        };

        subscribe(CLAIM_ALERT_CHANNEL, -1, messageCallback).then(response => {
            this.subscription = response;
            this.isConnected = true;
            this.error = null;
            this.isLoading = false;
            console.log('Successfully subscribed to:', CLAIM_ALERT_CHANNEL);
        }).catch(error => {
            this.error = 'Failed to subscribe: ' + error.body.message;
            console.error('Subscription error:', error);
            this.isLoading = false;
        });
    }

    handleUnsubscribe() {
        if (this.subscription) {
            unsubscribe(this.subscription, response => {
                console.log('Successfully unsubscribed:', response);
                this.isConnected = false;
                this.subscription = null;
            });
        }
    }

    handleReconnect() {
        this.eventStream = [];
        this.handleUnsubscribe();
        this.initializeEventStream();
    }

    handleClear() {
        this.eventStream = [];
    }

    get connectionStatus() {
        return this.isConnected ? 'Connected' : 'Disconnected';
    }

    get connectionStatusClass() {
        return this.isConnected ? 'slds-text-color_success' : 'slds-text-color_error';
    }

    getAlertIconClass(alertType) {
        return alertType === 'HIGH_RISK' ? 'alert-icon-high' : 
               alertType === 'MEDIUM_RISK' ? 'alert-icon-medium' : 'alert-icon-low';
    }

    getAlertIcon(alertType) {
        return alertType === 'HIGH_RISK' ? 'utility:warning' : 
               alertType === 'MEDIUM_RISK' ? 'utility:info' : 'utility:success';
    }

    navigateToClaim(event) {
        const claimId = event.currentTarget.dataset.claimId;
        if (claimId) {
            window.location.href = `/${claimId}`;
        }
    }
}
