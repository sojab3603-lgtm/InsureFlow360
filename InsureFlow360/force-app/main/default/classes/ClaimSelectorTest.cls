@isTest
private class ClaimSelectorTest {

    @isTest static void testGetHighValueClaims() {
        Claim__c lowClaim = new Claim__c(
            Claim_Amount__c = 5000,
            Claim_Status__c = 'Submitted'
        );

        Claim__c highClaim = new Claim__c(
            Claim_Amount__c = 20000,
            Claim_Status__c = 'Submitted'
        );

        insert new List<Claim__c>{ lowClaim, highClaim };

        List<Claim__c> highValueClaims =
            ClaimSelector.getHighValueClaims(10000);

        System.assertEquals(1, highValueClaims.size());
        System.assertEquals(highClaim.Id, highValueClaims[0].Id);
    }

    @isTest static void testGetClaimSummaryReturnsCounts() {
        Claim__c approvedClaim = new Claim__c(
            Claim_Amount__c = 10000,
            Claim_Status__c = 'Approved'
        );

        Claim__c submittedClaim = new Claim__c(
            Claim_Amount__c = 5000,
            Claim_Status__c = 'Submitted'
        );

        Claim__c highRiskClaim = new Claim__c(
            Claim_Amount__c = 50000,
            Claim_Status__c = 'Under Review',
            Fraud_Status__c = 'High Risk'
        );

        insert new List<Claim__c>{ approvedClaim, submittedClaim, highRiskClaim };

        ClaimSelector.ClaimSummary summary = ClaimSelector.getClaimSummary();

        System.assertEquals(3, summary.totalClaims);
        System.assertEquals(1, summary.approvedClaims);
        System.assertEquals(2, summary.pendingClaims);
        System.assertEquals(1, summary.highRiskClaims);
    }
}

