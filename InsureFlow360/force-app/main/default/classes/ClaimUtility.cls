public with sharing class ClaimUtility {

    public static Boolean isHighRiskClaim(
        Claim__c claim
    ) {

        return (
            claim.Claim_Amount__c != null &&
            claim.Claim_Amount__c > 1000000
        );
    }
}