public with sharing class PaymentMonitoringService {

    public class PaymentTransaction {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String claimId { get; set; }
        @AuraEnabled public String claimName { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public String status { get; set; } // pending, processing, completed, failed
        @AuraEnabled public String method { get; set; } // ACH, Wire, Check
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public DateTime completedDate { get; set; }
        @AuraEnabled public String reference { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<PaymentTransaction> getPaymentTransactions(Integer limit_count) {
        // This is a mock implementation - in production would query actual payment records
        List<PaymentTransaction> transactions = new List<PaymentTransaction>();

        // Sample transactions for demonstration
        transactions.add(createMockTransaction('CLM-00001', 'CLM-00001', 50000, 'completed', 'ACH'));
        transactions.add(createMockTransaction('CLM-00002', 'CLM-00002', 75000, 'processing', 'Wire'));
        transactions.add(createMockTransaction('CLM-00003', 'CLM-00003', 30000, 'pending', 'Check'));
        transactions.add(createMockTransaction('CLM-00004', 'CLM-00004', 120000, 'completed', 'Wire'));
        transactions.add(createMockTransaction('CLM-00005', 'CLM-00005', 45000, 'failed', 'ACH'));

        List<PaymentTransaction> pagedTransactions = new List<PaymentTransaction>();
        for (Integer i = 0; i < limit_count && i < transactions.size(); i++) {
            pagedTransactions.add(transactions[i]);
        }
        return pagedTransactions;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getPaymentStatusSummary() {
        Map<String, Integer> summary = new Map<String, Integer>();
        summary.put('Pending', 0);
        summary.put('Processing', 0);
        summary.put('Completed', 0);
        summary.put('Failed', 0);

        List<PaymentTransaction> transactions = getPaymentTransactions(100);
        for (PaymentTransaction t : transactions) {
            Integer count = summary.get(t.status);
            summary.put(t.status, count + 1);
        }

        return summary;
    }

    @AuraEnabled
    public static void retryFailedPayment(String paymentId) {
        // Retry payment logic
        IntegrationLogService.createInfoLog(
            'Payment Service',
            'Payment retry initiated for ' + paymentId,
            null
        );
    }

    @AuraEnabled
    public static void cancelPayment(String paymentId) {
        // Cancel payment logic
        IntegrationLogService.createInfoLog(
            'Payment Service',
            'Payment cancelled: ' + paymentId,
            null
        );
    }

    private static PaymentTransaction createMockTransaction(String id, String claimName, 
                                                             Decimal amount, String status, 
                                                             String method) {
        PaymentTransaction t = new PaymentTransaction();
        t.id = id;
        t.claimId = id;
        t.claimName = claimName;
        t.amount = amount;
        t.status = status;
        t.method = method;
        t.createdDate = DateTime.now().addDays(-5);
        if (status == 'completed') {
            t.completedDate = DateTime.now().addDays(-3);
        }
        t.reference = 'REF-' + id + '-' + System.currentTimeMillis();
        if (status == 'failed') {
            t.errorMessage = 'Insufficient funds in account';
        }
        return t;
    }
}
