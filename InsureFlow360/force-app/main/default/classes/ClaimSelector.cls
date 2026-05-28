public with sharing class ClaimSelector {

    public static List<Claim__c> getHighValueClaims(
        Decimal minimumAmount
    ) {

        return [
            SELECT
                Id,
                Name,
                Claim_Amount__c,
                Claim_Status__c
            FROM Claim__c
            WHERE Claim_Amount__c >= :minimumAmount
        ];
    }
}