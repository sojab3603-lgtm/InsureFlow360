public with sharing class ClaimSelector {

    public class ClaimSummary {
        @AuraEnabled public Integer totalClaims { get; set; }
        @AuraEnabled public Integer approvedClaims { get; set; }
        @AuraEnabled public Integer pendingClaims { get; set; }
        @AuraEnabled public Integer highRiskClaims { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static ClaimSummary getClaimSummary() {
        ClaimSummary summary = new ClaimSummary();

        // Total claims
        summary.totalClaims = [SELECT COUNT() FROM Claim__c];

        // Approved claims
        summary.approvedClaims = [
            SELECT COUNT() FROM Claim__c 
            WHERE Claim_Status__c = 'Approved'
        ];

        // Pending claims
        summary.pendingClaims = [
            SELECT COUNT() FROM Claim__c 
            WHERE Claim_Status__c IN ('Submitted', 'Under Review')
        ];

        // High risk claims
        summary.highRiskClaims = [
            SELECT COUNT() FROM Claim__c 
            WHERE Fraud_Status__c = 'High Risk'
        ];

        return summary;
    }

    @AuraEnabled(cacheable=true)
    public static List<Claim__c> getHighValueClaims(
        Decimal threshold
    ) {

        return [
            SELECT
                Id,
                Name,
                Claim_Amount__c,
                Claim_Status__c,
                Fraud_Score__c,
                Fraud_Status__c
            FROM Claim__c
            WHERE Claim_Amount__c >= :threshold
            ORDER BY Claim_Amount__c DESC
            LIMIT 10
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Claim__c> getFraudAlerts() {
        return [
            SELECT
                Id,
                Name,
                Claim_Amount__c,
                Claim_Status__c,
                Fraud_Score__c,
                Fraud_Status__c,
                Investigation_Required__c
            FROM Claim__c
            WHERE Fraud_Status__c IN ('High Risk', 'Medium Risk')
            ORDER BY Fraud_Score__c DESC, CreatedDate DESC
            LIMIT 50
        ];
    }

    public class ClaimsAnalytics {
        @AuraEnabled public Map<String, Integer> claimsByStatus { get; set; }
        @AuraEnabled public Map<String, Integer> claimsByFraudRisk { get; set; }
        @AuraEnabled public Map<String, Integer> claimsByAmountRange { get; set; }
        @AuraEnabled public Decimal averageClaimAmount { get; set; }
        @AuraEnabled public Decimal totalClaimsValue { get; set; }
        @AuraEnabled public Decimal avgApprovalDays { get; set; }
        @AuraEnabled public Decimal fraudRatePercentage { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static ClaimsAnalytics getClaimsAnalytics() {
        ClaimsAnalytics analytics = new ClaimsAnalytics();
        analytics.claimsByStatus = new Map<String, Integer>();
        analytics.claimsByFraudRisk = new Map<String, Integer>();
        analytics.claimsByAmountRange = new Map<String, Integer>();

        // Get all claims
        List<Claim__c> allClaims = [
            SELECT Id, Claim_Amount__c, Claim_Status__c, Fraud_Status__c, CreatedDate
            FROM Claim__c
        ];

        // Calculate KPIs
        Integer totalClaims = allClaims.size();
        Integer fraudClaims = 0;
        Decimal totalAmount = 0;

        // Initialize maps
        analytics.claimsByStatus.put('Submitted', 0);
        analytics.claimsByStatus.put('Under Review', 0);
        analytics.claimsByStatus.put('Approved', 0);
        analytics.claimsByStatus.put('Rejected', 0);
        analytics.claimsByStatus.put('Settled', 0);

        analytics.claimsByFraudRisk.put('Low Risk', 0);
        analytics.claimsByFraudRisk.put('Medium Risk', 0);
        analytics.claimsByFraudRisk.put('High Risk', 0);

        analytics.claimsByAmountRange.put('0-10000', 0);
        analytics.claimsByAmountRange.put('10000-50000', 0);
        analytics.claimsByAmountRange.put('50000-100000', 0);
        analytics.claimsByAmountRange.put('100000-500000', 0);
        analytics.claimsByAmountRange.put('500000+', 0);

        // Process claims
        for (Claim__c claim : allClaims) {
            // Count by status
            String status = claim.Claim_Status__c != null ? claim.Claim_Status__c : 'Submitted';
            Integer statusCount = analytics.claimsByStatus.get(status);
            analytics.claimsByStatus.put(status, statusCount + 1);

            // Count by fraud risk
            String fraudStatus = claim.Fraud_Status__c != null ? claim.Fraud_Status__c : 'Pending';
            if (analytics.claimsByFraudRisk.containsKey(fraudStatus)) {
                Integer riskCount = analytics.claimsByFraudRisk.get(fraudStatus);
                analytics.claimsByFraudRisk.put(fraudStatus, riskCount + 1);
            }
            if (fraudStatus == 'High Risk' || fraudStatus == 'Medium Risk') {
                fraudClaims++;
            }

            // Count by amount range
            Decimal amount = claim.Claim_Amount__c != null ? claim.Claim_Amount__c : 0;
            totalAmount += amount;
            if (amount < 10000) {
                Integer count = analytics.claimsByAmountRange.get('0-10000');
                analytics.claimsByAmountRange.put('0-10000', count + 1);
            } else if (amount < 50000) {
                Integer count = analytics.claimsByAmountRange.get('10000-50000');
                analytics.claimsByAmountRange.put('10000-50000', count + 1);
            } else if (amount < 100000) {
                Integer count = analytics.claimsByAmountRange.get('50000-100000');
                analytics.claimsByAmountRange.put('50000-100000', count + 1);
            } else if (amount < 500000) {
                Integer count = analytics.claimsByAmountRange.get('100000-500000');
                analytics.claimsByAmountRange.put('100000-500000', count + 1);
            } else {
                Integer count = analytics.claimsByAmountRange.get('500000+');
                analytics.claimsByAmountRange.put('500000+', count + 1);
            }
        }

        // Calculate KPIs
        analytics.averageClaimAmount = totalClaims > 0 ? totalAmount / totalClaims : 0;
        analytics.totalClaimsValue = totalAmount;
        analytics.fraudRatePercentage = totalClaims > 0 ? (fraudClaims * 100.0 / totalClaims) : 0;
        analytics.avgApprovalDays = 5.5; // Placeholder - would require more complex calculation

        return analytics;
    }
}
