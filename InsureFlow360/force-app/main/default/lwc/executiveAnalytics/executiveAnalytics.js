import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getClaimsAnalytics from '@salesforce/apex/ClaimSelector.getClaimsAnalytics';

export default class ExecutiveAnalytics extends LightningElement {
    @track analytics = null;
    @track chartDataByStatus = null;
    @track chartDataByFraudRisk = null;
    @track chartDataByAmount = null;
    @track isLoading = false;
    @track error = null;

    analyticsData;

    @wire(getClaimsAnalytics)
    wiredAnalytics(result) {
        this.analyticsData = result;
        const { error, data } = result;
        if (data) {
            this.analytics = data;
            this.prepareChartData(data);
            this.error = null;
        } else if (error) {
            this.error = error.body.message;
            console.error('Error fetching analytics:', error);
        }
    }

    prepareChartData(analytics) {
        // Chart data by claim status
        this.chartDataByStatus = {
            type: 'bar',
            options: {
                indexAxis: 'y',
                responsive: true,
                plugins: {
                    legend: {
                        display: false
                    }
                }
            },
            data: {
                labels: ['Submitted', 'Under Review', 'Approved', 'Rejected', 'Settled'],
                datasets: [{
                    label: 'Claims by Status',
                    data: [
                        analytics.claimsByStatus.Submitted || 0,
                        analytics.claimsByStatus['Under Review'] || 0,
                        analytics.claimsByStatus.Approved || 0,
                        analytics.claimsByStatus.Rejected || 0,
                        analytics.claimsByStatus.Settled || 0
                    ],
                    backgroundColor: '#1296d6'
                }]
            }
        };

        // Chart data by fraud risk
        this.chartDataByFraudRisk = {
            type: 'doughnut',
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            },
            data: {
                labels: ['Low Risk', 'Medium Risk', 'High Risk'],
                datasets: [{
                    data: [
                        analytics.claimsByFraudRisk['Low Risk'] || 0,
                        analytics.claimsByFraudRisk['Medium Risk'] || 0,
                        analytics.claimsByFraudRisk['High Risk'] || 0
                    ],
                    backgroundColor: ['#388e3c', '#f57c00', '#d32f2f']
                }]
            }
        };

        // Chart data by amount range
        this.chartDataByAmount = {
            type: 'bar',
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        display: false
                    }
                }
            },
            data: {
                labels: ['< $10K', '$10K-$50K', '$50K-$100K', '$100K-$500K', '> $500K'],
                datasets: [{
                    label: 'Claims by Amount Range',
                    data: [
                        analytics.claimsByAmountRange['0-10000'] || 0,
                        analytics.claimsByAmountRange['10000-50000'] || 0,
                        analytics.claimsByAmountRange['50000-100000'] || 0,
                        analytics.claimsByAmountRange['100000-500000'] || 0,
                        analytics.claimsByAmountRange['500000+'] || 0
                    ],
                    backgroundColor: '#0070d2'
                }]
            }
        };
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.analyticsData).then(() => {
            this.isLoading = false;
        }).catch(error => {
            this.error = error.body.message;
            this.isLoading = false;
        });
    }

    get averageClaimAmount() {
        return this.analytics?.averageClaimAmount?.toFixed(2) || '0.00';
    }

    get totalClaimsValue() {
        return this.analytics?.totalClaimsValue?.toFixed(2) || '0.00';
    }

    get avgApprovalDays() {
        return this.analytics?.avgApprovalDays?.toFixed(1) || '0.0';
    }

    get fraudRatePercentage() {
        return this.analytics?.fraudRatePercentage?.toFixed(2) || '0.00';
    }
}
