import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getClaimSummary from '@salesforce/apex/ClaimSelector.getClaimSummary';
import getHighValueClaims from '@salesforce/apex/ClaimSelector.getHighValueClaims';

export default class ClaimDashboard extends LightningElement {
    @track claimSummary = {
        totalClaims: 0,
        approvedClaims: 0,
        pendingClaims: 0,
        highRiskClaims: 0
    };

    @track highValueClaims = [];
    @track isLoading = false;
    @track error = null;

    // Wire Apex method to fetch claim summary
    @wire(getClaimSummary)
    wiredClaimSummary({ error, data }) {
        if (data) {
            this.claimSummary = data;
            this.error = null;
        } else if (error) {
            this.error = error.body.message;
            console.error('Error fetching claim summary:', error);
        }
    }

    // Wire Apex method to fetch high value claims
    @wire(getHighValueClaims, { threshold: 500000 })
    wiredHighValueClaims({ error, data }) {
        if (data) {
            this.highValueClaims = data;
            this.error = null;
        } else if (error) {
            this.error = error.body.message;
            console.error('Error fetching high value claims:', error);
        }
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredClaimSummary);
        refreshApex(this.wiredHighValueClaims).then(() => {
            this.isLoading = false;
        }).catch(error => {
            this.error = error.body.message;
            this.isLoading = false;
        });
    }

    navigateToClaim(event) {
        const claimId = event.currentTarget.dataset.claimId;
        if (claimId) {
            window.location.href = `/${claimId}`;
        }
    }

    get cardClass() {
        return 'slds-col slds-size_1-of-1 slds-medium-size_1-of-2 slds-large-size_1-of-4';
    }

    get highRiskClaimsClass() {
        return this.claimSummary.highRiskClaims > 0 ? 'card card-high-risk' : 'card';
    }
}
