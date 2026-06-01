import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPaymentTransactions from '@salesforce/apex/PaymentMonitoringService.getPaymentTransactions';
import getPaymentStatusSummary from '@salesforce/apex/PaymentMonitoringService.getPaymentStatusSummary';
import retryFailedPayment from '@salesforce/apex/PaymentMonitoringService.retryFailedPayment';
import cancelPayment from '@salesforce/apex/PaymentMonitoringService.cancelPayment';

export default class PaymentMonitoringConsole extends LightningElement {
    @track paymentTransactions = [];
    @track statusSummary = {};
    @track isLoading = false;
    @track error = null;
    @track selectedTransactions = [];
    @track filterStatus = 'all';

    paymentsData;
    summaryData;

    @wire(getPaymentTransactions, { limit_count: 50 })
    wiredPayments(result) {
        this.paymentsData = result;
        const { error, data } = result;
        if (data) {
            const sourceArray = Array.isArray(data) ? data : [];
            const enhancedTransactions = sourceArray.map(item => {
                const transaction = item || {};
                const amountNum = transaction.amount != null ? Number(transaction.amount) : 0;
                return {
                    ...transaction,
                    // Ensure numeric amounts to avoid string concatenation in reduce
                    amount: Number.isFinite(amountNum) ? amountNum : 0,
                    statusIcon: this.getStatusIcon(transaction.status),
                    statusClass: this.getStatusClass(transaction.status),
                    isProcessing: transaction.status === 'processing',
                    errorKey: (transaction.id ? transaction.id : Math.random().toString(36).substring(2,9)) + '-error'
                };
            });
            this.paymentTransactions = this.applyFilter(enhancedTransactions);
            this.error = null;
        } else if (error) {
            this.error = error.body.message;
        }
    }

    @wire(getPaymentStatusSummary)
    wiredSummary(result) {
        this.summaryData = result;
        const { error, data } = result;
        if (data) {
            this.statusSummary = data;
        } else if (error) {
            console.error('Error fetching status summary:', error);
        }
    }

    applyFilter(data) {
        const source = Array.isArray(data) ? data : [];
        if (this.filterStatus === 'all') {
            return source;
        }
        return source.filter(t => (t.status || '').toLowerCase() === this.filterStatus.toLowerCase());
    }

    handleFilterChange(event) {
        this.filterStatus = event.detail.value;
        this.paymentTransactions = this.applyFilter(this.paymentsData.data);
    }

    handleSelectPayment(event) {
        const paymentId = event.currentTarget.dataset.paymentId;
        if (this.selectedTransactions.includes(paymentId)) {
            this.selectedTransactions = this.selectedTransactions.filter(id => id !== paymentId);
        } else {
            this.selectedTransactions = [...this.selectedTransactions, paymentId];
        }
    }

    handleRetryPayment(event) {
        const paymentId = event.currentTarget.dataset.paymentId;
        this.isLoading = true;

        retryFailedPayment({ paymentId })
            .then(() => {
                this.showToast('Success', 'Payment retry initiated', 'success');
                return refreshApex(this.paymentsData);
            })
            .then(() => {
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error.body.message;
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    handleCancelPayment(event) {
        const paymentId = event.currentTarget.dataset.paymentId;
        this.isLoading = true;

        cancelPayment({ paymentId })
            .then(() => {
                this.showToast('Success', 'Payment cancelled', 'success');
                return refreshApex(this.paymentsData);
            })
            .then(() => {
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error.body.message;
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.paymentsData).then(() => {
            refreshApex(this.summaryData);
        }).then(() => {
            this.isLoading = false;
        }).catch(error => {
            this.error = error.body.message;
            this.isLoading = false;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    getStatusIcon(status) {
        return status === 'completed' ? 'utility:success' :
               status === 'failed' ? 'utility:error' :
               status === 'processing' ? 'utility:clock' : 'utility:hourglass';
    }

    getStatusClass(status) {
        return status === 'completed' ? 'status-completed' :
               status === 'failed' ? 'status-failed' :
               status === 'processing' ? 'status-processing' : 'status-pending';
    }

    get filterOptions() {
        return [
            { label: 'All Transactions', value: 'all' },
            { label: 'Pending', value: 'pending' },
            { label: 'Processing', value: 'processing' },
            { label: 'Completed', value: 'completed' },
            { label: 'Failed', value: 'failed' }
        ];
    }

    get totalAmount() {
        const arr = Array.isArray(this.paymentTransactions) ? this.paymentTransactions : [];
        const total = arr.reduce((sum, t) => sum + (t.amount || 0), 0);
        return Number.isFinite(total) ? total.toFixed(2) : '0.00';
    }

    get completedAmount() {
        const arr = Array.isArray(this.paymentTransactions) ? this.paymentTransactions : [];
        const total = arr.filter(t => t.status === 'completed').reduce((sum, t) => sum + (t.amount || 0), 0);
        return Number.isFinite(total) ? total.toFixed(2) : '0.00';
    }
}
